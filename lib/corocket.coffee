irc = require('./irc')
{debug,info} = require ('./helpers')

class Community
  constructor: (@irc, @spark, @channel) ->
    irc.on 'data', (msg) ->
      # This needs better handling with messages from the server.
      debug msg
      spark.write msg.trailing

  say: (msg) ->
    @irc.send(@channel, msg)

  away: (msg) ->
    if msg then @irc.away(msg) else @irc.away("I'll be back!")

  busy: (msg) ->
    @away(msg)

  leave: (msg) ->
    @irc.quit()

join = (nick, channel, spark) ->
  channel = "##{channel}" unless channel[0] is "#"
  ircClient = irc.join(nick, channel)
  spark.join(channel, ->
    debug "Spark joined room #{channel}"
    # spark.room(channel).write(type: joinCorocket, payload: {msg: spark.id})
  )

  community = new Community(ircClient, spark, channel)
  community

module.exports =
  join: join
