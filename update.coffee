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
    {classes} = atomApi

    publicClasses = {}
    for name, {instanceProperties, instanceMethods} of classes
      properties = instanceProperties.filter(isVisible).map ({name}) -> name
      methods = instanceMethods.filter(isVisible).map ({name}) -> name

      if properties?.length > 0 or methods.length > 0
        publicClasses[name] = {properties, methods}

    fs.writeFileSync('completions.json', JSON.stringify(publicClasses))

isVisible = ({visibility}) ->
  visibility in ['Essential', 'Extended', 'Public']
