createMessage = (type, payload) ->
  type: type
  payload: payload

joinRoomMessage = (room, nick) ->
  createMessage 'join', {channel: room, nick: nick}

module.exports =
  joinRoomMessage: joinRoomMessage
