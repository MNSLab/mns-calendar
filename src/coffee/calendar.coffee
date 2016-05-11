#= require Event

# Define the plugin class
class Calendar
  prefix = 'mns-cal'
  defaults:
    title: 'MNS Calendar'
    date: [(new Date()).getMonth(), (new Date()).getFullYear()]
    click: (link, event) -> console.log(link, event)
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
    @$el = $(el)
    @setup_skeleton()

    @month = 4
    @year = 2016
    @start_of_week = 1
    @max_slots = 4

    @load_events() #load events data from config
    @t = @options['i18n']['translations'] # setup translations


    @render()

  # Time manipulation routines:
  change_month: (diff) ->
    @month += diff

    while(@month < 0)
      @month += 12
      @year -= 1

    while(@month > 11)
      @month -= 12
      @year += 1
    @render()

  prev_month: () =>
    @change_month -1

  next_month: () =>
    @change_month 1

  today_month: () =>
    now = new Date()
    @month = now.getMonth()
    @year = now.getFullYear()
    @render()

  # get data from array or remote json
  load_events: () ->
    if Array.isArray @options.events
      # we've got a list of event
      @events = (new Event(event) for event in @options.events)
    else
      # we've got a remote JSON
      undefined


  # update skeleton
  render: () ->
    dow = (y,m,d) -> (new Date(y,m, d)).getDay()
    @update_header()
    rows = []
    day = 1

    while(dow(@year, @month, day) isnt @start_of_week)
      day--; # szukamy początku tygodnia

    while(true)
      start = new Date(@year, @month, day)

      if day > 0 and (start.getDay() is @start_of_week) and (start.getMonth() isnt @month) # zaczynamy nowy tydzień w przyszłym
        break

      rows.push( new Row(@year, @month, day, day+7, @max_slots, @options['click'] ) )
      day += 7

    for event in @events
      for row in rows
        row.add(event)

    body = @$el.find('.mns-cal-body')
    body.empty()
    for row in rows
      body.append row.render()




  # update settings
  update: () ->


  #
  update_header: () ->
    @$el.find('.mns-cal-title').text(@options['title'])
    @$el.find('.mns-cal-date').text("#{@t.months[@month]} #{@year}")

  # Create HTML skeleton of calendar
  setup_skeleton: () ->
    t = {'today': 'dzisiaj'}#defaults['i18n']['translations']
    header = div('.navbar-header',
      div('.navbar-brand',
        i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')
      ), div('.navbar-text.mns-cal-date') )

    form = div('.navbar-form.navbar-right',
      div('.btn-toolbar',
        div('.btn-group', a('.btn.btn-default.mns-cal-today', t['today']) ),
        div('.btn-group',
          a('.btn.btn-default.mns-cal-prev', i('.fa.fa-angle-left')),
          a('.btn.btn-default.mns-cal-next', i('.fa.fa-angle-right'))
        )
      ) )
    navbar = nav('.navbar.navbar-default',
      div('.container-fluid', header, form) )

    body = div('.panel.panel-default.mns-cal-body')

    skeleton = div('.mns-cal', navbar, body)

    #bind events
    skeleton.find('.mns-cal-prev').click(@prev_month)
    skeleton.find('.mns-cal-next').click(@next_month)
    skeleton.find('.mns-cal-today').click(@today_month)

    @$el.append skeleton
