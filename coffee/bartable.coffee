#!
# * BarTable, a light weight, very fast fork of
#

#   FooTable - Awesome Responsive Tables
# * Version : 2.0.1.2
# * http://fooplugins.com/plugins/bartable-jquery/
# *
# * Requires jQuery - http://jquery.com/
# *
# * Copyright 2013 Steven Usher & Brad Vincent
# * Released under the MIT license
# * You are free to use BarTable in commercial projects as long as this copyright header is left intact.
# *
# * Date: 21 Sep 2013
#
# The number of millseconds to wait before triggering the react event
# The different screen resolution breakpoints
#the selector used to find the column data in the thead
#trigger this event to force BarTable to reinitialize
#trigger this event to force BarTable to resize
#trigger this event to force BarTable to redraw
#fires when the BarTable has already been initialized
#fires before BarTable starts initializing
#fires after BarTable has finished initializing
#fires before BarTable resizes
#fires after BarTable has resized
#fires after BarTable has redrawn
#fires inside the resize function, when a breakpoint is hit
#fires when setting up column data. Plugins should use this event to capture their own info about a column
#fires when a row is removed
#fires when BarTable is reset
# Whether or not to log information to the console.

#/<summary>Simple validation of the <paramref name="plugin"/> to make sure any members called by BarTable actually exist.</summary>
#/<param name="plugin">The object defining the plugin, this should implement a string property called "name" and a function called "init".</param>
# An array containing all registered plugins.

#/<summary>Registers a <paramref name="plugin"/> and its default <paramref name="options"/> with BarTable.</summary>
#/<param name="plugin">The plugin that should implement a string property called "name" and a function called "init".</param>
#/<param name="options">The default options to merge with the BarTable's base options.</param>

#/<summary>Loops through all registered plugins and calls the "init" method supplying the current <paramref name="instance"/> of the BarTable as the first parameter.</summary>
#/<param name="instance">The current instance of the BarTable that the plugin is being initialized for.</param>

#/<summary>The main constructor call to initialize the plugin using the supplied <paramref name="options"/>.</summary>
#/<param name="options">
#/<para>A JSON object containing user defined options for the plugin to use. Any options not supplied will have a default value assigned.</para>
#/<para>Check the documentation or the default options object above for more information on available options.</para>
#/</param>
#merge user and default options

