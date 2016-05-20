#= require Calendar
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
