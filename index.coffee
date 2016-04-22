path = require 'path'
TermView = require './lib/term-view'
ListView = require './lib/build/list-view'
Terminals = require './lib/terminal-model'
{Emitter}  = require 'event-kit'
keypather  = do require 'keypather'
{CompositeDisposable} = require 'event-kit'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

getColors = ->
  {
    normalBlack, normalRed, normalGreen, normalYellow
    normalBlue, normalPurple, normalCyan, normalWhite
    brightBlack, brightRed, brightGreen, brightYellow
    brightBlue, brightPurple, brightCyan, brightWhite
    background, foreground
  } = (atom.config.getAll 'term3.colors')[0].value
  [
    normalBlack, normalRed, normalGreen, normalYellow
    normalBlue, normalPurple, normalCyan, normalWhite
    brightBlack, brightRed, brightGreen, brightYellow
    brightBlue, brightPurple, brightCyan, brightWhite
    background, foreground
  ].map (color) -> color.toHexString()

config =
  autoRunCommand:
    type: 'string'
    default: ''
  titleTemplate:
    type: 'string'
    default: "Terminal ({{ bashName }})"
  fontFamily:
    type: 'string'
    default: ''
  fontSize:
    type: 'string'
    default: ''
  colors:
    type: 'object'
    properties:
      normalBlack:
        type: 'color'
        default: '#2e3436'
      normalRed:
        type: 'color'
        default: '#cc0000'
      normalGreen:
        type: 'color'
        default: '#4e9a06'
      normalYellow:
        type: 'color'
        default: '#c4a000'
      normalBlue:
        type: 'color'
        default: '#3465a4'
      normalPurple:
        type: 'color'
        default: '#75507b'
      normalCyan:
        type: 'color'
        default: '#06989a'
      normalWhite:
        type: 'color'
        default: '#d3d7cf'
      brightBlack:
        type: 'color'
        default: '#555753'
      brightRed:
        type: 'color'
        default: '#ef2929'
      brightGreen:
        type: 'color'
        default: '#8ae234'
      brightYellow:
        type: 'color'
        default: '#fce94f'
      brightBlue:
        type: 'color'
        default: '#729fcf'
      brightPurple:
        type: 'color'
        default: '#ad7fa8'
      brightCyan:
        type: 'color'
        default: '#34e2e2'
      brightWhite:
        type: 'color'
        default: '#eeeeec'
      background:
        type: 'color'
        default: '#000000'
      foreground:
        type: 'color'
        default: '#f0f0f0'
  scrollback:
    type: 'integer'
    default: 1000
  cursorBlink:
    type: 'boolean'
    default: true
  shellOverride:
    type: 'string'
    default: ''
  shellArguments:
    type: 'string'
    default: do ({SHELL, HOME}=process.env) ->
      switch path.basename SHELL && SHELL.toLowerCase()
        when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
        when 'zsh'  then "-l"
        else ''
  openPanesInSameSplit:
    type: 'boolean'
    default: false

