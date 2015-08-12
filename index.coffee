path = require 'path'
TermView = require './lib/TermView'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports =

    termViews: []
    focusedTerminal: off

    config:
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
        default: do ({SHELL, HOME}=process.env)->
          switch path.basename SHELL.toLowerCase()
            when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
            when 'zsh'  then ""
            else ''
      openPanesInSameSplit:
        type: 'boolean'
        default: false

    activate: (@state)->

      ['up', 'right', 'down', 'left'].forEach (direction)=>
        atom.commands.add "atom-workspace", "term2:open-split-#{direction}", @splitTerm.bind(this, direction)

      atom.commands.add "atom-workspace", "term2:open", @newTerm.bind(this)
      atom.commands.add "atom-workspace", "term2:pipe-path", @pipeTerm.bind(this, 'path')
      atom.commands.add "atom-workspace", "term2:pipe-selection", @pipeTerm.bind(this, 'selection')

    getColors: ->
      {
        normalBlack, normalRed, normalGreen, normalYellow
        normalBlue, normalPurple, normalCyan, normalWhite
        brightBlack, brightRed, brightGreen, brightYellow
        brightBlue, brightPurple, brightCyan, brightWhite
        background, foreground
      } = (atom.config.getAll 'term2.colors')[0].value
      [
        normalBlack, normalRed, normalGreen, normalYellow
        normalBlue, normalPurple, normalCyan, normalWhite
        brightBlack, brightRed, brightGreen, brightYellow
        brightBlue, brightPurple, brightCyan, brightWhite
        background, foreground
      ]

    createTermView:->
      opts =
        runCommand    : atom.config.get 'term2.autoRunCommand'
        shellOverride : atom.config.get 'term2.shellOverride'
        shellArguments: atom.config.get 'term2.shellArguments'
        titleTemplate : atom.config.get 'term2.titleTemplate'
        cursorBlink   : atom.config.get 'term2.cursorBlink'
        fontFamily    : atom.config.get 'term2.fontFamily'
        fontSize      : atom.config.get 'term2.fontSize'
        colors        : @getColors()

      termView = new TermView opts
      termView.on 'remove', @handleRemoveTerm.bind this

      @termViews.push? termView
      termView

    splitTerm: (direction)->
      openPanesInSameSplit = atom.config.get 'term2.openPanesInSameSplit'
      termView = @createTermView()
      termView.on "click", =>

        # get focus in the terminal
        # avoid double click to get focus
        termView.term.element.focus()
        termView.term.focus()

        @focusedTerminal = termView
      direction = capitalize direction

      splitter = =>
        pane = activePane["split#{direction}"] items: [termView]
        activePane.termSplits[direction] = pane
        @focusedTerminal = [pane, pane.items[0]]

      activePane = atom.workspace.getActivePane()
      activePane.termSplits or= {}
      if openPanesInSameSplit
        if activePane.termSplits[direction] and activePane.termSplits[direction].items.length > 0
          pane = activePane.termSplits[direction]
          item = pane.addItem termView
          pane.activateItem item
          @focusedTerminal = [pane, item]
        else
          splitter()
      else
        splitter()

    newTerm: ->
      termView = @createTermView()
      pane = atom.workspace.getActivePane()
      item = pane.addItem termView
      pane.activateItem item

    pipeTerm: (action)->
      editor = @getActiveEditor()
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
      @termViews.forEach (view)-> view.deactivate()

    serialize:->
      termViewsState = this.termViews.map (view)-> view.serialize()
      {termViews: termViewsState}
