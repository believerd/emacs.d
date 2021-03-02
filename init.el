(defvar best-gc-cons-threshold 4000000)
;; test more on the value!

;; Set gc-cons-thread to the best after emacs-startup.
(add-hook 'emacs-startup-hook(lambda () (setq gc-cons-threshold best-gc-cons-threshold)))
;; Good for now, check [[https:gitlab.com/koral/gcmh][gcmh]] someday.

;;; init.el -*- lexical-binding: t; -*-

;; Bootstrap use-package
(require 'package)
(setq package-archives '(("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
	        	 ("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
			 ("org"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/org/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Automatically tangle our config.org config file when we save it
(defun b/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
        (expand-file-name "~/.emacs.d/config.org"))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'b/org-babel-tangle-config)))

(setq backup-directory-alist (quote (("." . "~/.emacs.d/autobackups"))))

(global-auto-revert-mode 1)

(defun b/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                   (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'b/display-startup-time)

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)
(show-paren-mode 1)

(global-display-line-numbers-mode 1)
;; Disable line-numbers-mode for some cases
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                vterm-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Disable hl-mode for terminals
(dolist (mode '(term-mode-hook
                shell-mode-hook
                vterm-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (setq global-hl-line-mode nil))))
  
(column-number-mode 1)
(global-hl-line-mode t)
(make-variable-buffer-local 'global-hl-line-mode)
(set-fringe-mode 5)
(setq visible-bell t)
(setq inhibit-startup-message t)

(setq initial-scratch-message ";;Happy Hacking!\n\n")

(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-gruvbox t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  ;(doom-themes-neotree-config)
  ;; or for treemacs users
  ;(setq doom-themes-treemacs-theme "doom-colors") ; use the colorful treemacs theme
  ;(doom-themes-treemacs-config)
  
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(set-face-attribute 'default nil :font "Jetbrains Mono" :height 105)
;(set-face-attribute 'default nil :font "Fira Code Retina" :height 110)

(use-package evil
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)

  :config
  (evil-mode 1))
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package hydra)

(defhydra hydra-text-scale (:timeout 4)
  "scale-text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("q" nil "quit" :exit t))

(use-package general
  :config
  (general-create-definer b/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")
    
;; define my functions
(defun b/open-config-file ()
  "Quickly open config file"
  (interactive)
  (find-file (expand-file-name "~/.emacs.d/config.org")))

(b/leader-keys
  "t" '(:ignore t :which-key "toggles")
  "tt" '(counsel-load-theme :which-key "choose theme")
  "ts" '(hydra-text-scale/body :which-key "scale-text")
  "fc" '(b/open-config-file :which-key "config-file")))

(use-package which-key
  :init
  (which-key-mode)
  :config
  (setq which-key-idle-delay 0.3))

(use-package magit
  :bind
  ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package projectile
  :bind (:map projectile-mode-map
         ("C-c p" . projectile-command-map))
  :config
  (projectile-mode)
  :custom
  ((projectile-completion-system 'ivy))
  :init
  (when (file-directory-p "~/Sync/code")
    (setq projectile-project-search-path '("~/Sync/code")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package company
  :after lsp-mode
  :hook (lsp-mode . company-mode)
  :bind (:map company-active-map
         ("<tab>" . company-complete-selection))
        (:map lsp-mode-map
         ("<tab>" . company-indent-or-complete-common))
  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.0))

(use-package company-box
  :hook (company-mode . company-box-mode))

(use-package evil-nerd-commenter
  :bind ("M-;" . evilnc-comment-or-uncomment-lines))

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (python-mode . lsp-deferred)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp lsp-deferred)
;; optionally
(use-package lsp-ui :commands lsp-ui-mode)
;; if you are ivy user
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
(use-package lsp-treemacs :commands lsp-treemacs-errors-list)

(use-package dap-mode)

(use-package term
  :config
  (setq explicit-shell-file-name "/usr/bin/zsh"))
  
(use-package eterm-256color
  :hook (term-mode . eterm-256color-mode))

(use-package vterm
  :config (setq vterm-max-scrollback 10000))

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer))

(use-package dired-single
  :commands (dired dired-jump))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package dired-open
  ;; :commands (dired dired-jump)
  :config
  ;; Doesn't work as expected!
  ;;(add-to-list 'dired-open-functions #'dired-open-xdg t)
  (setq dired-open-extensions '(("png" . "feh")
                                ("mkv" . "mpv"))))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

(defun b/org-mode-setup()
  (org-indent-mode)
  (visual-line-mode 1))

(use-package org
  :hook (org-mode . b/org-mode-setup)
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture))
  :config
  (setq org-directory "~/Sync/org/")
  (setq org-agenda-files
    '("~/Sync/org/tasks.org"
	  "~/Sync/org/birthdays.org"))

  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-ellipsis " ▾")
  
  (setq org-refile-targets
    '(("archive.org" :maxlevel . 1)))
  (advice-add 'org-refile :after 'org-save-all-org-buffers)

  (setq org-capture-templates
       `(("i" "Inbox" entry  (file "tasks.org")
        ,(concat "* TODO %?\n"
                 "/Entered on/ %U")))))


(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode))
  
;;Use "<el" <Tab> to quickly expand a org elisp src block
(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))

;;Load org babel languages
(with-eval-after-load 'org
  (org-babel-do-load-languages
    'org-babel-load-languages
    '((emacs-lisp . t)
     (python . t))))

;; (use-package org-roam
;;   :hook
;;   (after-init . org-roam-mode)
;;   :custom
;;   (org-roam-directory "~/Sync/org")
;;   :bind (:map org-roam-mode-map
;;           (("C-c n l" . org-roam)
;;            ("C-c n f" . org-roam-find-file)
;;            ("C-c n g" . org-roam-graph-show))
;;           :map org-mode-map
;;           (("C-c n i" . org-roam-insert))
;;           (("C-c n I" . org-roam-insert-immediate))))

(use-package org-pomodoro)

(use-package ox-hugo
  :after ox)

(use-package try)

(use-package pyim
  :demand t
  :config
  ;; 激活 basedict 拼音词库，五笔用户请继续阅读 README
  (use-package pyim-basedict
    :ensure nil
    :config (pyim-basedict-enable))

  (setq default-input-method "pyim")

  ;; 我使用全拼
  (setq pyim-default-scheme 'quanpin)

  ;; 设置 pyim 探针设置，这是 pyim 高级功能设置，可以实现 *无痛* 中英文切换 :-)
  ;; 我自己使用的中英文动态切换规则是：
  ;; 1. 光标只有在注释里面时，才可以输入中文。
  ;; 2. 光标前是汉字字符时，才能输入中文。
  ;; 3. 使用 M-j 快捷键，强制将光标前的拼音字符串转换为中文。
;  (setq-default pyim-english-input-switch-functions
;                '(pyim-probe-dynamic-english
;                  pyim-probe-isearch-mode
;                  pyim-probe-program-mode
;                  pyim-probe-org-structure-template))

  (setq-default pyim-punctuation-half-width-functions
                '(pyim-probe-punctuation-line-beginning
                  pyim-probe-punctuation-after-punctuation))

  ;; 开启拼音搜索功能
  (pyim-isearch-mode 1)

  ;; 使用 popup-el 来绘制选词框, 如果用 emacs26, 建议设置
  ;; 为 'posframe, 速度很快并且菜单不会变形，不过需要用户
  ;; 手动安装 posframe 包。
  (setq pyim-page-tooltip 'popup)

  ;; 选词框显示5个候选词
  (setq pyim-page-length 5)

  :bind
  (("M-j" . pyim-convert-string-at-point) ;与 pyim-probe-dynamic-english 配合
   ("C-;" . pyim-delete-word-from-personal-buffer)))

(use-package dashboard
  :diminish (dashboard-mode)
  :init
  (setq dashboard-center-content nil
        dashboard-banner-logo-title "Happy Hacking! Beliver!"
        dashboard-show-shortcuts nil
        dashboard-items '((recents  . 10)
                          (agenda . 10)
                          (bookmarks . 5)
                          (projects . 5)))
  :config
  (dashboard-setup-startup-hook))

(use-package counsel
  :init
  (ivy-mode 1)
  :config
  ;(setq ivy-initial-inputs-alist nil) ;;Do not start search with ^
  :bind (("C-s" . swiper-isearch)
         ("M-x" . counsel-M-x)
         ("C-x C-f" . counsel-find-file)
         ("M-y" . counsel-yank-pop)
         ("C-x b" . ivy-switch-buffer)
         ("C-h b" . counsel-descbinds)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-minibuffer-map
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)))
         
(use-package ivy-rich
  :after ivy
  :init
  (ivy-rich-mode 1))

(use-package flycheck
  :init (global-flycheck-mode))

(use-package nyan-mode
  :config
  (nyan-mode))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package auto-package-update
  :custom
  (auto-package-update-interval 14)
  (auto-package-update-prompt-before-update t)
  (auto-package-update-hide-results t)
  :config
  (auto-package-update-maybe)
  (auto-package-update-at-time "19:00")
  :hook (auto-package-update-before-hook . (lambda () (message "Updating packages!"))))

(use-package youdao-dictionary
  :defer t
  :bind ("C-c d" . youdao-dictionary-search-from-input)
  :config
  (evil-collection-define-key 'normal 'youdao-dictionary-mode-map
  "q" 'kill-buffer-and-window)
  :custom
  (setq url-automatic-caching t))
