;;; test-org-link-edit.el --- Tests for org-link-edit.el

;; Copyright (C) 2015 Kyle Meyer <kyle@kyleam.com>

;; Author:  Kyle Meyer <kyle@kyleam.com>

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

;;; Code:

(require 'org-link-edit)
(require 'ert)

;; This is taken from `org-tests.el' (55c0708).
(defmacro org-test-with-temp-text (text &rest body)
  "Run body in a temporary buffer with Org-mode as the active
mode holding TEXT.  If the string \"<point>\" appears in TEXT
then remove it and place the point there before running BODY,
otherwise place the point at the beginning of the inserted text."
  (declare (indent 1))
  `(let ((inside-text (if (stringp ,text) ,text (eval ,text)))
         (org-mode-hook nil))
     (with-temp-buffer
       (org-mode)
       (let ((point (string-match "<point>" inside-text)))
         (if point
             (progn
               (insert (replace-match "" nil nil inside-text))
               (goto-char (1+ (match-beginning 0))))
           (insert inside-text)
           (goto-char (point-min))))
       ,@body)))
(def-edebug-spec org-test-with-temp-text (form body))


;;; Slurping

(ert-deftest test-org-link-edit/forward-slurp-word ()
  "Test `org-link-edit-forward-slurp-word'."
  ;; Slurp one word into plain link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's\]\] website is"
    (org-test-with-temp-text
        "http://orgmode.org/ Org's website is"
      (org-link-edit-forward-slurp-word)
      (buffer-string))))
  ;; Slurp one word into empty bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's\]\] website is"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\] Org's website is"
      (org-link-edit-forward-slurp-word)
      (buffer-string))))
  ;; Slurp one word into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\] website is"
      (org-link-edit-forward-slurp-word)
      (buffer-string))))
  ;; Slurp two words into plain link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "http://orgmode.org/ Org's website is"
      (org-link-edit-forward-slurp-word 2)
      (buffer-string))))
  ;; Slurp two words into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website is\]\]"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\] website is"
      (org-link-edit-forward-slurp-word 2)
      (buffer-string))))
  ;; Slurp new line as space.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\]