Bartable = (table, options, id) ->

  class Timer
    id: null
    busy: false

    start: (code, milliseconds) ->
      #/<summary>Starts the timer and waits the specified amount of <paramref name="milliseconds"/> before executing the supplied <paramref name="code"/>.</summary>
      #/<param name="code">The code to execute once the timer runs out.</param>
      #/<param name="milliseconds">The time in milliseconds to wait before executing the supplied <paramref name="code"/>.</param>
      return  if @busy
      @stop()
      @id = setTimeout(=>
        code()
        @id = null
        @busy = false
      , milliseconds)
      @busy = true

    stop: ->
      #/<summary>Stops the timer if its runnning and resets it back to its starting state.</summary>
      if @id isnt null
        clearTimeout @id
        @id = null
        @busy = false

  class TableRowCollection
    transformIn: null
    transformOut: null
    _noTransform: false

    constructor: ({@transformOut, @transformIn}) ->
      @tbody = document.createElement 'tbody'

    each: (func) ->
      if @_noTransform
        _.each @tbody.children, (node, index) ->
          node = node.cloneNode true
          func node, index
      else
        _.each @tbody.children, (node, index) ->
          node = node.cloneNode true
          @transformOut?(node)
          func node, index

    clear: ->
      tbody = @tbody
      childs = tbody.children
      while childs.length
        tbody.removeChild childs[0]
      true

    querySelectorAll: (selector, func) ->
      if @_noTransform
        _.each @tbody.querySelector selector, (node, index) ->
          node = node.cloneNode true
          func node, index
      else
        _.each @tbody.querySelector selector, (node, index) ->
          node = node.cloneNode true
          @transformOut?(node)
          func node, index

    querySelector: (selector) ->
      node = @tbody.querySelectorAll selector
      if node
        node = node.cloneNode true
        @transformOut?(node)
      node

    _getById: (id) ->
      @tbody.children[id]

    getById: (id) ->
      row = @_getById id
      row = row.cloneNode true
      @transformOut?(row)
      row

    _item: (position) ->
      @tbody.children[position]

    item: (position) ->
      row = @_item position
      row = row.cloneNode true
      @transformOut?(row)
      row

    # optimized
    range: (start, end, func) ->
      `var i = start, childs = this.tbody.children, node;
      if (end >= childs.length) end = childs.length - 1;
      for (; i <= end; ++i) {
        node = childs[i].cloneNode(true);
        if (typeof this.transformOut == 'function') this.transformOut(node);
        func(node);
      }`
      true


    add: (row) ->
      @transformIn?(row)
      @tbody.appendChild row
      row

    addAt: (row, position) ->
      curRow = @_item position
      @transformIn?(row)
      if curRow
        @tbody.insertBefore row, curRow
      else
        @tbody.appendChild row
      row

    # inplace moving for sorting
    moveById: (id, position) ->
      row = @_getById id
      curRow = @_item position
      if curRow and row != curRow
        @tbody.insertBefore row, curRow
      row

    moveNode: (node, position) ->
      curRow = @_item position
      if curRow and node != curRow
        @tbody.insertBefore node, curRow
      node

    append: (row) ->
      @transformIn?(row) unless @_noTransform
      @tbody.appendChild row
      row

    prepend: (row) ->
      @transformIn?(row) unless @_noTransform
      @tbody.prepend row
      row

    removeRows: (rows) ->
      _.each rows, (row) =>
        @tbody.removeChild row

    # optimized
    removeByIds: (ids) ->
      tbody = @tbody
      childs = tbody.children
      for id in ids
        tbody.removeChild childs.namedItem id
      true

    removeById: (id) ->
      row = @_getById id
      row = @tbody.removeChild row
      row

    removeByPosition: (position) ->
      row = @_item position
      row = @tbody.removeChild row
      row

    size: () ->
      @tbody.children.length


  #/<summary>Inits a new instance of the plugin.</summary>
  #/<param name="t">The main table element to apply this plugin to.</param>
  #/<param name="o">The options supplied to the plugin. Check the defaults object to see all available options.</param>
  #/<param name="id">The id to assign to this instance of the plugin.</param>
  bt = this
  bt.id = id
  bt.table = table
  bt.options = options
  bt.breakpoints = []
  bt.displayStart = 0
  bt.displayEnd = null
  bt.breakpointNames = ""
  bt.columns = {}
  bt.plugins = $.fn.bartable.global.plugins.load(bt)
  opt = bt.options
  ids = opt.ids
  cls = opt.classes
  evt = opt.events
  trg = opt.triggers
  attrs = opt.attrs

  _.each ids, (id, key) ->
    opt.ids[key] = id + '-' + bt.id

  # lowlevel dom utils to avoid jQuery slowness
  clSplitRe = /\s+/
  bt.domUtils =
    removeClass: (node, className) ->
      node.className = _.without(String(node.className).split(clSplitRe), className).join " "
    addClass: (node, className) ->
      node.className = _.uniq(String(node.className).split(clSplitRe).concat className).join " "
    hasClass: (node, className) ->
      _.contain String(node.className).split(clSplitRe), className

  bt.insertPosition =
    registered: []
    register: (func) ->
      @registered.push func
    get: (row, size) ->
      # the default is to insert at the end.
      def = size
      for func in @registered
        # pass the size along as an optimization for insertion sorting
        def = func row, def, size
      def

  # This object simply houses all the timers used in the BarTable.
  bt.timers =
    resize: new Timer()
    register: (name) ->
      bt.timers[name] = new Timer()
      bt.timers[name]

  bt.init = ->
    bt.rowCollection = new TableRowCollection
      transformIn:  bt._beforeRowAdd
      transformOut: bt._beforeRowFetch

    $window = $(window)
    $table = $(bt.table)

    $table.find('>thead').attr 'id', ids.thead
    $table.find('>tbody').attr 'id', ids.tbody
    $table.find('>tfoot').attr 'id', ids.tfoot

    $.fn.bartable.global.plugins.init bt
    if $table.hasClass(cls.loaded)

      #already loaded BarTable for the table, so don't init again
      bt.raise evt.alreadyInitialized
      return

    # maybe bind the toggle selector click events
    bt.bindToggleSelectors()

    #raise the initializing event
    bt.raise evt.initializing
    $table.addClass cls.loading

    # Get the column data once for the life time of the plugin
    $table.find(opt.columnDataSelector).each ->
      data = bt.getColumnData(this)
      bt.columns[data.index] = data


    # Create a nice friendly array to work with out of the breakpoints object.
    for name of opt.breakpoints
      bt.breakpoints.push
        name: name
        width: opt.breakpoints[name]

      bt.breakpointNames += (name + " ")

    # Sort the breakpoints so the smallest is checked first
    bt.breakpoints.sort (a, b) ->
      a["width"] - b["width"]


    #bind to BarTable initialize trigger

    #remove previous "state" (to "force" a resize)

    #trigger the BarTable resize

    #remove the loading class

    #add the BarTable and loaded class

    #raise the initialized event

    #bind to BarTable redraw trigger

    #bind to BarTable resize trigger
    $table.unbind(trg.initialize).bind(trg.initialize, ->
      $table.removeData "bartable_info"
      $table.data "breakpoint", ""
      bt.addRows $table.find("tbody##{ids.tbody} > tr"), false
      $table.trigger trg.resize
      $table.removeClass cls.loading
      $table.addClass(cls.loaded).addClass cls.main
      bt.raise evt.initialized
    ).unbind(trg.redraw).bind(trg.redraw, ->
      bt.redraw()
    ).unbind(trg.resize).bind(trg.resize, ->
      bt.resize()
    ).unbind(trg.expandFirstRow).bind(trg.expandFirstRow, ->
      bt.toggleExpandFirst()
    ).unbind(trg.expandAll).bind(trg.expandAll, ->
      bt.toggleExpendAll()
    ).unbind(trg.collapseAll).bind trg.collapseAll, ->
      bt.toggleCollapseAll()

    #bind to window resize
    $window.bind "resize.bartable", ->
      bt.timers.resize.stop()
      bt.timers.resize.start (->
        bt.raise trg.resize
      ), opt.delay

    #trigger a BarTable initialize
    $table.trigger trg.initialize


  bt.addRowToggle = ->
    return unless opt.addRowToggle

    #first remove all toggle spans
    _.each bt.table.querySelector "tbody##{ids.tbody} > tr[#{attrs.trow}] > td > span.#{cls.toggle}", (toggle) ->
      toggle.parentElement.removeChild toggle
    for c of bt.columns
      col = bt.columns[c]
      if col.toggle
        selector = "tbody##{ids.tbody} > tr[#{attrs.trow}] > td:nth-child(" + (parseInt(col.index, 10) + 1) + ")"
        _.each bt.table.querySelectorAll(selector), (cell) ->
          child = document.createElement 'span'
          child.className = cls.toggle
          if cell.firstChild
            cell.insertBefore child, cell.firstChild
          else
            cell.appendChild child
        break
    bt

  bt.setColumnClasses = ->
    table = bt.table
    splitRe = /\s+/
    for c of bt.columns
      col = bt.columns[c]
      if col.className isnt null
        selector = "tbody##{ids.tbody} > tr[#{attrs.trow}] > td:nth-child(" + col.index + ")"
        _.each table.querySelectorAll(selector), (cell) ->
          bt.domUtils.addClass cell, col.className

  bt.bindToggleSelectors = ->
    $table = $(bt.table)
    $table.on "click.#{trg.toggleRow}", "tbody##{ids.tbody} > tr[#{attrs.trow}] > td > span.#{cls.toggle}", (e) ->
      $row = $(@).closest "tr"
      bt.toggleDetail $row
    true

  bt.toggleExpendAll = ->
    selector = "tbody##{ids.tbody} > tr[#{attrs.trow}]"
    _.each bt.table.querySelectorAll(selector), (row) ->
      bt.domUtils.removeClass row, cls.detailShow
      bt.toggleDetail row

  bt.toggleCollapseAll = ->
    selector = "tbody##{ids.tbody} > tr[#{attrs.trow}]"
    _.each bt.table.querySelectorAll(selector), (row) ->
      bt.domUtils.addClass row, cls.detailShow
      bt.toggleDetail row

  bt.toggleExpandFirst = ->
    selector = "tbody##{ids.tbody} > tr[#{attrs.trow}]:first"
    row = bt.table.querySelector selector
    bt.domUtils.removeClass row, cls.detailShow
    bt.toggleDetail row

  bt.toggleDetail = (row) ->
    $row = (if (row.jquery) then row else $(row))
    $next = $row.next()

    #check if the row is already expanded
    if $row.hasClass(cls.detailShow)
      $row.removeClass cls.detailShow

      #only remove the next row if it's a detail row
      if $next.hasClass(cls.detail)
        $next.remove()
        bt.raise evt.rowCollapsed,
          row: $row[0]

    else
      $row.addClass(cls.detailShow)
      bt.createOrUpdateDetailRow($row[0])?.show()
      bt.raise evt.rowExpanded,
        row: $row[0]

  bt.createOrUpdateDetailRow = (actualRow) ->
    $row = $(actualRow)
    $next = $row.next()
    values = []
    return null  if $row.is(":hidden") #if the row is hidden for some reason (perhaps filtered) then get out of here
    bt.raise evt.rowDetailUpdating,
      row: $row
      detail: $next

    $row.find("> td:hidden").each ->
      index = $(this).index()
      column = bt.columns[index]
      name = column.name
      return true  if column.ignore is true
      values.push
        name: name
        value: bt.parse(this, column)
        display: $.trim($(this).html())
      true

    return null  if values.length is 0 #return if we don't have any data to show
    colspan = $row.find("> td:visible").length
    exists = $next.hasClass(cls.detail)
    unless exists # Create
      $next = $("<tr data-bartable_detail=\"1\" class=\"" + cls.detail + "\"><td class=\"" + cls.detailCell + "\"></td></tr>")
      $row.after $next
    $detail = $next.find("> td:first").attr "colspan", colspan
    $details = $('<div class="table-responsive"/>')

    # XXX make more customizable, uses Twitter Bootstrap 3 table defs
    detailHtml = """<table class="table table-condensed table-bordered"><tbody>"""
    for value in values
      detailHtml += """
        <tr>
          <td class="text-right text-primary">
            #{value.name}
          </td>
          <td class="text-center">
            #{value.display}
          </td>
        </tr>
        """
    detailHtml += "</tbody></table>"
    $details.append detailHtml

    $detail.empty().append $details
    bt.raise evt.rowDetailUpdated,
      row: $row
      detail: $next

    $next


  bt.parse = (cell, type) ->
    parser = opt.parsers[type] or opt.parsers.alpha
    parser cell

  bt.getColumnData = (th) ->
    $th = $(th)
    hide = $th.data("hide")
    index = $th.index()
    hide = hide or ""
    hide = jQuery.map(hide.split(","), (a) ->
      jQuery.trim a
    )
    data =
      index: index
      hide: {}
      type: $th.data("type") or "alpha"
      name: $th.data("name") or $.trim($th.text())
      ignore: $th.data("ignore") or false
      toggle: $th.data("toggle") or false
      className: $th.data("class") or null

    data.hide["default"] = ($th.data("hide") is "all") or ($.inArray("default", hide) >= 0)
    hasBreakpoint = false
    for name of opt.breakpoints
      data.hide[name] = ($th.data("hide") is "all") or ($.inArray(name, hide) >= 0)
      hasBreakpoint = hasBreakpoint or data.hide[name]
    data.hasBreakpoint = hasBreakpoint
    e = bt.raise(evt.columnData,
      column:
        data: data
        th: th
    )
    e.column.data

  bt.getViewportWidth = ->
    window.innerWidth or ((if document.body then document.body.offsetWidth else 0))

  bt.calculateWidth = ($table, info) ->
    return opt.calculateWidthOverride($table, info)  if jQuery.isFunction(opt.calculateWidthOverride)
    info.width = info.viewportWidth  if info.viewportWidth < info.width
    info.width = info.parentWidth  if info.parentWidth < info.width
    info

  bt.hasBreakpointColumn = (breakpoint) ->
    for c of bt.columns
      if bt.columns[c].hide[breakpoint]
        continue  if bt.columns[c].ignore
        return true
    false

  bt.hasAnyBreakpointColumn = ->
    for c of bt.columns
      return true  if bt.columns[c].hasBreakpoint
    false

  bt.resize = ->
    $table = $(bt.table)
    return  unless $table.is(":visible")
    #we only care about BarTables that are visible
    return  unless bt.hasAnyBreakpointColumn()
    #we only care about BarTables that have breakpoints
    info =
      width: $table.width() #the table width
      viewportWidth: bt.getViewportWidth() #the width of the viewport
      parentWidth: $table.parent().width() #the width of the parent

    info = bt.calculateWidth($table, info)
    pinfo = $table.data("bartable_info")
    $table.data "bartable_info", info
    bt.raise evt.resizing,
      old: pinfo
      info: info


    # This (if) statement is here purely to make sure events aren't raised twice as mobile safari seems to do
    if not pinfo or (pinfo and pinfo.width and pinfo.width isnt info.width)
      current = null
      breakpoint = undefined
      i = 0

      while i < bt.breakpoints.length
        breakpoint = bt.breakpoints[i]
        if breakpoint and breakpoint.width and info.width <= breakpoint.width
          current = breakpoint
          break
        i++
      breakpointName = ((if current is null then "default" else current["name"]))
      hasBreakpointFired = bt.hasBreakpointColumn(breakpointName)
      previousBreakpoint = $table.data("breakpoint")
      $table.data("breakpoint", breakpointName).removeClass("default breakpoint").removeClass(bt.breakpointNames).addClass breakpointName + ((if hasBreakpointFired then " breakpoint" else ""))

      #only do something if the breakpoint has changed
      if breakpointName isnt previousBreakpoint

        #trigger a redraw
        $table.trigger trg.redraw

        #raise a breakpoint event
        bt.raise evt.breakpoint,
          breakpoint: breakpointName
          info: info

    bt.raise evt.resized,
      old: pinfo
      info: info

  bt.getRangeInfo = ->
    start = 0
    end = bt.rowCollection.size()
    start = bt.displayStart  if bt.displayStart isnt null
    end = bt.displayEnd  if bt.displayEnd isnt null
    {start, end}

  # public interface, tells the backgroundQueue it needs to run again
  # or it needs to start running if it's not
  bt.redraw = ->
    $table = $(bt.table)
    $table.addClass cls.loading
    tbody = bt.table.querySelector("tbody##{ids.tbody}")

    {start, end} = bt.getRangeInfo()

    newTbody = document.createElement 'tbody'
    newTbody.className = tbody.className
    newTbody.setAttribute 'id', tbody.getAttribute 'id'
    bt.rowCollection.range start, end, (row) ->
      newTbody.appendChild row

    bt.table.replaceChild newTbody, tbody

    # maybe add the toggler to each row
    bt.addRowToggle()

    #set any cell classes defined for the columns
    bt.setColumnClasses()

    bt._updateBreakpoints()

    bt._updateDetailShowRows()

    $table.removeClass cls.loading
    bt.raise evt.redrawn


  bt._updateBreakpoints = ->
    $table = $(bt.table)
    breakpointName = $table.data("breakpoint")
    # last-child breaks ie8
    _.each bt.table.querySelectorAll("thead##{ids.thead} > tr:last-child > th"), (headCell, index) ->
      data = bt.columns[index]
      # breaks ie8 support because of nth-child selector
      selector = "tbody##{ids.tbody} > tr > td:nth-child(" + (index + 1) + ")"
      selector += ", tfoot##{ids.tfoot} > tr > td:nth-child(" + (index + 1) + ")"
      if data.hide[breakpointName] is false
        _.each bt.table.querySelectorAll(selector), (cell) ->
          if cell.style.display
            cell.style.display = "table-cell"
          if headCell.style.display
            headCell.style.display = "table-cell"
      else
        _.each bt.table.querySelectorAll(selector), (cell) ->
          cell.style.display = "none"
          headCell.style.display = "none"
    bt

  bt._updateDetailShowRows = ->
    $table = $(bt.table)
    _.each bt.table.querySelectorAll("tbody##{ids.tbody} > tr.#{cls.detailShow}"), (row) ->
      bt.createOrUpdateDetailRow(row)?.show()
    bt

  bt.$ = (selector, func) ->
    bt.rowCollection.querySelectorAll selector, func

  bt.removeRowsByIds = (ids) ->
    bt.rowCollection.removeByIds ids
    if ids.length
      bt.raise evt.rowsRemoved
      bt.redraw()

  bt.getRowById = (id) ->
    bt.rowCollection.getById id

  bt.replaceRows = (rows) ->
    if _.isString rows
      tbody = document.createElement 'tbody'
      tbody.innerHTML = rows
      rows = tbody.children

    size = bt.rowCollection.size()
    hasRows = !! rows.length
    while rows.length
      row = rows[0]
      # get the new row position, insertion sort
      bt.rowCollection.removeById row.getAttribute attrs.trow
      insertPosition = bt.insertPosition.get row, size - 1
      bt.rowCollection.addAt row, insertPosition

    if hasRows
      bt.raise evt.rowsChanged
      bt.redraw()
    bt

  bt.addRows = (rows, redraw) ->
    if _.isString rows
      tbody = document.createElement 'tbody'
      tbody.innerHTML = rows
      rows = tbody.children

    size = bt.rowCollection.size()
    origSize = size
    while rows.length
      row = rows[0]
      if size
        insertPosition = bt.insertPosition.get row, size
        bt.rowCollection.addAt row, insertPosition
      else
        bt.rowCollection.add row
      size++

    if size != origSize and redraw isnt false
      bt.raise evt.rowsAdded
      bt.redraw()
    bt

  bt._beforeRowAdd = (row) ->
    id = row.getAttribute attrs.trow
    row.removeAttribute attrs.trow
    id = bt.generateId() unless id
    row.setAttribute 'id', id

  bt._beforeRowFetch = (row) ->
    id = row.getAttribute 'id'
    row.removeAttribute 'id'
    id = bt.generateId() unless id
    row.setAttribute attrs.trow, id

  bt.generateId = ->
    d = new Date().getTime()
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
      r = undefined
      r = (d + Math.random() * 16) % 16 | 0
      d = Math.floor(d / 16)
      ((if c is "x" then r else r & 0x7 | 0x8)).toString 16

  ##########################################################
  # The following _ methods are thin wrappers around the DOM
  # for the internal represention we keep of the TBody TR
  # collection. We use this instead of jQuery because jQuery
  # is too slow. We also need to keep an internal copy of
  # the nodes which are not rendered to the DOM
  ##########################################################


  bt.raise = (eventName, args) ->
    bt.options.log eventName, "event"  if bt.options.debug is true and $.isFunction(bt.options.log)
    args = args or {}
    def = bt: bt
    $.extend true, def, args
    e = $.Event(eventName, def)
    $.extend true, e, def  unless e.bt
    #pre jQuery 1.6 which did not allow data to be passed to event object constructor
    $(bt.table).trigger e
    e


  #reset the state of BarTable
  bt.reset = ->
    $table = $(bt.table)
    $table.removeData("bartable_info").data("breakpoint", "").removeClass(cls.loading).removeClass cls.loaded
    $table.off "click.#{trg.toggleRow}"
    bt.rowCollection.clear()
    bt.raise evt.reset

  bt.clear = ->
    bt.rowCollection.clear()
    bt.redraw()

  # because plugins may register events on external elements
  bt.destroy = ->
    bt.rowCollection.clear()
    $.fn.bartable.global.plugins.destroy bt
    $(bt.table).remove()

  bt.init()
  bt

