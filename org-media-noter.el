;;; org-media-noter.el --- Take Video and audio notes compatible with org-roam  -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2023 Sébastien Le Maguer

;; Author: Sébastien Le Maguer <lemagues@tcd.ie>
;; URL: https://github.com/seblemaguer/org-media-noter
;; Package-Requires: ((emacs "27.1") (mpv "0.1.0") (pretty-hydra "0.2.2") (org-media-note "1.7.0"))
;; Version: 0.1
;; Keywords: mpv, org, notes, org-roam, convenience
;; Homepage:

;;; Commentary:

;; Take notes for video and audio files compatible with org-roam.
;; This is an extension of org-media-note which brings some ideas of org-noter.

;;; License:

;; org-media-noter is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; org-media-noter is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with org-media-noter.  If not, see http://www.gnu.org/licenses.



;;; Code:
;;;; Requirements

(require 'cl-lib)
(require 'mpv)
(require 'org-media-note)


;;;; Customize variables
(defgroup org-media-noter nil
  "A synchronized, external annotator for media based on mpv"
  :group 'convenience
  :version "25.3.1")

(defcustom org-media-noter-property-doc-file "MEDIA_NOTER_FILE"
  "Name of the property that specifies the media file."
  :group 'org-media-noter
  :type 'string)

(defcustom org-media-noter-property-note-timestamp "MEDIA_NOTER_TIMESTAMP"
  "Name of the property that specifies the location of the current note."
  :group 'org-media-noter
  :type 'string)

(defcustom org-media-noter-default-heading-title "Notes for current timestamp"
  "The default title for headings created with `org-media-noter-insert-note'."
  :group 'org-media-noter
  :type 'string)

(defcustom org-media-noter-suggest-from-attachments t
  "When non-nil, org-media-noter will suggest files from the attachments
when creating a session, if the document is missing."
  :group 'org-media-noter
  :type 'boolean)

;;;; Internals
(defsubst org-media-noter--check-doc-prop (doc-prop)
  (and doc-prop (not (file-directory-p doc-prop)) (file-readable-p doc-prop)))

(defun org-media-noter--get-or-read-document-property (inherit-prop &optional force-new)
  (let ((doc-prop (and (not force-new) (org-entry-get nil org-media-noter-property-doc-file inherit-prop))))
    (unless (org-media-noter--check-doc-prop doc-prop)
      (setq doc-prop nil)

      (when org-media-noter-suggest-from-attachments
        (require 'org-attach)
        (let* ((attach-dir (org-attach-dir))
               (attach-list (and attach-dir (org-attach-file-list attach-dir))))
          (when (and attach-list (y-or-n-p "Do you want to annotate an attached file?"))
            (setq doc-prop (completing-read "File to annotate: " attach-list nil t))
            (when doc-prop (setq doc-prop (file-relative-name (expand-file-name doc-prop attach-dir)))))))

      (unless (org-media-noter--check-doc-prop doc-prop)
        (setq doc-prop (expand-file-name
                        (read-file-name
                         "Invalid or no document property found. Please specify a document path: " nil nil t)))
        (when (or (file-directory-p doc-prop) (not (file-readable-p doc-prop))) (user-error "Invalid file path"))
        (when (y-or-n-p "Do you want a relative file name? ") (setq doc-prop (file-relative-name doc-prop))))

      (org-entry-put nil org-media-noter-property-doc-file doc-prop))
    doc-prop))


;;;; Commands
(defun org-media-noter-insert-note ()
  "Insert note associated with the current location."
  (interactive)
  (let* ((note-title (read-from-minibuffer "Note: ")))
    (org-insert-heading nil t)
    (insert (org-trim (replace-regexp-in-string "\n" " " note-title)))
    (org-entry-put nil
                   org-media-noter-property-note-timestamp
                   (format "%s "
                           (org-media-note--get-current-timestamp)))
    (when org-media-note-pause-after-insert-link
      (mpv-pause))))

(defun org-media-noter-seek ()
  (interactive)
  (let* ((cur-timestamp (org-entry-get nil org-media-noter-property-note-timestamp nil)))
    (when cur-timestamp
      (org-media-note--seek-position-in-current-media-file cur-timestamp))))


;;;###autoload
(defun org-media-noter ()
  (interactive)
  (when (org-before-first-heading-p)
    (user-error "`org-media-noter' must be issued inside a heading"))

  (let* ((media-path (org-media-noter--get-or-read-document-property t nil))
         (start-timestamp (org-entry-get nil org-media-noter-property-note-timestamp nil)))
    (if start-timestamp
        (mpv-start (expand-file-name media-path) (concat "--start=+" start-timestamp))
      (mpv-play media-path))))

(provide 'org-media-noter)
;;; org-media-noter.el ends here
