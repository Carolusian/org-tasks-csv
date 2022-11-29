;;; org-tasks-csv.el --- Export `org-mode' task entries to CSV format.

;; Copyright (C) 2022 Carolusian

;; Author: carolusian
;; URL: https://github.com/carolusian/org-tasks-csv
;; Keywords: calendar, data, org, tasks
;; Version: 0.1
;; Package-Requires: ((org "8.3") (org-clock-csv "1.2"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package makes use of the `org-element' API and the 'org-clock-csv' package 
;; to extract task headline entries from org files and convert them into CSV format. 
;; It is intended to facilitate clocked time and schedule time analysis in external 
;; programs.

;; In interactive mode, calling `org-tasks-csv' will open a buffer
;; with the parsed entries from the files in `org-agenda-files', while
;; `org-tasks-csv-to-file' will write this output to a file. Both
;; functions take a prefix argument to read entries from the current
;; buffer instead.

;; Finally, thanks to Aaron Jacobs, the author of `org-clock-csv`. This package 
;; heavily borrows the ideas and reference code from `org-clock-csv` and is intended 
;; to be used together with the CSV files generated from `org-clock-csv`, e.g. you can
;; join the files generated from `org-tasks-csv-to-file` and `org-clock-csv-to-file` 
;; to assess the difference between your planned/scheduled duration and the clock-in/clock-out
;; time duration.

;;; Code:

(require 'org-clock-csv)

(eval-when-compile
  (require 'cl-lib))

(defcustom org-tasks-csv-header "task,parents,level,priority,todo,status,scheduled_start,scheduled_end,deadline_start,deadline_end,closed,tags"
  "Header for the CSV output.
Be sure to keep this in sync with changes to
`org-tasks-csv-row-fmt'."
  :group 'org-tasks-csv)

(defun org-tasks-csv--format-start (timestamp)
  (cond ((org-element-property :hour-start timestamp)
         (format "%s-%s-%s %s:%s:00"
                 (org-element-property :year-start timestamp)
                 (org-clock-csv--pad
                  (org-element-property :month-start timestamp))
                 (org-clock-csv--pad
                  (org-element-property :day-start timestamp))
                 (org-clock-csv--pad
                  (org-element-property :hour-start timestamp))
                 (org-clock-csv--pad
                  (org-element-property :minute-start timestamp))))
        ((org-element-property :year-start timestamp)
         (format "%s-%s-%s"
                 (org-element-property :year-start timestamp)
                 (org-clock-csv--pad
                  (org-element-property :month-start timestamp))
                 (org-clock-csv--pad
                  (org-element-property :day-start timestamp))))
        ))

(defun org-tasks-csv--format-end (timestamp)
  (cond ((org-element-property :hour-end timestamp)
         (format "%s-%s-%s %s:%s:00"
                 (org-element-property :year-end timestamp)
                 (org-clock-csv--pad
                  (org-element-property :month-end timestamp))
                 (org-clock-csv--pad
                  (org-element-property :day-end timestamp))
                 (org-clock-csv--pad
                  (org-element-property :hour-end timestamp))
                 (org-clock-csv--pad
                  (org-element-property :minute-end timestamp))))
        ((org-element-property :year-end timestamp)
         (format "%s-%s-%s"
                 (org-element-property :year-end timestamp)
                 (org-clock-csv--pad
                  (org-element-property :month-end timestamp))
                 (org-clock-csv--pad
                  (org-element-property :day-end timestamp))))
        ))


