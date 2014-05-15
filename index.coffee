path = require 'path'
TermView = require './lib/TermView'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports =

    termViews: []

    configDefaults:
      titleTemplate: "Terminal ({{ bashName }})"
      autoRunCommand: null
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

    createTermView:->
      opts =
        runCommand: atom.config.get 'term2.autoRunCommand'
        shellArguments: atom.config.get 'term2.shellArguments'
        titleTemplate: atom.config.get 'term2.titleTemplate'

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
