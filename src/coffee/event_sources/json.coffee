##
# EventSource parsing events from remote JSON file
# options:
#   calendar: overide calendar_id of all events
#   paremeterless: if data source support quering for date range and calendar_id
#   url: url of remote data source
class JSONEventSource
  constructor: (options, @data_callback, @event_callback) ->
    @calendar = options.calendar
    @parameterless = options.parameterless
    @url = options.url


  ##
  # Return event overlaping given period [start, end] in given calendar
  #  if calendar == null then match any event
  #  token must be resend via callback
  fetch:(start, end, calendar, token) =>
    results = []

    if @calendar? and @calendar isnt calendar
      @callback(token, [])
    else
      data = {}
      # if server accept parameters
      unless @parameterless
        data =
          start_date: start.toISOString()
          end_date: end.toISOString()

        calendar =
        data['calendar_id'] = calendar unless @calendar?

      # perform AJAX query
      data_callback = @data_callback
      event_callback = @event_callback

      $.getJSON(@url, data)
      .done (json) ->
        data_callback(token, (new Event(event, event_callback) for event in json))
      .fail ( jqxhr, textStatus, error) ->
        # TODO do something with errors
        console.log(jqxhr, textStatus, error)
        # complete request without data
        data_callback(token, [])
