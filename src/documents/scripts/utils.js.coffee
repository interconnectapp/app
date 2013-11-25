createMessage = (type, payload) ->
  type: type
  payload: payload

joinRoomMessage = (room, nick) ->
  createMessage 'join', room: room, nick: nick

module.exports =
  joinRoomMessage: joinRoomMessage
