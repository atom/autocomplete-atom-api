# Run this to update the static list of properties stored in the
# completions.json file at the root of this repository.

path = require 'path'
fs = require 'fs'
request = require 'request'

requestOptions =
  url: 'https://api.github.com/repos/atom/atom/releases/latest'
  json: true
  headers:
    'User-Agent': 'agent'

request requestOptions, (error, response, release) ->
  if error?
    console.error(error.message)
    return process.exit(1)

  [apiAsset] = release.assets.filter ({name}) -> name is 'atom-api.json'

  unless apiAsset?.browser_download_url
    console.error('No atom-api.json asset found in latest release')
    return process.exit(1)

  apiRequestOptions =
    json: true
    url: apiAsset.browser_download_url

  request apiRequestOptions, (error, response, atomApi) ->
    if error?
      console.error(error.message)
      return process.exit(1)

    {classes} = atomApi

    publicClasses = {}
    for name, {instanceProperties, instanceMethods} of classes
      properties = instanceProperties.filter(isVisible).map(pluckPropertyAttributes).sort(textComparator)
      methods = instanceMethods.filter(isVisible).map(pluckMethodAttributes).sort(textComparator)

      if properties?.length > 0 or methods.length > 0
        publicClasses[name] = properties.concat(methods)

    fs.writeFileSync('completions.json', JSON.stringify(publicClasses))

isVisible = ({visibility}) ->
  visibility in ['Essential', 'Extended', 'Public']

pluckMethodAttributes = (attributes) ->
  {name, summary, returnValues} = attributes
  args = attributes['arguments']

  snippets = []
  if args?.length
    for arg, i in args
      snippets.push("${#{i+1}:#{arg.name}}")

  text = null
  snippet = null
  if snippets.length
    snippet = "#{name}(#{snippets.join(', ')})"
  else
    text = "#{name}()"

  returnValue = returnValues?[0]?.type
  {name, text, snippet, description: summary, leftLabel: returnValue, type: 'method'}

pluckPropertyAttributes = ({name, summary}) ->
  text = name
  returnValue = summary?.match(/\{(\w+)\}/)?[1]
  {name, text, description: summary, leftLabel: returnValue, type: 'property'}

textComparator = (a, b) ->
  return 1 if a.name > b.name
  return -1 if a.name < b.name
  0
