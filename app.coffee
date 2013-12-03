'use strict'

path    = require('path')
express = require('express')

app     = express()
server  = require('http').createServer(app)

if process.env.REDISTOGO_URL
  redisenv = require('url').parse(process.env.REDISTOGO_URL)
  console.log redisenv
  primus  = new require('primus')(server, redis: {
                                    host: redisenv.hostname,
                                    port: redisenv.port,
                                    auth: redisenv.auth.split(':')[1]
                                  }, transformer: 'websockets')
else
  primus  = new require('primus')(server,
                                  redis: host: 'localhost', port: 6379
                                  transformer: 'websockets')

PrimusRooms = require('primus-rooms')
PrimusRedis = require('primus-redis-rooms')

routes     = require('./routes')
corocket   = require('./lib/corocket')
Room       = require('./lib/room')

{debug, info, dispatch} = require('./lib/helpers')

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
  debug 'connected'
  room = new Room(spark)

  spark.on 'data', ({type,payload}) ->
    switch type
      when 'join'
        room.join(payload.nick, payload.channel)
      when 'say', 'away', 'leave', 'busy'
        room[type](payload.msg)
      when 'alive', 'ircMembers'
        room[type](payload.sender)
      when 'pingRtcMember'
        room[type](payload.sender, payload.receiver)
      else
        debug payload[type]

  spark.on 'end', ->
    room?.leave("Goodbye")

server.listen app.get('port')
