# be-quiet.el - Emacs, be quiet!
![Build Status](https://github.com/jamescherti/easysession.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/be-quiet.el)
![](https://raw.githubusercontent.com/jamescherti/be-quiet.el/master/.images/made-for-gnu-emacs.svg)

The `be-quiet` Emacs package helps manage and minimize unwanted output in your Emacs environment. It is useful in contexts where controlling or suppressing verbosity is required.

## Installation

### Install using straight

To install `be-quiet` using `straight.el`:

1. If you haven't already done so, [add the straight.el bootstrap code](https://github.com/radian-software/straight.el?tab=readme-ov-file#getting-started) to your init file.
2. Add the following code to your Emacs init file:
```
(use-package be-quiet
  :ensure t
  :straight (be-quiet
             :type git
             :host github
             :repo "jamescherti/be-quiet.el"))
```

## Usage

### The be-quiet macro

The simplest way to use the `be-quiet` macro is as follows:
``` lisp
(be-quiet
  (message "You will not see this message")
  (message "You will also not see this message"))
```

The `be-quiet` macro silences specific function calls while allowing you to capture their output. For example:
```lisp
(let (output) (be-quiet (message "Foo")
                        (setq output (be-quiet-current-output)))
  (message "This was the last message: %s" output))
```

In this example, the message "Foo" is silenced, but its output is captured and stored in the variable output.

### The be-quiet-advice-add function

To prevent certain functions from generating output, use the `be-quiet-advice-add` function.

For instance, to disable the message "Indentation setup for shell type bash" when `sh-set-shell` is called:
``` lisp
(be-quiet-advice-add #'sh-set-shell)
```

In this example, calling the `sh-set-shell` function will execute as usual without displaying any messages.

Here is another example to prevent `recentf` from showing messages during saving and cleanup:
```lisp
(with-eval-after-load "recentf"
  (be-quiet-advice-add #'recentf-save-list)
  (be-quiet-advice-add #'recentf-cleanup))
```

## Frequently asked question

### Are there any other Emacs parameters that can help reduce the output?

In non-interactive sessions, you can further reduce output by using be-quiet-silence-emacs, which adjusts some global Emacs settings:

```lisp
(when noninteractive
  (setq dired-use-ls-dired nil)
  (remove-hook 'find-file-hook 'vc-find-file-hook))
```

### Identifying Functions to Silence in Emacs

You can assign a regular expression to the variable `debug-on-message` by adding the following line early in your Emacs init files. This will cause Emacs to invoke the debugger when a matching message is displayed during Emacs startup:
```lisp
(setq debug-on-message "Regular expression")
```

## License

- Copyright (C) 2024 [James Cherti](https://www.jamescherti.com)
- Copyright (C) 2013-2014 Johan Andersson
- Copyright (C) 2014-2015 Sebastian Wiesner

The `be-quiet` package is based on the shut-up package, originally developed by Johan Andersson and Sebastian Wiesner. This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [be-quiet.el @GitHub](https://github.com/jamescherti/be-quiet.el)
