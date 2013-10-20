defaults =
  paginate: true
  pageSize: 10
  pageDisplaySize: 5
  pageNavigation: ".pagination"
  firstText: "&laquo;"
  previousText: "&lsaquo;"
  nextText: "&rsaquo;"
  lastText: "&raquo;"

pageInfo = (bt) ->
  $table = $(bt.table)

  @pageNavigation = $table.data("page-navigation") or bt.options.pageNavigation
  @pageDisplaySize = $table.data("page-display-size") or bt.options.pageDisplaySize
  @pageSize = $table.data("page-size") or bt.options.pageSize
  @firstText = $table.data("page-first-text") or bt.options.firstText
  @previousText = $table.data("page-previous-text") or bt.options.previousText
  @nextText = $table.data("page-next-text") or bt.options.nextText
  @lastText = $table.data("page-last-text") or bt.options.lastText
  @currentPage = 1
  @pageCount = 1

  @setPage = (page) ->
    @currentPage = if page > @pageCount then @pageCount else page
    @redraw()

  @setPageSize = (pageSize) ->
    @pageSize = pageSize
    @redraw()

  @redraw = () ->
    $table.trigger 'paging_change'
    bt.redraw()
  @

Paginate = ->
  p = this
  p.name = "Bartable Paginate"
  p.init = (bt) ->
    return unless bt.options.paginate is true
    return if $(bt.table).data("page") is false
    p.bartable = bt
    $table = $(bt.table)
    bt.pageInfo = new pageInfo bt unless bt.pageInfo

    triggerEvents = [
      'bartable_initialized'
      'bartable_rows_removed'
      'bartable_rows_added'
      'paging_change'
    ]
    $table.unbind '.paging'
    $table.bind(evt + '.paging', p.setupPaging) for evt in triggerEvents

  p.setupPaging = ->
    bt = p.bartable
    p.calculate()
    p.createNavigation()
    p.setOffsets()

  p.calculate = ->
    bt = p.bartable
    pageInfo = bt.pageInfo
    count = bt.rowCollection.size()

    # [ [1] 2 3 4 5 > >>       ]
    # [ < 1 [2] 3 4 5 > >>     ]
    # [ << < 2 3 [4] 5 6 > >>  ]
    # [ << < 3 4 [5] 6 7 > >>  ]
    # [ << < 4 5 [6] 7 8 > >>  ]
    # [ << < 5 6 [7] 8 9 > >>  ]
    # [ << < 6 7 [8] 9 10 > >> ]
    # [ << < 6 7 8 [9] 10 >    ]
    # [ << < 6 7 8 9 [10]      ]
    #

    p.navInfo =
      needsFirst: false
      needsLast: false
      needsPrev: false
      needsNext: false
      lastPage: 1
      pages: []
    p.offsets =
      start: 0
      end: count

    pageSize = parseInt pageInfo.pageSize, 10
    p.navInfo.lastPage = Math.ceil count / pageSize
    p.navInfo.lastPage = 1 if p.navInfo.lastPage < 1
    pageInfo.pageCount = lastPage = p.navInfo.lastPage
    firstPage = 1
    displaySize = parseInt pageInfo.pageDisplaySize, 10

    return p if lastPage <= 1 or pageSize < 1

    currentPage = parseInt pageInfo.currentPage, 10
    currentPage = lastPage if currentPage > lastPage
    currentPage = 1 if currentPage < 1
    pageInfo.currentPage = currentPage

    p.offsets.start = (currentPage - 1) * pageSize
    p.offsets.end = p.offsets.start + pageSize - 1
    p.offsets.end = count if p.offsets.end > count

    p.navInfo.needsFirst = currentPage > 2
    p.navInfo.needsLast = currentPage < lastPage - 1

    p.navInfo.needsPrev = currentPage > 1
    p.navInfo.needsNext = currentPage != lastPage

    if displaySize % 2
      left = Math.floor displaySize / 2
      right = Math.floor displaySize / 2
    else
      left = (displaySize / 2) - 1
      right = displaySize / 2


    # all pages
    if lastPage < displaySize
      [first, last] = [firstPage, lastPage]

    # left
    else if currentPage <= displaySize - left
      [first, last] = [firstPage, displaySize]
    # right
    else if currentPage > lastPage - right
      [first, last] = [(1 + lastPage) - displaySize, lastPage]
    # middle
    else
      [first, last] = [currentPage - left, currentPage + right]

    p.navInfo.pages = [first..last]
    p

  p.createNavigation = () ->
    bt = p.bartable
    $nav = $(bt.table).find(bt.pageInfo.pageNavigation)
    
    #if we cannot find the navigation control within the table, then try find it outside
    if $nav.length is 0
      $nav = $(bt.pageInfo.pageNavigation)
      
    #if we still cannot find the control, then don't do anything
    return if $nav.length is 0
    
    #if the nav is not a UL, then find or create a UL
    unless $nav.is "ul"
      $parent = $nav
      $nav = $nav.find "ul:first"
      if $nav.length is 0
        $nav = $('<ul/>').appendTo $parent
        $nav.addClass 'pagination pagination-sm'

    $nav.off('click.paging').on 'click.paging', 'a[href]', (e) ->
      e.preventDefault()
      pageInfo.setPage parseInt($(e.currentTarget).attr('href').slice(1), 10)

    $nav.find("li").remove()
    navInfo = p.navInfo
    pageInfo = bt.pageInfo
    currentPage = parseInt pageInfo.currentPage, 10
    lastPage = navInfo.lastPage
    prevPage = currentPage - 1
    nextPage = currentPage + 1
    pageInfo.control = $nav

    if navInfo.pages.length
      $first = $(""""<li><a href="#1">#{pageInfo.firstText}</a></li>""").appendTo $nav
      $first.addClass 'disabled' unless navInfo.needsFirst
      $prev = $(""""<li><a href="##{prevPage}">#{pageInfo.previousText}</a></li>""").appendTo $nav
      $prev.addClass 'disabled' unless navInfo.needsPrev

    for page in navInfo.pages
      $page = $("""<li><a href="##{page}">#{page}</a></li>""").appendTo $nav
      if page is currentPage
        $page.addClass 'active' if page == currentPage
        $page.find('a').append $("""<span class="sr-only">(current)</span>""")

    if navInfo.pages.length
      $next = $(""""<li><a href="##{nextPage}">#{pageInfo.nextText}</a></li>""").appendTo $nav
      $next.addClass 'disabled' unless navInfo.needsNext
      $last = $(""""<li><a href="##{lastPage}">#{pageInfo.lastText}</a></li>""").appendTo $nav
      $last.addClass 'disabled' unless navInfo.needsLast
    p

  p.setOffsets = ->
    bt = p.bartable
    bt.displayStart = p.offsets.start
    bt.displayEnd = p.offsets.end

  p

throw new Error("Please check and make sure bartable.js is included in the page and is loaded prior to this script.")  unless $.fn.bartable?.global?
$.fn.bartable.global.plugins.register Paginate, defaults

