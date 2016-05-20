##
# EventSource parsing events from remote JSON file
# options:
#   calendar: overide calendar_id of all events
#   paremeterless: if data source support quering for date range and calendar_id
#   url: url of remote data source
class JSONEventSource
  constructor: (options, @data_callback, @event_callback) ->
    @calendar = options.calendar
    @parameterless = options.parameterless
    @url = options.url


  ##
  # Return event overlaping given period [start, end] in given calendar
  #  if calendar == null then match any event
  #  token must be resend via callback
  fetch:(start, end, calendar, token) =>
    results = []

    if @calendar? and @calendar isnt calendar
      @callback(token, [])
    else
      data = {}
      # if server accept parameters
      unless @parameterless
        data =
          start_date: start.toISOString()
          end_date: end.toISOString()

        calendar =
        data['calendar_id'] = calendar unless @calendar?

      # perform AJAX query
      data_callback = @data_callback
      event_callback = @event_callback
      
      $.getJSON(@url, data)
      .done (json) ->
        data_callback(token, (new Event(event, event_callback) for event in json))
      .fail ( jqxhr, textStatus, error) ->
        # TODO do something with errors
        alert(jqxhr, textStatus, error)
        # complete request without data
        callback(token, [])

class ArrayEventSource
  constructor: (options, @data_callback, @event_callback) ->
    @events = (new Event(event, @event_callback) for event in (options.data || []))
    @calendar = options.calendar

  ##
  # Return event overlaping given period [start, end] in given calendar
  #  if calendar == null then match any event
  #  token must be resend via callback
  fetch: (start, end, calendar, token) =>
    results = []

    p = (not calendar?) or (@calendar? and @calendar is calendar)
    if p or (not @calendar?)
      for event in @events
        if (p or (not event.calendar?) or (event.calendar is calendar)) and event.overlap_range(start, end)
          results.push event

    # send back events
    @data_callback(token, results)


class FunctionEventSource extends ArrayEventSource
  constructor: (options, data_callback, event_callback) ->
    @function = options.function
    delete options.data
    delete options.functon

    super(options, data_callback, event_callback)
    @events = []

  fetch: (start, end, calendar, token) ->
    events = @function(start, end, calendar)
    @events = (new Event(event, @event_callback) for event in events)

    super(start, end, calendar, token)

# Cross platform check for direct instanceOf
#  eg. instanceOf('abc', String) == true, instanceOf('', Object)
window.instanceOf = (obj, constructor) ->
  (obj != undefined) and (obj).constructor == constructor



