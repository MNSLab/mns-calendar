# AngularJS directive for mns-calendar
# eg. <mns-calendar />

angular.module 'mnsCalendar', []
.directive 'mnsCalendar', () ->
  {
    restrict: 'E'
    replace: 'true'
    template: '<div></div>'
    link: (scope, elem, attrs)  ->
      cache = []

      scope.$watch attrs['events'], (newVal, oldVal) ->
        cache = newVal
        elem.MnsCalendar('refetch')
      , true

      elem.MnsCalendar({
        events: [{
          type: 'function'
          function: () ->
            cache
        }]
      })

  }
