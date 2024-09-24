;;; be-quiet-test.el --- Test suite for be-quiet       -*- lexical-binding: t; -*-

;; Copyright (C) 2024 James Cherti | https://www.jamescherti.com/contact/
;; Copyright (C) 2014, 2015  Sebastian Wiesner <swiesner@lunaryorn.com>

;; Maintainer: James Cherti | https://www.jamescherti.com/contact/
;; Author: Sebastian Wiesner <swiesner@lunaryorn.com>
;; Maintainer: Johan Andersson <johan.rejeep@gmail.com>
;; URL: https://github.com/jamescherti/be-quiet.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Test be-quiet

;;; Code:

(require 'be-quiet)
(require 's)

(defun be-quiet-test-message-shown-p (message)
  "Determine whether MESSAGE was shown in the messages buffer."
  (let ((pattern (concat "^" (regexp-quote message) "$")))
    (with-current-buffer "*Messages*"
      (save-excursion
        (goto-char (point-min))
        (re-search-forward pattern nil 'no-error)))))

(ert-deftest be-quiet/binds-the-sink-buffer-in-body ()
  (be-quiet
    (should (bufferp be-quiet-sink))
    (should (buffer-live-p be-quiet-sink))))

(ert-deftest be-quiet/silences-message ()
  (message "This message shall be visible")
  (be-quiet-test-message-shown-p "This message shall be visible")
  (be-quiet
    (message "This message shall be hidden")
    ;; Cannot use string equality because Emacs 24.3 prints message
    ;; "ad-handle-definition: `message' got redefined".
    (should (s-ends-with? "This message shall be hidden\n"
                          (be-quiet-current-output)))
    (should-not (be-quiet-test-message-shown-p "This message shall be hidden")))
  ;; Test that `message' is properly restored
  (message "This message shall be visible again")
  (be-quiet-test-message-shown-p "This message shall be visible again"))

(ert-deftest be-quiet/handles-message-with-nil-argument ()
  (be-quiet
    (message nil)
    (should (s-blank? (be-quiet-current-output)))))

(ert-deftest be-quiet/silences-princ ()
  (with-temp-buffer
    (let ((standard-output (current-buffer)))
      (princ "This text is visible. ")
      (should (string= "This text is visible. " (buffer-string)))
      (be-quiet
        (princ "This text is hidden. ")
        ;; Cannot use string equality because Emacs 24.3 prints message
        ;; "ad-handle-definition: `message' got redefined".
        (should (s-ends-with? "This text is hidden. "
                              (be-quiet-current-output)))
        (should (string= "This text is visible. " (buffer-string))))
      (princ "This text is visible again.")
      (should (string= "This text is visible. This text is visible again."
                       (buffer-string))))))

(ert-deftest be-quiet/silences-write-region ()
  (let ((emacs (concat invocation-directory invocation-name))
        (be-quiet (symbol-file 'be-quiet 'defun))
        (temp-file (make-temp-file "be-quiet-test-")))
    (with-temp-buffer
      ;; We must use a sub-process, because we have no way to intercept
      ;; `write-region' messages otherwise
      (call-process emacs nil t nil "-Q" "--batch"
                    "-l" be-quiet
                    "--eval" (prin1-to-string
                              `(progn
                                 (message "Start")
                                 (be-quiet
                                   (write-region "Silent world" nil ,temp-file))
                                 (message "Done"))))
      ;; Can not do strict equality because in Emacs-23 this message
      ;; is printed:
      ;; "This `cl-labels' requires `lexical-binding' to be non-nil"
      (should (s-contains? "Start\n" (buffer-string)))
      (should (s-contains? "Done\n" (buffer-string)))
      ;; Test that the overridden be-quiet did it's work actually
      (with-temp-buffer
        (insert-file-contents temp-file)
        (should (string= "Silent world" (buffer-string)))))))

(ert-deftest be-quiet/kill-sink-buffer ()
  (be-quiet
    (kill-buffer be-quiet-sink)
    (message "bar")
    (should (string= (be-quiet-current-output) "")))
  (be-quiet
    (kill-buffer be-quiet-sink)
    (print "bar")
    (should (string= (be-quiet-current-output) "")))
  (be-quiet
    (kill-buffer be-quiet-sink)
    (should (string= (be-quiet-current-output) ""))))

(ert-deftest be-quiet/ignore ()
  (with-temp-buffer
    (let ((standard-output (current-buffer)))
      (be-quiet
        (princ "foo")
        (should (s-ends-with? "foo" (be-quiet-current-output)))))
    (should (string= (buffer-string) "")))
  (with-temp-buffer
    (let ((be-quiet-ignore t)
          (standard-output (current-buffer)))
      (be-quiet
        (princ "foo")
        (should-not (s-ends-with? "foo" (be-quiet-current-output)))))
    (should (string= (buffer-string) "foo"))))

(ert-deftest be-quiet/message-return-value ()
  (should (equal (be-quiet (message "hi"))
                 "hi"))
  (should (equal (be-quiet (message "hi %s" "something"))
                 "hi something")))

(defun be-quiet/test-function-advice ()
  "Display a test message."
  (message "test"))

(ert-deftest be-quiet/add-remove-advice ()
  "Test adding and removing the `be-quiet' advice."

  ;; Verify that no advice is present initially
  (should (equal (advice-member-p #'be-quiet--around-advice
                                  #'be-quiet/test-function-advice)
                 nil))

  ;; Add the be-quiet advice
  (be-quiet-advice-add #'be-quiet/test-function-advice)

  ;; Verify that the advice has been added and is the correct advice
  (should (not (equal (advice-member-p #'be-quiet--around-advice
                                       #'be-quiet/test-function-advice)
                      nil)))

  ;; Remove the be-quiet advice
  (be-quiet-advice-remove #'be-quiet/test-function-advice)

  ;; Verify that the advice has been removed
  (should (equal (advice-member-p #'be-quiet--around-advice
                                  #'be-quiet/test-function-advice)
                 nil)))

(provide 'be-quiet-test)
;;; be-quiet-test.el ends here
