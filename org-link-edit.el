;;; org-link-edit.el --- Slurp and barf with Org links

;; Copyright (C) 2015 Kyle Meyer <kyle@kyleam.com>

;; Author:  Kyle Meyer <kyle@kyleam.com>
;; URL: https://github.com/kyleam/org-link-edit
;; Keywords: convenience
;; Version: 0.1.0
;; Package-Requires: ((cl-lib "0.5") (org "8.2"))

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

;; Org Link Edit provides Paredit-inspired slurping and barfing
;; commands for Org link descriptions.
;;
;; There are four commands, all which operate when point is on an Org
;; link.
;;
;; - org-link-edit-forward-slurp-word
;; - org-link-edit-backward-slurp-word
;; - org-link-edit-forward-barf-word
;; - org-link-edit-backward-barf-word
;;
;; Org Link Edit doesn't bind these commands to any keys.  Finding
;; good keys for these commands is difficult because, while it's
;; convenient to be able to quickly repeat these commands, they won't
;; be used frequently enough to be worthy of a short, repeat-friendly
;; binding.  Using Hydra [1] provides a nice solution to this.  After
;; an initial key sequence, any of the commands will be repeatable
;; with a single key.  (Plus, you get a nice interface that reminds
;; you of the keys).  Below is one example of how you could configure
;; this.
;;
;;     (define-key org-mode-map YOUR-KEY
;;       (defhydra hydra-org-link-edit ()
;;         "Org Link Edit"
;;         ("j" org-link-edit-forward-slurp-word "forward slurp")
;;         ("k" org-link-edit-forward-barf-word "forward barf")
;;         ("u" org-link-edit-backward-slurp-word "backward slurp")
;;         ("i" org-link-edit-backward-barf-word "backward barf")
;;         ("q" nil "cancel")))
;;
;; [1] https://github.com/abo-abo/hydra

;;; Code:

