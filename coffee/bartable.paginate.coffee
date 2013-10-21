defaults =
  paginate: true
  pageSize: 10
  pageDisplaySize: 5
  pageNavigation: ".pagination"
  firstText: "&laquo;"
  previousText: "&lsaquo;"
  nextText: "&rsaquo;"
  lastText: "&raquo;"
  pageSelect: ".page-select-list"

PageInfo = (bt) ->
  $table = $(bt.table)

  @pageNavigation = $table.data("page-navigation") or bt.options.pageNavigation
  @pageDisplaySize = $table.data("page-display-size") or bt.options.pageDisplaySize
  @pageSize = $table.data("page-size") or bt.options.pageSize
  @firstText = $table.data("page-first-text") or bt.options.firstText
  @previousText = $table.data("page-previous-text") or bt.options.previousText
  @nextText = $table.data("page-next-text") or bt.options.nextText
  @lastText = $table.data("page-last-text") or bt.options.lastText
  @pageSelect = $table.data("page-select") or bt.options.pageSelect
  @currentPage = 1
  @pageCount = 1
  @control = null
  @select = null

  @setPage = (page) ->
    page = if page > @pageCount then @pageCount else page
    if @currentPage != page
      @currentPage = page
      @redraw()

  @setPageSize = (pageSize) ->
    if @pageSize != pageSize
      @pageSize = pageSize
      @redraw()

  @redraw = () ->
    $table.trigger 'paging_change'
    bt.redraw()
  @

Paginate = ->
  p = this
  p.name = "Bartable Paginate"
  p.appendedNav = false
  p.init = (bt) ->
    return unless bt.options.paginate is true
    return if $(bt.table).data("page") is false
    p.bartable = bt
    $table = $(bt.table)
    bt.pageInfo = new PageInfo bt unless bt.pageInfo
    p.setupPageSelectEvents()

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
    p.setPageSelect()
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

  p.setupPageSelectEvents = ->
    bt = p.bartable
    $select = p.findPageSelect()
    return unless $select
    $select
      .off('change.bartable_paging')
      .on 'change.bartable_paging', (e) ->
        bt.pageInfo.setPageSize parseInt($(e.currentTarget).val(), 10)
    p

  p.setPageSelect = ->
    bt = p.bartable
    pageInfo = bt.pageInfo

    $select = p.findPageSelect()
    return unless $select

    $select
      .find("option[value!='#{pageInfo.pageSize}']")
      .removeAttr('selected')
    $select
      .find("option[value='#{pageInfo.pageSize}']")
      .attr('selected', 'selected')

  p.createNavigation = () ->
    bt = p.bartable
    pageInfo = bt.pageInfo

    $nav = p.findNav()
    return unless $nav

    $nav.off('click.bartable_paging').on 'click.bartable_paging', 'a[href]', (e) ->
      e.preventDefault()
      pageInfo.setPage parseInt($(e.currentTarget).attr('href').slice(1), 10)

    $nav.find("li").remove()
    navInfo = p.navInfo
    currentPage = parseInt pageInfo.currentPage, 10
    lastPage = navInfo.lastPage
    prevPage = currentPage - 1
    nextPage = currentPage + 1

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

  p.findPageSelect = ->
    bt = p.bartable
    pageInfo = bt.pageInfo

    $select = pageInfo.select
    unless $select
      $select = $(bt.table).find(bt.pageInfo.pageSelect)
      if $select.length is 0
        $select = $(bt.pageInfo.pageSelect)
      return null if $select.length is 0
      pageInfo.select = $select

    return $select

  p.findNav = ->
    bt = p.bartable
    $nav = bt.pageInfo.control
    unless $nav
      $nav = $(bt.table).find(bt.pageInfo.pageNavigation)
      #if we cannot find the navigation control within the table, then try find it outside
      if $nav.length is 0
        $nav = $(bt.pageInfo.pageNavigation)
      
      #if we still cannot find the control, then don't do anything
      return null if $nav.length is 0

      #if the nav is not a UL, then find or create a UL
      unless $nav.is "ul"
        $parent = $nav
        $nav = $nav.find "ul:first"
        if $nav.length is 0
          p.appendedNav = true
          $nav = $('<ul/>').appendTo $parent
          $nav.addClass 'pagination pagination-sm'
      bt.pageInfo.control = $nav

    return $nav

  p.destroy = ->
    console.log "pagination destroyed"
    bt = p.bartable
    $nav = p.findNav()
    if $nav
      $nav.off 'click.bartable_paging'
      $nav.find('li').remove()
      $nav.remove() if p.appendedNav
    $select = p.findPageSelect()
    $select.off 'change.bartable_paging' if $select
    delete bt.pageInfo.control
    delete bt.pageInfo.select
    delete bt.pageInfo
    delete p.bartable
    null

  p

throw new Error("Please check and make sure bartable.js is included in the page and is loaded prior to this script.")  unless $.fn.bartable?.global?
$.fn.bartable.global.plugins.register Paginate, defaults

