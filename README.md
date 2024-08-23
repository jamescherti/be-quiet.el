# be-quiet.el - Emacs, be quiet!
![Build Status](https://github.com/jamescherti/easysession.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/be-quiet.el)
![](https://raw.githubusercontent.com/jamescherti/be-quiet.el/master/.images/made-for-gnu-emacs.svg)

The be-quiet.el Emacs package is designed to help you manage and minimize unwanted output in your Emacs environment. It is particularly useful for Emacs shell scripts or any context where you want to suppress or control the verbosity of Emacs.

```
Loading vc-git...
```

This package helps keep your Emacs output clean and quiet.

## Installation

### Install using straight

To install the `be-quiet` using `straight.el`:

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

## License

Copyright (C) 2024 [James Cherti](https://www.jamescherti.com)

(The `be-quiet` package is based on the shut-up package, originally developed by Johan Andersson and Sebastian Wiesner.)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.

## Usage

To silence specific function calls, use the be-quiet macro:

```lisp
(let (output)
  (be-quiet
    (message "Foo")
    (setq output (be-quiet-current-output)))
  (message "This was the last message: %s" output))
```

In non-interactive sessions, you can further reduce output by using be-quiet-silence-emacs, which adjusts some global Emacs settings:

```lisp
(when noninteractive
  (setq dired-use-ls-dired nil)
  (remove-hook 'find-file-hook 'vc-find-file-hook))
```

## Links

- [be-quiet.el @GitHub](https://github.com/jamescherti/be-quiet.el)
