#=require ArrayEventSource
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
