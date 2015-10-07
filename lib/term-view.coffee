util = require 'util'
os = require 'os'
fs = require 'fs-plus'
path = require 'path'
debounce = require 'debounce'
Terminal = require 'atom-term.js'
{CompositeDisposable} = require 'atom'
 # see https://github.com/f/atom-term.js/pull/5
 # see https://github.com/f/atom-term.js/pull/4
window.isMac = window.navigator.userAgent.indexOf('Mac') != -1;

{Task} = require 'atom'
{Emitter}  = require 'event-kit'
{$, View} = require 'atom-space-pen-views'

last = (str)-> str[str.length-1]

renderTemplate = (template, data) ->
  vars = Object.keys data
  vars.reduce (_template, key) ->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

class TermView extends View
  constructor: (@opts={})->
    @emitter = new Emitter
    @fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    super

  focusPane: () ->
    pane = atom.workspace.getActivePane()
    items = pane.getItems()
    index = items.indexOf(this)
    return unless index != -1
    pane.activateItemAtIndex(index)
    focus()

  getForked: () ->
    return @opts.forkPTY

  @content: ->
    @div class: 'term3'

  onData: (callback) ->
    @emitter.on 'data', callback

  onExit: (callback) ->
    @emitter.on 'exit', callback

  onResize: (callback) ->
    @emitter.on 'resize', callback

  onSTDIN: (callback) ->
    @emitter.on 'stdin', callback

  onSTDOUT: (callback) ->
    @emitter.on 'stdout', callback

  input: (data) ->
    return unless @term
    try
      if @ptyProcess
        base64ed = new Buffer(data).toString("base64")
        @ptyProcess.send event: 'input', text: base64ed
      else
        @term.write data
    catch error
      console.error error
    @resizeToPane_()
    @focusTerm()

  attached: () ->
    @disposable = new CompositeDisposable();

    {cols, rows, cwd, shell, shellArguments, shellOverride, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg) -> arg

    if @opts.forkPTY
      {cols, rows} = @getDimensions_()

    @term = term = new Terminal {
      useStyle: no
      screenKeys: no
      handler: (data) =>
        @emitter.emit 'stdin', data
      colors, cursorBlink, scrollback, cols, rows
    }

    term.on "data", (data) =>
      # let the remote term write to stdin - we slurp up its stdout
      if @ptyProcess
        @input data

    term.on "title", (title) =>
      if title.length > 20
        split = title.split(path.sep)
        newTitle = ""
        if split[0] == ""
          split.shift(1)

        if split.length == 1
          title = title.slice(0, 10) + "..." + title.slice(-10)
        else
          title = path.sep + [split[0], "...", split[split.length - 1]].join(path.sep)
          if title.length > 25
            title = path.sep + [split[0], split[split.length - 1]].join(path.sep)
            title = title.slice(0, 10) + "..." + title.slice(-10)

      @title_ = title
      @emitter.emit 'did-change-title', title

    term.open this.get(0)

    if not @opts.forkPTY
      term.end = => @exit()
    else
      processPath = require.resolve './pty'
      @ptyProcess = Task.once processPath, fs.absolute(atom.project.getPaths()[0] ? '~'), shellOverride, cols, rows, args

      @ptyProcess.on 'term3:data', (data) =>
        utf8 = new Buffer(data, "base64").toString("utf-8")
        @term.write utf8
        @emitter.emit('stdout', utf8)

      @ptyProcess.on 'term3:exit', () =>
        @exit()


    @input "#{runCommand}#{os.EOL}" if (runCommand)
    term.focus()
    @applyStyle()
    @attachEvents()
    @resizeToPane_()

  resize: (cols, rows) ->
    return unless @term
    return if @term.rows is rows and @term.cols is cols
    return unless cols > 0 and rows > 0 and isFinite(cols) and isFinite(rows)
    console.log @term.rows, @term.cols, "->", rows, cols
    try
      if @ptyProcess
        @ptyProcess.send {event: 'resize', rows, cols}
      if @term
        @term.resize cols, rows
    catch error
      console.error error
      return

    @emitter.emit 'resize', {cols, rows}

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    return @title_ if @title_
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

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
    @resizeToPane_ = @resizeToPane_.bind this
    @on 'focus', @focus
    $(window).on 'resize', => @resizeToPane_()
    @disposable.add atom.workspace.getActivePane().observeFlexScale => setTimeout (=> @resizeToPane_()), 300
    @disposable.add atom.commands.add "atom-workspace", "term3:paste", => @paste()
    @disposable.add atom.commands.add "atom-workspace", "term3:copy", => @copy()

  copy: ->
    return unless @term

    if @term._selected  # term.js visual mode selections
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

  focus: ->
    @resizeToPane_()
    @focusTerm()

  focusTerm: ->
    return unless @term
    @term.focus()

  resizeToPane_: ->
    return unless @ptyProcess
    {cols, rows} = @getDimensions_()
    @resize cols, rows

  getDimensions: ->
    cols = @term.cols
    rows = @term.rows
    {cols, rows}

  getDimensions_: ->
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
    if @ptyProcess
      @ptyProcess.terminate()
      @ptyProcess = null
    # we always have a @term
    if @term
      @emitter.emit('exit')
      @term.destroy()
      @term = null
      @off 'focus', @focus
      $(window).off 'resize', @resizeToPane_
    if @disposable
      @disposable.dispose()
      @disposable = null


module.exports = TermView
