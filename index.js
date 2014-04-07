var url = require('url');
var TermView = require('./lib/TermView');

module.exports = {
    termViews: [],
    activate: function (state) {
      this.state = state;
      var self = this;
      ['up', 'right', 'down', 'left'].forEach(function (direction) {
        atom.workspaceView.command('term:open-split-'+direction, self.splitTerm.bind(self, direction));
      });
      if (state.termViews) {
        // TODO: restore
      }
    },
    createTermView: function () {
      var termView = new TermView();
      termView.on('remove', this.handleRemoveTerm.bind(this));
      this.termViews.push(termView);
      return termView;
    },
    splitTerm: function (direction) {
      var termView = this.createTermView();
      direction = capitalize(direction);
      atom.workspace.getActivePane()['split'+direction]({
        items: [termView]
      });
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

function capitalize (str) {
  return str[0].toUpperCase() + str.slice(1).toLowerCase();
}