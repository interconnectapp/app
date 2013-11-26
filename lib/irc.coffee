irc = require('slate-irc')
net = require('net')

logger = ->
  (irc) ->
    irc.stream.pipe(process.stdout)

class ChatRoom
  constructor: (@client, @channel) ->
  say: (msg) ->
    @client.send(@channel, msg)

join = (nick, channel, spark) ->
  channel = "##{channel}" unless channel[0] is "#"

  stream = net.connect(port: 6667, host: 'irc.freenode.org')
  client = irc(stream)
  client.use(logger)
  client.nick(nick)
  client.user(nick, "Nomen Nescio")
  client.join(channel)

  chatRoom = new ChatRoom(client, channel)

  client.on 'data', (msg) ->
    console.log msg
    spark.write msg.trailing
  chatRoom

module.exports =
  join: join
