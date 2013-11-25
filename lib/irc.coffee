# IRCClient = require 'node-irc'

# join = (nick, channel) ->
#   console.log "Join IRC #{nick}:#{channel}"
#   channel = "#{channel}" unless channel[0] is "#"
#   client = new IRCClient 'irc.freenode.net', 6667, nick, "Nomen Nescio"
#   client.connect()
#   client.join channel
#
irc = require 'slate-irc'
net = require 'net'

logger = ->
  (irc) ->
    irc.stream.pipe process.stdout

join = (nick, channel) ->
  channel = "##{channel}" unless channel[0] is "#"
  stream = net.connect port: 6667, host: 'irc.freenode.org'
  client = irc stream
  client.use logger
  client.nick nick
  client.user nick, "Nomen Nescio"
  client.join channel
  client.names channel, (err, name) ->
    console.log name

module.exports =
  join: join
