util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs-plus'

debounce   = require 'debounce'
Terminal   = require 'atom-term.js'

keypather  = do require 'keypather'

{$, View, Task} = require 'atom'

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

  forkPtyProcess: (args=[])->
    processPath = require.resolve './pty'
    path = atom.project.getPath() ? '~'
    Task.once processPath, fs.absolute(path), args

  initialize: (@state)->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg)-> arg

    @ptyProcess = @forkPtyProcess args
    @ptyProcess.on 'term2:data', (data) => @term.write data
    @ptyProcess.on 'term2:exit', (data) => @destroy()

    colorsArray = (colorCode for colorName, colorCode of colors)
    @term = term = new Terminal {
      useStyle: no
      screenKeys: no
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    term.end = => @destroy()

    term.on "data", (data)=> @input data
    term.open this.get(0)

    @input "#{runCommand}#{os.EOL}" if runCommand
    term.focus()

    @attachEvents()
    @resizeToPane()

  input: (data) ->
    @ptyProcess.send event: 'input', text: data

  resize: (cols, rows) ->
    @ptyProcess.send {event: 'resize', rows, cols}

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
    @input atom.clipboard.read()

  attachResizeEvents: ->
    setTimeout (=>  @resizeToPane()), 10
    @on 'focus', @resizeToPane
    $(window).on 'resize', => @resizeToPane()

  detachResizeEvents: ->
    @off 'focus', @resizeToPane

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @resize cols, rows
    @term.resize cols, rows
    atom.workspaceView.getActivePaneView().css overflow: 'visible'

  getDimensions: ->
    fakeCol = $("<span id='colSize'>&nbsp;</span>").css visibility: 'hidden'
    if @term
      @find('.terminal').append fakeCol
      fakeCol = @find(".terminal span#colSize")
      cols = Math.floor (@width() / fakeCol.width()) or 9
      rows = Math.floor (@height() / fakeCol.height()) or 16
      fakeCol.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}

  destroy: ->
    @ptyProcess.terminate()
    @detachResizeEvents()
    @term.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()


module.exports = TermView