# helper function for buildin HTML layout
# params = (shortcut, attrs, childs...)
window.tag = (name, params...) ->
  obj = $("<#{name}>")

  # use shortcut
  if instanceOf(params[0], String)
    sc = params.shift()
    klass = (sc.match(/\.[-_0-9a-z]+/gi)||[]).join('').replace(/\./g,' ').trim()
    id = ((sc.match(/\#[-_0-9a-z]+/gi)||[])[0] || '').slice(1)

    obj.attr(
      class: klass,
      id: if id == '' then null else id
    )


  # set attributes
  if instanceOf(params[0], Object)
    attrs = params.shift()
    if instanceOf(attrs['class'], Array)
      attrs['class'] = attrs['class'].join ' '
    if instanceOf(attrs['style'], Object)
      attrs['style'] = ("#{k}:#{v}" for k,v of attrs['style']).join ';'
    obj.attr(attrs)

  # append content
  for child in params
    if instanceOf(child, String)
      obj.append(document.createTextNode(child))
    else
      obj.append(child)
  obj

# tag helpers
tags =  [
  'div', 'strong', 'em', 'span', 'a', 'nav', 'i', # general
  'table', 'th', 'tr', 'td', # tables
  'ul', 'ol', 'li' #lists
]

# define shortcuts
for tag_name in tags
  do (tag_name) ->
    window[tag_name] = (params...) -> tag(tag_name, params...)


window['nbsp'] = document.createTextNode(String.fromCharCode(160))

#= require<helpers.coffee>

class Row
  constructor: (calendar, start_day) ->
    @current = calendar.current
    @days = (moment(start_day).add(d, 'days') for d in [0..6])

    @callback = calendar.callback
    @today = calendar.today

    # generate empty slots
    @slot_count = calendar.max_slots
    @slots = ((true for j in [0..@slot_count-1]) for i in [0..6])


  add: (event) ->
    [start, end] = [null, null]
    for day, i in @days
      if event.overlap_day(day)
        start ?= i
        end = i

    if start is null
      return false

    free_slot = @find_free_slot(start, end)
    if free_slot is false
      return false


    @slots[start][free_slot] = {
      event: event,
      colspan: end-start+1,
      starts_here: @days[start].isSame(event.start, 'day'),
      ends_here: @days[end].isSame(event.end, 'day'),
    }

    for j in [start+1..end] by 1
      @slots[j][free_slot] = false

    return true


  find_free_slot: (start, end) ->
    for slot in [0..@slot_count-1]
      ok = true
      for pos in [start..end]
        if @slots[pos][slot] isnt true
          ok = false
          break
      if ok is true
        return slot
    return false


  # display days numbers
  render_header: () ->
    days = []
    for day in @days
      days.push th({}, day.format('D'))

    tr('.mns-cal-row-header', days)


  # display day background below events indicating 'this month' or 'today'
  render_bg: () ->
    table('.table.table-bordered',
      tr({},
        for day in @days
          klass = {}
          klass = '.active' unless day.isSame(@current, 'month')
          klass = '.mns-cal-bg-today.info' if day.isSame(@today, 'day')
          td(klass)
      ) )

  render_slot: (id) ->
    res = []
    for day, i in @days
      obj = @slots[i][id]

      if obj is true
        res.push td({},'')
      else if instanceOf(obj, Object)
        klass = []
        klass.push 'mns-cal-starts-here' if obj.starts_here
        klass.push 'mns-cal-ends-here' if obj.ends_here
        res.push td({class: klass, colspan: obj.colspan}, obj.event.render_as_label)

    tr('.mns-cal-row', res)


  # return html representing given row
  render: () ->
    html = [@render_header()]
    for i in [0..@slot_count-1]
      html.push(@render_slot(i))

    div('.mns-cal-week', div('.mns-cal-bg', @render_bg() ), div('.mns-cal-rows', table('.table.table-condensed', html ) ) )

class Event
  defaults =
    name: 'Event'
    start: undefined
    end: undefined
    day_long: undefined
    icon: undefined # font-awesome icon suffix, eg fa-birthday-cake -> birthday-cake
    textColor: undefined # text color as css compatible string
    backgroundColor: undefined # background color as css compatible string
    #callback: undefined # callback executed after html element create
    #textClass: undefined
    #backgroundClass: undefined

  constructor: (options, callback) ->
    @event_data = $.extend({}, @defaults, options)

    @name = options.name
    @day_long = options.day_long

    @start = moment(options.start) if options.start?

    if options.end?
      @end = moment(options.end)
    else
      @end = moment(@start).endOf('day')

    # day long
    unless @day_long?
      @day_long = @start.isSame(moment(@start).startOf('day')) and (
        @end.isSame(moment(@end).startOf('day')) or
        @end.isSame(moment(@end).endOf('day')) )

    if @day_long is true
      @start.startOf('day')
      @end.endOf('day')

    @icon = options.icon
    @color = options.textColor
    @background = options.backgroundColor
    @callback = callback

    # store remeining user data
    for key of @defaults
      delete options[key]
    @data = options



  # check if this event overlap given day
  overlap_day: (day) ->
    day.isSameOrAfter(@start, 'day') and day.isSameOrBefore(@end, 'day')

  # check if this event overlap given time range
  #  range[---(--]----)event
  overlap_range: (from, end) ->
    from.isSameOrBefore(@end, 'day') and end.isSameOrAfter(@start, 'day')

  # Check if object is event
  is_event: () ->
    true
  # create html tag for this event
  render_as_label: =>
    content = []

    if @icon?
      content.push em(".fa.fa-#{@icon}")
      content.push ' '

    unless @day_long
      content.push strong('', @start.format('LT').toLowerCase().replace(/ /g,''))
      content.push ' '

    content.push @name
    klass = ['label', 'label-primary']

    el = a({class: klass, role: 'button', tabindex: '0'}, content)
    el.css('color', @color) if @color?
    el.css('background', @background) if @background?

    @callback(el, @) if @callback?
    el




# Define the plugin class
class Calendar
  prefix = 'mns-cal'
  defaults:
    title: 'MNS Calendar'
    callback: undefined
    weekdays_names: true
    events: []
    calendar: undefined
    calendars: []
    i18n:
      lang: 'pl'
      translations:
        months: ['Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec', 'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień']
        today: 'Dzisiaj'
        next: 'Następny miesiąc'
        prev: 'Poprzedni miesiąc'
        week: 'Tydzień'


  constructor: (el, options) ->
    @options = $.extend({}, @defaults, options)

    # HTML container of calendar
    @$el = $(el)

    # Today
    @today = moment().startOf('day')

    # Current displayed month
    @current = moment(@today).startOf('month')

    # Callback fired after event label is created
    @callback = @options.callback

    # Translations
    @t = @options['i18n']['translations']

    # Max number of slots displayed per day
    @max_slots = 4

    # Create HTML skeleton of the calendar and parse calendar list
    @setup_skeleton()

    # Setup event sources
    @bootstrap_event_sources(@options.events)

    # render empty grid
    @render()

    # Load events data from config and render
    if @calendars?
      @set_calendar(@options.calendar)
    else
      @refetch()


  # Time manipulation routines:
  change_month: (diff) =>
    @current.add(diff, 'month')
    @refetch()

  prev_month: () =>
    @change_month -1

  next_month: () =>
    @change_month 1

  today_month: () =>
    @current = moment(@today).startOf('month')
    @refetch()


  # set currently displayed calendar
  set_calendar: (calendar_id) =>
    if @calendars?
      for calendar in @calendars
        if calendar.id is calendar_id or not calendar_id?
          @calendar_id = calendar.id
          @calendar_name = calendar.name
          @refetch()
          break

  # Create EventSources
  bootstrap_event_sources: (sources) ->
    @events = []
    @event_sources = []

    for source in sources
      obj = EventSourceFactory.new(source, @fetch_events_callback, @callback)
      @event_sources.push obj if obj?


  fetch_events: () =>
    start_date = moment(@current).startOf('month').startOf('week')
    end_date = moment(@current).endOf('month').endOf('week')

    @pending_event_sources = []
    @events = []
    tokens = []

    if @event_sources.length == 0
      @render()
    else
      for source in @event_sources
        token = Math.random()
        @pending_event_sources.push token
        tokens.push token

      for source in @event_sources
        source.fetch(start_date, end_date, @calendar_id, tokens.pop())


  # executed after all EventSources completed work
  fetch_events_completed: () =>
    #TODO: disable spinner
    #TODO: disable timmer
    @render()


  # each EventSource should invoke this callback after data collecting
  fetch_events_callback: (token, results) =>
    index = @pending_event_sources.indexOf token

    if index isnt -1
      @pending_event_sources.splice(index, 1)
      Array.prototype.push.apply @events, results
      if @pending_event_sources.length is 0
        @fetch_events_completed()


  # update skeleton
  render: () =>
    @update_header()
    rows = []

    day = moment(@current).startOf('month').startOf('week')

    while(day.isSameOrBefore(@current, 'month'))
      rows.push( new Row(@, day) )
      day.add(7, 'days') # next week

    for event in @events
      for row in rows
        row.add(event)

    body = @$el.find('.mns-cal-body')
    body.empty()
    body.append @build_weekdays_header()  if @options.weekdays_names
    for row in rows
      body.append row.render()

  # update settings
  refetch: () =>
    @fetch_events()

  update: () ->
    undefined
  #
  update_header: () =>
    @$el.find('.mns-cal-title').text(@options['title'])
    @$el.find('.mns-cal-date').text(@current.format('MMMM YYYY'))
    @$el.find('.mns-cal-calendar-name').text(@calendar_name) if @calendars?

  build_calendars_list: () ->
    items = []
    callback = @set_calendar
    @calendars = []
    if @options.calendars.length == 0
      return ''

    create_li = (id, name) ->
      # TODO: some replacement for this href
      link = a({href:'javascript:;'}, name)
      link.click () ->
        callback(id)

      li('', link)

    for calendar in @options.calendars
      if calendar is '---'
        items.push li({role: 'separator', class: 'divider'})
      else if calendar.title?
        items.push li('.dropdown-header', calendar.title)
        for item in calendar.items
          items.push create_li(item.id, item.name)
          @calendars.push item
      else
        items.push create_li(calendar.id, calendar.name)
        @calendars.push calendar


    li('.dropdown',
      a({class:'dropdown-toggle', 'data-toggle': 'dropdown', role: 'button'},
        span('.mns-cal-calendar-name'), ' '
        span('.caret')
      ), ul('.dropdown-menu', items)
    )

  # Create HTML table with weekdays names
  build_weekdays_header: () ->
    days = ( th('', day) for day in moment.weekdays() )
    div('',
      table('.table.table-condensed.table-bordered.text-center',
        tr('.mns-cal-row-header', days)
    ))


  # Create HTML skeleton of calendar
  setup_skeleton: () ->
    header = div('.navbar-header',
      div('.navbar-brand',
        i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')
      ) )

    dropdown = @build_calendars_list()

    text = ul('.nav.navbar-nav',
      dropdown, div('.navbar-text.mns-cal-date')
    )

    form = div('.navbar-form.navbar-right',
      div('.btn-toolbar',
        div('.btn-group', a('.btn.btn-default.mns-cal-today', @t['today']) ),
        div('.btn-group',
          a('.btn.btn-default.mns-cal-prev', i('.fa.fa-angle-left')),
          a('.btn.btn-default.mns-cal-next', i('.fa.fa-angle-right'))
        )
      ) )
    navbar = nav('.navbar.navbar-default',
      div('.container-fluid', header, text, form) )

    # TODO: display week days names

    body = div('.panel.panel-default.mns-cal-body')

    cal = div('.mns-cal', navbar, body)

    #bind events
    cal.find('.mns-cal-prev').click(@prev_month)
    cal.find('.mns-cal-next').click(@next_month)
    cal.find('.mns-cal-today').click(@today_month)

    @$el.append cal


(($, window) ->
  # Define the plugin
  $.fn.extend MnsCalendar: (option, args...) ->
    @each ->
      $this = $(this)
      data = $this.data('mnsCalendar')

      if !data
        $this.data 'mnsCalendar', (data = new Calendar(this, option))
      if typeof option == 'string'
        data[option].apply(data, args)

) window.jQuery, window

#=require <event_sources/array>

#
# class EventSourceInterface
#   fetch_for_date: (from, to) ->
#     # return events in given time range
#
#

##
# EventSources factory:
#  e.g. EventSource.new {type: 'arrray', data: [{..}, {..}, {..}] }
class EventSourceFactory
  @types =
    json: JSONEventSource
    array: ArrayEventSource
    function: FunctionEventSource

  @new: (options, data_callback, label_callback) ->
    @constructor = @types[options.type]
    return null unless @constructor?
    delete options['type']
    return new @constructor(options, data_callback, label_callback)

