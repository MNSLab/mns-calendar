(($, window) ->
  # helper function for buildin HTML layout params = (shortcut, attrs, childs...)
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
      console.log(attrs)
      obj.attr(attrs)

    # append content
    for child in params
      if typeof(child) is 'string'
        obj.append(document.createTextNode(child))
      else
        obj.append(child)
    obj

  # define shortcuts
  for tag_name in ['div', 'i', 'span', 'a', 'nav']
    ((s) ->
      window[s] = (params...) -> tag(s, params...)
    )(tag_name)
  window['nbsp'] = document.createTextNode(String.fromCharCode(160))



  # Define the plugin class
  class MnsCalendar
    prefix = 'mns-cal'
    defaults:
      title: 'MNS Calendar'
      date: [(new Date()).getMonth(), (new Date()).getFullYear()]

      i18n:
        lang: 'pl'
        translations:
          today: 'Dzisiaj'
          next: 'Następny miesiąc'
          prev: 'Poprzedni miesiąc'
          week: 'Tydzień'


    constructor: (el, options) ->
      @options = $.extend({}, @defaults, options)
      @$el = $(el)

      @$el.append($('<div class="mns-cal" />').append(this.setup_skeleton()))

      @render()

    # Additional plugin methods go here
    myMethod: (echo) ->
      @$el.html(@options.paramA + ': ' + echo)

    # set displayed month to month/year
    set_month: (month, year) ->
      console.log(month, year)

    # get data from array or remote json
    get_data: () ->

    # update skeleton
    render: () ->
      # set calendar title
      @$el.find('.mns-cal-title').text('Hello')
    #
    reshow: () ->
      # update config
      # load remote data
      # render

    # update settings
    update: () ->


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
      navbar = nav('.navbar.navbar-default', div('.container-fluid', header, form) )
      body = div('.panel.panel-default')

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
    a('.btn.btn-default.btn-xs', {href: 'http://www.google.com'},
      i('.fa.fa-birthday-cake'),
      ' Happy Birthday'
    )
  )