instanceCount = 0
$.fn.bartable = (options) ->
  options = options or {}
  o = $.extend(true, {}, $.fn.bartable.global.options, options)
  @each ->
    instanceCount++
    bartable = new Bartable(this, o, instanceCount)
    $(@).data "bartable", bartable

$.fn.bartable.global =
  options:
    delay: 100
    breakpoints:
      phone: 480
      tablet: 1024

    parsers:
      alpha: (cell) ->
        cell.getAttribute("data-value") or $.trim(cell.textContent || cell.innerText || "")

      numeric: (cell) ->
        val = cell.getAttribute("data-value") or (cell.textContent || cell.innerText || "0")
        val = parseFloat(val)
        val = 0  if isNaN(val)
        val

    addRowToggle: true
    calculateWidthOverride: null
    columnDataSelector: "> thead > tr:last-child > th, > thead > tr:last-child > td"
    classes:
      main: "bartable"
      loading: "bartable-loading"
      loaded: "bartable-loaded"

      # on every row, so minimize size
      toggle: "bttg"

      disabled: "bartable-disabled"
      detail: "bartable-row-detail"
      detailCell: "bartable-row-detail-cell"
      detailInner: "bartable-row-detail-inner"
      detailInnerRow: "bartable-row-detail-row"
      detailInnerGroup: "bartable-row-detail-group"
      detailInnerName: "bartable-row-detail-name"
      detailInnerValue: "bartable-row-detail-value"
      detailShow: "bartable-detail-show"

    attrs:
      # om every row, minimize size
      trow: "data-btid"

    ids:
      tbody: "bartable-tbody"
      tfoot: "bartable-tfoot"
      thead: "bartable-thead"

    triggers:
      initialize: "bartable_initialize"
      resize: "bartable_resize"
      redraw: "bartable_redraw"
      toggleRow: "bartable_toggle_row"
      expandFirstRow: "bartable_expand_first_row"
      expandAll: "bartable_expand_all"
      collapseAll: "bartable_collapse_all"

    events:
      alreadyInitialized: "bartable_already_initialized"
      initializing: "bartable_initializing"
      initialized: "bartable_initialized"
      resizing: "bartable_resizing"
      resized: "bartable_resized"
      redrawn: "bartable_redrawn"
      breakpoint: "bartable_breakpoint"
      columnData: "bartable_column_data"
      rowDetailUpdating: "bartable_row_detail_updating"
      rowDetailUpdated: "bartable_row_detail_updated"
      rowsChanged: "bartable_rows_changed"
      rowsRemoved: "bartable_rows_removed"
      rowsAdded: "bartable_rows_added"
      rowCollapsed: "bartable_row_collapsed"
      rowExpanded: "bartable_row_expanded"
      rowInsertPosition: "bartable_row_insert_position"
      reset: "bartable_reset"

    debug: false
    log: null

  version:
    major: 0
    minor: 5
    toString: ->
      $.fn.bartable.global.version.major + "." + $.fn.bartable.global.version.minor

    parse: (str) ->
      version = /(\d+)\.?(\d+)?\.?(\d+)?/.exec(str)
      major: parseInt(version[1], 10) or 0
      minor: parseInt(version[2], 10) or 0
      patch: parseInt(version[3], 10) or 0

  plugins:
    _validate: (plugin) ->
      unless $.isFunction(plugin)
        console.error "Validation failed, expected type \"function\", received type \"{0}\".", typeof plugin  if $.fn.bartable.global.options.debug is true
        return false
      p = new plugin()
      if typeof p["name"] isnt "string"
        console.error "Validation failed, plugin does not implement a string property called \"name\".", p  if $.fn.bartable.global.options.debug is true
        return false
      unless $.isFunction(p["init"])
        console.error "Validation failed, plugin \"" + p["name"] + "\" does not implement a function called \"init\".", p  if $.fn.bartable.global.options.debug is true
        return false
      console.log "Validation succeeded for plugin \"" + p["name"] + "\".", p  if $.fn.bartable.global.options.debug is true
      true

    registered: []
    register: (plugin, options) ->
      if $.fn.bartable.global.plugins._validate(plugin)
        $.fn.bartable.global.plugins.registered.push plugin
        $.extend true, $.fn.bartable.global.options, options  if typeof options is "object"

    load: (instance) ->
      loaded = []
      registered = undefined
      i = undefined
      i = 0
      while i < $.fn.bartable.global.plugins.registered.length
        try
          registered = $.fn.bartable.global.plugins.registered[i]
          loaded.push new registered(instance)
        catch err
          console.error err  if $.fn.bartable.global.options.debug is true
        i++
      loaded

    init: (instance) ->
      i = 0

      if $.fn.bartable.global.options.debug
        while i < instance.plugins.length
          instance.plugins[i]["init"] instance
          i++
      else
        while i < instance.plugins.length
          try
            instance.plugins[i]["init"] instance
          catch err
            # ignore
          i++
      i
    destroy: (instance) ->
      i = 0
      if $.fn.bartable.global.options.debug
        while i < instance.plugins.length
          plugin = instance.plugins[i]
          if plugin.destroy
            plugin.destroy instance
          i++
      else
        while i < instance.plugins.length
          try
            plugin = instance.plugins[i]
            if plugin.destroy
              plugin.destroy instance
          catch err
            # ignore
          i++
      i

