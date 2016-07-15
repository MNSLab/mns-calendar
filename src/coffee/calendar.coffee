#= require Event
#= require Row

# Define the plugin class
class Calendar
  @default_callback: (label, event) ->
    f = if event.day_long then 'LL' else 'LLL'
    start = event.start.format(f)
    end = event.end.format(f)

    if start is end
      date = "#{start}"
    else
      date = "#{start}&nbsp;–&nbsp;#{end}"

    icon  = if event.icon
      '<span class="fa fa-'+event.icon+'" style="margin-right:6px"></span> '
    else
      ''

    $(label).popover
      container: 'body'
      title: icon+event.name
      placement: 'bottom'
      html: true
      content: '<div><i class="fa fa-calendar"></i> '+date+'</div>'+'<p class="text-justify">'+(event.data.text||'')+'</p>'
      trigger: 'focus'

  prefix = 'mns-cal'
  defaults:
    title: 'MNS Calendar'
    callback: Calendar.default_callback
    weekdays_names: true
    weekdays_abbreviations: false
    events: []
    calendar: undefined
    calendars: []
    lang: undefined
    i18n:
      en:
        today: 'Today'
        next: 'Next month'
        prev: 'Previous month'
      pl:
        today: 'Dzisiaj'
        next: 'Następny miesiąc'
        prev: 'Poprzedni miesiąc'


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
    @lang = @options.lang || moment.locale()
    @t = @options['i18n'][@lang]

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

    body.append @build_weekdays_header(day)  if @options.weekdays_names
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
  build_weekdays_header: (day) ->
    days = for diff in [0..6]
      d = moment(day).add(diff, 'days')
      th('', d.format('ddd'  + (if @options['weekdays_abbreviations'] then '' else 'd') ))

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
          a('.btn.btn-default.mns-cal-prev', {title: @t['prev']}, i('.fa.fa-angle-left')),
          a('.btn.btn-default.mns-cal-next', {title: @t['next']}, i('.fa.fa-angle-right'))
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
