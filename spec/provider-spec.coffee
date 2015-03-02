describe "Atom API autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      cursor: cursor
      scope: cursor.getScopeDescriptor()
      prefix: prefix
    provider.requestHandler(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-atom-api')
    runs ->
      [provider] = atom.packages.getActivePackage('autocomplete-atom-api').mainModule.getProvider().providers
    waitsFor -> Object.keys(provider.completions).length > 0
    waitsForPromise -> atom.workspace.open('test.html')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "includes properties and functions on the atom global", ->
    editor.setText('atom.')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 45
    expect(getCompletions()[0].word).toBe 'clipboard'
    expect(getCompletions()[0].prefix).toBe ''

    editor.setText('atom.co')
    editor.setCursorBufferPosition([0, Infinity])
    expect(getCompletions().length).toBe 4
    expect(getCompletions()[0].word).toBe 'commands'
    expect(getCompletions()[0].prefix).toBe 'co'
    expect(getCompletions()[1].word).toBe 'config'
    expect(getCompletions()[1].prefix).toBe 'co'
    expect(getCompletions()[2].word).toBe 'contextMenu'
    expect(getCompletions()[2].prefix).toBe 'co'
    expect(getCompletions()[3].word).toBe 'confirm'
    expect(getCompletions()[3].prefix).toBe 'co'

    editor.setText('atom.commands')
    editor.setCursorBufferPosition([0, Infinity])
    expect(getCompletions().length).toBe 1
    expect(getCompletions()[0].word).toBe 'commands'
    expect(getCompletions()[0].prefix).toBe 'commands'

  it "includes methods on atom global properties", ->
    editor.setText('atom.clipboard.')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 3
    expect(getCompletions()[0].word).toBe 'read'
    expect(getCompletions()[0].prefix).toBe ''
    expect(getCompletions()[1].word).toBe 'readWithMetadata'
    expect(getCompletions()[1].prefix).toBe ''
    expect(getCompletions()[2].word).toBe 'write'
    expect(getCompletions()[2].prefix).toBe ''

    editor.setText('atom.clipboard.rea')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 2
    expect(getCompletions()[0].word).toBe 'read'
    expect(getCompletions()[0].prefix).toBe 'rea'
    expect(getCompletions()[1].word).toBe 'readWithMetadata'
    expect(getCompletions()[1].prefix).toBe 'rea'
