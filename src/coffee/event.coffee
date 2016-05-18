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
