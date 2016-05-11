// Generated by CoffeeScript 1.10.0
(function() {
  var Calendar, DateHelper, Event, Row, fn, k, len, ref, tag_name,
    slice = [].slice,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.tag = function() {
    var attrs, child, id, k, klass, len, name, obj, params, sc;
    name = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    obj = $("<" + name + ">");
    if (typeof params[0] === 'string') {
      sc = params.shift();
      klass = sc.match(/\.[-_0-9a-z]+/gi).join('').replace(/\./g, ' ').trim();
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
      obj.attr(attrs);
    }
    for (k = 0, len = params.length; k < len; k++) {
      child = params[k];
      if (typeof child === 'string') {
        obj.append(document.createTextNode(child));
      } else {
        obj.append(child);
      }
    }
    return obj;
  };

  ref = ['div', 'i', 'span', 'a', 'nav', 'table', 'th', 'tr', 'td'];
  fn = function(s) {
    return window[s] = function() {
      var params;
      params = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return tag.apply(null, [s].concat(slice.call(params)));
    };
  };
  for (k = 0, len = ref.length; k < len; k++) {
    tag_name = ref[k];
    fn(tag_name);
  }

  window['nbsp'] = document.createTextNode(String.fromCharCode(160));

  DateHelper = (function() {
    function DateHelper() {}

    DateHelper.begining_of_day = function(date) {
      if (typeof date === 'string') {
        date = new Date(date);
      }
      date.setHours(0);
      date.setMinutes(0);
      date.setSeconds(0, 0);
      return date;
    };

    DateHelper.end_of_day = function(date) {
      if (typeof date === 'string') {
        date = new Date(date);
      }
      date.setHours(23);
      date.setMinutes(59);
      date.setSeconds(59, 999);
      return date;
    };

    DateHelper.day_overlap_range = function(day, range_from, range_to) {
      var end, start;
      start = DateHelper.begining_of_day(day);
      end = DateHelper.end_of_day(day);
      return !(range_to < start || range_from > end);
    };

    DateHelper.day = function(year, month, day) {
      return new Date(year, month - 1, day);
    };

    DateHelper.days_in_month = function(year, month) {
      return (new Date(year, month, 0)).getDate();
    };

    DateHelper.day_of_week = function(year, month, day) {
      return (new Date(year, month - 1, day)).getDay();
    };

    return DateHelper;

  })();

  Row = (function() {
    function Row(year, month, start, end, slots, callback) {
      var i, j;
      console.log('Kalendarz: ', year, month);
      this.year = year;
      this.month = month;
      this.start = start;
      this.end = end;
      this.slot_count = slots;
      this.slots = (function() {
        var l, ref1, ref2, results;
        results = [];
        for (i = l = ref1 = start, ref2 = end - 1; ref1 <= ref2 ? l <= ref2 : l >= ref2; i = ref1 <= ref2 ? ++l : --l) {
          results.push((function() {
            var m, ref3, results1;
            results1 = [];
            for (j = m = 0, ref3 = slots - 1; 0 <= ref3 ? m <= ref3 : m >= ref3; j = 0 <= ref3 ? ++m : --m) {
              results1.push(true);
            }
            return results1;
          })());
        }
        return results;
      })();
      this.callback = callback;
      this.days_in_month = DateHelper.days_in_month(year, month);
    }

    Row.prototype.add = function(event) {
      var end, free_slot, i, j, l, m, ref1, ref2, ref3, ref4, ref5, start;
      ref1 = [null, null], start = ref1[0], end = ref1[1];
      for (i = l = ref2 = this.start, ref3 = this.end - 1; ref2 <= ref3 ? l <= ref3 : l >= ref3; i = ref2 <= ref3 ? ++l : --l) {
        if (event.overlap_day(DateHelper.day(this.year, this.month, i))) {
          if (start == null) {
            start = i - this.start;
          }
          end = i - this.start;
        }
      }
      if (start === null) {
        return false;
      }
      free_slot = this.find_free_slot(start, end);
      if (free_slot !== false) {
        this.slots[start][free_slot] = {
          event: event,
          colspan: end - start + 1,
          start: start + this.start,
          end: end + this.start
        };
        for (j = m = ref4 = start + 1, ref5 = end; m <= ref5; j = m += 1) {
          this.slots[j][free_slot] = false;
        }
        return true;
      }
      return false;
    };

    Row.prototype.find_free_slot = function(start, end) {
      var l, m, ok, pos, ref1, ref2, ref3, slot;
      for (slot = l = 0, ref1 = this.slot_count - 1; 0 <= ref1 ? l <= ref1 : l >= ref1; slot = 0 <= ref1 ? ++l : --l) {
        ok = true;
        for (pos = m = ref2 = start, ref3 = end; ref2 <= ref3 ? m <= ref3 : m >= ref3; pos = ref2 <= ref3 ? ++m : --m) {
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
      var i, l, ref1, ref2, res;
      res = [];
      for (i = l = ref1 = this.start, ref2 = this.end - 1; ref1 <= ref2 ? l <= ref2 : l >= ref2; i = ref1 <= ref2 ? ++l : --l) {
        res.push(th({}, (DateHelper.day(this.year, this.month, i)).getDate()));
      }
      return tr('.mns-cal-row-header', res);
    };

    Row.prototype.render_bg = function() {
      var i, is_active;
      return table('.table.table-bordered', tr({}, (function() {
        var l, ref1, ref2, results;
        results = [];
        for (i = l = ref1 = this.start, ref2 = this.end - 1; ref1 <= ref2 ? l <= ref2 : l >= ref2; i = ref1 <= ref2 ? ++l : --l) {
          is_active = (0 < i && i <= this.days_in_month);
          results.push(td((is_active ? {} : '.active')));
        }
        return results;
      }).call(this)));
    };

    Row.prototype.render_label = function(event, at_start, at_end) {
      var callback, klass, res;
      res = [];
      if (event.icon) {
        res.push(i(".fa.fa-" + event.icon));
        res.push(' ');
      }
      res.push(event.name);
      klass = ['label', 'label-primary'];
      if (at_start) {
        klass.push('mns-cal-starts-here');
      }
      if (at_end) {
        klass.push('mns-cal-ends-here');
      }
      callback = this.callback;
      return span({
        "class": klass
      }, res).click(function() {
        return callback(this, event);
      });
    };

    Row.prototype.render_slot = function(id) {
      var i, l, obj, res, type;
      res = [];
      for (i = l = 0; l <= 6; i = ++l) {
        obj = this.slots[i][id];
        type = typeof obj;
        if (obj === true) {
          res.push(td({}, ''));
        } else if (type === 'object') {
          res.push(td({
            colspan: obj.colspan
          }, this.render_label(obj.event, !obj.event.overlap_day(DateHelper.day(this.year, this.month, obj.start - 1)), !obj.event.overlap_day(DateHelper.day(this.year, this.month, obj.end + 1)))));
        }
      }
      return tr('.mns-cal-row', res);
    };

    Row.prototype.render = function() {
      var html, i, l, ref1;
      html = [this.render_header()];
      for (i = l = 0, ref1 = this.slot_count - 1; 0 <= ref1 ? l <= ref1 : l >= ref1; i = 0 <= ref1 ? ++l : --l) {
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

    function Event(options) {
      var key;
      this.event_data = $.extend({}, this.defaults, options);
      this.name = options.name;
      this.day_long = options.day_long;
      if (options.start != null) {
        this.start = new Date(options.start);
      }
      if (options.end != null) {
        this.end = new Date(options.end);
      }
      if (this.day_long == null) {
        this.day_long = (this.start === DateHelper.begining_of_day(this.start)) && (this.end === DateHelper.begining_of_day(this.end));
      }
      if (this.day_long === true) {
        this.start = DateHelper.begining_of_day(this.start);
        this.end = DateHelper.end_of_day(this.end);
      }
      this.icon = options.icon;
      for (key in this.defaults) {
        delete options[key];
      }
      this.data = options;
    }

    Event.prototype.overlap_day = function(day) {
      return DateHelper.day_overlap_range(day, this.start, this.end);
    };

    return Event;

  })();

  Calendar = (function() {
    var prefix;

    prefix = 'mns-cal';

    Calendar.prototype.defaults = {
      title: 'MNS Calendar',
      click: function(link, event) {
        return console.log(link, event);
      },
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
      this.today_month = bind(this.today_month, this);
      this.next_month = bind(this.next_month, this);
      this.prev_month = bind(this.prev_month, this);
      this.options = $.extend({}, this.defaults, options);
      this.$el = $(el);
      this.month = 5;
      this.year = 2016;
      this.start_of_week = 1;
      this.max_slots = 4;
      this.load_events();
      this.t = this.options['i18n']['translations'];
      this.setup_skeleton();
      this.render();
    }

    Calendar.prototype.change_month = function(diff) {
      this.month += diff;
      while (this.month < 1) {
        this.month += 12;
        this.year -= 1;
      }
      while (this.month > 12) {
        this.month -= 12;
        this.year += 1;
      }
      return this.render();
    };

    Calendar.prototype.prev_month = function() {
      return this.change_month(-1);
    };

    Calendar.prototype.next_month = function() {
      return this.change_month(1);
    };

    Calendar.prototype.today_month = function() {
      var now;
      now = new Date();
      this.month = now.getMonth() + 1;
      this.year = now.getFullYear();
      return this.render();
    };

    Calendar.prototype.load_events = function() {
      var event;
      if (Array.isArray(this.options.events)) {
        return this.events = (function() {
          var l, len1, ref1, results;
          ref1 = this.options.events;
          results = [];
          for (l = 0, len1 = ref1.length; l < len1; l++) {
            event = ref1[l];
            results.push(new Event(event));
          }
          return results;
        }).call(this);
      } else {
        return void 0;
      }
    };

    Calendar.prototype.render = function() {
      var body, day, event, l, len1, len2, len3, m, n, ref1, results, row, rows, start;
      if (this.start_of_week == null) {
        this.start_of_week = 0;
      }
      this.update_header();
      rows = [];
      day = 1;
      while (DateHelper.day_of_week(this.year, this.month, day) !== this.start_of_week) {
        day--;
      }
      while (true) {
        start = DateHelper.day(this.year, this.month, day);
        if (day > 0 && (start.getDay() === this.start_of_week) && (start.getMonth() + 1 !== this.month)) {
          break;
        }
        rows.push(new Row(this.year, this.month, day, day + 7, this.max_slots, this.options['click']));
        day += 7;
      }
      ref1 = this.events;
      for (l = 0, len1 = ref1.length; l < len1; l++) {
        event = ref1[l];
        for (m = 0, len2 = rows.length; m < len2; m++) {
          row = rows[m];
          row.add(event);
        }
      }
      body = this.$el.find('.mns-cal-body');
      body.empty();
      results = [];
      for (n = 0, len3 = rows.length; n < len3; n++) {
        row = rows[n];
        results.push(body.append(row.render()));
      }
      return results;
    };

    Calendar.prototype.update = function() {};

    Calendar.prototype.update_header = function() {
      this.$el.find('.mns-cal-title').text(this.options['title']);
      return this.$el.find('.mns-cal-date').text(this.t.months[this.month - 1] + " " + this.year);
    };

    Calendar.prototype.setup_skeleton = function() {
      var body, cal, form, header, navbar;
      header = div('.navbar-header', div('.navbar-brand', i('.fa.fa-calendar'), nbsp, span('.mns-cal-title')), div('.navbar-text.mns-cal-date'));
      form = div('.navbar-form.navbar-right', div('.btn-toolbar', div('.btn-group', a('.btn.btn-default.mns-cal-today', this.t['today'])), div('.btn-group', a('.btn.btn-default.mns-cal-prev', i('.fa.fa-angle-left')), a('.btn.btn-default.mns-cal-next', i('.fa.fa-angle-right')))));
      navbar = nav('.navbar.navbar-default', div('.container-fluid', header, form));
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
