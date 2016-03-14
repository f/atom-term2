# from atom/terminal to reduce cpu usage

pty = require 'ptyw.js'

module.exports = (ptyCwd, sh, cols, rows, args) ->
  callback = @async()
  if sh
      shell = sh
  else
      shell = process.env.SHELL
      if not shell
        # Try to salvage some sort of shell to execute. Horrible code below.
        path = require 'path'
        if process.platform is 'win32'
          shell = path.resolve(process.env.SystemRoot, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe')
        else
          shell = '/bin/sh'

  ptyProcess = pty.fork shell, args,
    name: 'xterm-256color'
    cols: cols
    rows: rows
    cwd: ptyCwd
    env: process.env

  ptyProcess.on 'data', (data) ->
    emit('term3:data', new Buffer(data).toString("base64"))

  ptyProcess.on 'exit', ->
    emit('term3:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(new Buffer(text, "base64").toString("utf-8"))
