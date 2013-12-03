irc = require('./irc')

{debug,info} = require ('./helpers')

class Room
  constructor: (@spark) ->

  writeTo: (target, type, payload) ->
    debug "Sending #{type} to #{target} containing #{JSON.stringify(payload)}"
    @spark.room(target).write(type: type, payload: payload)

  write: (type, payload) ->
    debug "Sending #{type} to this client containing #{JSON.stringify(payload)}"
    @spark.write( type: type, payload: payload)

  join: (@nick, @channel) ->
    @channel = "##{@channel}" unless @channel[0] is "#"
    @communityId = "#{@channel}/#{@nick}"

    @irc = irc.join(@nick, @channel)
    @spark.join(@channel, => debug "Spark joined room #{@channel}")
    @spark.join(@communityId, => debug "Spark joined room #{@communityId}")

    @irc.on 'join', => @write('joined', {})

    @irc.on 'data', (msg) =>
      # This needs better handling with messages from the server.
      if msg.command in ['PRIVMSG']
        @write('message', {from: msg.prefix.split('!')[0], msg: msg.trailing})
    @

  leave: (msg) ->
    @irc.quit("Goodbye") if @irc
    # leave webrtc
    @

  say: (msg) ->
    @irc.send(@channel, msg)
    @

  away: (msg) ->
    if msg then @irc.away(msg) else @irc.away("I'll be back!")
    @

  busy: (msg) ->
    @away(msg)
    @

  ircMembers: (sender) ->
    @irc.names(@channel, (err, names) =>
      # Need to handle error
      @write('ircMembers', (name for name in names when name isnt @nick)))
    @

  alive: (sender) ->
    @writeTo(@channel, 'living', sender: sender)
    @

  pingRtcMember: (sender, receiver) ->
    @writeTo(receiver, 'ping', sender: sender)
    @

module.exports = Room
