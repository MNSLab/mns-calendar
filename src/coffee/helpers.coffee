# Cross platform check for direct instanceOf
#  eg. instanceOf('abc', String) == true, instanceOf('', Object)
window.instanceOf = (obj, constructor) ->
  (obj != undefined) and (obj).constructor == constructor
