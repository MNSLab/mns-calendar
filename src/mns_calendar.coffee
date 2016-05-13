# helper function for buildin HTML layout
# params = (shortcut, attrs, childs...)
window.tag = (name, params...) ->
  obj = $("<#{name}>")

  # use shortcut
  if typeof(params[0]) is 'string'
    sc = params.shift()
    klass = (sc.match(/\.[-_0-9a-z]+/gi)||[]).join('').replace(/\./g,' ').trim()
    id = ((sc.match(/\#[-_0-9a-z]+/gi)||[])[0] || '').slice(1)

    obj.attr(
      class: klass,
      id: if id == '' then null else id
    )

  # set attributes
  if typeof(params[0]) is 'object' and params[0].constructor.name is 'Object'
    attrs = params.shift()
    if Array.isArray attrs['class']
      attrs['class'] = attrs['class'].join ' '
    if typeof attrs['style'] is 'object'
      attrs['style'] = ("#{k}:#{v}" for k,v of attrs['style']).join ';'
    obj.attr(attrs)

  # append content
  for child in params
    if typeof(child) is 'string'
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

class Row
  constructor: (calendar, start_day) ->
    @current = calendar.current
    @days = (moment(start_day).add(d, 'days') for d in [0..6])

    @callback = calendar.callback
    @today = calendar.today
    # console.log('Kalendarz [wiersz]: ', @current, @today, @days)

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
      type = typeof(obj)

      if obj is true
        res.push td({},'')
      else if type is 'object'
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
    callback: (link, event) -> console.log('Callback', link, event)
    events: []
    calendar: undefined
    calendars: undefined
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

    # List of calendars
    @calendar_id = @options.calendar
    @calendars = @options.calendars
    if @calendars? and not @calendar_id?
      @calendars[0]?.id

    # Create HTML skeleton of the calendar
    @setup_skeleton()

    # Load events data from config and render
    @redraw()


  # Time manipulation routines:
  change_month: (diff) ->
    @current.add(diff, 'month')
    @redraw()

  prev_month: () =>
    @change_month -1

  next_month: () =>
    @change_month 1

  today_month: () =>
    @current = moment(@today).startOf('month')
    @redraw()


  # set currently displayed calendar
  set_calendar: (calendar_id) =>
    if @calendars?
      console.log(@calendar_id, calendar_id)
      for calendar in @calendars
        if calendar.id is calendar_id
          @calendar_id = calendar.id
          @calendar_name = calendar.name
          @redraw()
          break

  # callbacks for loading JSON events
  load_json: (json) =>
    @events = (new Event(event, @callback) for event in json)
    @render()


  # get data from array or remote json
  load_events: () ->
    if Array.isArray @options.events
      # we've got a list of event
      @events = (new Event(event, @callback) for event in @options.events)
    else if @options.events.url?
      # we've got a remote JSON
      @events = []

      # build request
      request =
        url: @options.events.url

      # if server accept parameters
      unless @options.events.parameterless
        start_date = moment(@current).startOf('month').startOf('week')
        end_date = moment(@current).endOf('month').endOf('week')

        request['data'] =
          start_date: start_date.toISOString()
          end_date: end_date.toISOString()

        request['data']['calendar_id'] = @calendar_id if @calendar_id?

      # perform AJAX query
      $.getJSON request
      .done @load_json
      .fail ( jqxhr, textStatus, error) ->
        # TODO do something on error
        console.log(jqxhr, textStatus, error)


  # update skeleton
  render: () ->
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
    for row in rows
      body.append row.render()

  # update settings
  redraw: () ->
    @load_events()
    @render()

  update: () ->
    undefined
  #
  update_header: () ->
    @$el.find('.mns-cal-title').text(@options['title'])
    @$el.find('.mns-cal-date').text(@current.format('MMMM YYYY'))
    @$el.find('.mns-cal-calendar-name').text(@calendar_name) if @calendars?

  build_dropdown: () ->
    items = []

    for calendar in @calendars
      if calendar is '---'
        items.push li({role: 'separator', class: 'divider'})
      else
        # TODO: some replacement for this href
        link = a({href:'javascript:;'}, calendar.name)
        callback = @set_calendar

        link.click do (id = calendar.id) ->
          () ->
            callback(id)

        items.push li('', link)

    li('.dropdown',
      a({class:'dropdown-toggle', 'data-toggle': 'dropdown', role: 'button'},
        span('.mns-cal-calendar-name'), ' '
        span('.caret')
      ), ul('.dropdown-menu', items)
    )


  # Create HTML skeleton of calendar
  setup_skeleton: () ->
    header = div('.navbar-header',
      div('.navbar-brand',
        i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')
      ) )

    dropdown = if @calendars? then @build_dropdown() else ''

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


#
# $ ->
#   $('body').append(
#     a('.btn.btn-default.btn-xs', {href: 'http://www.mnslab.pl'},
#       i('.fa.fa-birthday-cake'), ' MNS Lab'
#     )
#   )

