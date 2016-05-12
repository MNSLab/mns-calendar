#= require Event
#= require Row

# Define the plugin class
class Calendar
  prefix = 'mns-cal'
  defaults:
    title: 'MNS Calendar'
    callback: (link, event) -> console.log('Callback', link, event)
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

    # Create HTML skeleton of the calendar
    @setup_skeleton()

    # Load events data from config
    @load_events()

    @render()

  # Time manipulation routines:
  change_month: (diff) ->
    @current.add(diff, 'month')
    @render()

  prev_month: () =>
    @change_month -1

  next_month: () =>
    @change_month 1

  today_month: () =>
    @current = moment(@today).startOf('month')
    @render()

  # get data from array or remote json
  load_events: () ->
    if Array.isArray @options.events
      # we've got a list of event
      @events = (new Event(event, @callback) for event in @options.events)
    else
      # we've got a remote JSON
      undefined


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
  update: () ->
    undefined

  #
  update_header: () ->
    @$el.find('.mns-cal-title').text(@options['title'])
    @$el.find('.mns-cal-date').text(@current.format('MMMM YYYY'))

  # Create HTML skeleton of calendar
  setup_skeleton: () ->
    header = div('.navbar-header',
      div('.navbar-brand',
        i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')
      ), div('.navbar-text.mns-cal-date') )

    form = div('.navbar-form.navbar-right',
      div('.btn-toolbar',
        div('.btn-group', a('.btn.btn-default.mns-cal-today', @t['today']) ),
        div('.btn-group',
          a('.btn.btn-default.mns-cal-prev', i('.fa.fa-angle-left')),
          a('.btn.btn-default.mns-cal-next', i('.fa.fa-angle-right'))
        )
      ) )
    navbar = nav('.navbar.navbar-default',
      div('.container-fluid', header, form) )

    # TODO: display week days names

    body = div('.panel.panel-default.mns-cal-body')

    cal = div('.mns-cal', navbar, body)

    #bind events
    cal.find('.mns-cal-prev').click(@prev_month)
    cal.find('.mns-cal-next').click(@next_month)
    cal.find('.mns-cal-today').click(@today_month)

    @$el.append cal
