#= require DateHelper

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
