irc = require('./irc')

class Community
  constructor: (@irc, @spark, @channel) ->
    irc.on 'data', (msg) ->
      # This needs better handling with messages from the server.
      console.log msg
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
    console.log "Spark joined room #{channel}"
    # spark.room(channel).write(type: joinCorocket, payload: {msg: spark.id})
  )

  community = new Community(ircClient, spark, channel)
  community

module.exports =
  join: join
