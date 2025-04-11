# be-quiet.el - Emacs, be quiet!
![Build Status](https://github.com/jamescherti/easysession.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/be-quiet.el)
![](https://raw.githubusercontent.com/jamescherti/be-quiet.el/master/.images/made-for-gnu-emacs.svg)

The `be-quiet` Emacs package helps manage and minimize unwanted output in your Emacs environment. It is useful in contexts where controlling or suppressing verbosity is required.

## Installation

### Emacs: Install with straight (Emacs version < 30)

To install *be-quiet* with `straight.el`:

1. It if hasn't already been done, [add the straight.el bootstrap code](https://github.com/radian-software/straight.el?tab=readme-ov-file#getting-started) to your init file.
2. Add the following code to the Emacs init file:
```emacs-lisp
(use-package be-quiet
  :ensure t
  :straight (be-quiet
             :type git
             :host github
             :repo "jamescherti/be-quiet.el"))
```

### Emacs: Installing with use-package and :vc (Built-in feature in Emacs version >= 30)

To install *be-quiet* with `use-package` and `:vc` (Emacs >= 30):

``` emacs-lisp
(use-package be-quiet
  :ensure t
  :vc (:url "https://github.com/jamescherti/be-quiet.el"
       :rev :newest))
```

### Doom Emacs

Here is how to install *be-quiet* on Doom Emacs:

1. Add to the `~/.doom.d/packages.el` file:
```elisp
(package! be-quiet
  :recipe
  (:host github :repo "jamescherti/be-quiet.el"))
```

2. Add to `~/.doom.d/config.el`:
```elisp
(after! be-quiet
  ;; TODO: Add setq options here
  )
```

3. Run the `doom sync` command:
```
doom sync
```

## Usage

### The be-quiet macro

The simplest way to use the `be-quiet` macro is as follows:
```elisp
(be-quiet
  (message "You will not see this message")
  (message "You will also not see this message"))
```

The `be-quiet` macro silences specific function calls while allowing you to capture their output. For example:
```elisp
(let (output) (be-quiet (message "Foo")
                        (setq output (be-quiet-current-output)))
  (message "This was the last message: %s" output))
```

In this example, the message "Foo" is silenced, but its output is captured and stored in the variable output.

### The be-quiet-advice-add function

To prevent certain functions from generating output, use the `be-quiet-advice-add` function.

For instance, to disable the message "Indentation setup for shell type bash" when `sh-set-shell` is called:
```elisp
(be-quiet-advice-add #'sh-set-shell)
```

In this example, calling the `sh-set-shell` function will execute as usual without displaying any messages.

Here is another example to prevent `recentf` from showing messages during saving and cleanup:
```elisp
(with-eval-after-load "recentf"
  (be-quiet-advice-add #'recentf-save-list)
  (be-quiet-advice-add #'recentf-cleanup))
```

## Frequently asked question

### Identifying Functions to Silence in Emacs

You can assign a regular expression to the variable `debug-on-message` by adding the following line early in your Emacs init files. This will cause Emacs to invoke the debugger when a matching message is displayed during Emacs startup:
```elisp
(setq debug-on-message "Regular expression")
```

### What is the difference between be-quiet and shut-up?

The *be-quiet* package offers the same core functionality as *shut-up*, but with several enhancements:

- Provides new functions: `be-quiet-advice-add` and `be-quiet-advice-remove`
- Ensures internal helper functions are properly marked as internal
- Fixes byte-compiler warnings and other issues and improves docstrings for clarity and completeness

## License

- Copyright (C) 2024-2025 [James Cherti](https://www.jamescherti.com)
- Copyright (C) 2013-2014 Johan Andersson
- Copyright (C) 2014-2015 Sebastian Wiesner

The `be-quiet` package is based on the shut-up package, originally developed by Johan Andersson and Sebastian Wiesner. This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [be-quiet.el @GitHub](https://github.com/jamescherti/be-quiet.el)

Other Emacs packages by the same author:
- [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d): This repository hosts a minimal Emacs configuration designed to serve as a foundation for your vanilla Emacs setup and provide a solid base for an enhanced Emacs experience.
- [compile-angel.el](https://github.com/jamescherti/compile-angel.el): **Speed up Emacs!** This package guarantees that all .el files are both byte-compiled and native-compiled, which significantly speeds up Emacs.
- [outline-indent.el](https://github.com/jamescherti/outline-indent.el): An Emacs package that provides a minor mode that enables code folding and outlining based on indentation levels for various indentation-based text files, such as YAML, Python, and other indented text files.
- [easysession.el](https://github.com/jamescherti/easysession.el): Easysession is lightweight Emacs session manager that can persist and restore file editing buffers, indirect buffers/clones, Dired buffers, the tab-bar, and the Emacs frames (with or without the Emacs frames size, width, and height).
- [vim-tab-bar.el](https://github.com/jamescherti/vim-tab-bar.el): Make the Emacs tab-bar Look Like Vim’s Tab Bar.
- [elispcomp](https://github.com/jamescherti/elispcomp): A command line tool that allows compiling Elisp code directly from the terminal or from a shell script. It facilitates the generation of optimized .elc (byte-compiled) and .eln (native-compiled) files.
- [tomorrow-night-deepblue-theme.el](https://github.com/jamescherti/tomorrow-night-deepblue-theme.el): The Tomorrow Night Deepblue Emacs theme is a beautiful deep blue variant of the Tomorrow Night theme, which is renowned for its elegant color palette that is pleasing to the eyes. It features a deep blue background color that creates a calming atmosphere. The theme is also a great choice for those who miss the blue themes that were trendy a few years ago.
- [Ultyas](https://github.com/jamescherti/ultyas/): A command-line tool designed to simplify the process of converting code snippets from UltiSnips to YASnippet format.
- [dir-config.el](https://github.com/jamescherti/dir-config.el): Automatically find and evaluate .dir-config.el Elisp files to configure directory-specific settings.
- [flymake-bashate.el](https://github.com/jamescherti/flymake-bashate.el): A package that provides a Flymake backend for the bashate Bash script style checker.
- [flymake-ansible-lint.el](https://github.com/jamescherti/flymake-ansible-lint.el): An Emacs package that offers a Flymake backend for ansible-lint.
- [inhibit-mouse.el](https://github.com/jamescherti/inhibit-mouse.el): A package that disables mouse input in Emacs, offering a simpler and faster alternative to the disable-mouse package.
