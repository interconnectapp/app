fail = (msg) -> throw new Error(JSON.stringify msg)
warn = (msg) -> console.log ['WARN:', JSON.stringify msg].join(' ')
info = (msg) -> console.log ['INFO:', JSON.stringify msg].join(' ')
debug = (msg) -> console.log ['DEBUG:', JSON.stringify(msg, null, "  ")].join(' ')

existy = (x) -> x?
truthy = (x) -> x isnt false and existy x

cat = (args...) ->
  head = args[0]
  if existy head then head.concat.apply head, args[1..-1] else []

construct = (head, tail...) -> cat [head], tail

doWhen = (cond, action) -> if truthy cond then action() else undefined

dispatch = (funcs...) ->
  size = funcs.length
  (target, args) ->
    ret = undefined

    for fn in funcs then do ->
      ret = fn.apply fn, construct target, args
      if existy ret then return ret
    ret

module.exports =
  fail: fail
  warn: warn
  info: info
  debug: debug

  existy: existy
  truthy: truthy

  dispatch: dispatch
