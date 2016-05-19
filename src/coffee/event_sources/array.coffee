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
