;;; test-org-link-edit.el --- Tests for org-link-edit.el

;; Copyright (C) 2015-2017 Kyle Meyer <kyle@kyleam.com>

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

(ert-deftest test-org-link-edit/forward-slurp ()
  "Test `org-link-edit-forward-slurp'."
  ;; Slurp one blob into plain link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's\]\] website is"
    (org-test-with-temp-text
        "http://orgmode.org/ Org's website is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp one blob into empty bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's\]\] website is"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\] Org's website is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp one blob into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\] website is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp one blob, but not trailing punctuation, into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\]."
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\] website."
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp all-punctuation blob into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's .?.?\]\]"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\] .?.?"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp two blobs into plain link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "http://orgmode.org/ Org's website is"
      (org-link-edit-forward-slurp 2)
      (buffer-string))))
  ;; Slurp two blobs into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website is\]\]"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\] website is"
      (org-link-edit-forward-slurp 2)
      (buffer-string))))
  ;; Slurp new line as space.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\]
website is"
      (org-link-edit-forward-slurp 1)
      (buffer-string))))
  ;; Collapse stretches of new lines.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Org's website is\]\]"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\[Org's\]\]
\n\nwebsite\n\n\nis"
      (org-link-edit-forward-slurp 2)
      (buffer-string))))
  ;; Slurp blob that has no whitespace.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[website\]\]"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\]website"
      (org-link-edit-forward-slurp 1)
      (buffer-string))))
  ;; Slurp blob that isn't separated from link by whitespace.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[-website\]\]"
    (org-test-with-temp-text
        "\[\[http://orgmode.org/\]\]-website"
      (org-link-edit-forward-slurp 1)
      (buffer-string))))
  ;; Slurp beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "\[\[http://orgmode.org/\]\[Org's\]\] website is"
     (org-link-edit-forward-slurp 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/backward-slurp ()
  "Test `org-link-edit-backward-slurp'."
  ;; Slurp one blob into plain link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>http://orgmode.org/ Org's website"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp one blob into empty bracket link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp one blob into bracket link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is Org's\]\] website"
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp one blob with trailing punctuation into bracket link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is: Org's\]\] website."
    (org-test-with-temp-text
        "Here is: <point>\[\[http://orgmode.org/\]\[Org's\]\] website."
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp all-punctuation blob into bracket link.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[... Org's\]\] website."
    (org-test-with-temp-text
        "Here ... <point>\[\[http://orgmode.org/\]\[Org's\]\] website."
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp two blobs into plain link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Here is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>http://orgmode.org/ Org's website"
      (org-link-edit-backward-slurp 2)
      (buffer-string))))
  ;; Slurp two blobs into bracket link.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Here is Org's\]\] website"
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp 2)
      (buffer-string))))
  ;; Slurp new line as space.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is Org's website\]\]"
    (org-test-with-temp-text
        "Here is
<point>\[\[http://orgmode.org/\]\[Org's website\]\]"
      (org-link-edit-backward-slurp 1)
      (buffer-string))))
  ;; Collapse stretches of new lines.
  (should
   (string=
    "\[\[http://orgmode.org/\]\[Here is Org's website\]\]"
    (org-test-with-temp-text
        "Here\n\nis\n\n\n
<point>\[\[http://orgmode.org/\]\[Org's website\]\]"
      (org-link-edit-backward-slurp 2)
      (buffer-string))))
  ;; Slurp blob that has no whitespace.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is<point>\[\[http://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp 1)
      (buffer-string))))
  ;; Slurp blob that isn't separated from link by whitespace.
  (should
   (string=
    "Here \[\[http://orgmode.org/\]\[is-\]\] Org's website"
    (org-test-with-temp-text
        "Here is-<point>\[\[http://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp 1)
      (buffer-string))))
  ;; Slurp beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
     (org-link-edit-backward-slurp 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/slurp-negative-argument ()
  "Test `org-link-edit-forward-slurp' and
`org-link-edit-backward-slurp' with negative arguments."
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-slurp 1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp -1)
      (buffer-string))))
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-slurp -1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp)
      (buffer-string)))))


;;; Barfing

(ert-deftest test-org-link-edit/forward-barf ()
  "Test `org-link-edit-forward-barf'."
  ;; Barf last blob.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\] website is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website\]\] is"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barf last blob with puctuation.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\] website,"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website,\]\]"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barf last blob, all punctuation.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\] ..."
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[...\]\]"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barf two last blobs.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\] website is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-forward-barf 2)
      (buffer-string))))
  ;; Barf one blob, not last.
  (should
   (string=
    "Org's \[\[http://orgmode.org/\]\[website\]\] is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-forward-barf 1)
      (buffer-string))))
  ;; Barf beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
     (org-link-edit-forward-barf 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/backward-barf ()
  "Test `org-link-edit-backward-barf'."
  ;; Barf last blob.
  (should
   (string=
    "Org's website \[\[http://orgmode.org/\]\] is"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website\]\] is"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barf last blob with puctuation.
  (should
   (string=
    "Org's website: \[\[http://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website:\]\]"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barf last all-puctuation blob.
  (should
   (string=
    "Org's ... \[\[http://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[...\]\]"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barf two last blobs.
  (should
   (string=
    "Org's website is \[\[http://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-backward-barf 2)
      (buffer-string))))
  ;; Barf one blob, not last.
  (should
   (string=
    "Org's website \[\[http://orgmode.org/\]\[is\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
      (org-link-edit-backward-barf 1)
      (buffer-string))))
  ;; Barf one blob with punctuation, not last.
  (should
   (string=
    "Org's website. \[\[http://orgmode.org/\]\[is\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[http://orgmode.org/\]\[website. is\]\]"
      (org-link-edit-backward-barf 1)
      (buffer-string))))
  ;; Barf beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "Org's <point>\[\[http://orgmode.org/\]\[website is\]\]"
     (org-link-edit-backward-barf 3)
     (buffer-string))
   :type (list 'user-error)))

(ert-deftest test-org-link-edit/barf-negative-argument ()
  "Test `org-link-edit-forward-barf' and
`org-link-edit-backward-barf' with negative arguments."
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-barf 1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-barf -1)
      (buffer-string))))
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-barf -1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-barf)
      (buffer-string)))))


;;; Slurp and Barf round trip
;;
;; Slurping and then barfing in the same direction, and vice versa,
;; usually result in the original link stage.  This is not true in the
;; following cases.
;; - The slurped string contains one or more newlines.
;; - When slurping into a link with an empty description, the slurped
;;   string is separated from a link by whitespace other than a single
;;   space.

(ert-deftest test-org-link-edit/slurp-barf-round-trip ()
  "Test `org-link-edit-forward-barf' and
`org-link-edit-backward-barf' reversibility."
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-forward-barf 1)
              (org-link-edit-forward-slurp 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[http://orgmode.org/\]\] Org's website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\] Org's website"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-backward-barf 1)
              (org-link-edit-backward-slurp 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-backward-slurp 1)
              (org-link-edit-backward-barf 1)
              (buffer-string))))
  ;; Handle escaped link components.
  (should
   (string= "Here is \[\[file:t.org::some%20text\]\[Org\]\] file"
            (org-test-with-temp-text
                "Here is <point>\[\[file:t.org::some%20text\]\[Org\]\] file"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string))))
  ;; Failed round trip because of newline.
  (should
   (string= "Here is \[\[http://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\[Org's\]\]
website"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string))))
  ;; Failed round trip because of empty description and more than one
  ;; whitespace.
  (should
   (string= "Here is \[\[http://orgmode.org/\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[http://orgmode.org/\]\]    website"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
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
      (org-test-with-temp-text "\[\[http://orgmode.org/\]\[org\]\]"
        (org-link-edit--get-link-data))
    (should (string= link "http://orgmode.org/"))
    (should (string= desc "org"))))

(ert-deftest test-org-link-edit/forward-blob ()
  "Test `org-link-edit--forward-blob'."
  ;; Move forward one blob.
  (should
   (string=
    "one"
    (org-test-with-temp-text "one two"
      (org-link-edit--forward-blob 1)
      (buffer-substring (point-min) (point)))))
  ;; Move forward one blob with point mid.
  (should
   (string=
    "one"
    (org-test-with-temp-text "o<point>ne two"
      (org-link-edit--forward-blob 1)
      (buffer-substring (point-min) (point)))))
  ;; Move forward two blobs.
  (should
   (string=
    "one two"
    (org-test-with-temp-text "one two"
      (org-link-edit--forward-blob 2)
      (buffer-substring (point-min) (point)))))
  ;; Move forward blob, including punctuation.
  (should
   (string=
    "one."
    (org-test-with-temp-text "one."
      (org-link-edit--forward-blob 1)
      (buffer-substring (point-min) (point)))))
  ;; Move forward blob, adjusting for punctuation.
  (should
   (string=
    "one"
    (org-test-with-temp-text "one."
      (org-link-edit--forward-blob 1 t)
      (buffer-substring (point-min) (point)))))
  ;; Move forward blob consisting of only punctuation characters.
  (should
   (string=
    "...."
    (org-test-with-temp-text "...."
      (org-link-edit--forward-blob 1 t)
      (buffer-substring (point-min) (point)))))
  ;; Move backward one blob.
  (should
   (string=
    "two"
    (org-test-with-temp-text "one two<point>"
      (org-link-edit--forward-blob -1)
      (buffer-substring (point) (point-max)))))
  ;; Move backward two blobs.
  (should
   (string=
    "one two"
    (org-test-with-temp-text "one two<point>"
      (org-link-edit--forward-blob -2)
      (buffer-substring (point) (point-max)))))
  ;; Move backward one blobs, including punctuation.
  (should
   (string=
    ".two."
    (org-test-with-temp-text "one .two.<point>"
      (org-link-edit--forward-blob -1)
      (buffer-substring (point) (point-max)))))
  ;; Move beyond last blob.
  (org-test-with-temp-text "one two"
    (should (org-link-edit--forward-blob 1))
    (should-not (org-link-edit--forward-blob 2))
    (should (string= "one two"
                     (buffer-substring (point-min) (point))))))

(ert-deftest test-org-link-edit/split-firsts ()
  "Test `org-link-edit--split-first-blobs'."
  ;; Single blob, n = 1
  (should (equal '("one" . "")
                 (org-link-edit--split-first-blobs "one" 1)))
  ;; Single blob, out-of-bounds
  (should (equal '("one" . nil)
                 (org-link-edit--split-first-blobs "one" 2)))
  ;; Multiple blobs, n = 1
  (should (equal '("one " . "two three")
                 (org-link-edit--split-first-blobs "one two three" 1)))
  ;; Multiple blobs, n > 1
  (should (equal '("one two " . "three")
                 (org-link-edit--split-first-blobs "one two three" 2))))

(ert-deftest test-org-link-edit/split-lasts ()
  "Test `org-link-edit--split-last-blobs'."
  ;; Single blob, n = 1
  (should (equal '("" . "one")
                 (org-link-edit--split-last-blobs "one" 1)))
  ;; Single blob, out-of-bounds
  (should (equal '(nil . "one")
                 (org-link-edit--split-last-blobs "one" 2)))
  ;; Multiple blobs, n = 1
  (should (equal '("one two" . " three")
                 (org-link-edit--split-last-blobs "one two three" 1)))
  ;; Multiple blobs, n > 1
  (should (equal '("one" . " two three")
                 (org-link-edit--split-last-blobs "one two three" 2))))

(provide 'test-org-link-edit)
;;; test-org-link-edit.el ends here
