irc = require('slate-irc')
net = require('net')

join = (nick, channel) ->
  stream = net.connect(port: 6667, host: 'irc.freenode.org')
  client = irc(stream)
  client.nick(nick)
  client.user(nick, "Nomen Nescio")
  client.join(channel)
  client

module.exports =
  join: join
