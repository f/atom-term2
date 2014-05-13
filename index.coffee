TermView = require './lib/TermView'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports =

    termViews: []

    configDefaults:
      autoRunCommand: null
      shellArguments: '--init-file ~/.bash_profile'

    activate: (@state)->

      ['up', 'right', 'down', 'left'].forEach (direction)=>
        atom.workspaceView.command "term2:open-split-#{direction}", @splitTerm.bind(this, direction)

    createTermView:->
      opts =
        runCommand: atom.config.get 'term2.autoRunCommand'
        shellArguments: atom.config.get 'term2.shellArguments'

      termView = new TermView opts
      termView.on 'remove', @handleRemoveTerm.bind this

      @termViews.push? termView
      termView

    splitTerm: (direction)->
      termView = @createTermView()
      direction = capitalize direction
      atom.workspace.getActivePane()["split#{direction}"] items: [termView]

    handleRemoveTerm: (termView)->
      {termViews} = this
      termViews.splice termViews.indexOf(termView), 1

    deactivate:->
      termViews.forEach (view)-> view.deactivate()

    serialize:->
      termViewsState = this.termViews.map (view)-> view.serialize()
      {termViews: termViewsState}
