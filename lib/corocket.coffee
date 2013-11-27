irc = require('./irc')
{debug,info} = require ('./helpers')

class Community
  constructor: (@irc, @spark, @channel, @nick) ->
    irc.on 'join', ->
      spark.write(type: 'joined', payload: {})

    irc.on 'data', (msg) ->
      # This needs better handling with messages from the server.
      if msg.command in ['PRIVMSG']
        spark.write(type: 'message', payload: "#{msg.prefix.split('!')[0]}: #{msg.trailing}")

  say: (msg) ->
    @irc.send(@channel, msg)

  away: (msg) ->
    if msg then @irc.away(msg) else @irc.away("I'll be back!")

  busy: (msg) ->
    @away(msg)

  leave: (msg) ->
    @irc.quit()

  ircMembers: () ->
    @irc.names(@channel, (err, names) =>
      # Need to handle error
      @spark.write type: 'ircMembers', payload: (name for name in names when name isnt @nick)
    )

join = (nick, channel, spark) ->
  channel = "##{channel}" unless channel[0] is "#"
  ircClient = irc.join(nick, channel)
  spark.join(channel, ->
    debug "Spark joined room #{channel}"
  )

  spark.join("#{channel}/#{nick}", ->
    debug "Spark joined room #{channel}/#{nick}"
  )
  community = new Community(ircClient, spark, channel, nick)
  community

module.exports =
  join: join
