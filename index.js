var url = require('url');
var TermView = require('./lib/TermView');

module.exports = {
    termViews: [],
    activate: function (state) {
      this.state = state;
      atom.workspaceView.command('term:open', this.openTerm.bind(this));
      atom.workspace.registerOpener(this.handleUrl.bind(this));
      if (state.termViews) {
        // restore
      }
    },
    openTerm: function () {
      atom.workspace.open('term://', {
        split:'right',
        searchAllPanes: true
      }); //.done
    },
    handleUrl: function (urlToOpen) {
      var parsedUrl = url.parse(urlToOpen);
      if (parsedUrl.protocol === 'term:') {
        var termView = new TermView();
        termView.on('remove', this.handleRemoveTerm.bind(this));
        this.termViews.push(termView);
        return termView;
      }
    },
    handleRemoveTerm: function (termView) {
      var termViews = this.termViews;
      termViews.splice(termViews.indexOf(termView), 1); // remove
    },
    deactivate: function () {
      termViews.forEach(function (view) {
        view.deactivate();
      });
    },
    serialize: function () {
      var termViewsState = this.termViews.map(function () {
        return termViews.serialize();
      });
      return {
        termViews: termViewsState
      };
    }
};