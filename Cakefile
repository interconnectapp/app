# =====================================
# Imports

fsUtil = require('fs')
pathUtil = require('path')

APP_DIR    = process.cwd()
BROWSERIFY = 'node_modules/browserify/bin/cmd.js'
DOCPAD     = 'node_modules/docpad/bin/docpad'
COFFEE     = 'node_modules/coffee-script/bin/coffee'

# =====================================
# Generic

{exec,spawn} = require('child_process')
safe = (next,fn) ->
  fn ?= next  # support only one argument
  return (err) ->
    # success status code
    if err is 0
      err = null

    # error status code
    else if err is 1
      err = new Error('Process exited with error status code')

    # Error
    return next(err)  if err

    # Continue
    return fn()

finish = (err) ->
  throw err  if err
  console.log('OK')

actions =
  browserify: (opts, next) ->
    (next = opts; opts = {}) unless next?
    step = ->
      spawn(BROWSERIFY, ['-e', pathUtil.join(APP_DIR, 'src/documents/scripts/script.js'),
                         '-o', pathUtil.join(APP_DIR, 'src/documents/scripts/app.js')],
        {stdio: 'inherit', cwd: APP_DIR}).on('close', safe next)
    step()

  docpad: (opts, next) ->
    (next = opts; opts = {}) unless next?
    step = ->
      spawn(DOCPAD, ['generate'], {stdio: 'inherit', cwd: APP_DIR})
        .on('close', safe next)
    step()

  publish: (opts, next) ->
    (next = opts; opts = {}) unless next?
    step1 = ->
      actions.browserify(opts, safe next, step2)
    step2 = ->
      actions.docpad(opts, safe next)
    step1()

  server: (opts, next) ->
    (next = opts; opts = {}) unless next?
    actions.publish opts, safe next, ->
      spawn(COFFEE, ['app.coffee'], {stdio: 'inherit', cwd: APP_DIR})
        .on('close', safe next)

# =====================================
# Commands

commands =
  browserify:  'Compile the client side javascript'
  docpad:      'Generate static content using docpad'
  publish:     'Create static assets (runs browserify and docpad)'
  server:      'Run a server (runs publish)'

Object.keys(commands).forEach (key) ->
  description = commands[key]
  fn = actions[key]
  task key, description, (opts) ->  fn(opts, finish)
