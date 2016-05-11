# helper function for buildin HTML layout
# params = (shortcut, attrs, childs...)
window.tag = (name, params...) ->
  obj = $("<#{name}>")

  # use shortcut
  if typeof(params[0]) is 'string'
    sc = params.shift()
    klass = sc.match(/\.[-_0-9a-z]+/gi).join('').replace(/\./g,' ').trim()
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
    obj.attr(attrs)

  # append content
  for child in params
    if typeof(child) is 'string'
      obj.append(document.createTextNode(child))
    else
      obj.append(child)
  obj

# define shortcuts
for tag_name in ['div', 'i', 'span', 'a', 'nav', 'table', 'th', 'tr', 'td']
  ((s) ->
    window[s] = (params...) -> tag(s, params...)
  )(tag_name)

window['nbsp'] = document.createTextNode(String.fromCharCode(160))

class DateHelper
  # return begining of day pointed by given date
  @begining_of_day: (date) ->
    date = new Date(date) if typeof(date) is 'string'
    date.setHours(0); date.setMinutes(0); date.setSeconds(0, 0)
    date

  # return end of dat pointed by given date
  @end_of_day: (date) ->
    date = new Date(date) if typeof(date) is 'string'
    date.setHours(23); date.setMinutes(59); date.setSeconds(59, 999)
    date

  @day_overlap_range: (day, range_from, range_to) ->
    start = DateHelper.begining_of_day(day)
    end = DateHelper.end_of_day(day)
    not (range_to < start or range_from > end)

  @day: (year, month, day) ->
    new Date(year, month-1, day)

  @days_in_month: (year, month) ->
    (new Date(year, month, 0)).getDate()

  @day_of_week: (year, month, day) ->
    (new Date(year, month-1, day)).getDay()



class Row
  constructor: (year, month, start, end, slots, callback) ->
    console.log('Kalendarz: ', year, month)
    @year = year
    @month = month
    @start = start
    @end  = end
    # generate empty slots
    @slot_count = slots
    @slots = ((true for j in [0..slots-1]) for i in [start..end-1])
    @callback = callback
    @days_in_month = DateHelper.days_in_month(year, month)

    # check today
    @today = (new Date())
    @today = if @today.getMonth()+1 is @month then @today.getDate() else null
    console.log(@today)



  add: (event) ->
    [start, end] = [null, null]
    for i in [@start..@end-1]
      if event.overlap_day(DateHelper.day(@year, @month, i))
        start ?= i-@start
        end = i-@start

    if start is null
      return false

    free_slot = @find_free_slot(start, end)

    if free_slot isnt false
      @slots[start][free_slot] = {
        event: event,
        colspan: end-start+1,
        start: start+@start,
        end: end+@start
      }

      for j in [start+1..end] by 1
        @slots[j][free_slot] = false
      return true

    return false

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



  render_header: () ->
    res = []
    for i in [@start..@end-1]
      res.push(th({}, (DateHelper.day(@year, @month, i)).getDate()))

    tr('.mns-cal-row-header', res )

  render_bg: () ->
    table('.table.table-bordered',
      tr({},
        for i in [@start..@end-1]
          klass = {}
          klass = '.active' unless (0 < i <= @days_in_month)
          klass = '.mns-cal-today.info' if i is @today
          td(klass)
      ) )

  render_label: (event, at_start, at_end) ->
    res =[]
    if event.icon
      res.push i(".fa.fa-#{event.icon}")
      res.push ' '
    res.push event.name
    klass = ['label', 'label-primary']
    if at_start
      klass.push 'mns-cal-starts-here'
    if at_end
      klass.push 'mns-cal-ends-here'
    callback = @callback
    span({class: klass}, res).click( () -> callback(this, event) )

  render_slot: (id) ->
    res = []
    for i in [0..6]
      obj = @slots[i][id]
      type = typeof(obj)

      if obj is true
        res.push td({},'')
      else if type is 'object'

        res.push td({colspan: obj.colspan}, @render_label(
          obj.event,
          !obj.event.overlap_day(DateHelper.day(@year, @month, obj.start-1)),
          !obj.event.overlap_day(DateHelper.day(@year, @month, obj.end+1))
        ) )
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
    textColor: undefined
    #textClass: undefined
    backgroundColor: undefined
    #backgroundClass: undefined

  constructor: (options) ->
    @event_data = $.extend({}, @defaults, options)

    @name = options.name
    @day_long = options.day_long

    @start = new Date(options.start) if options.start?
    @end   = new Date(options.end)   if options.end?

    # day long
    unless @day_long?
      @day_long = (@start is DateHelper.begining_of_day(@start)) and
        (@end is DateHelper.begining_of_day(@end))

    if @day_long is true
      @start = DateHelper.begining_of_day(@start)
      @end   = DateHelper.end_of_day(@end)

    @icon = options.icon
    
    # store remeining user data
    for key of @defaults
      delete options[key]
    @data = options



  # check if this event overlap given day
  overlap_day: (day) ->
    DateHelper.day_overlap_range(day, @start, @end)



# Define the plugin class
class Calendar
  prefix = 'mns-cal'
  defaults:
    title: 'MNS Calendar'
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


    @month = 5
    @year = 2016
    @start_of_week = 1
    @max_slots = 4

    @load_events() #load events data from config
    @t = @options['i18n']['translations'] # setup translations
    @setup_skeleton()
    @render()

  # Time manipulation routines:
  change_month: (diff) ->
    @month += diff

    while(@month < 1)
      @month += 12
      @year -= 1

    while(@month > 12)
      @month -= 12
      @year += 1
    @render()

  prev_month: () =>
    @change_month -1

  next_month: () =>
    @change_month 1

  today_month: () =>
    now = new Date()
    @month = now.getMonth()+1
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
    @start_of_week ?= 0

    @update_header()
    rows = []
    day = 1

    # TODO: optimize
    while(DateHelper.day_of_week(@year, @month, day) isnt @start_of_week)
      day--; # szukamy początku tygodnia

    while(true)
      start = DateHelper.day(@year, @month, day)

      if day > 0 and (start.getDay() is @start_of_week) and (start.getMonth()+1 isnt @month) # zaczynamy nowy tydzień w przyszłym
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
    @$el.find('.mns-cal-date').text("#{@t.months[@month-1]} #{@year}")

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

