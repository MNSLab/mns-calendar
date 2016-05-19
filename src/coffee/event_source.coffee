#=require <event_sources/array>

#
# class EventSourceInterface
#   fetch_for_date: (from, to) ->
#     # return events in given time range
#
#

##
# EventSources factory:
#  e.g. EventSource.new {type: 'arrray', data: [{..}, {..}, {..}] }
class EventSourceFactory
  @types =
    json: JSONEventSource
    array: ArrayEventSource
    function: FunctionEventSource

  @new: (options, data_callback, label_callback) ->
    @constructor = @types[options.type]
    return null unless @constructor?
    delete options['type']
    return new @constructor(options, data_callback, label_callback)
