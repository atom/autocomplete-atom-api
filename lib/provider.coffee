fs = require 'fs'
path = require 'path'

propertyPrefixPattern = /(?:^|\[|\(|,|=|:)\s*atom\.(?:[a-zA-Z]+\.?){0,2}$/

module.exports =
  selector: '.source.coffee, .source.js'
  id: 'autocomplete-atom-api-atomapiprovider'

  constructor: ->
    @completions = {}

  requestHandler: ({cursor, editor, prefix}) ->
    completions = []
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    @getCompletions(line)

  loadCompletions: ->
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      return if error?

      @completions = {}
      classes = JSON.parse(content)
      @loadProperty('atom', 'Atom', classes)
      return

  getCompletions: (line) ->
    completions = []
    match =  propertyPrefixPattern.exec(line)?[0]
    return completions unless match

    segments = match.split('.')
    prefix = segments.pop() ? ''
    segments = segments.filter (segment) -> segment
    property = segments[segments.length - 1]
    propertyCompletions = @completions[property]?.completions ? []
    for completion in propertyCompletions when completion.name.indexOf(prefix) is 0
      completions.push({word: completion.name, label: completion.type, prefix})

    completions

  isVisible: (visibility) ->
    visibility in ['Essential', 'Extended', 'Public']

  getPropertyClass: (name) ->
    atom[name]?.constructor?.name

  loadProperty: (propertyName, className, classes, parent) ->
    classDetails = classes[className]
    return unless classDetails?

    @completions[propertyName] = completions: []

    for name in classDetails?.properties
      @completions[propertyName].completions.push({name: name, type: 'property'})
      propertyClass = @getPropertyClass(name)
      @loadProperty(name, propertyClass, classes)

    for name in classDetails?.methods
      @completions[propertyName].completions.push({name, type: 'method'})
