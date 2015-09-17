"use strict";

const flux = require("flukes");

const TerminalModel = flux.createModel({
  modelName: "Terminal",
  fieldTypes: {
    id: flux.FieldTypes.number,
    local: flux.FieldTypes.bool.ephemeral(),
    term: flux.FieldTypes.object.ephemeral(),
    title: flux.FieldTypes.string,
    pane: flux.FieldTypes.bool.ephemeral(),
  },
  open: function () {
    if (this.pane) {
      const items = this.pane.getItems();
      const index = items.indexOf(this.term);
      this.pane.activateItemAtIndex(index);
      items[index].focus();
      this.term.focus();
      return;
    }
    atom.commands.dispatch(atom.views.getView(atom.workspace), "term2:open")
  },
  init: function () {
    this.pane.onWillDestroy(function () {

    });
  }
});

const Terminals = flux.createCollection({
  model: TerminalModel,
  modelName: "Terminals",
});

module.exports = new Terminals();

