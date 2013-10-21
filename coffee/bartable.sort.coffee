
Sort = ->
  p = this
  p.name = "Bartable Sortable"
  p.currentSortInfo = null
  p.initialSortInfo = null
  p.columnIndices = []
  p.columnIndicesDesc = []
  p.getSortInfo = ->
    if p.currentSortInfo
      return p.currentSortInfo
    else if p.initialSortInfo
      return p.currentSortInfo = p.initialSortInfo

  # modified from _.sortedIndex to take ascending option
  p._sortedIndexDesc = (arr, high, obj, iterator) ->
    value = iterator.call(p, obj)
    low = 0
    while low < high
      mid = (low + high) >>> 1
      if iterator.call(p, arr[mid]) > value
        low = mid + 1
      else
        high = mid
    low

  p._sortedIndex = (arr, high, obj, iterator) ->
    value = iterator.call(p, obj)
    low = 0
    while low < high
      mid = (low + high) >>> 1
      if iterator.call(p, arr[mid]) < value
        low = mid + 1
      else
        high = mid
    low

  p.init = (bt) ->
    p.bartable = bt
    cls = bt.options.classes.sort

    evts = bt.options.events
    ids = bt.options.ids
    $table = $(bt.table)
    events = {}

    return if bt.options.sort isnt true

    # insertion sort, no need to resort when rows are added/changed/removed
    bt.insertPosition.register (row, def) ->
      if p.currentSortInfo
        sortInfo = p.currentSortInfo
      else if p.initialSortInfo
        sortInfo = p.currentSortInfo = p.initialSortInfo
      else
        return def

      column = sortInfo.sortColumn
      match = column.sort.match
      type = column.type
      parse = bt.parse
      childs = bt.rowCollection.tbody.children
      if sortInfo.ascending
        return p._sortedIndex childs, def, row, (row) ->
          parse row.cells[match], type
      else
        return p._sortedIndexDesc childs, def, row, (row) ->
          parse row.cells[match], type

    events[evts.initialized + ".sorting"] = (e) ->
      return if $table.data("sort") is false
      selector = "thead##{ids.thead} > tr:last-child > th, > thead##{ids.thead} > tr:last-child > td"
      $table.find(selector).each ->
        $th = $(this)
        column = bt.columns[$th.index()]

        if column.sort.ignore isnt true and not $th.hasClass(cls.sortable)
          $th.addClass cls.sortable
          $("<span />").addClass(cls.indicator).appendTo $th

      for k, column of bt.columns
        if column.sort.initial
          p.initialSortInfo =
            ascending: (column.sort.initial isnt "descending")
            sortColumn: column
          break

      p.adjustColumnHeaders()

      selector = "thead##{ids.thead} > tr:last-child > th.#{cls.sortable}, thead##{ids.thead} > tr:last-child > td.#{cls.sortable}"
      $table.find(selector).unbind("click.bartable").bind "click.bartable", (ec) ->
        ec.preventDefault()
        $th = $(this)
        ascending = not $th.hasClass(cls.sorted)
        p.currentSortInfo =
          ascending: ascending
          sortColumn: bt.columns[$th.index()]
        p.doSort()
        bt.redraw()
        false
      true

    events[evts.columnData + ".sorting"] = (e) ->
      $th = $(e.column.th)
      e.column.data.sort = e.column.data.sort or {}
      e.column.data.sort.initial = $th.data("sort-initial") or false
      e.column.data.sort.ignore = $th.data("sort-ignore") or false
      e.column.data.sort.match = $th.data("sort-match") or e.column.data.index

    $(bt.table).unbind(".sorting").bind events

  p.getAscendingToggle = ->
    bt = p.bartable
    ids = bt.options.ids
    sortInfo = p.getSortInfo()
    cls = bt.options.classes.sort
    $table = $(bt.table)

    column = sortInfo.sortColumn
    ascending = sortInfo.ascending

    $th = $table.find("thead##{ids.thead} > tr:last-child > th:eq(#{column.index}), thead##{ids.thead} > tr:last-child > td:eq(#{column.index})").first()
    ascending = (if (ascending is `undefined`) then $th.hasClass(cls.sorted) else (if (ascending is "toggle") then not $th.hasClass(cls.sorted) else ascending))
    ascending

  p.adjustColumnHeaders = ->
    bt = p.bartable
    ids = bt.options.ids
    cls = bt.options.classes.sort

    $table = $(bt.table)

    sortInfo = p.getSortInfo()
    return unless sortInfo
    column = sortInfo.sortColumn
    ascending = sortInfo.ascending

    $th = $table.find("thead##{ids.thead} > tr:last-child > th:eq(#{column.index}), thead##{ids.thead} > tr:last-child > td:eq(#{column.index})").first()
    $table.find("thead##{ids.thead} > tr:last-child > th, thead##{ids.thead} > tr:last-child > td")
      .not($th)
      .removeClass cls.sorted + ' ' + cls.descending
    ascending = $th.hasClass(cls.sorted)  if ascending is `undefined`
    if ascending
      $th.removeClass(cls.descending).addClass cls.sorted
    else
      $th.removeClass(cls.sorted).addClass cls.descending

  p.doSort = ->
    bt = p.bartable
    sortInfo = p.getSortInfo()
    column = sortInfo.sortColumn
    ascending = sortInfo.ascending
    $table = $(bt.table)

    return if column.sort.ignore is true

    cls = bt.options.classes.sort
    evt = bt.options.events.sort

    #raise a pre-sorting event so that we can cancel the sorting if needed
    event = bt.raise(evt.sorting,
      column: column
      direction: (if ascending then "ASC" else "DESC")
    )
    return if event and event.result is false

    $table.data "sorted", column.index
    ascending = p.getAscendingToggle()

    p.currentSortInfo =
      ascending: ascending
      sortColumn: column

    p.adjustColumnHeaders()
    p.sort()
    bt.raise evt.sorted,
      column: column
      direction: (if ascending then "ASC" else "DESC")

  # optimized
  p.sort = ->
    `var child, insertPosition, tr, i`
    bt = p.bartable
    colBodyChilds = bt.rowCollection.tbody.children
    tbodyLen = colBodyChilds.length
    return unless tbodyLen
    sortInfo = p.currentSortInfo
    column = sortInfo.sortColumn
    ascending = sortInfo.ascending

    tbody = document.createElement 'tbody'
    parse = bt.parse
    sortedIndex = if ascending then p._sortedIndex else p._sortedIndexDesc
    match = column.sort.match
    type = column.type
    tbodyChildren = tbody.children
    tbody.appendChild colBodyChilds[0].cloneNode()
    `for (i = 1; i < tbodyLen; ++i) {
      tr = colBodyChilds[i];
      insertPosition = sortedIndex(tbodyChildren, i, tr, function (row) {
        return parse(row.cells[match], type);
      });
      child = tbodyChildren[insertPosition];
      tbody.insertBefore(tr.cloneNode(), child);
    }`
    bt.rowCollection.tbody = tbody
    p

  p

unless $.fn.bartable?.global?
  throw new Error("Please check and make sure bartable.js is included in the page and is loaded prior to this script.")
defaults =
  sort: true
  classes:
    sort:
      sortable: "bartable-sortable"
      sorted: "bartable-sorted"
      descending: "bartable-sorted-desc"
      indicator: "bartable-sort-indicator"

  events:
    sort:
      sorting: "bartable_sorting"
      sorted: "bartable_sorted"

$.fn.bartable.global.plugins.register Sort, defaults
