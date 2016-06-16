#= require<helpers.coffee>
class Row
  constructor: (calendar, start_day) ->
    @current = calendar.current
    @days = (moment(start_day).add(d, 'days') for d in [0..6])

    @callback = calendar.callback
    @today = calendar.today

    # generate empty slots
    @slot_count = calendar.max_slots
    @slots = ((true for j in [0..@slot_count-1]) for i in [0..6])


  add: (event) ->
    [start, end] = [null, null]
    for day, i in @days
      if event.overlap_day(day)
        start ?= i
        end = i

    if start is null
      return false

    free_slot = @find_free_slot(start, end)
    if free_slot is false
      return false


    @slots[start][free_slot] = {
      event: event,
      colspan: end-start+1,
      starts_here: @days[start].isSame(event.start, 'day'),
      ends_here: @days[end].isSame(event.end, 'day'),
    }

    for j in [start+1..end] by 1
      @slots[j][free_slot] = false

    return true


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


  # display days numbers
  render_header: () ->
    days = []
    for day in @days
      days.push th({}, day.format('D'))

    tr('.mns-cal-row-header', days)


  # display day background below events indicating 'this month' or 'today'
  render_bg: () ->
    table('.table.table-bordered',
      tr({},
        for day in @days
          klass = {}
          klass = '.active' unless day.isSame(@current, 'month')
          klass = '.mns-cal-bg-today.info' if day.isSame(@today, 'day')
          td(klass)
      ) )

  render_slot: (id) ->
    res = []
    for day, i in @days
      obj = @slots[i][id]

      if obj is true
        res.push td({},'')
      else if instanceOf(obj, Object)
        klass = []
        klass.push 'mns-cal-starts-here' if obj.starts_here
        klass.push 'mns-cal-ends-here' if obj.ends_here
        res.push td({class: klass, colspan: obj.colspan}, obj.event.render_as_label)

    tr('.mns-cal-row', res)


  # return html representing given row
  render: () ->
    html = [@render_header()]
    for i in [0..@slot_count-1]
      html.push(@render_slot(i))

    div('.mns-cal-week', div('.mns-cal-bg', @render_bg() ), div('.mns-cal-rows', table('.table.table-condensed', html ) ) )
