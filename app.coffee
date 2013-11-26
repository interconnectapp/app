'use strict'

path    = require('path')
express = require('express')

app     = express()
server  = require('http').createServer(app)
primus  = new require('primus')(server, transformer: 'websockets')

routes     = require('./routes')
{dispatch} = require('./lib/helpers')
irc        = require('./lib/irc')

app.configure ->
  app.set('port', process.env.PORT or 5000)
  app.use(express.favicon())
  app.use(express.logger 'dev')
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(app.router)
  app.use(express.static(path.join __dirname, 'out'))

app.configure 'development', ->
  app.use(express.errorHandler())

client = undefined

primus.on 'connection', (spark) ->
  console.log 'connected'

  spark.on 'data', (data) ->
    dispatch(
      (n, payload) -> if n is 'join' then chatRoom = irc.join(payload.nick, payload.channel, spark)
      (n, payload) -> if n is 'say'  then chatRoom.say(payload.msg)
    )(data.type, data.payload)

primus.on 'disconnection', (spark) ->
  client.quit('Goodbye') if client

server.listen app.get('port')
