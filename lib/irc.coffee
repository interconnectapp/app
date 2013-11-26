irc = require('slate-irc')
net = require('net')

logger = ->
  (irc) ->
    irc.stream.pipe(process.stdout)


join = (nick, channel) ->
  stream = net.connect(port: 6667, host: 'irc.freenode.org')
  client = irc(stream)
  client.use(logger)
  client.nick(nick)
  client.user(nick, "Nomen Nescio")
  client.join(channel)

  client

module.exports =
  join: join
