'use strict'

path    = require 'path'
express = require 'express'
irc     = require 'node-irc'

app     = express()
server  = require('http').createServer app
primus  = new require('primus') server, transformer: 'websockets'

routes     = require './routes'
{dispatch} = require './lib/helpers'

app.configure ->
  app.set 'port', process.env.PORT or 5000
  app.use express.favicon()
  app.use express.logger 'dev'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join __dirname, 'out')

app.configure 'development', ->
  app.use express.errorHandler()

primus.on 'connection', (spark) ->
  console.log 'connected'
  primus.write 'From server with Love.'

  spark.on 'data', (data) ->
    dispatch(
      (n) -> if n is 'join' then console.log 'Join Room' else undefined
    )(data.type)
    # console.log 'Received from client:', JSON.stringify data

server.listen app.get('port')
