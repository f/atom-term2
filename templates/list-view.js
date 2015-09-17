/** @jsx React.DOM */
"use strict";

var React = require("react-atom-fork");
var flux = require("flukes");
var terminals = require("../terminal-model");

var TerminalView = React.createClass({
  onMouseDown: function (e) {
    this.props.terminal.open();
  },
  render: function () {
    const t = this.props.terminal;
    return (
      <li onMouseDown={this.onMouseDown.bind(this, t.id)} >tty-{t.title}</li>
    );
  }
});

var ListView = React.createClass({
  mixins: [flux.createAutoBinder([], [terminals])],
  openTerm: function (id) {
    if (id in this.openTerminals) {
      var pane = this.openTerminals[id];
      var view = pane.getView()[0];
      pane.activePane.activateItem(pane);
      view.focus();
      return;
    }
  },
  render: function () {
    const terms = terminals.map(function (t) {
      return (<TerminalView terminal={t} key={t.id} />);
    });
    return (
      <div className="header">
        <span className=""><i className="icon icon-terminal"></i>terminals</span>
        <ul>
          {terms}
        </ul>
      </div>
    );
  }
});

const HTMLElementProto = Object.create(HTMLElement.prototype);

// HTMLElementProto.createdCallback = function () {
//   return;
// };

HTMLElementProto.attachedCallback = function () {
  this.reactNode = React.renderComponent(ListView({}), this);
};

// HTMLElementProto.attributeChangedCallback = function (attrName, oldVal, newVal) {
//   return;
// };

// HTMLElementProto.detachedCallback = function () {
//   return;
// };

module.exports = document.registerElement('terminal-list-view', {prototype: HTMLElementProto});
