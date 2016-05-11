#= require DateHelper

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
