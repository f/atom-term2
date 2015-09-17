"use strict";

const flux = require("flukes");

const TerminalModel = flux.createModel({
  modelName: "Terminal",
  fieldTypes: {
    id: flux.FieldTypes.number,
    local: flux.FieldTypes.bool.ephemeral(),
    term: flux.FieldTypes.object.ephemeral(),
    username: flux.FieldTypes.string,
    title: flux.FieldTypes.string,
    deleted: flux.FieldTypes.bool.ephemeral(),
  }
});

const Terminals = flux.createCollection({
  model: TerminalModel,
  modelName: "Terminals",
});


module.exports = new Terminals();

