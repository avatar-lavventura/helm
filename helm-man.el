;;; helm-man.el --- Man and woman UI -*- lexical-binding: t -*-

;; Copyright (C) 2012 ~ 2015 Thierry Volpiatto <thierry.volpiatto@gmail.com>

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

(require 'cl-lib)
(require 'helm)

(defvar woman-topic-all-completions)
(defvar woman-manpath)
(defvar woman-path)
(defvar woman-expanded-directory-path)
(declare-function woman-file-name "woman.el" (topic &optional re-cache))
(declare-function woman-file-name-all-completions "woman.el" (topic))
(declare-function Man-getpage-in-background "man.el" (topic))
(declare-function woman-expand-directory-path "woman.el" (path-dirs path-regexps))
(declare-function woman-topic-all-completions "woman.el" (path))
(declare-function helm-generic-sort-fn "helm-utils.el" (S1 S2))

(defgroup helm-man nil
  "Man and Woman applications for helm."
  :group 'helm)

(defcustom helm-man-or-woman-function 'Man-getpage-in-background
  "Default command to display a man page."
  :group 'helm-man
  :type '(radio :tag "Preferred command to display a man page"
          (const :tag "Man" Man-getpage-in-background)
          (const :tag "Woman" woman)))

(defcustom helm-man-format-switches "-l %s"
  "Arguments to pass to the `manual-entry' function.
Arguments are passed to `manual-entry' with `format.'
Default use \"-l\" which may not be supported on old man versions,
in this case use \"%s\" as value to pass only the filename as argument.
See Issue #1035"
  :group 'helm-man
  :type 'string)

;; Internal
(defvar helm-man--pages nil
  "All man pages on system.
Will be calculated the first time you invoke helm with this
source.")

(defun helm-man-default-action (candidate)
  "Default action for jumping to a woman or man page from helm."
  (let ((wfiles (mapcar
                 'car (woman-file-name-all-completions candidate))))
    (condition-case nil
        (if (> (length wfiles) 1)
            (let ((file (helm-comp-read
                         "ManFile: " wfiles :must-match t)))
              (if (eq helm-man-or-woman-function 'Man-getpage-in-background)
                  (manual-entry (format helm-man-format-switches file))
                  (woman-find-file file)))
          (funcall helm-man-or-woman-function candidate))
      ;; If woman is unable to format correctly
      ;; use man instead.
      (error (kill-buffer)              ; Kill woman buffer.
             (Man-getpage-in-background candidate)))))

(defun helm-man--init ()
  (require 'woman)
  (require 'helm-utils)
  (unless helm-man--pages
    (setq woman-expanded-directory-path
          (woman-expand-directory-path woman-manpath woman-path))
    (setq woman-topic-all-completions
          (woman-topic-all-completions woman-expanded-directory-path))
    (setq helm-man--pages (mapcar 'car woman-topic-all-completions)))
  (helm-init-candidates-in-buffer 'global helm-man--pages))

(defvar helm-source-man-pages
  (helm-build-in-buffer-source "Manual Pages"
    :init #'helm-man--init 
    :persistent-action #'ignore
    :filtered-candidate-transformer
     (lambda (candidates _source)
       (sort candidates #'helm-generic-sort-fn))
    :action  '(("Display Man page" . helm-man-default-action))))

;;;###autoload
(defun helm-man-woman (arg)
  "Preconfigured `helm' for Man and Woman pages.
With a prefix arg reinitialize the cache."
  (interactive "P")
  (when arg (setq helm-man--pages nil))
    (helm :sources 'helm-source-man-pages
          :buffer "*Helm man woman*"))

(provide 'helm-man)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-man.el ends here
