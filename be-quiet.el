;;; be-quiet.el --- Be quiet!  -*- lexical-binding: t; -*-

;; Copyright (C) 2024-2025 James Cherti | https://www.jamescherti.com/contact/
;; Copyright (C) 2013-2014 Johan Andersson
;; Copyright (C) 2014-2015 Sebastian Wiesner <swiesner@lunaryorn.com>

;; Maintainer: James Cherti | https://www.jamescherti.com/contact/
;; Author: Johan Andersson <johan.rejeep@gmail.com>
;; Package-Requires: ((cl-lib "0.3") (emacs "24.4"))
;; Keywords: convenience
;; Version: 1.0.1
;; URL: https://github.com/jamescherti/be-quiet.el
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; The be-quiet Emacs package helps manage and minimize unwanted output in your
;; Emacs environment. It is useful in contexts where controlling or suppressing
;; verbosity is required.

;;; Code:

(require 'cl-lib)

(unless (boundp 'inhibit-message)
  (setq inhibit-message nil))

;;; Variables

(defgroup be-quiet nil
  "Emacs, be quiet!"
  :group 'be-quiet
  :prefix "be-quiet-")

(defvar be-quiet-ignore nil
  "When non-nil, do not hide output inside `be-quiet'.
Changes to this variable inside a `be-quiet' block has no effect.")

;;; Internal variables

(defvar be-quiet--write-region-original (symbol-function 'write-region)
  "Original write region function.")

(defvar be-quiet--load-original (symbol-function 'load)
  "Original load function.")

;;; Internal functions

(defun be-quiet--write-region (start end filename
                                     &optional append visit lockname mustbenew)
  "Like `write-region', but try to suppress any messages.
START, END, FILENAME are the mandatory arguments.
APPEND, VISIT, LOCKNAME, MUSTBENEW are optional."
  (unless visit
    (setq visit 'no-message))
  ;; Call our "copy" of `write-region', because if this function is used to
  ;; override `write-region', calling `write-region' directly here would result
  ;; in any endless recursion.
  (funcall be-quiet--write-region-original start end filename
           append visit lockname mustbenew))

(defun be-quiet--load (file &optional noerror _nomessage nosuffix must-suffix)
  "Like `load', but try to be quiet about it.
FILE is mandatory and NOERROR, _NOMESSAGE, NOSUFFIX, MUST-SUFFIX are optional."
  (funcall be-quiet--load-original
           file noerror :nomessage nosuffix must-suffix))

(defun be-quiet--buffer-string (buffer)
  "Get the contents of BUFFER.

When BUFFER is alive, return its contents without properties.
Otherwise return nil."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (buffer-substring-no-properties (point-min) (point-max)))))

(defun be-quiet--insert-to-buffer (object buffer)
  "Insert OBJECT into BUFFER.
If BUFFER is not live, do nothing."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (cl-typecase object
        (character (insert-char object 1))
        (string (insert object))
        (t (princ object #'insert-char))))))

;;; Obsolete variables

(defalias 'be-quiet-buffer-string
  'be-quiet--buffer-string
  "Renamed to `be-quiet--buffer-string'.")

(defalias 'be-quiet-write-region
  'be-quiet--write-region
  "Renamed to `be-quiet--write-region'.")

(defalias 'be-quiet-load
  'be-quiet--load
  "Renamed to `be-quiet--load'.")

(defalias 'be-quiet-insert-to-buffer
  'be-quiet--insert-to-buffer
  "Renamed to `be-quiet--insert-to-buffer'.")

(make-obsolete 'be-quiet-buffer-string 'be-quiet--buffer-string "1.0.2")
(make-obsolete 'be-quiet-write-region 'be-quiet--write-region "1.0.2")
(make-obsolete 'be-quiet-load 'be-quiet--load "1.0.2")
(make-obsolete 'be-quiet-insert-to-buffer 'be-quiet--insert-to-buffer "1.0.2")

;;; Functions

;;;###autoload
(defmacro be-quiet (&rest body)
  "Evaluate BODY while suppressing output.

During the evaluation of BODY, all output is redirected to an internal buffer
unless `be-quiet-ignore' is non-nil. The following types of output are
suppressed:
- Messages generated by the `message' function.
- Output to `standard-output', such as that produced by functions like
  `print', `princ', and others.

Inside BODY, the buffer is bound to the lexical variable `be-quiet-sink'.
Additionally provide a lexical function `be-quiet-current-output', which returns
the current contents of `be-quiet-sink' when called with no arguments.

Changes to the variable `be-quiet-ignore' inside BODY have no effect on output
suppression."
  (declare (indent 0))
  `(let ((be-quiet-sink (generate-new-buffer " *be-quiet*"))
         (inhibit-message t))
     (cl-labels ((be-quiet-current-output ()
                   (or (be-quiet--buffer-string be-quiet-sink) "")))
       (if be-quiet-ignore
           (progn ,@body)
         (unwind-protect
             ;; Override `standard-output', for `print' and friends, and
             ;; monkey-patch `message'
             (cl-letf ((standard-output
                        (lambda (char)
                          (be-quiet--insert-to-buffer char be-quiet-sink)))
                       ((symbol-function 'message)
                        (lambda (fmt &rest args)
                          (when fmt
                            (let ((text (apply #'format fmt args)))
                              (be-quiet--insert-to-buffer (concat text "\n")
                                                          be-quiet-sink)
                              text))))
                       ((symbol-function 'write-region) #'be-quiet--write-region)
                       ((symbol-function 'load) #'be-quiet--load))
               ,@body)
           (and (buffer-name be-quiet-sink)
                (kill-buffer be-quiet-sink)))))))

(defun be-quiet--around-advice (orig-fn &rest args)
  "Advise function to suppress any output of the ORIG-FN function.
ARGS are the ORIG_-FN function arguments."
  (be-quiet
    (apply orig-fn args)))

;;;###autoload
(defun be-quiet-advice-add (fn)
  "Advise the the FN function to be quiet."
  (advice-add fn :around #'be-quiet--around-advice))

;;;###autoload
(defun be-quiet-advice-remove (fn)
  "Remove silence advice from the FN function."
  (advice-remove fn #'be-quiet--around-advice))

(provide 'be-quiet)

;;; be-quiet.el ends here