(defun org-tasks-csv--parse-element (element title default-category)
  "Ingest headline ELEMENT of tasks and produces a plist of its relevant
properties."
  (when (org-element-property :todo-keyword element)
    (let* ((task (org-element-property :raw-value element))
           (headlines (org-clock-csv--find-headlines element))
           (headlines-values (mapcar (lambda (h) (org-element-property :raw-value h)) headlines ))
           (parents (car headlines-values))
           (level (org-element-property :level element))
           (priority (org-element-property :priority element))
           (tags (mapconcat #'identity
                            (org-element-property :tags element) ":"))
           (todo-keyword (org-element-property :todo-keyword element))
           (todo-status (org-element-property :todo-type element))
           (scheduled (org-element-property :scheduled element))
           (deadline (org-element-property :deadline element))
           (closed (org-element-property :closed element))
           (scheduled-start (org-tasks-csv--format-start scheduled))
           (scheduled-end (org-tasks-csv--format-end scheduled))
           (deadline-start (org-tasks-csv--format-start deadline))
           (deadline-end (org-tasks-csv--format-end deadline))
           (closed-time (org-tasks-csv--format-start closed)))
      (list :task task
            :parents parents
            :level level
            :priority priority
            :tags tags
            :todo todo-keyword
            :status todo-status
            :scheduled_start scheduled-start
            :scheduled_end scheduled-start
            :deadline_start deadline-start
            :deadline_end deadline-end
            :closed closed-time))))


(defun org-tasks-csv--get-entries (filelist)
  "Retrieves headline entries from files in FILELIST."
  (cl-loop for file in filelist append
           (with-current-buffer (find-file-noselect file)
             (let* ((ast (org-element-parse-buffer))
                    (title (org-clock-csv--get-org-data 'TITLE ast file))
                    (category (org-clock-csv--get-org-data 'CATEGORY ast "")))
               (org-element-map ast 'headline
                 (lambda (c) (org-tasks-csv--parse-element c title category)))))))


(defun org-tasks-csv-row-fmt (plist)
  "Default row formatting function."
  (mapconcat #'identity
             (list (org-clock-csv--escape (plist-get plist ':task))
                   (if (plist-get plist ':parents) (org-clock-csv--escape (plist-get plist ':parents)))
                   (if (plist-get plist ':level) (number-to-string (plist-get plist ':level)))
                   (if (plist-get plist ':priority) (number-to-string (plist-get plist ':priority)))
                   (plist-get plist ':todo)
                   (symbol-name (plist-get plist ':status))
                   (plist-get plist ':scheduled_start)
                   (plist-get plist ':scheduled_end)
                   (plist-get plist ':deadline_start)
                   (plist-get plist ':deadline_end)
                   (plist-get plist ':closed)
                   (plist-get plist ':tags))
             ","))


;;;###autoload
(defun org-tasks-csv (&optional infile no-switch use-current)
  "Export task entries from INFILE to CSV format.
When INFILE is a filename or list of filenames, export clock
entries from these files. Otherwise, use `org-agenda-files'.
When NO-SWITCH is non-nil, do not call `switch-to-buffer' on the
rendered CSV output, simply return the buffer.
USE-CURRENT takes the value of the prefix argument. When non-nil,
use the current buffer for INFILE."
  (interactive "i\ni\nP")
  (when use-current
    (unless (equal major-mode 'org-mode)
      (user-error "Not in an org buffer")))
  (let* ((infile (if (and use-current buffer-file-name)
                     (list buffer-file-name)
                   infile))
         (filelist (if (null infile) (org-agenda-files)
                     (if (listp infile) infile (list infile))))
         (buffer (get-buffer-create "*task-entries-csv*"))
         (entries (org-tasks-csv--get-entries filelist)))
    (with-current-buffer buffer
      (goto-char 0)
      (erase-buffer)
      (insert org-tasks-csv-header "\n")
      (mapc (lambda (entry)
              (insert (concat (org-tasks-csv-row-fmt entry) "\n")))
            entries))
    (if no-switch buffer
      (switch-to-buffer buffer))))


;;;###autoload
(defun org-tasks-csv-to-file (outfile &optional infile use-current)
  "Write task entries from INFILE to OUTFILE in CSV format.
See `org-tasks-csv' for additional details."
  (interactive "FFile: \ni\nP")
  (let ((buffer (org-tasks-csv infile 'no-switch use-current)))
    (with-current-buffer buffer
      (write-region nil nil outfile nil nil))
    (kill-buffer buffer)))


(provide 'org-tasks-csv)

;; Local Variables:
;; coding: utf-8
;; End:

;;; org-tasks-csv.el ends here
