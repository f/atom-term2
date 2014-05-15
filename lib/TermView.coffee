util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs'

debounce   = require 'debounce'
ptyjs      = require 'pty.js'
Terminal   = require 'atom-term.js'

keypather  = do require 'keypather'

{$, View} = require 'atom'

last = (str)-> str[str.length-1]

renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

class TermView extends View

  @content: ->
    @div class: 'term2'

  constructor: (@opts={})->
    opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= ''

    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPath() or editorPath or process.env.HOME
    super

  initialize: (@state)->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg)-> arg
    @pty = pty = ptyjs.spawn shell, args, {
      name: if fs.existsSync('/usr/share/terminfo/x/xterm-256color') then 'xterm-256color' else 'xterm'
      env : process.env
      cwd, cols, rows
    }
    colorsArray = (colorCode for colorName, colorCode of colors)
    @term = term = new Terminal {
      useStyle: yes
      screenKeys: no
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    term.end = => @destroy()

    term.on "data", (data)=> pty.write data
    term.open this.get(0)

    pty.write "#{runCommand}#{os.EOL}" if runCommand
    pty.pipe term
    term.focus()

    @attachEvents()
    @resizeToPane()

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  attachEvents: ->
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()
    @command "term2:paste", => @paste()

  paste: ->
    @pty.write atom.clipboard.read()

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
