# from atom/terminal to reduce cpu usage

pty = require 'pty.js'

module.exports = (ptyCwd, sh, cols, rows, args) ->
  callback = @async()
  if sh
      shell = sh
  else
      if process.platform is 'win32'
        path = require 'path'
        shell = path.resolve(process.env.SystemRoot, 'WindowsPowerShell', 'v1.0', 'powershell.exe')
      else
        shell = process.env.SHELL

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
