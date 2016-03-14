;; .emacs

;; Load package repositories
(require 'package)
(add-to-list 'package-archives
    '("marmalade" . "http://marmalade-repo.org/package/") t)
(add-to-list 'package-archives
    '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

;; Emacs Speaks Statistics
(require 'ess-site)

;; Set color theme
(load-theme 'tango-dark)

;; Set font
(set-frame-font "Courier 10 Pitch-12" nil t)
(set-default-font "Courier 10 Pitch-12")
(defun fontify-frame (frame)
  (set-frame-parameter frame 'font "Courier 10 Pitch-12"))
;; Fontify current frame
(fontify-frame nil)
;; Fontify any future frames
(push 'fontify-frame after-make-frame-functions)

;; Use spaces instead of tab characters, and
;; use 4 spaces as default for tab.
(setq default-tab-width 4)
(setq-default indent-tabs-mode nil)

;; Make C mode use 4 spaces instead of 2.
(setq-default c-basic-offset 4)

;;;;;;;;;;;;;
;; Aliases ;;
;;;;;;;;;;;;;
(defalias 'yes-or-no-p 'y-or-n-p)
(defalias 'rb 'revert-buffer)
(defalias 'qr 'query-replace)

;;;;;;;;;;;
;; Modes ;;
;;;;;;;;;;;

;; Turn on font-lock mode
(when (fboundp 'global-font-lock-mode)
      (global-font-lock-mode t))

;; Turn on overwrite/selection delete mode.
(delete-selection-mode t)

;; Turn on standard line wrapping:
(global-visual-line-mode t)

;; Enable visual feedback on selections
;; (setq transient-mark-mode t))

;; Uncomment to disable loading of 'default.el' at startup.
;; (setq inhibit-default-init t)

;; Improved frame titles
(setq frame-title-format
      (concat "%b - emacs@" (system-name)))

;; Default to unified diffs
(setq diff-switches "-u")

;; Always end with a newline
;; (setq require-final-newline 'query)

;; Allow Ctl-n n to narrow on region.
(put 'narrow-to-region 'disabled nil)

;; Toggle horizontal or vertical split in 2-window layout.
(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
         (next-win-buffer (window-buffer (next-window)))
         (this-win-edges (window-edges (selected-window)))
         (next-win-edges (window-edges (next-window)))
         (this-win-2nd (not (and (<= (car this-win-edges)
                     (car next-win-edges))
                     (<= (cadr this-win-edges)
                     (cadr next-win-edges)))))
         (splitter
          (if (= (car this-win-edges)
             (car (window-edges (next-window))))
          'split-window-horizontally
        'split-window-vertically)))
    (delete-other-windows)
    (let ((first-win (selected-window)))
      (funcall splitter)
      (if this-win-2nd (other-window 1))
      (set-window-buffer (selected-window) this-win-buffer)
      (set-window-buffer (next-window) next-win-buffer)
      (select-window first-win)
      (if this-win-2nd (other-window 1))))))

;; Bind above function to "Ctrl-x 4 t" to toggle.
(define-key ctl-x-4-map "t" 'toggle-window-split)

;; Alter size of a window in 2-window mode, will make the in-focus
;; window extend to take up half of the other's lines.
(defun halve-other-window-height ()
  "Expand current window to use half of the other window's lines."
  (interactive)
  (enlarge-window (/ (window-height (next-window)) 2)))

;; Bind above function to C-c v
(global-set-key (kbd "C-c v") 'halve-other-window-height)

;; Custom function to perform C-l twice
;; bound to M-x home. Used the following to obtain it:
;; 1. define the kbd macro using C-x (, then C-l C-l, then C-x )
;; 2. name the most recent macro with C-x C-k n name. In this
;;        case name is "home".
;; 3. Produce code into the current buffer for the macro, with:
;;        M-x insert-kbd-macro <RET> name <RET>
(fset 'home
   (lambda (&optional arg) "Flush cursor to top of buffer screen." 
       (interactive "p") 
       (kmacro-exec-ring-item (quote ("" 0 "%d")) arg)))    

;; Swap buffers into different windows
(defun swap-buffer ()
  (interactive)
  (cond ((one-window-p) (display-buffer (other-buffer)))
        ((let* ((buffer-a (current-buffer))
                (window-b (cadr (window-list)))
                (buffer-b (window-buffer window-b)))
           (set-window-buffer window-b buffer-a)
           (switch-to-buffer buffer-b)))))
           ;; Use following to always swap into the primary window.
           ;;(other-window 1)))))

;; Bind the above function to Ctrl-x c
(global-set-key (kbd "C-x c") 'swap-buffer)
;;(define-key ctl-x-map "c" 'swap-buffer)

;; Set buffer console to always show current system name
;; and the whole file path of the buffer being edited.
(setq frame-title-format
      (list (format "%s %%S: %%j " (system-name))
        '(buffer-file-name "%f" (dired-directory dired-directory "%b"))))

;; Make a non-killing version of the rectangle copy, and
;; bind it to C-x r M-w
(defun my-copy-rectangle (start end)
   "Copy the region-rectangle instead of `kill-rectangle'."
   (interactive "r")
   (setq killed-rectangle (extract-rectangle start end))) 
(global-set-key (kbd "C-x r M-w") 'my-copy-rectangle)

;; Functions to list currently-open buffers in order by their size.
(defmacro with-buffer-set (b &rest args)
  (list 'save-excursion
        (list 'set-buffer b)
        (cons 'progn args)))

;; From Mark Weissman.
(defun list-sized-buffers ()
  (interactive)
  (let ((standard-output standard-output)
    (files-only nil)
    (old-buffer (current-buffer)))
    (with-buffer-set
     (get-buffer-create "*Buffers*")
     (setq buffer-read-only nil)
     (erase-buffer)
     (beginning-of-buffer)
     (insert " MR Buffer           Size  Mode         File\n")
     (insert " -- ------           ----  ----         ----\n")
     (setq standard-output (current-buffer))
     (dolist (buffer (mapcar 'cdr (sort
                   (mapcar '(lambda (b) 
                               (with-buffer-set b 
                                 (cons (point-max) (current-buffer))))
                       (buffer-list))
                   '(lambda (x y) (> (car x) (car y))))))
       (let ((name (buffer-name buffer))
         (file (buffer-file-name buffer))
         this-buffer-line-start
         this-buffer-read-only
         (this-buffer-size (buffer-size buffer))
         this-buffer-mode-name
         this-buffer-directory)
     (with-current-buffer buffer
       (setq this-buffer-read-only buffer-read-only
         this-buffer-mode-name mode-name)
       (unless file
         ;; No visited file.  Check local value of
         ;; list-buffers-directory.
         (when (and (boundp 'list-buffers-directory)
            list-buffers-directory)
           (setq this-buffer-directory list-buffers-directory))))
     (cond
      ;; Don't mention internal buffers.
      ((string= (substring name 0 1) " "))
      ;; Maybe don't mention buffers without files.
      ((and files-only (not file)))
      ((string= name "*Buffer List*"))
      ;; Otherwise output info.
      (t
       (setq this-buffer-line-start (point))
       ;; Identify current buffer.
       (if (eq buffer old-buffer)
           (progn
         (setq desired-point (point))
         (princ "."))
         (princ " "))
       ;; Identify modified buffers.
       (princ (if (buffer-modified-p buffer) "*" " "))
       ;; Handle readonly status.  The output buffer is special
       ;; cased to appear readonly; it is actually made so at a
       ;; later date.
       (princ (if (or (eq buffer standard-output)
              this-buffer-read-only)
              "% "
            "  "))
       (princ name)
       ;; Put the buffer name into a text property
       ;; so we don't have to extract it from the text.
       ;; This way we avoid problems with unusual buffer names.
       (setq this-buffer-line-start
         (+ this-buffer-line-start Buffer-menu-buffer-column))
       (let ((name-end (point)))
         (indent-to 17 2)
         (put-text-property this-buffer-line-start name-end
                'buffer-name name)
         (put-text-property this-buffer-line-start (point)
                'buffer buffer)
         (put-text-property this-buffer-line-start name-end
                'mouse-face 'highlight)
         (put-text-property this-buffer-line-start name-end
                'help-echo "mouse-2: select this buffer"))
       (let ((size (format "%8d" this-buffer-size))
         (mode this-buffer-mode-name)
         (excess (- (current-column) 17)))
         (while (and (> excess 0) (= (aref size 0) ?\ ))
           (setq size (substring size 1)
             excess (1- excess)))
         (princ size)
         (indent-to 27 1)
         (princ mode))
       (indent-to 40 1)
       (or file (setq file this-buffer-directory))
       (when file
         (princ (abbreviate-file-name file)))
       (princ "\n")))))
     (Buffer-menu-mode)
     (beginning-of-buffer)
     (display-buffer (current-buffer)))))
;; end of list-sized-buffers

;; Word and character count in highlighted region.
(defun count-words-region (posBegin posEnd)
  "Print number of words and chars in region."
  (interactive "r")
  (message "Counting: ")
  (save-excursion
    (let (wordCount charCount)
        (setq wordCount 0)
        (setq charCount (- posEnd posBegin))
        (goto-char posBegin)
        (while (and (< (point) posEnd)
                    (re-search-forward "\\w+\\W*" posEnd t))
          (setq wordCount (1 + wordCount)))

        (message "Words: %d. Chars: %d." wordCount charCount))))

;; Bind word count function to C-x M-c
(global-set-key (kbd "C-x M-c") 'count-words-region)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Modes handled by Custom. ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Variables set by saving options for menus/parentheses, etc.
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(show-paren-mode t)
 '(tool-bar-mode nil))
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
