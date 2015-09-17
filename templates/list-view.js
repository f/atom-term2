/** @jsx React.DOM */
"use strict";

var React = require("react-atom-fork");
var flux = require("flukes");

var ListView = React.createClass({
  mixins: [flux.createAutoBinder(["terminals"])],
  openTerm: function (id) {
    if (id in this.openTerminals) {
      var pane = this.openTerminals[id];
      var view = pane.getView()[0];
      pane.activePane.activateItem(pane);
      view.focus();
      return;
    }
  },
  onMouseDown: function (tty, e) {
    editorAction.open_term(tty);
  },
  render: function () {
    return (
      <div className="header">
        <span className=""><i className="icon icon-terminal"></i>terminals</span>
        <ul onMouseDown={this.onMouseDown}>
          {this.props.terminals && this.props.terminals.map(function (t) {
            return <li onMouseDown={this.onMouseDown.bind(this, t.id)} >tty-{t.username}</li>;
          }.bind(this))}
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
