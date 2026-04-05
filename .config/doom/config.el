(setq doom-theme 'doom-gruvbox
      doom-font (font-spec :family "Berkeley Mono" :size 30))

(setq user-full-name "McCoy R. Becker"
      user-mail-address "mccoyb@mit.edu")

(global-visual-line-mode t)

(setq display-line-numbers-type 'relative)

;; Code cells
(with-eval-after-load 'code-cells
  (let ((map code-cells-mode-map))
    (define-key map (kbd "M-p") 'code-cells-backward-cell)
    (define-key map (kbd "M-n") 'code-cells-forward-cell)
    (define-key map (kbd "M-<return>") 'code-cells-eval)
    ;; Overriding other minor mode bindings requires some insistence...
    (define-key map [remap jupyter-eval-line-or-region] 'code-cells-eval)))

(defun jupyter-eval-region-ab (beg end)
  (jupyter-eval-region nil beg end))