website is"
      (org-link-edit-forward-slurp-word 1)
      (buffer-string))))
  ;; Slurp beyond the number of present words.
  (should-error
   (org-test-with-temp-text
       "\[\[http://orgmode.org/\]\[Org's\]\] website is"
     (org-link-edit-forward-slurp-word 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/backward-slurp-word ()
  "Test `org-link-edit-backward-slurp-word'."
  ;; Slurp one word into plain link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>http://orgmode.org/ Org's website"
      (org-link-edit-backward-slurp-word)
      (buffer-string))))
  ;; Slurp one word into empty bracket link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp-word)
      (buffer-string))))
  ;; Slurp one word into bracket link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is Org's\]\] website"
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp-word)
      (buffer-string))))
  ;; Slurp two words into plain link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Here is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>http://orgmode.org/ Org's website"
      (org-link-edit-backward-slurp-word 2)
      (buffer-string))))
  ;; Slurp two words into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Here is Org's\]\] website"
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp-word 2)
      (buffer-string))))
  ;; Slurp new line as space.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is Org's website\]\]"
    (org-test-with-temp-text
        "Here is
<point>\[\[http://orgmode.org/\]\[Org's website\]\]"
      (org-link-edit-backward-slurp-word 1)
      (buffer-string))))
  ;; Slurp beyond the number of present words.
  (should-error
   (org-test-with-temp-text
       "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
     (org-link-edit-backward-slurp-word 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/slurp-negative-argument ()
  "Test `org-link-edit-forward-slurp-word' and
`org-link-edit-backward-slurp-word' with negative arguments."
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-slurp-word 1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp-word -1)
      (buffer-string))))
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-slurp-word -1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp-word)
      (buffer-string)))))


;;; Barfing

(ert-deftest test-org-link-edit/forward-barf-word ()
  "Test `org-link-edit-forward-barf-word'."
  ;; Barf last word.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\] website is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website\]\] is"
      (org-link-edit-forward-barf-word)
      (buffer-string))))
  ;; Barf two last words.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\] website is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-forward-barf-word 2)
      (buffer-string))))
  ;; Barf one word, not last.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\[website\]\] is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-forward-barf-word 1)
      (buffer-string))))
  ;; Barf beyond the number of present words.
  (should-error
   (org-test-with-temp-text
       "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
     (org-link-edit-forward-barf-word 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/backward-barf-word ()
  "Test `org-link-edit-backward-barf-word'."
  ;; Barf last word.
  (should
   (string=
    "Org's website \[\[http://orgmode.org/\]\] is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website\]\] is"
      (org-link-edit-backward-barf-word)
      (buffer-string))))
  ;; Barf two last words.
  (should
   (string=
    "Org's website is \[\[http://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-backward-barf-word 2)
      (buffer-string))))
  ;; Barf one word, not last.
  (should
   (string=
    "Org's website \[\[http://orgmode.org/\]\[is\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-backward-barf-word 1)
      (buffer-string))))
  ;; Barf beyond the number of present words.
  (should-error
   (org-test-with-temp-text
       "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
     (org-link-edit-backward-barf-word 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/barf-negative-argument ()
  "Test `org-link-edit-forward-barf-word' and
`org-link-edit-backward-barf-word' with negative arguments."
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-barf-word 1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-barf-word -1)
      (buffer-string))))
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-barf-word -1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-barf-word)
      (buffer-string)))))


;;; Slurp and Barf round trip
;;
;; Slurping and barfing should round trip unless there are new lines
;; in the slurped string, which slurping replaces with spaces.

(ert-deftest test-org-link-edit/slurp-barf-round-trip ()
  "Test `org-link-edit-forward-barf-word' and
`org-link-edit-backward-barf-word' reversibility."
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-forward-barf-word 1)
              (org-link-edit-forward-slurp-word 1)
              (buffer-string))))
  (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
           (org-test-with-temp-text
               "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
             (org-link-edit-forward-slurp-word 1)
             (org-link-edit-forward-barf-word 1)
             (buffer-string)))
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-backward-barf-word 1)
              (org-link-edit-backward-slurp-word 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-backward-slurp-word 1)
              (org-link-edit-backward-barf-word 1)
              (buffer-string)))))


;;; Other

(ert-deftest test-org-link-edit/get-link-data ()
  "Test `org-link-edit--get-link-data'."
  ;; Plain link
  (cl-multiple-value-bind (beg end link desc)
      (org-test-with-temp-text "http://orgmode.org/"
        (org-link-edit--get-link-data))
    (should (string= link "http://orgmode.org/"))
    (should-not desc))
  ;; Bracket link
  (cl-multiple-value-bind (beg end link desc)
      (org-test-with-temp-text  "\[\[http://orgmode.org/\]\[org\]\]"
        (org-link-edit--get-link-data))
    (should (string= link "http://orgmode.org/"))
    (should (string= desc "org"))))

(ert-deftest test-org-link-edit/split-first-words ()
  "Test `org-link-edit--split-first-words'."
  ;; Single word, n = 1
  (should (equal '("one" . "")
                 (org-link-edit--split-first-words "one" 1)))
  ;; Single word, out-of-bounds
  (should (equal '("one" . nil)
                 (org-link-edit--split-first-words "one" 2)))
  ;; Multiple words, n = 1
  (should (equal '("one " . "two three")
                 (org-link-edit--split-first-words "one two three" 1)))
  ;; Multiple words, n > 1
  (should (equal '("one two " . "three")
                 (org-link-edit--split-first-words "one two three" 2))))

(ert-deftest test-org-link-edit/split-last-words ()
  "Test `org-link-edit--split-last-words'."
  ;; Single word, n = 1
  (should (equal '("" . "one")
                 (org-link-edit--split-last-words "one" 1)))
  ;; Single word, out-of-bounds
  (should (equal '(nil . "one")
                 (org-link-edit--split-last-words "one" 2)))
  ;; Multiple words, n = 1
  (should (equal '("one two" . " three")
                 (org-link-edit--split-last-words "one two three" 1)))
  ;; Multiple words, n > 1
  (should (equal '("one" . " two three")
                 (org-link-edit--split-last-words "one two three" 2))))

(provide 'test-org-link-edit)
;;; test-org-link-edit.el ends here
