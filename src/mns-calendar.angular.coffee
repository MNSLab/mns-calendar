# AngularJS directive for mns-calendar
# eg. <mns-calendar />

angular.module 'mnsCalendar', []
.directive 'mnsCalendar', () ->
  {
    restrict: 'E'
    replace: 'true'
    template: '<div></div>'
    link: (scope, elem, attrs)  ->
      scope.$watch attrs['events'], (newVal, oldVal) ->
        elem.MnsCalendar('refetch')
      , true

      elem.MnsCalendar({
        events: [{
          type: 'function'
          function: () ->
            scope[attrs['events']]
        }]
      })

  }
