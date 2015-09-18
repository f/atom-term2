pty = require 'pty.js'
util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs-plus'

debounce   = require 'debounce'
Terminal   = require 'atom-term.js'
window.isMac = window.navigator.userAgent.indexOf('Mac') != -1;

{Task} = require 'atom'
{Emitter}  = require 'event-kit'
{$, View} = require 'atom-space-pen-views'

last = (str)-> str[str.length-1]

renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

class TermView extends View
  constructor: (@opts={})->
    @emitter = new Emitter
    @fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    super

  @content: ->
    @div class: 'term2'

  onData: (callback) ->
    @emitter.on 'data', callback

  onExit: (callback) ->
    @emitter.on 'exit', callback

  onResize: (callback) ->
    @emitter.on 'resize', callback


  input: (data) ->
    console.log("in", data)
    try
      if @ptyProcess
        @ptyProcess.write(data)
        # @ptyProcess.send event: 'input', text: data
      else
        @term.write data
    catch error
      console.log error
    @resizeToPane()
    @focusTerm()

  attached: () ->
    {cols, rows, cwd, shell, shellArguments, shellOverride, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg) -> arg

    {cols, rows} = @getDimensions()

    @term = term = new Terminal {
      useStyle: no
      screenKeys: no
      colors, cursorBlink, scrollback, cols, rows
    }

    term.on "data", (data) => @input data
    term.open this.get(0)

    if @opts.forkPTY
      shell = shell or process.env.SHELL
      @ptyProcess = pty.spawn shell, args,
        name: 'xterm-256color'
        cols: cols
        rows: rows
        cwd: atom.project.getPaths()[0] || '~'
        env: process.env

      @ptyProcess.on 'data', (data) =>
        console.log('tty', data)
        @emitter.emit('data', data)
        @term.write data

      @ptyProcess.on 'exit', (data) =>
        @emitter.emit('exit', data)
        @exit()
    else
      term.end = => @exit()

    @input "#{runCommand}#{os.EOL}" if (runCommand)
    term.focus()
    @applyStyle()
    @attachEvents()
    @resizeToPane

  resize: (cols, rows) ->
    return if @term.rows is rows and @term.cols is cols
    console.log @term.rows, @term.cols, "->", rows, cols
    try

      if @ptyProcess
        @ptyProcess.resize cols, rows
        # @ptyProcess.send {event: 'resize', rows, cols}

      if @term
        @term.resize cols, rows
    catch error
      console.log error
      return

    @emitter.emit 'resize', cols, rows

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
    @on 'focus', @focus
    $(window).on 'resize', => @resizeToPane()
    @disposable = atom.workspace.getActivePane().observeFlexScale => setTimeout (=> @resizeToPane()), 300

  focus: ->
    @resizeToPane()
    @focusTerm()
    super

  focusTerm: ->
    @term.element.focus()
    @term.focus()

  resizeToPane: ->
    # return if not @ptyProcess?
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    @resize cols, rows

  getDimensions: ->
    if not @term
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 15
      return {cols, rows}

    @find('.terminal').append @fakeRow
    fakeCol = @fakeRow.children().first()
    cols = Math.floor (@width() / fakeCol.width()) or 9
    rows = Math.floor (@height() / fakeCol.height()) or 16
    @fakeRow.remove()
    {cols, rows}

  exit: ->
    pane = atom.workspace.getActivePane()
    pane.destroyItem(this);

  destroy: ->
    @off 'focus', @focus
    $(window).off 'resize', @resizeToPane
    if @ptyProcess
      @ptyProcess.kill()
      @ptyProcess = null
    if @term
      @term.destroy()
      @term = null
    if @disposable
      @disposable.dispose()
      @disposable = null


module.exports = TermView
