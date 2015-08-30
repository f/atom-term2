util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs-plus'

debounce   = require 'debounce'
Terminal   = require 'atom-term.js'

keypather  = do require 'keypather'

{Task} = require 'atom'
{$, View} = require 'atom-space-pen-views'

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
    if opts.shellOverride
        opts.shell = opts.shellOverride
    else
        opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= ''
    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPaths()[0] or editorPath or process.env.HOME
    super

  forkPtyProcess: (sh, args=[])->
    processPath = require.resolve './pty'
    path = atom.project.getPaths()[0] ? '~'
    Task.once processPath, fs.absolute(path), sh, args

  initialize: (@state)->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, shellOverride, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg)-> arg
    @ptyProcess = @forkPtyProcess shellOverride, args
    @ptyProcess.on 'term2:data', (data) => @term.write data
    @ptyProcess.on 'term2:exit', (data) => @destroy()

    colorsArray = colors.map (color) -> color.toHexString()
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

    @applyStyle()
    @attachEvents()
    @resizeToPane()

  input: (data) ->
    try
      @ptyProcess.send event: 'input', text: data
    catch error
      console.log error
    @resizeToPane()
    @focusTerm()

  resize: (cols, rows) ->
    try
      @ptyProcess.send {event: 'resize', rows, cols}
    catch error
      console.log error

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  getIconName: ->
    "terminal"

  applyStyle: ->
    # remove background color in favor of the atom background
    @term.element.style.background = null
    @term.element.style.fontFamily = (
      @opts.fontFamily or
      atom.config.get('editor.fontFamily') or
      # (Atom doesn't return a default value if there is none)
      # so we use a poor fallback
      "monospace"
    )
    # Atom returns a default for fontSize
    @term.element.style.fontSize = (
      @opts.fontSize or
      atom.config.get('editor.fontSize')
    ) + "px"

  attachEvents: ->
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()
    atom.commands.add "atom-workspace", "term2:paste", => @paste()
    atom.commands.add "atom-workspace", "term2:copy", => @copy()

  copy: ->
    if  @term._selected  # term.js visual mode selections
      textarea = @term.getCopyTextarea()
      text = @term.grabText(
        @term._selected.x1, @term._selected.x2,
        @term._selected.y1, @term._selected.y2)
    else # fallback to DOM-based selections
      rawText = @term.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  paste: ->
    @input atom.clipboard.read()

  attachResizeEvents: ->
    setTimeout (=>  @resizeToPane()), 10
    @on 'focus', @focus
    $(window).on 'resize', => @resizeToPane()
    atom.workspace.getActivePane().observeFlexScale => setTimeout (=> @resizeToPane()), 300

  detachResizeEvents: ->
    @off 'focus', @focus
    $(window).off 'resize'

  focus: ->
    @resizeToPane()
    @focusTerm()
    super

  focusTerm: ->
    @term.element.focus()
    @term.focus()

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @resize cols, rows
    @term.resize cols, rows
    atom.views.getView(atom.workspace).style.overflow = 'visible'

  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    if @term
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()
      cols = Math.floor (@width() / fakeCol.width()) or 9
      rows = Math.floor (@height() / fakeCol.height()) or 16
      fakeCol.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}

  destroy: ->
    @detachResizeEvents()
    @ptyProcess.terminate()
    @term.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()


module.exports = TermView
