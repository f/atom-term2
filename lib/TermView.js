var ptyjs = require('pty.js');
var Terminal = require('term.js');
var debounce = require('debounce');
var util = require('util');
var $ = require('atom').$;
var View = require('atom').View;
var path = require('path');
var keypather = require('keypather')();
var os = require('os');
// var EventEmitter = require('events').EventEmitter;
var __hasProp = {}.hasOwnProperty;
var __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
var last = function (str) {
  return str[str.length-1];
};

module.exports = TermView;

function TermView (opts) {
  opts = opts || {};
  this.opts = opts;
  opts.shell = process.env.SHELL || 'bash';
  var editorPath = keypather.get(atom, 'workspace.getEditorViews[0].getEditor().getPath()');
  opts.cwd = opts.cwd || atom.project.getPath() ||
    editorPath || process.env.HOME ||
    path.resolve(__dirname, '..', '..', '..', '..'); // back out of .atom/packages/term/lib
  TermView.__super__.constructor.apply(this, arguments);
}

// util.inherits(TermView, EventEmitter);
__extends(TermView, View);

TermView.content = function () {
  return this.div({ class: 'term' });
};

TermView.prototype.initialize = function (state) {
  this.state = state;
  var opts = this.opts;
  var dims = this.getDimensions();
  var pty = this.pty = ptyjs.spawn(opts.shell, [], {
    name: 'xterm-color',
    cols: dims.cols,
    rows: dims.rows,
    cwd: opts.cwd,
    env: process.env
  });
  var term = this.term = new Terminal({
    cols: dims.cols,
    rows: dims.rows,
    useStyle: true,
    screenKeys: true,
  });
  term.on('data', pty.write.bind(pty));
  term.open(this[0]);
  if (this.opts.runCommand) {
    pty.write(this.opts.runCommand + os.EOL);
  }
  pty.pipe(term);
  term.end = this.destroy.bind(this);
  term.focus();

  this.attachEvents();

  window.term = term;
  window.pty = pty;
};

TermView.prototype.getTitle = function () {
  return '(' + last(this.opts.shell.split('/')) + ')';
};

TermView.prototype.attachEvents = function () {
  this.resizeToPane = this.resizeToPane.bind(this);
  this.attachResizeEvents();
};

TermView.prototype.attachResizeEvents = function () {
  // call immediately (after timeout) for initial sizing
  var self = this;
  setTimeout(function () {
    self.resizeToPane.bind(self);
  }, 10);

  // focus
  this.on('focus', this.resizeToPane);
  var parentPane = atom.workspace.getActivePane();
  // atom missing: no item-activated event :-/, use interval for now
  // parentPane.on('item-activated', function (item) {
  //   if (item === self) self.resizeToPane();
  // });
  this.resizeInterval = setInterval(this.resizeToPane.bind(this), 50);
  // resize
  var resizeHandlers = this.resizeHandlers = [debounce(this.resizeToPane, 10)];
  if (window.onresize) {
    resizeHandlers.push(window.onresize);
  }
  window.onresize = function (evt) {
    resizeHandlers.forEach(function (handler) {
      handler(evt);
    });
  };
};

TermView.prototype.detachResizeEvents = function () {
  window.onresize = this.resizeHandlers.pop();
  this.off('focus', this.resizeToPane);
  this.resizeHandlers = [];
  clearInterval(this.resizeInterval);
};

TermView.prototype.resizeToPane = function () {
  var dims = this.getDimensions();
  if (this.term.rows === dims.rows && this.term.cols === dims.cols) return; // no change
  this.pty.resize(dims.cols, dims.rows);
  this.term.resize(dims.cols, dims.rows);
};

TermView.prototype.getDimensions = function () {
  var term = this.term;
  var colSize = term ? this.find('.terminal').width() / term.cols : 7; // default is 7
  var rowSize = term ? this.find('.terminal').height() / term.rows : 15; // default is 15
  var cols = this.width()  / colSize | 0;
  var rows = this.height() / rowSize | 0;

  return {
    cols: cols,
    rows: rows
  };
};

TermView.prototype.destroy = function () {
  // this.eventElement.trigger('remove');
  this.detachResizeEvents();
  this.pty.destroy();
  this.term.destroy();
  // atom bug: closes all panes
  // atom.workspace.getActivePane().destroyActiveItem();
  var parentPane = atom.workspace.getActivePane();
  if (parentPane.activeItem === this) {
    parentPane.removeItem(parentPane.activeItem);
  }
  this.detach();
};
