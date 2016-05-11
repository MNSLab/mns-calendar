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
