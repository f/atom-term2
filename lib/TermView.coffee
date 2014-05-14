util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs'

debounce   = require 'debounce'
ptyjs      = require 'pty.js'
Terminal   = require 'term.js'

keypather  = do require 'keypather'

{$, View} = require 'atom'

last = (str)-> str[str.length-1]

class TermView extends View

  @content: ->
    @div class: 'term'

  constructor: (@opts={})->
    opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= []

    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPath() or editorPath or process.env.HOME
    super

  initialize: (@state)->
    console.log "initializing"
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand} = @opts
    args = shellArguments.split /\s+/g
    @pty = pty = ptyjs.spawn shell, args, {
      name: if fs.existsSync('/usr/share/terminfo/x/xterm-256color') then 'xterm-256color' else 'xterm'
      env : process.env
      cwd, cols, rows
    }
    @term = term = new Terminal {useStyle: yes, screenKeys: no, cols, rows}
    term.refresh = require('./termjs-refresh-fix').bind term
    term.end = => @destroy()

    term.on "data", (data)=> pty.write data
    term.open this.get(0)

    pty.write "#{runCommand}#{os.EOL}" if runCommand
    pty.pipe term
    term.focus()

    @attachEvents()
    @resizeToPane()

  getTitle: -> "Terminal (#{last @opts.shell.split '/'})"

  attachEvents: ->
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()

  attachResizeEvents: ->
    setTimeout (=> @resizeToPane()), 10
    @on "focus", @resizeToPane
    @resizeInterval = setInterval @resizeToPane.bind(this), 50
    @resizeHandlers = [debounce @resizeToPane.bind(this), 10]
    if window.onresize
      @resizeHandlers.push window.onresize
    window.onresize = (event)=> @resizeHandlers.forEach (handler)-> handler event

  detachResizeEvents: ->
    window.onresize = @resizeHandlers.pop?()
    @off "focus", @resizeToPane
    @resizeHandlers = []
    clearInterval @resizeInterval

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @pty.resize cols, rows
    @term.resize cols, rows
    atom.workspaceView.getActivePaneView().css overflow: 'visible'

  getDimensions: ->
    colSize = if @term then @find('.terminal').width() / @term.cols else 7
    rowSize = if @term then @find('.terminal').height() / @term.rows else 15
    cols = @width() / colSize | 0
    rows = @height() / rowSize | 0

    {cols, rows}

  destroy: ->
    @detachResizeEvents()
    @pty.destroy()
    @term.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()


module.exports = TermView
