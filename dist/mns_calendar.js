// Generated by CoffeeScript 1.10.0
(function() {
  var Calendar, Event, Row, fn, l, len, tag_name, tags,
    slice = [].slice,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.tag = function() {
    var attrs, child, id, k, klass, l, len, name, obj, params, sc, v;
    name = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    obj = $("<" + name + ">");
    if (typeof params[0] === 'string') {
      sc = params.shift();
      klass = (sc.match(/\.[-_0-9a-z]+/gi) || []).join('').replace(/\./g, ' ').trim();
      id = ((sc.match(/\#[-_0-9a-z]+/gi) || [])[0] || '').slice(1);
      obj.attr({
        "class": klass,
        id: id === '' ? null : id
      });
    }
    if (typeof params[0] === 'object' && params[0].constructor.name === 'Object') {
      attrs = params.shift();
      if (Array.isArray(attrs['class'])) {
        attrs['class'] = attrs['class'].join(' ');
      }
      if (typeof attrs['style'] === 'object') {
        attrs['style'] = ((function() {
          var ref, results;
          ref = attrs['style'];
          results = [];
          for (k in ref) {
            v = ref[k];
            results.push(k + ":" + v);
          }
          return results;
        })()).join(';');
      }
      obj.attr(attrs);
    }
    for (l = 0, len = params.length; l < len; l++) {
      child = params[l];
      if (typeof child === 'string') {
        obj.append(document.createTextNode(child));
      } else {
        obj.append(child);
      }
    }
    return obj;
  };

  tags = ['div', 'strong', 'em', 'span', 'a', 'nav', 'i', 'table', 'th', 'tr', 'td', 'ul', 'ol', 'li'];

  fn = function(tag_name) {
    return window[tag_name] = function() {
      var params;
      params = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return tag.apply(null, [tag_name].concat(slice.call(params)));
    };
  };
  for (l = 0, len = tags.length; l < len; l++) {
    tag_name = tags[l];
    fn(tag_name);
  }

  window['nbsp'] = document.createTextNode(String.fromCharCode(160));

  Row = (function() {
    function Row(calendar, start_day) {
      var d, i, j;
      this.current = calendar.current;
      this.days = (function() {
        var m, results;
        results = [];
        for (d = m = 0; m <= 6; d = ++m) {
          results.push(moment(start_day).add(d, 'days'));
        }
        return results;
      })();
      this.callback = calendar.callback;
      this.today = calendar.today;
      this.slot_count = calendar.max_slots;
      this.slots = (function() {
        var m, results;
        results = [];
        for (i = m = 0; m <= 6; i = ++m) {
          results.push((function() {
            var n, ref, results1;
            results1 = [];
            for (j = n = 0, ref = this.slot_count - 1; 0 <= ref ? n <= ref : n >= ref; j = 0 <= ref ? ++n : --n) {
              results1.push(true);
            }
            return results1;
          }).call(this));
        }
        return results;
      }).call(this);
    }

    Row.prototype.add = function(event) {
      var day, end, free_slot, i, j, len1, m, n, ref, ref1, ref2, ref3, start;
      ref = [null, null], start = ref[0], end = ref[1];
      ref1 = this.days;
      for (i = m = 0, len1 = ref1.length; m < len1; i = ++m) {
        day = ref1[i];
        if (event.overlap_day(day)) {
          if (start == null) {
            start = i;
          }
          end = i;
        }
      }
      if (start === null) {
        return false;
      }
      free_slot = this.find_free_slot(start, end);
      if (free_slot === false) {
        return false;
      }
      this.slots[start][free_slot] = {
        event: event,
        colspan: end - start + 1,
        starts_here: this.days[start].isSame(event.start, 'day'),
        ends_here: this.days[end].isSame(event.end, 'day')
      };
      for (j = n = ref2 = start + 1, ref3 = end; n <= ref3; j = n += 1) {
        this.slots[j][free_slot] = false;
      }
      return true;
    };

    Row.prototype.find_free_slot = function(start, end) {
      var m, n, ok, pos, ref, ref1, ref2, slot;
      for (slot = m = 0, ref = this.slot_count - 1; 0 <= ref ? m <= ref : m >= ref; slot = 0 <= ref ? ++m : --m) {
        ok = true;
        for (pos = n = ref1 = start, ref2 = end; ref1 <= ref2 ? n <= ref2 : n >= ref2; pos = ref1 <= ref2 ? ++n : --n) {
          if (this.slots[pos][slot] !== true) {
            ok = false;
            break;
          }
        }
        if (ok === true) {
          return slot;
        }
      }
      return false;
    };

    Row.prototype.render_header = function() {
      var day, days, len1, m, ref;
      days = [];
      ref = this.days;
      for (m = 0, len1 = ref.length; m < len1; m++) {
        day = ref[m];
        days.push(th({}, day.format('D')));
      }
      return tr('.mns-cal-row-header', days);
    };

    Row.prototype.render_bg = function() {
      var day, klass;
      return table('.table.table-bordered', tr({}, (function() {
        var len1, m, ref, results;
        ref = this.days;
        results = [];
        for (m = 0, len1 = ref.length; m < len1; m++) {
          day = ref[m];
          klass = {};
          if (!day.isSame(this.current, 'month')) {
            klass = '.active';
          }
          if (day.isSame(this.today, 'day')) {
            klass = '.mns-cal-bg-today.info';
          }
          results.push(td(klass));
        }
        return results;
      }).call(this)));
    };

    Row.prototype.render_slot = function(id) {
      var day, i, klass, len1, m, obj, ref, res, type;
      res = [];
      ref = this.days;
      for (i = m = 0, len1 = ref.length; m < len1; i = ++m) {
        day = ref[i];
        obj = this.slots[i][id];
        type = typeof obj;
        if (obj === true) {
          res.push(td({}, ''));
        } else if (type === 'object') {
          klass = [];
          if (obj.starts_here) {
            klass.push('mns-cal-starts-here');
          }
          if (obj.ends_here) {
            klass.push('mns-cal-ends-here');
          }
          res.push(td({
            "class": klass,
            colspan: obj.colspan
          }, obj.event.render_as_label));
        }
      }
      return tr('.mns-cal-row', res);
    };

    Row.prototype.render = function() {
      var html, i, m, ref;
      html = [this.render_header()];
      for (i = m = 0, ref = this.slot_count - 1; 0 <= ref ? m <= ref : m >= ref; i = 0 <= ref ? ++m : --m) {
        html.push(this.render_slot(i));
      }
      return div('.mns-cal-week', div('.mns-cal-bg', this.render_bg()), div('.mns-cal-rows', table('.table.table-condensed', html)));
    };

    return Row;

  })();

  Event = (function() {
    var defaults;

    defaults = {
      name: 'Event',
      start: void 0,
      end: void 0,
      day_long: void 0,
      icon: void 0,
      textColor: void 0,
      backgroundColor: void 0
    };

    function Event(options, callback) {
      this.render_as_label = bind(this.render_as_label, this);
      var key;
      this.event_data = $.extend({}, this.defaults, options);
      this.name = options.name;
      this.day_long = options.day_long;
      if (options.start != null) {
        this.start = moment(options.start);
      }
      if (options.end != null) {
        this.end = moment(options.end);
      } else {
        this.end = moment(this.start).endOf('day');
      }
      if (this.day_long == null) {
        this.day_long = this.start.isSame(moment(this.start).startOf('day')) && (this.end.isSame(moment(this.end).startOf('day')) || this.end.isSame(moment(this.end).endOf('day')));
      }
      if (this.day_long === true) {
        this.start.startOf('day');
        this.end.endOf('day');
      }
      this.icon = options.icon;
      this.color = options.textColor;
      this.background = options.backgroundColor;
      this.callback = callback;
      for (key in this.defaults) {
        delete options[key];
      }
      this.data = options;
    }

    Event.prototype.overlap_day = function(day) {
      return day.isSameOrAfter(this.start, 'day') && day.isSameOrBefore(this.end, 'day');
    };

    Event.prototype.render_as_label = function() {
      var content, el, klass;
      content = [];
      if (this.icon != null) {
        content.push(em(".fa.fa-" + this.icon));
        content.push(' ');
      }
      if (!this.day_long) {
        content.push(strong('', this.start.format('LT').toLowerCase().replace(/ /g, '')));
        content.push(' ');
      }
      content.push(this.name);
      klass = ['label', 'label-primary'];
      el = a({
        "class": klass,
        role: 'button',
        tabindex: '0'
      }, content);
      if (this.color != null) {
        el.css('color', this.color);
      }
      if (this.background != null) {
        el.css('background', this.background);
      }
      if (this.callback != null) {
        this.callback(el, this);
      }
      return el;
    };

    return Event;

  })();

  Calendar = (function() {
    var prefix;

    prefix = 'mns-cal';

    Calendar.prototype.defaults = {
      title: 'MNS Calendar',
      callback: function(link, event) {
        return console.log('Callback', link, event);
      },
      events: [],
      calendar: void 0,
      calendars: [],
      i18n: {
        lang: 'pl',
        translations: {
          months: ['Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec', 'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'],
          today: 'Dzisiaj',
          next: 'Następny miesiąc',
          prev: 'Poprzedni miesiąc',
          week: 'Tydzień'
        }
      }
    };

    function Calendar(el, options) {
      this.load_json = bind(this.load_json, this);
      this.set_calendar = bind(this.set_calendar, this);
      this.today_month = bind(this.today_month, this);
      this.next_month = bind(this.next_month, this);
      this.prev_month = bind(this.prev_month, this);
      this.options = $.extend({}, this.defaults, options);
      this.$el = $(el);
      this.today = moment().startOf('day');
      this.current = moment(this.today).startOf('month');
      this.callback = this.options.callback;
      this.t = this.options['i18n']['translations'];
      this.max_slots = 4;
      this.setup_skeleton();
      if (this.calendars != null) {
        this.set_calendar(this.options.calendar);
      }
      this.events = [];
      this.render();
      this.redraw();
    }

    Calendar.prototype.change_month = function(diff) {
      this.current.add(diff, 'month');
      return this.redraw();
    };

    Calendar.prototype.prev_month = function() {
      return this.change_month(-1);
    };

    Calendar.prototype.next_month = function() {
      return this.change_month(1);
    };

    Calendar.prototype.today_month = function() {
      this.current = moment(this.today).startOf('month');
      return this.redraw();
    };

    Calendar.prototype.set_calendar = function(calendar_id) {
      var calendar, len1, m, ref, results;
      if (this.calendars != null) {
        console.log(this.calendar_id, calendar_id);
        ref = this.calendars;
        results = [];
        for (m = 0, len1 = ref.length; m < len1; m++) {
          calendar = ref[m];
          if (calendar.id === calendar_id || (calendar_id == null)) {
            this.calendar_id = calendar.id;
            this.calendar_name = calendar.name;
            this.redraw();
            break;
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    };

    Calendar.prototype.load_json = function(json) {
      var event;
      this.events = (function() {
        var len1, m, results;
        results = [];
        for (m = 0, len1 = json.length; m < len1; m++) {
          event = json[m];
          results.push(new Event(event, this.callback));
        }
        return results;
      }).call(this);
      this.render();
      return this.$el.find('.mns-cal-body').removeClass('data-loading');
    };

    Calendar.prototype.load_events = function() {
      var data, end_date, event, start_date, url;
      if (Array.isArray(this.options.events)) {
        this.events = (function() {
          var len1, m, ref, results;
          ref = this.options.events;
          results = [];
          for (m = 0, len1 = ref.length; m < len1; m++) {
            event = ref[m];
            results.push(new Event(event, this.callback));
          }
          return results;
        }).call(this);
        return this.render();
      } else if (this.options.events.url != null) {
        url = this.options.events.url;
        data = {};
        if (!this.options.events.parameterless) {
          start_date = moment(this.current).startOf('month').startOf('week');
          end_date = moment(this.current).endOf('month').endOf('week');
          data = {
            start_date: start_date.toISOString(),
            end_date: end_date.toISOString()
          };
          if (this.calendar_id != null) {
            data['calendar_id'] = this.calendar_id;
          }
        }
        return $.getJSON(url, data).done(this.load_json).fail(function(jqxhr, textStatus, error) {
          return alert(jqxhr, textStatus, error);
        });
      }
    };

    Calendar.prototype.render = function() {
      var body, day, event, len1, len2, len3, m, n, o, ref, results, row, rows;
      this.update_header();
      rows = [];
      day = moment(this.current).startOf('month').startOf('week');
      while (day.isSameOrBefore(this.current, 'month')) {
        rows.push(new Row(this, day));
        day.add(7, 'days');
      }
      ref = this.events;
      for (m = 0, len1 = ref.length; m < len1; m++) {
        event = ref[m];
        for (n = 0, len2 = rows.length; n < len2; n++) {
          row = rows[n];
          row.add(event);
        }
      }
      body = this.$el.find('.mns-cal-body');
      body.empty();
      results = [];
      for (o = 0, len3 = rows.length; o < len3; o++) {
        row = rows[o];
        results.push(body.append(row.render()));
      }
      return results;
    };

    Calendar.prototype.redraw = function() {
      return this.load_events();
    };

    Calendar.prototype.update = function() {
      return void 0;
    };

    Calendar.prototype.update_header = function() {
      this.$el.find('.mns-cal-title').text(this.options['title']);
      this.$el.find('.mns-cal-date').text(this.current.format('MMMM YYYY'));
      if (this.calendars != null) {
        return this.$el.find('.mns-cal-calendar-name').text(this.calendar_name);
      }
    };

    Calendar.prototype.build_calendars_list = function() {
      var calendar, callback, create_li, item, items, len1, len2, m, n, ref, ref1;
      items = [];
      callback = this.set_calendar;
      this.calendars = [];
      if (this.options.calendars.length === 0) {
        return '';
      }
      create_li = function(id, name) {
        var link;
        link = a({
          href: 'javascript:;'
        }, name);
        link.click(function() {
          return callback(id);
        });
        return li('', link);
      };
      ref = this.options.calendars;
      for (m = 0, len1 = ref.length; m < len1; m++) {
        calendar = ref[m];
        console.log(calendar);
        if (calendar === '---') {
          items.push(li({
            role: 'separator',
            "class": 'divider'
          }));
        } else if (calendar.title != null) {
          items.push(li('.dropdown-header', calendar.title));
          ref1 = calendar.items;
          for (n = 0, len2 = ref1.length; n < len2; n++) {
            item = ref1[n];
            items.push(create_li(item.id, item.name));
            this.calendars.push(item);
          }
        } else {
          items.push(create_li(calendar.id, calendar.name));
          this.calendars.push(calendar);
        }
      }
      return li('.dropdown', a({
        "class": 'dropdown-toggle',
        'data-toggle': 'dropdown',
        role: 'button'
      }, span('.mns-cal-calendar-name'), ' ', span('.caret')), ul('.dropdown-menu', items));
    };

    Calendar.prototype.setup_skeleton = function() {
      var body, cal, dropdown, form, header, navbar, text;
      header = div('.navbar-header', div('.navbar-brand', i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')));
      dropdown = this.build_calendars_list();
      text = ul('.nav.navbar-nav', dropdown, div('.navbar-text.mns-cal-date'));
      form = div('.navbar-form.navbar-right', div('.btn-toolbar', div('.btn-group', a('.btn.btn-default.mns-cal-today', this.t['today'])), div('.btn-group', a('.btn.btn-default.mns-cal-prev', i('.fa.fa-angle-left')), a('.btn.btn-default.mns-cal-next', i('.fa.fa-angle-right')))));
      navbar = nav('.navbar.navbar-default', div('.container-fluid', header, text, form));
      body = div('.panel.panel-default.mns-cal-body');
      cal = div('.mns-cal', navbar, body);
      cal.find('.mns-cal-prev').click(this.prev_month);
      cal.find('.mns-cal-next').click(this.next_month);
      cal.find('.mns-cal-today').click(this.today_month);
      return this.$el.append(cal);
    };

    return Calendar;

  })();

  (function($, window) {
    return $.fn.extend({
      MnsCalendar: function() {
        var args, option;
        option = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
        return this.each(function() {
          var $this, data;
          $this = $(this);
          data = $this.data('mnsCalendar');
          if (!data) {
            $this.data('mnsCalendar', (data = new Calendar(this, option)));
          }
          if (typeof option === 'string') {
            return data[option].apply(data, args);
          }
        });
      }
    });
  })(window.jQuery, window);

}).call(this);

//# sourceMappingURL=mns_calendar.js.map
