# Atom Term 3

Run shell sessions within Atom Editor using `term3` package.
Run **Vim, Emacs, Htop, etc.** in Atom.
It's based on `pty.js` as shell spawner, and `term.js` as xterm, with the power
of Atom Package environment.

_Term3 is a fork and rebuilt version of [Term2](http://atom.io/packages/term2) package which was a fork of [Term](http://atom.io/packages/term) package._

## Why is Term3 a thing ?!

This fork fixes some bugs in upstream including [fixing the letter k](https://github.com/Floobits/atom-term3/issues/1).
Term3 adds a terminal list above the treeview list.
Term3 also adds a [service API](http://blog.atom.io/2015/03/25/new-services-API.html) for other plugins, like [Floobits](https://github.com/Floobits/floobits-atom), so you can pair on your terminals in addition to your code.

To install **Term3**

```console
$ apm install term3
```
![Term3 in action](https://raw.githubusercontent.com/Floobits/atom-term3/master/static/term3.png)

## Key Bindings and Events

| key binding | event | action |
| ----------- | ----- | ------ |
| `ctrl + alt + t` | `term3:open` | Opens new terminal tab pane |
| `ctrl + alt + up`| `term3:open-split-up` | Opens new terminal tab pane in up split |
| `ctrl + alt + right`| `term3:open-split-right` | Opens new terminal tab pane in right split |
| `ctrl + alt + down`| `term3:open-split-down` | Opens new terminal tab pane in down split |
| `ctrl + alt + left`| `term3:open-split-left` | Opens new terminal tab pane in left split |
| `ctrl + k, t, t` | `term3:open` | Opens new terminal tab pane |
| `ctrl + k, t, up`| `term3:open-split-up` | Opens new terminal tab pane in up split |
| `ctrl + k, t, right`| `term3:open-split-right` | Opens new terminal tab pane in right split |
| `ctrl + k, t, down`| `term3:open-split-down` | Opens new terminal tab pane in down split |
| `ctrl + k, t, left`| `term3:open-split-left` | Opens new terminal tab pane in left split |
| `cmd + k, t, t` | `term3:open` | Opens new terminal tab pane |
| `cmd + k, t, up`| `term3:open-split-up` | Opens new terminal tab pane in up split |
| `cmd + k, t, right`| `term3:open-split-right` | Opens new terminal tab pane in right split |
| `cmd + k, t, down`| `term3:open-split-down` | Opens new terminal tab pane in down split |
| `cmd + k, t, left`| `term3:open-split-left` | Opens new terminal tab pane in left split |
| `ctrl + insert` | `term3:copy` | Copy text (if `ctrl + c` is not working) |
| `shift + insert` | `term3:paste` | Paste text (if `ctrl + v` is not working) |

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
Terminal ({{ bashName }})
```

## Additional Features

  - **Run a defined command automatically** when shell session starts.
  - You can customize font-family or font-size (default to Atom settings values)
  - You can define **Terminal Colors** in `config.cson`.
  - Turn on or off **blinking cursor**
  - Change **scrollback** limit
  - Start shell sessions with additional parameters.
  - You can **pipe the text and paths** to the Terminal sessions.
  - Paste from clipboard

### Note about colors

Currently, you will need to adjust the colors in `config.cson`
(then you should be able to edit them in the package settings view).

You can add something like (please note the 2 examples of color format):

```cson
term3:
  colors:
    normalBlack: #000
    normalRed:
      red: 255
      blue: 0
      green: 0
      alpha: 1
    normalGreen: ...
    normalYellow: ...
    normalBlue: ...
    normalPurple: ...
    normalCyan: ...
    normalWhite: ...
    brightBlack: ...
    brightRed: ...
    brightGreen: ...
    brightYellow: ...
    brightBlue: ...
    brightPurple: ...
    brightCyan: ...
    brightWhite: ...
    background: ...
    foreground: ...
```

- **Colors are not taken from the Atom theme.**
- alpha channel are not used for now.
- _The background color is for now the only exception and is not used.
The background is transparent so you benefit of Atom app background color._

## FAQ

### Why some commands do not work like in my previous terminal ?

It's [a known `$PATH` issue](https://github.com/floobits/atom-term3/issues/50).
You are probably an OS X user (if not, let us know).
GUI app doesn't get `/etc/paths` (and might come from `/usr/local/bin`).
There is some workaround for OS X 10.9-, but OS X 10.10+ doesn't execute
`/etc/launchd.conf` anymore.
So, in order to get the right PATH in atom-term3 context, you have this
solutions:

- In your `.(bash|zsh|*)rc`, add

  ```bash
  export PATH=$(cat /etc/paths | xargs | tr " " :)
  # or just hardcode your path like this
  export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
  ```

- You can automatically call a command when you open a terminal to `login` by
editing your Atom config:

  ```cson
  term3:
    autoRunCommand: 'login -f `whoami`'
  ```

---

## [Contributors](https://github.com/floobits/atom-term3/graphs/contributors)

## [License](LICENSE)
