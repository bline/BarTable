

Filter = ->
  f = @
  f.name = "Bartable Filter"

  f.init = (bt) ->
    return unless bt.options.filter is true
    return if $(bt.table).data('filter') is false
    evts = bt.options.events

    f.filteredElements
    f.bartable = bt
    $table = $(bt.table)
    f.filterInputSelector = $table.data('filter-input') or bt.options.filterInput
    f.search = ""
    bt.rowCollection.registerFilter f.filterRow
    f.setupFilterEvents()
    $table.unbind('.filter').bind evts.columnData + '.filter', (e) ->
      $th = $(e.column.th)
      e.column.data.filter = e.column.data.filter or {}
      e.column.data.filter.ignore = $th.data('filter-ignore') or false
      true
    f

  f.setupFilterEvents = ->
    bt = f.bartable
    f.input = $(f.filterInputSelector)
    return unless f.input.length
    f.input.off '.bartable_filter'
    f.input.on 'keydown.bartable_filter', (e) ->
      if e.which == 13
        e.preventDefault()
      true
    f.input.on 'keyup.bartable_filter', (e) ->
      bt.rowCollection.filterCheckAll()
      $(bt.table).trigger 'paging_change'
      bt.redraw()
      true
    f

  f.filterRow = (row) ->
    search = f.input.val()
    return false unless search
    bt = f.bartable
    searchList = search.toLowerCase().split /\s+/
    searchListLen = searchList.length

    cells = row.cells
    cellsLen = cells.length

    parse = bt.parse
    columns = bt.columns
    match = false
    i = 0
    while i < cellsLen
      column = columns[i]
      if column.filter.ignore or column.ignore
        ++i
        continue
      cell = cells[i]
      value = cell.getAttribute("data-value") or cell.textContent or cell.innerText || ""
      unless value
        ++i
        continue
      e = 0
      while e < searchListLen
        if value.toLowerCase().indexOf(searchList[e]) != -1
          match = true
          break
        ++e
      break if match
      ++i
    return false if match
    return true

  f.destroy = ->
    $(f.bartable.table).unbind '.filter'
    delete f.bartable
    f.input.off '.bartable_filter' if f.input
    delete f.input

  f

unless $.fn.bartable?.global?
  throw new Error("Please check and make sure bartable.js is included in the page and is loaded prior to this script.")
defaults =
  filter: true
  filterInput: '.search-filter'

$.fn.bartable.global.plugins.register Filter, defaults
