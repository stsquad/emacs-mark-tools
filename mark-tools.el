;;; mark-tools.el --- Some simple tools to access the mark-ring in Emacs

;; Copyright (C) 2012, Alex Bennée

;; Author: Alex Bennee <alex@bennee.com>
;; Maintainer: Alex Bennee <alex@bennee.com>
;; Version: ?
;; Homepage: ?

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Some useful utilities for navigating the mark-ring

;;; Code:

;; un-comment to debug
(setq debug-on-error t)
(setq edebug-all-defs t)

(defvar mark-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "RET") 'mark-list-visit-buffer)
    (define-key map "\C-m" 'mark-list-visit-buffer)
    map)
  "Local keymap for `mark-list-mode-mode' buffers.")


(define-derived-mode mark-list-mode tabulated-list-mode "Mark List"
  "Major mode for listing the historical Mark List.
The Buffer Menu is invoked by the commands \\[list-marks].

Letters do not insert themselves; instead, they are commands.
\\<mark-list-mode-map>
\\{mark-list-mode-map}"
  (setq tabulated-list-format [("Buffer" 30 t)
	                       ("Pos" 6 nil)
			       ("Function" 30 t)])
  (setq tabulated-list-use-header-line 't)
  (setq tabulated-list-sort-key (cons "Buffer" nil))
  (add-hook 'tabulated-list-revert-hook 'mark-list--refresh nil t)
  (tabulated-list-init-header))

(defun list-marks (&optional arg)
  "Display the mark ring.
The list is displayed in a buffer named \"*Mark List*\".

By default it displays the global-mark-ring.
With prefix argument ARG, show local buffer mark-ring."
  (interactive "P")
  (let ((old-buffer (current-buffer))
	(marks (if arg
		   mark-ring
		 global-mark-ring))
	(buffer (get-buffer-create "*Mark List*")))

    (with-current-buffer buffer
      (mark-list-mode)
      (mark-list--refresh marks)
      (tabulated-list-print))
    (switch-to-buffer buffer))
    nil)

(defun mark-list--refresh (&optional marks)
  (let (entries)
    (dolist (mark marks)
      (when (and (markerp mark)
		 (marker-position mark))
	(message "processing mark: %s" mark)
	(let* ((buffer (marker-buffer mark))
	       (bufname (buffer-name buffer))
	       (bufpos (format "%d" (marker-position mark))))
	  (push (list mark (vector bufname bufpos "TODO: show nearest defun")) entries))))
    (setq tabulated-list-entries (nreverse entries)))
  (tabulated-list-init-header))

(defun mark-list-visit-buffer ()
  "Visit the mark in the mark-list buffer"
  (interactive)
  (let* ((mark (tabulated-list-get-id))
	 (entry (and mark (assq mark tabulated-list-entries)))
	 (buffer (marker-buffer mark))
	 (position (marker-position mark)))
    (set-buffer buffer)
    (or (and (>= position (point-min))
	     (<= position (point-max)))
	(if widen-automatically
	    (widen)
	  (error "Global mark position is outside accessible part of buffer")))
    (goto-char position)
    (switch-to-buffer buffer)))


