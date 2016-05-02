(($, window) ->
  # helper function for buildin HTML layout
  # params = (shortcut, attrs, childs...)
  window.tag = (name, params...) ->
    obj = $("<#{name}>")

    # use shortcut
    if typeof(params[0]) is 'string'
      sc = params.shift()
      klass = sc.match(/\.[-_0-9a-z]+/gi).join('').replace(/\./g,' ').trim()
      id = ((sc.match(/\#[-_0-9a-z]+/gi)||[])[0] || '').slice(1)

      obj.attr(
        class: klass,
        id: if id == '' then null else id
      )

    # set attributes
    if typeof(params[0]) is 'object' and params[0].constructor.name is 'Object'
      attrs = params.shift()
      obj.attr(attrs)

    # append content
    for child in params
      if typeof(child) is 'string'
        obj.append(document.createTextNode(child))
      else
        obj.append(child)
    obj

  # define shortcuts
  for tag_name in ['div', 'i', 'span', 'a', 'nav', 'table', 'th', 'tr', 'td']
    ((s) ->
      window[s] = (params...) -> tag(s, params...)
    )(tag_name)
  window['nbsp'] = document.createTextNode(String.fromCharCode(160))

  bind = (obj, name) ->
    () ->  obj[name]()




  class Row
    constructor: (year, month, start, end, slots) ->
      @year = year
      @month = month
      @start = start
      @end  = end

    add: (event) ->

    render_header: () ->
      res = []
      for i in [@start..@end-1]
        res.push(th({}, (new Date(@year, @month, i)).getDate()))

      tr('.mns-cal-row-header', res )

    render_bg: () ->


    # return html representing given row
    render: () ->
      bg = @render_bg()
      html = [@render_header()]
      for i in [1..4]
        html.push tr('.mns-cal-row', td({colspan: 7}))

      div('.mns-cal-week', bg, div('.mns-cal-rows', html) )


  # Define the plugin class
  class MnsCalendar
    prefix = 'mns-cal'
    defaults:
      title: 'MNS Calendar'
      date: [(new Date()).getMonth(), (new Date()).getFullYear()]

      i18n:
        lang: 'pl'
        translations:
          months: ['Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec', 'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień']
          today: 'Dzisiaj'
          next: 'Następny miesiąc'
          prev: 'Poprzedni miesiąc'
          week: 'Tydzień'


    constructor: (el, options) ->
      @options = $.extend({}, @defaults, options)
      @$el = $(el)

      @$el.append @setup_skeleton()
      @title = @options['title']
      @date = @options['date']
      @month = 11
      @year = 2016
      @start_of_week = 1
      @events = [{
        title: 'Happy Birthday',
        start: '2016-02-01',
        end: '2016-02-03',
        icon: 'birthday-cake',
        class: 'text-warning'
      }]
      @t = @options['i18n']['translations']

      @render()
      @$el.find('.mns-cal-prev').click(bind(@, 'prev_month'))
      @$el.find('.mns-cal-next').click(bind(@, 'next_month'))
      @$el.find('.mns-cal-today').click(bind(@, 'today_month'))

    # Time manipulation routines:
    change_month: (diff) ->
      @month += diff

      while(@month < 0)
        @month += 12
        @year -= 1

      while(@month > 11)
        @month -= 12
        @year += 1
      @render()

    prev_month: () ->
      @change_month -1

    next_month: () ->
      @change_month 1

    today_month: () ->
      now = new Date()
      @month = now.getMonth()
      @year = now.getFullYear()
      @render()

    # get data from array or remote json
    load_data: () ->

    # update skeleton
    render: () ->
      console.log(@, 'Rendering')
      dow = (y,m,d) -> (new Date(y,m, d)).getDay()
      @update_header()
      rows = []
      day = 1

      while(dow(@year, @month, day) isnt @start_of_week)
        day--; # szukamy początku tygodnia

      while(true)
        start = new Date(@year, @month, day)

        if day > 0 and (start.getDay() is @start_of_week) and (start.getMonth() isnt @month) # zaczynamy nowy tydzień w przyszłym
          break

        rows.push( new Row(@year, @month, day, day+7, @max_slots) )
        day += 7

      for event in @events
        for row in rows
          row.add(event)

      body = @$el.find('.mns-cal-body')
      body.empty()
      for row in rows
        body.append row.render()




    # update settings
    update: () ->


    #
    update_header: () ->
      @$el.find('.mns-cal-title').text(@title)
      @$el.find('.mns-cal-date').text("#{@t.months[@month]} #{@year}")

    # Create HTML skeleton of calendar
    setup_skeleton: () ->
      t = {'today': 'dzisiaj'}#defaults['i18n']['translations']
      header = div('.navbar-header',
        div('.navbar-brand',
          i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')
        ), div('.navbar-text.mns-cal-date') )

      form = div('.navbar-form.navbar-right',
        div('.btn-toolbar',
          div('.btn-group', a('.btn.btn-default.mns-cal-today', t['today']) ),
          div('.btn-group',
            a('.btn.btn-default.mns-cal-prev', i('.fa.fa-angle-left')),
            a('.btn.btn-default.mns-cal-next', i('.fa.fa-angle-right'))
          )
        ) )
      navbar = nav('.navbar.navbar-default',
        div('.container-fluid', header, form) )

      body = div('.panel.panel-default.mns-cal-body')

      return div('.mns-cal', navbar, body)


  # Define the plugin
  $.fn.extend MnsCalendar: (option, args...) ->
    @each ->
      $this = $(this)
      data = $this.data('mnsCalendar')

      if !data
        $this.data 'mnsCalendar', (data = new MnsCalendar(this, option))
      if typeof option == 'string'
        data[option].apply(data, args)

) window.jQuery, window

$ ->
  $('body').append(
    a('.btn.btn-default.btn-xs', {href: 'http://www.mnslab.pl'},
      i('.fa.fa-birthday-cake'), ' MNS Lab'
    )
  )
