# helper function for buildin HTML layout
# params = (shortcut, attrs, childs...)
window.tag = (name, params...) ->
  obj = $("<#{name}>")

  # use shortcut
  if typeof(params[0]) is 'string'
    sc = params.shift()
    klass = (sc.match(/\.[-_0-9a-z]+/gi)||[]).join('').replace(/\./g,' ').trim()
    id = ((sc.match(/\#[-_0-9a-z]+/gi)||[])[0] || '').slice(1)

    obj.attr(
      class: klass,
      id: if id == '' then null else id
    )

  # set attributes
  if typeof(params[0]) is 'object' and params[0].constructor.name is 'Object'
    attrs = params.shift()
    if Array.isArray attrs['class']
      attrs['class'] = attrs['class'].join ' '
    if typeof attrs['style'] is 'object'
      attrs['style'] = ("#{k}:#{v}" for k,v of attrs['style']).join ';'
    obj.attr(attrs)

  # append content
  for child in params
    if typeof(child) is 'string'
      obj.append(document.createTextNode(child))
    else
      obj.append(child)
  obj

# define shortcuts
for tag_name in ['div', 'strong', 'em', 'span', 'a', 'nav', 'table', 'th', 'tr', 'td', 'i']
  ((s) ->
    window[s] = (params...) -> tag(s, params...)
  )(tag_name)

window['nbsp'] = document.createTextNode(String.fromCharCode(160))
