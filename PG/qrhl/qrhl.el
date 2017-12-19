;(require ’proof-easy-config)

(defun qrhl-find-and-forget (span)
  (proof-generic-count-undos span))
  
(proof-easy-config 'qrhl "qRHL"
		   proof-prog-name "bin/qrhl"
		   proof-script-command-end-regexp "\\.[ \t]*$"
		   proof-shell-annotated-prompt-regexp "^\\(\\.\\.\\.\\|qrhl\\)> "
		   proof-script-comment-start-regexp "#"
		   proof-script-comment-end "\n"
		   proof-shell-error-regexp "\\[ERROR\\]\\|Exception"
		   proof-undo-n-times-cmd "undo %s."
		   proof-find-and-forget-fn 'qrhl-find-and-forget
		   proof-shell-start-goals-regexp "^[0-9]+ subgoals:\\|No current goal\\."
		   proof-shell-proof-completed-regexp "^No current goal.$"
		   proof-shell-eager-annotation-start "\\*\\*\\* "
		   proof-shell-eager-annotation-start-length 4
		   )

(add-hook 'qrhl-mode-hook
	  (lambda ()
	    (set-input-method "TeX")
	    (set-language-environment "UTF-8")
	    (set-variable 'indent-tabs-mode nil)
	    (set-variable 'electric-indent-mode nil)))

(defun qr () ; Just for testing
  "Restarts the prover, restarts it, and then processes the buffer to current position"
  (interactive)
  (proof-shell-exit t)
  (proof-goto-point))

  
    

(provide 'qrhl)


