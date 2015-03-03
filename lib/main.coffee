provider = require './provider'

module.exports =
  activate: -> provider.load()

  getProvider: -> providers: [provider]
