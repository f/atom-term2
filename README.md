# Atom Term 2

You can run shell sessions within Atom Editor using Term 2 package. You can run **Vim, Emacs, Htop, etc.** in your Atom.
It's based on `pty.js` as shell spawner, and `term.js` as xterm, with the power of Atom Package environment.

It's a fork and rebuilt version of "[Term][1]" package.

To install **Term2** easily into your Atom;

```bash
apm install term2
```

![Vim, Emacs and HTop](https://dl.dropboxusercontent.com/u/20947008/webbox/atom/atom-term3.png)

## Key Bindings and Events

| key binding | event | action |
| ----------- | ----- | ------ |
| `ctrl + alt + t` | `term2:open` | Opens new terminal tab pane |
| `ctrl + alt + up`| `term2:open-split-up` | Opens new terminal tab pane in up split |
| `ctrl + alt + right`| `term2:open-split-right` | Opens new terminal tab pane in right split |
| `ctrl + alt + down`| `term2:open-split-down` | Opens new terminal tab pane in down split |
| `ctrl + alt + left`| `term2:open-split-left` | Opens new terminal tab pane in left split |
| `cmd + k, t, t` | `term2:open` | Opens new terminal tab pane |
| `cmd + k, t, up`| `term2:open-split-up` | Opens new terminal tab pane in up split |
| `cmd + k, t, right`| `term2:open-split-right` | Opens new terminal tab pane in right split |
| `cmd + k, t, down`| `term2:open-split-down` | Opens new terminal tab pane in down split |
| `cmd + k, t, left`| `term2:open-split-left` | Opens new terminal tab pane in left split |

## Customize Title

You can customize Title with using some variables. These are the current variables you can use:

| title variable | value |
| -------------- | ----- |
| `bashName` | Current Shell's name, (e.g. bash, zsh) |
| `hostName` | OS's host name |
| `platform` | Platform name, (e.g. darwin, linux) |
| `home` | Home path of current user |

Default version of **title template** is

```
Template ({{ bashName }})
```

## Additional Features

  - You can define **Terminal Colors** in settings.
  - **Run a defined command automatically** when shell session starts.
  - Turn on or off **blinking cursor**
  - Change **scrollback** limit
  - Start shell sessions with additional parameters.
  - You can **pipe the text and paths** to the Terminal sessions.

[1]: http://atom.io/packages/term
