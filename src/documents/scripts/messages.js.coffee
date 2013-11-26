createMessage = (type, payload) ->
  type: type
  payload: payload

joinRoom = (room, nick) ->
  createMessage 'join', {channel: room, nick: nick}

sendMessage = (msg) ->
  createMessage 'say', {msg: msg}

module.exports =
  joinRoom: joinRoom
  sendMessage: sendMessage
