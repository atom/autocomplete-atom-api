fs = require 'fs'
path = require 'path'

propertyPrefixPattern = /(?:^|\[|\(|,|=|:|\s)\s*(atom\.(?:[a-zA-Z]+\.?){0,2})$/

module.exports =
  selector: '.source.coffee, .source.js'
  id: 'autocomplete-atom-api-atomapiprovider'

  requestHandler: ({cursor, editor}) ->
    return [] unless @isEditingAnAtomPackageFile(editor)

    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    @getCompletions(line)

  load: ->
    @loadCompletions()
    atom.project.onDidChangePaths => @scanProjectDirectoriesForAtomPackages()
    @scanProjectDirectoriesForAtomPackages()

  scanProjectDirectoriesForAtomPackages: ->
    @packageDirectories = []
    atom.project.getDirectories().forEach (directory) =>
      fs.readFile path.join(directory.getPath(), 'package.json'), (error, contents) =>
        try
          if JSON.parse(contents)?.engines?.atom
            @packageDirectories.push(directory)

  loadCompletions: ->
    @completions ?= {}

    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      return if error?

      @completions = {}
      classes = JSON.parse(content)
      @loadProperty('atom', 'Atom', classes)
      return

  isEditingAnAtomPackageFile: (editor) ->
    for directory in @packageDirectories ? []
      return true if directory.contains(editor.getPath())
    false

  getCompletions: (line) ->
    completions = []
    match =  propertyPrefixPattern.exec(line)?[1]
    return completions unless match

    segments = match.split('.')
    prefix = segments.pop() ? ''
    segments = segments.filter (segment) -> segment
    property = segments[segments.length - 1]
    propertyCompletions = @completions[property]?.completions ? []
    for completion in propertyCompletions when completion.name.indexOf(prefix) is 0
      completions.push({word: completion.name, label: completion.type, prefix})

    completions

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