module.exports =

  termViews: []
  focusedTerminal: off
  emitter: new Emitter()
  config: config
  disposables: null

  activate: (@state) ->
    @disposables = new CompositeDisposable()

    unless process.env.LANG
      console.warn "Term3: LANG environment variable is not set. Fancy characters (å, ñ, ó, etc`) may be corrupted. The only work-around is to quit Atom and run `atom` from your shell."

    ['up', 'right', 'down', 'left'].forEach (direction) =>
      @disposables.add atom.commands.add "atom-workspace", "term3:open-split-#{direction}", @splitTerm.bind(this, direction)

    @disposables.add atom.commands.add "atom-workspace", "term3:open", @newTerm.bind(this)
    @disposables.add atom.commands.add "atom-workspace", "term3:pipe-path", @pipeTerm.bind(this, 'path')
    @disposables.add atom.commands.add "atom-workspace", "term3:pipe-selection", @pipeTerm.bind(this, 'selection')

    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      node = new ListView()
      treeViewPkg.mainModule.treeView.find(".tree-view-scroller").prepend node

  service_0_1_3: () ->
    {
      getTerminals: @getTerminals.bind(this),
      onTerm: @onTerm.bind(this),
      newTerm: @newTerm.bind(this),
    }

  getTerminals: ->
    Terminals.map (t) ->
      t.term

  onTerm: (callback) ->
    @emitter.on 'term', callback

  attachSubscriptions: (termView, item, pane) ->
    subscriptions = new CompositeDisposable

    focusNextTick = (activeItem) ->
      process.nextTick ->
        termView.focus()
        # HACK!
        # so, term.js allows for a special _textarea because of iframe shenanigans,
        # but, it is the constructor instead of the instance!!!1 - probably to avoid having to bind this as a premature
        # optimization.
        atomPane = activeItem.parentsUntil("atom-pane").parent()[0]
        if termView.term
          termView.term.constructor._textarea = atomPane

    subscriptions.add pane.onDidActivate ->
      activeItem = pane.getActiveItem()
      if activeItem != item
        return
      @focusedTerminal = termView
      termView.focus()
      focusNextTick activeItem

    subscriptions.add pane.onDidChangeActiveItem (activeItem) ->
      if activeItem != termView
        if termView.term
          termView.term.constructor._textarea = null
        return
      focusNextTick activeItem

    subscriptions.add termView.onExit () ->
      Terminals.remove termView.id

    subscriptions.add pane.onWillRemoveItem (itemRemoved, index) =>
      if itemRemoved.item == item
        item.destroy()
        Terminals.remove termView.id
        @disposables.remove subscriptions
        subscriptions.dispose()

    subscriptions

  newTerm: (forkPTY=true, rows=30, cols=80, title='tty') ->
    termView = @createTermView forkPTY, rows, cols, title
    pane = atom.workspace.getActivePane()
    item = pane.addItem termView
    @disposables.add @attachSubscriptions(termView, item, pane)
    pane.activateItem item
    termView

  createTermView: (forkPTY=true, rows=30, cols=80, title='tty') ->
    opts =
      runCommand    : atom.config.get 'term3.autoRunCommand'
      shellOverride : atom.config.get 'term3.shellOverride'
      shellArguments: atom.config.get 'term3.shellArguments'
      titleTemplate : atom.config.get 'term3.titleTemplate'
      cursorBlink   : atom.config.get 'term3.cursorBlink'
      fontFamily    : atom.config.get 'term3.fontFamily'
      fontSize      : atom.config.get 'term3.fontSize'
      colors        : getColors()
      forkPTY       : forkPTY
      rows          : rows
      cols          : cols

    if opts.shellOverride
        opts.shell = opts.shellOverride
    else
        opts.shell = process.env.SHELL or 'bash'

    # opts.shellArguments or= ''
    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPaths()[0] or editorPath or process.env.HOME

    termView = new TermView opts
    model = Terminals.add {
      local: !!forkPTY,
      term: termView,
      title: title,
    }
    id = model.id
    termView.id = id

    termView.on 'remove', @handleRemoveTerm.bind this
    termView.on 'click', =>
      # get focus in the terminal
      # avoid double click to get focus
      termView.term.element.focus()
      termView.term.focus()

      @focusedTerminal = termView

    termView.onDidChangeTitle () ->
      if forkPTY
        model.title = termView.getTitle()
      else
        model.title = title + '-' + termView.getTitle()

    @termViews.push? termView
    process.nextTick () => @emitter.emit 'term', termView
    termView

  splitTerm: (direction) ->
    openPanesInSameSplit = atom.config.get 'term3.openPanesInSameSplit'
    termView = @createTermView()
    direction = capitalize direction

    splitter = =>
      pane = activePane["split#{direction}"] items: [termView]
      activePane.termSplits[direction] = pane
      @focusedTerminal = [pane, pane.items[0]]
      @disposables.add @attachSubscriptions(termView, pane.items[0], pane)

    activePane = atom.workspace.getActivePane()
    activePane.termSplits or= {}
    if openPanesInSameSplit
      if activePane.termSplits[direction] and activePane.termSplits[direction].items.length > 0
        pane = activePane.termSplits[direction]
        item = pane.addItem termView
        pane.activateItem item
        @focusedTerminal = [pane, item]
        @disposables.add @attachSubscriptions(termView, item, pane)
      else
        splitter()
    else
      splitter()

  pipeTerm: (action) ->
    editor = atom.workspace.getActiveTextEditor()
    if !editor
      return
    stream = switch action
      when 'path'
        editor.getBuffer().file.path
      when 'selection'
        editor.getSelectedText()

    if stream and @focusedTerminal
      if Array.isArray @focusedTerminal
        [pane, item] = @focusedTerminal
        pane.activateItem item
      else
        item = @focusedTerminal

      item.pty.write stream.trim()
      item.term.focus()

  handleRemoveTerm: (termView)->
    @termViews.splice @termViews.indexOf(termView), 1

  deactivate:->
    @termViews.forEach (view) -> view.exit()
    @termViews = []
    @disposables.dispose

  serialize:->
    termViewsState = this.termViews.map (view)-> view.serialize()
    {termViews: termViewsState}
