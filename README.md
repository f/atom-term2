# Atom Term 2

Run shell sessions within Atom Editor using `term2` package.
Run **Vim, Emacs, Htop, etc.** in Atom.
It's based on `pty.js` as shell spawner, and `term.js` as xterm, with the power
of Atom Package environment.

_It's a fork and rebuilt version of "[Term](http://atom.io/packages/term)" package._

## What about this fork ?!

This fork adds a 'ShellOverride' configuration option which allows to override
the shell Term2 is using (your default shell).

If your default shell is zsh you see that it's not yet fully compatible with
Term2 (scrolling might not work):
setting ShellOverride to i.e. 'bash' let you use Term2 with another (working)
shell without messing up with your default shell configuration.

The fork was focused on this option in the first place but evolved a lot since.

To install **Term2** easily into your Atom:

```console
$ apm install term2
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
| `ctrl + k, t, t` | `term2:open` | Opens new terminal tab pane |
| `ctrl + k, t, up`| `term2:open-split-up` | Opens new terminal tab pane in up split |
| `ctrl + k, t, right`| `term2:open-split-right` | Opens new terminal tab pane in right split |
| `ctrl + k, t, down`| `term2:open-split-down` | Opens new terminal tab pane in down split |
| `ctrl + k, t, left`| `term2:open-split-left` | Opens new terminal tab pane in left split |
| `cmd + k, t, t` | `term2:open` | Opens new terminal tab pane |
| `cmd + k, t, up`| `term2:open-split-up` | Opens new terminal tab pane in up split |
| `cmd + k, t, right`| `term2:open-split-right` | Opens new terminal tab pane in right split |
| `cmd + k, t, down`| `term2:open-split-down` | Opens new terminal tab pane in down split |
| `cmd + k, t, left`| `term2:open-split-left` | Opens new terminal tab pane in left split |
| `ctrl + insert` | `term2:copy` | Copy text (if `ctrl + c` is not working) |
| `shift + insert` | `term2:paste` | Paste text (if `ctrl + v` is not working) |

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
term2:
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

It's [a known `$PATH` issue](https://github.com/webBoxio/atom-term2/issues/50).
You are probably an OS X user (if not, let us know).
GUI app doesn't get `/etc/paths` (and might come from `/usr/local/bin`).
There is some workaround for OS X 10.9-, but OS X 10.10+ doesn't execute
`/etc/launchd.conf` anymore.
So, in order to get the right PATH in atom-term2 context, you have this
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
  term2:
    autoRunCommand: 'login -f `whoami`'
  ```

---

## [Contributors](https://github.com/webBoxio/atom-term2/graphs/contributors)

## [License](LICENSE)
