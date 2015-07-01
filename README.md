# Atom Term 2

You can run shell sessions within Atom Editor using Term 2 package. You can run **Vim, Emacs, Htop, etc.** in your Atom.
It's based on `pty.js` as shell spawner, and `term.js` as xterm, with the power of Atom Package environment.

It's a fork and rebuilt version of "[Term][1]" package.

## What about this fork ?!

This fork just adds a 'ShellOverride' configuration option which allows to override the shell Term2 is using (your default shell).

If your default shell is zsh you see that it's not yet fully compatible with Term2 (scrolling do not work): setting ShellOverride
to i.e. 'bash' let you use Term2 with another (working) shell without messing up with your default shell configuration.
Thats all :)

To install **Term2** easily into your Atom;

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
| `ctrl + insert | `term2:copy` | Copy text (if `ctrl + c` is not working) |
| `shift + insert | `term2:paste` | Paste text (if `ctrl + v` is not working) |

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

  - You can define **Terminal Colors** in `config.cson`.
  - **Run a defined command automatically** when shell session starts.
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

# Contributors

  - [@tjmehta][2] *(Owner of the original Term Package)*
  - [@Azerothian][3]
  - [@abe33][4]

[1]: http://atom.io/packages/term
[2]: https://github.com/tjmehta
[3]: https://github.com/Azerothian
[4]: https://github.com/abe33
