# Atom Term 2

Shell sessions within atom editor. It's a fork of "[Term][1]" package.

```bash
apm install term2
```

![Term](https://dl.dropboxusercontent.com/u/20947008/webbox/atom/atom-term2-1.png)

## A Complete Terminal

You can run **Vim, Emacs, Htop, etc.** in your Atom.

![Vim, Emacs and HTop](https://dl.dropboxusercontent.com/u/20947008/webbox/atom/atom-term3.png)

## Startup Command

It adds startup command to run at startup.

![Term Startup](https://dl.dropboxusercontent.com/u/20947008/webbox/atom/atom-term2.png)

## Shell Arguments

You can define your bash arguments. It's `--init-file ~/.bash_profile` by default.

[1]: http://atom.io/packages/term

## Key Bindings:

**`CTRL + ALT + T`** Opens new tab.

**`CTRL + ALT + <Direction>`**

and you can also use **`CMD + K T <Direction>`**

`CMD + K <Direction>` is the default key binding to open split windows. If you just add `T` after
`K` press, you'll open a window.

Now you can use simply `CTRL + ALT + Left`, `CTRL + ALT + Right`, `CTRL + ALT + Up` or `CTRL + ALT + Down`.

## Custom Title

You can customize Title with using some variables. These are the current variables you can use:

  - `bashName`
  - `hostName`
  - `platform`
  - `home`

Default version of Title template is `Template ({{ bashName }})`.
