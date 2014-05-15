path = require 'path'
TermView = require './lib/TermView'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports =

    termViews: []

    configDefaults:
      autoRunCommand: null
      titleTemplate: "Terminal ({{ bashName }})"
      colors:
        normalBlack : '#2e3436'
        normalRed   : '#cc0000'
        normalGreen : '#4e9a06'
        normalYellow: '#c4a000'
        normalBlue  : '#3465a4'
        normalPurple: '#75507b'
        normalCyan  : '#06989a'
        normalWhite : '#d3d7cf'
        brightBlack : '#555753'
        brightRed   : '#ef2929'
        brightGreen : '#8ae234'
        brightYellow: '#fce94f'
        brightBlue  : '#729fcf'
        brightPurple: '#ad7fa8'
        brightCyan  : '#34e2e2'
        brightWhite : '#eeeeec'

      scrollback: 1000
      cursorBlink: yes
      shellArguments: do ({SHELL, HOME}=process.env)->
        switch path.basename SHELL.toLowerCase()
          when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
          when 'zsh'  then ""
          else ''
      openPanesInSameSplit: no

    activate: (@state)->

      ['up', 'right', 'down', 'left'].forEach (direction)=>
        atom.workspaceView.command "term2:open-split-#{direction}", @splitTerm.bind(this, direction)

      atom.workspaceView.command "term2:open", @newTerm.bind(this)

    getColors: ->
      {colors: {
        normalBlack, normalRed, normalGreen, normalYellow
        normalBlue, normalPurple, normalCyan, normalWhite
        brightBlack, brightRed, brightGreen, brightYellow
        brightBlue, brightPurple, brightCyan, brightWhite
      }} = atom.config.getSettings().term2
      [
        normalBlack, normalRed, normalGreen, normalYellow
        normalBlue, normalPurple, normalCyan, normalWhite
        brightBlack, brightRed, brightGreen, brightYellow
        brightBlue, brightPurple, brightCyan, brightWhite
      ]

    createTermView:->
      opts =
        runCommand    : atom.config.get 'term2.autoRunCommand'
        shellArguments: atom.config.get 'term2.shellArguments'
        titleTemplate : atom.config.get 'term2.titleTemplate'
        cursorBlink   : atom.config.get 'term2.cursorBlink'
        colors        : @getColors()

      termView = new TermView opts
      termView.on 'remove', @handleRemoveTerm.bind this

      @termViews.push? termView
      termView

    splitTerm: (direction)->
      openPanesInSameSplit = atom.config.get 'term2.openPanesInSameSplit'
      termView = @createTermView()
      direction = capitalize direction

      splitter = ->
        activePane.termSplits[direction] = activePane["split#{direction}"] items: [termView]

      activePane = atom.workspace.getActivePane()
      activePane.termSplits or= {}
      if openPanesInSameSplit
        if activePane.termSplits[direction] and activePane.termSplits[direction].items.length > 0
          pane = activePane.termSplits[direction]
          item = pane.addItem termView
          pane.activateItem item
        else
          splitter()
      else
        splitter()

    newTerm: ->
      termView = @createTermView()
      pane = atom.workspace.getActivePane()
      item = pane.addItem termView
      pane.activateItem item

    handleRemoveTerm: (termView)->
      {termViews} = this
      termViews.splice termViews.indexOf(termView), 1

    deactivate:->
      termViews.forEach (view)-> view.deactivate()

    serialize:->
      termViewsState = this.termViews.map (view)-> view.serialize()
      {termViews: termViewsState}
