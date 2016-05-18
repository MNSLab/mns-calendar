#=require <helpers.coffee>

# helper function for buildin HTML layout
# params = (shortcut, attrs, childs...)
window.tag = (name, params...) ->
  obj = $("<#{name}>")

  # use shortcut
  if instanceOf(params[0], String)
    sc = params.shift()
    klass = (sc.match(/\.[-_0-9a-z]+/gi)||[]).join('').replace(/\./g,' ').trim()
    id = ((sc.match(/\#[-_0-9a-z]+/gi)||[])[0] || '').slice(1)

    obj.attr(
      class: klass,
      id: if id == '' then null else id
    )


  # set attributes
  if instanceOf(params[0], Object)
    attrs = params.shift()
    if instanceOf(attrs['class'], Array)
      attrs['class'] = attrs['class'].join ' '
    if instanceOf(attrs['style'], Object)
      attrs['style'] = ("#{k}:#{v}" for k,v of attrs['style']).join ';'
    obj.attr(attrs)

  # append content
  for child in params
    if instanceOf(child, String)
      obj.append(document.createTextNode(child))
    else
      obj.append(child)
  obj

# tag helpers
tags =  [
  'div', 'strong', 'em', 'span', 'a', 'nav', 'i', # general
  'table', 'th', 'tr', 'td', # tables
  'ul', 'ol', 'li' #lists
]

# define shortcuts
for tag_name in tags
  do (tag_name) ->
    window[tag_name] = (params...) -> tag(tag_name, params...)


window['nbsp'] = document.createTextNode(String.fromCharCode(160))
