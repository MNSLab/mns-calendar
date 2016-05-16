#= require Event
#= require Row

# Define the plugin class
class Calendar
  prefix = 'mns-cal'
  defaults:
    title: 'MNS Calendar'
    callback: (link, event) -> console.log('Callback', link, event)
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

    # Set default calendar
    @set_calendar(@options.calendar) if @calendars?

    # render empty grid
    @events = []
    @render()

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
        if calendar.id is calendar_id or not calendar_id?
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
      @render()

    else if @options.events.url?
      # TODO: show spinner
      #@$el.find('.mns-cal-body').addClass('data-loading')

      # we've got a remote JSON
      #@events = []

      # request url
      url = @options.events.url

      data = {}
      # if server accept parameters
      unless @options.events.parameterless
        start_date = moment(@current).startOf('month').startOf('week')
        end_date = moment(@current).endOf('month').endOf('week')

        data =
          start_date: start_date.toISOString()
          end_date: end_date.toISOString()

        data['calendar_id'] = @calendar_id if @calendar_id?

      # perform AJAX query
      $.getJSON(url, data)
      .done @load_json
      .fail ( jqxhr, textStatus, error) ->
        # TODO do something with errors
        #console.log(jqxhr, textStatus, error)
        alert(jqxhr, textStatus, error)


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

  update: () ->
    undefined
  #
  update_header: () ->
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
      console.log(calendar)
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
