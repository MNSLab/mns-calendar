// Generated by CoffeeScript 1.10.0
(function() {
  angular.module('mnsCalendar', []).directive('mnsCalendar', function() {
    return {
      restrict: 'E',
      replace: 'true',
      template: '<div></div>',
      link: function(scope, elem, attrs) {
        scope.$watch(attrs['events'], function(newVal, oldVal) {
          return elem.MnsCalendar('refetch');
        }, true);
        return elem.MnsCalendar({
          events: [
            {
              type: 'function',
              "function": function() {
                return scope[attrs['events']];
              }
            }
          ]
        });
      }
    };
  });

}).call(this);

//# sourceMappingURL=mns-calendar.angular.js.map