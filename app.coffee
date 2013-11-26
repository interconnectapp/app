'use strict'

path    = require('path')
express = require('express')

app     = express()
server  = require('http').createServer(app)
primus  = new require('primus')(server,
                                redis: { host: 'localhost', port: 6379},
                                transformer: 'websockets')

PrimusRooms = require('primus-rooms')
PrimusRedis = require('primus-redis-rooms')

routes     = require('./routes')
{dispatch} = require('./lib/helpers')
corocket  = require('./lib/corocket')

primus.use('rooms', PrimusRooms)  # Remember to use rooms first
primus.use('redis', PrimusRedis)

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

primus.on 'connection', (spark) ->
  console.log 'connected'
  session = undefined

  spark.on 'data', (data) ->
    dispatch(
      (n, payload) ->
        if n is 'join'
          session = corocket.join(payload.nick, payload.channel, spark)
      (n, payload) -> if n is 'say'   then session.say(payload.msg)
      (n, payload) -> if n is 'away'  then session.away(payload.msg)
      (n, payload) -> if n is 'leave' then session.leave(payload.msg)
      (n, payload) -> if n is 'busy'  then session.busy(payload.msg)
    )(data.type, data.payload)

primus.on 'disconnection', (spark) ->
  session.leave('Goodbye') if session

server.listen app.get('port')
