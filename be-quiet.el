;;; be-quiet.el --- Be quiet!  -*- lexical-binding: t; -*-

;; Copyright (C) 2024-2025 James Cherti | https://www.jamescherti.com/contact/
;; Copyright (C) 2013-2014 Johan Andersson <johan.rejeep@gmail.com>
;; Copyright (C) 2014, 2015  Sebastian Wiesner <swiesner@lunaryorn.com>

;; Author: James Cherti | https://www.jamescherti.com/contact/
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience
;; Version: 1.0.2
;; URL: https://github.com/jamescherti/be-quiet.el
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; License:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; The be-quiet Emacs package helps manage and minimize unwanted output in your
;; Emacs environment. It is useful in contexts where controlling or suppressing
;; verbosity is required.

;;; Code:

(require 'cl-lib)

;;; Variables

(defgroup be-quiet nil
  "Emacs, be quiet!"
  :group 'be-quiet
  :prefix "be-quiet-")

(define-obsolete-variable-alias
  'be-quiet-ignore
  'be-quiet-disable "1.0.3"
  "Obsolete. Use `be-quiet-disable' instead.")

(defvar be-quiet-disable nil
  "When non-nil, do not hide output inside `be-quiet'.
Changes to this variable inside a `be-quiet' block has no effect.")

;;; Internal variables

(defvar be-quiet--write-region-original (symbol-function 'write-region)
  "Original `write-region' function.")

(defvar be-quiet--load-original (symbol-function 'load)
  "Original `load' function.")

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

(defalias 'be-quiet-buffer-string 'be-quiet--buffer-string
  "Renamed to `be-quiet--buffer-string'.")
(defalias 'be-quiet-write-region 'be-quiet--write-region
  "Renamed to `be-quiet--write-region'.")
(defalias 'be-quiet-load 'be-quiet--load
  "Renamed to `be-quiet--load'.")
(defalias 'be-quiet-insert-to-buffer 'be-quiet--insert-to-buffer
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
unless `be-quiet-disable' is non-nil.

The following types of output are suppressed:
- Messages generated by the `message' function.
- Output to `standard-output', such as that produced by functions like `print',
  `princ', and others.

Inside BODY, the buffer is bound to the lexical variable `be-quiet-sink'.
Additionally provide a lexical function `be-quiet-current-output', which returns
the current contents of `be-quiet-sink' when called with no arguments."
  (declare (indent 0))
  `(let ((be-quiet-sink (generate-new-buffer " *be-quiet*")))
     (unwind-protect
         (cl-labels ((be-quiet-output ()
                       (or (be-quiet--buffer-string be-quiet-sink) ""))
                     (be-quiet-current-output ()
                       ;; Backward compatibility
                       (be-quiet-output)))
           (if be-quiet-disable
               (progn ,@body)
             (let ((inhibit-message t))
               (cl-letf
                   ;; Override `standard-output', for `print'
                   ((standard-output
                     (lambda (char)
                       (be-quiet--insert-to-buffer char be-quiet-sink)))

                    ;; Override `message'
                    ((symbol-function 'message)
                     (lambda (fmt &rest args)
                       (when fmt
                         (let ((text (apply #'format fmt args)))
                           (be-quiet--insert-to-buffer (concat text "\n")
                                                       be-quiet-sink)
                           text))))

                    ;; Override `write-region'
                    ((symbol-function 'write-region)
                     #'be-quiet--write-region)

                    ;; Override `load'
                    ((symbol-function 'load)
                     #'be-quiet--load))
                 ,@body))))
       (and (buffer-live-p be-quiet-sink)
            (kill-buffer be-quiet-sink)))))

;;;###autoload
(defun be-quiet-funcall (fn &rest args)
  "Call FN with ARGS while suppressing all output.

This function evaluates FN with the given ARGS while redirecting output that
would normally be sent to `standard-output' and suppressing messages produced by
`message'. It also overrides `write-region' and `load' with custom
implementations that prevent unintended output.

If `be-quiet-disable' is non-nil, the function behaves like a normal `apply'."
  (if be-quiet-disable
      (apply fn args)
    (let ((inhibit-message t))
      (cl-letf
          ;; Override `standard-output' (for `print'), `message',
          ;; `write-region', `load'.
          ((standard-output #'ignore)
           ((symbol-function 'message) #'ignore)
           ((symbol-function 'write-region) #'be-quiet--write-region)
           ((symbol-function 'load) #'be-quiet--load))
        (apply fn args)))))

;;;###autoload
(defun be-quiet-advice-add (fn)
  "Advise the FN function to be quiet."
  (advice-add fn :around #'be-quiet-funcall))

;;;###autoload
(defun be-quiet-advice-remove (fn)
  "Remove silence advice from the FN function."
  (advice-remove fn #'be-quiet-funcall))

(provide 'be-quiet)

;;; be-quiet.el ends here