(require 'org)
(require 'org-element)
(require 'cl-lib)

(defun org-link-edit--get-link-data ()
  "Return list with information about the link at point.
The list includes
- the position at the start of the link
- the position at the end of the link
- the link text
- the link description (nil when on a plain link)"
  (let ((el (org-element-context)))
    ;; Don't use `org-element-lineage' because it isn't available
    ;; until Org version 8.3.
    (while (and el (not (memq (car el) '(link))))
      (setq el (org-element-property :parent el)))
    (unless (eq (car el) 'link)
      (user-error "Point is not on a link"))
    (save-excursion
      (goto-char (org-element-property :begin el))
      (cond
       ;; Use match-{beginning,end} because match-end is consistently
       ;; positioned after ]], while the :end property is positioned
       ;; at the next word on the line, if one is present.
       ((looking-at org-bracket-link-regexp)
        (list (match-beginning 0)
              (match-end 0)
              (match-string-no-properties 1)
              (or (and (match-end 3)
                       (match-string-no-properties 3))
                  "")))
       ((looking-at org-plain-link-re)
        (list (match-beginning 0)
              (match-end 0)
              (match-string-no-properties 0)
              nil))
       (t
        (error "What am I looking at?"))))))

;;;###autoload
(defun org-link-edit-forward-slurp-word (&optional n)
  "Slurp N trailing words into link's description.

  The \[\[http://orgmode.org/\]\[Org mode\]\] site

                        |
                        v

  The \[\[http://orgmode.org/\]\[Org mode site\]\]

After slurping, return the slurped text and move point to the
beginning of the link.

If N is negative, slurp leading words instead of trailing words."
  (interactive "p")
  (setq n (or n 1))
  (cond
   ((= n 0))
   ((< n 0)
    (org-link-edit-backward-slurp-word (- n)))
   (t
    (cl-multiple-value-bind (beg end link desc) (org-link-edit--get-link-data)
      (goto-char (save-excursion
                   (goto-char end)
                   (or (forward-word n)
                       (user-error "Not enough words after the link"))
                   (point)))
      (let ((slurped (buffer-substring-no-properties end (point))))
        (setq slurped (replace-regexp-in-string "\n" " " slurped))
        (when (and (= (length desc) 0)
                   (string-match "^\\W*\\(\\w.*\\)" slurped))
          (setq slurped (match-string 1 slurped)))
        (setq desc (concat desc slurped)
              end (+ end (length slurped)))
        (delete-region beg (point))
        (insert (org-make-link-string link desc))
        (goto-char beg)
        slurped)))))

;;;###autoload
(defun org-link-edit-backward-slurp-word (&optional n)
  "Slurp N leading words into link's description.

  The \[\[http://orgmode.org/\]\[Org mode\]\] site

                        |
                        v

  \[\[http://orgmode.org/\]\[The Org mode\]\] site

After slurping, return the slurped text and move point to the
beginning of the link.

If N is negative, slurp trailing words instead of leading
words."
  (interactive "p")
  (setq n (or n 1))
  (cond
   ((= n 0))
   ((< n 0)
    (org-link-edit-forward-slurp-word (- n)))
   (t
    (cl-multiple-value-bind (beg end link desc) (org-link-edit--get-link-data)
      (goto-char (save-excursion
                   (goto-char beg)
                   (or (forward-word (- n))
                       (user-error "Not enough words before the link"))
                   (point)))
      (let ((slurped (buffer-substring-no-properties (point) beg)))
        (when (= (length desc) 0)
          (setq slurped (progn (string-match "\\(.*\\w\\)\\W*$" slurped)
                               (match-string 1 slurped))))
        (setq slurped (replace-regexp-in-string "\n" " " slurped))
        (setq desc (concat slurped desc)
              beg (- beg (length slurped)))
        (delete-region (point) end)
        (insert (org-make-link-string link desc))
        (goto-char beg)
        slurped)))))

(defun org-link-edit--split-first-words (string n)
  "Split STRING into (N first words . other) cons cell.
The N first word contains all text up to the next word.  If there
number of words in STRING is fewer than N, 'other' is nil."
  (when (< n 0) (user-error "N cannot be negative"))
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (let ((within-bound (forward-word n)))
      (skip-syntax-forward "^\w")
      (cons (buffer-substring 1 (point))
            (and within-bound
                 (buffer-substring (point) (point-max)))))))

(defun org-link-edit--split-last-words (string n)
  "Split STRING into (other . N last words) cons cell.
The N last words contains all leading text up to the previous
word.  If there number of words in STRING is fewer than N,
'other' is nil."
  (when (< n 0) (user-error "N cannot be negative"))
  (with-temp-buffer
    (insert string)
    (goto-char (point-max))
    (let ((within-bound (forward-word (- n))))
      (skip-syntax-backward "^\w")
      (cons (and within-bound
                 (buffer-substring 1 (point)))
            (buffer-substring (point) (point-max))))))

;;;###autoload
(defun org-link-edit-forward-barf-word (&optional n)
  "Barf N trailing words from link's description.

  The \[\[http://orgmode.org/\]\[Org mode\]\] site

                        |
                        v

  The \[\[http://orgmode.org/\]\[Org\]\] mode site

After barfing, return the barfed text and move point to the
beginning of the link.

If N is negative, barf leading words instead of trailing words."
  (interactive "p")
  (setq n (or n 1))
  (cond
   ((= n 0))
   ((< n 0)
    (org-link-edit-backward-barf-word (- n)))
   (t
    (cl-multiple-value-bind (beg end link desc) (org-link-edit--get-link-data)
      (when (= (length desc) 0)
        (user-error "Link has no description"))
      (pcase-let ((`(,new-desc . ,barfed) (org-link-edit--split-last-words
                                           desc n)))
        (unless new-desc (user-error "Not enough words in description"))
        (delete-region beg end)
        (insert (org-make-link-string link new-desc))
        (if (string= new-desc "")
            ;; Two brackets are dropped when a nil description is
            ;; passed to `org-make-link-string'.
            (progn (goto-char (- end (+ 2 (length desc))))
                   (setq barfed (concat " " barfed)))
          (goto-char (- end (- (length desc) (length new-desc)))))
        (insert barfed)
        (goto-char beg)
        barfed)))))

;;;###autoload
(defun org-link-edit-backward-barf-word (&optional n)
  "Barf N leading words from link's description.

  The \[\[http://orgmode.org/\]\[Org mode\]\] site

                        |
                        v

  The Org \[\[http://orgmode.org/\]\[mode\]\] site

After barfing, return the barfed text and move point to the
beginning of the link.

If N is negative, barf trailing words instead of leading words."
  (interactive "p")
  (setq n (or n 1))
  (cond
   ((= n 0))
   ((< n 0)
    (org-link-edit-forward-barf-word (- n)))
   (t
    (cl-multiple-value-bind (beg end link desc) (org-link-edit--get-link-data)
      (when (= (length desc) 0)
        (user-error "Link has no description"))
      (pcase-let ((`(,barfed . ,new-desc) (org-link-edit--split-first-words
                                           desc n)))
        (unless new-desc (user-error "Not enough words in description"))
        (delete-region beg end)
        (insert (org-make-link-string link new-desc))
        (when (string= new-desc "")
          (setq barfed (concat barfed " ")))
        (goto-char beg)
        (insert barfed)
        (goto-char (+ beg (length barfed)))
        barfed)))))

(provide 'org-link-edit)
;;; org-link-edit.el ends here
