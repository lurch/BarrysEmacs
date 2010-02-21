;
; EMACSPROF.ML for EMACS V7.1
;
; This file sets up the default EMACS environment for user who work in an
; uncustomized environment.
; 
; The default key bindings are loaded from EMACS_DEFAULT_KEYBINDINGS and the
; default autoloads are loaded from EMACS_DEFAULT_AUTOLOADS. Both of these
; files are loaded after the MLisp-library database search list is set up so
; users can have their own key bindings
; 
(setq error-messages-buffer "Startup Error Messages")
(defun
    (~emacs-profile-clear-error-buffer
	(if (!= error-messages-buffer "")
	    (save-window-excursion
		
		(switch-to-buffer error-messages-buffer)
		(erase-buffer)
		(setq highlight-region 1)
		(setq syntax-colouring 1)
	    )
	)
    )
)
(defun
    ~emacs-profile-log-to-error-buffer(~message)
    (if (!= error-messages-buffer "")
	(save-window-excursion
	    (switch-to-buffer error-messages-buffer)
	    (end-of-file)
	    (insert-string
		~message "\n" 
		(string-extract "-------------------------------------------" 0 (length ~message)) "\n"
	    )
	)
    )
)
(~emacs-profile-log-to-error-buffer "Running emacs_profile")

(message "Emacs is initialising...") (sit-for 0)

(setq swap-ctrl-x-char '^x')		; disable swapping

(declare-global library-access vms-mail-hook)
(declare-buffer-specific logical-tab-size)
(declare-buffer-specific tab-indents-region)
(declare-buffer-specific tab-insert-spaces)

;
; Fill in the MLisp-library database
;
(if
    (error-occurred
	(setq
	    library-access
	    (getenv "EMACS_LIBRARY_ACCESS")
	)
    )
    (setq library-access 0)
)
(error-occurred
    (extend-database-search-list 
	"MLisp-library"
	"emacs_library:emacslib"
	(if (= operating-system-name "VMS") library_access 3)
    )
)
(error-occurred
    (extend-database-search-list
	"describe"
	"emacs_library:emacsdesc"
	(if (= operating-system-name "VMS") library_access 3)
    )
)
;
; Load up the EMACS default keys and autoloads
;
(execute-mlisp-file "emacs_control_strings")
(execute-mlisp-file "emacs_default_autoloads")
(execute-mlisp-file "emacs_default_keybindings")

; 
; setup to load the user interface
; this hook is executed after the
; 
(defun
    (~load-emacs_default_user_interface
	(execute-mlisp-file "emacs_default_user_interface")
    )
)
(setq user-interface-hook "~load-emacs_default_user_interface")
;
; Define the enter-emacs function which loads in a user's
; initialization file
;
(defun
    (enter-emacs-function
	(error-occurred
	    (setq
		library-access
		(getenv "EMACS_LIBRARY_ACCESS")
	    )
	)
	(error-occurred
	    (extend-database-search-list
		"MLisp-library"
		"sys$login:emacslib"
		(if (= operating-system-name "VMS") library_access 3)
	    )
	)
	(error-occurred
	    (extend-database-search-list
		"describe"
		"sys$login:emacsdesc"
		(if (= operating-system-name "VMS") library_access 3)
	    )
	)
	; 
	; any errors that occur during startup will be saved
	; in the buffer "Startup Error Messages"
	; 
	(setq error-messages-buffer "Startup Error Messages")
	(setq stack-trace-on-error 1)
	(~emacs-profile-clear-error-buffer)
	(~emacs-profile-log-to-error-buffer "Loading emacsinit")

	(if
	    (error-occurred
		(if (file-exists "sys$login:emacsinit.ml")
		    (execute-mlisp-file "sys$login:emacsinit.ml")
		    (execute-mlisp-file "emacsinit")
		)
		(if (= enter-emacs-hook "enter-emacs-function")
		    (setq enter-emacs-hook "")
		    (execute-mlisp-line (concat "(" enter-emacs-hook ")"))
		)
	    )
	    (progn ~msg
		(setq ~msg error-message)
		(switch-to-buffer "Startup Error Messages")
		(setq error-messages-buffer "")

		; highlight the error that started this all off
		(end-of-file)
		(set-mark)
		(error-occurred (search-reverse ~msg))
		(beginning-of-line)

		(save-excursion
		    (switch-to-buffer "Stack Trace")
		)

		(get-tty-string "Emacs detected an error while starting. Press enter to continue: ")
	    )
	    (if (= error-messages-buffer "Startup Error Messages")
		(progn
		    (setq error-messages-buffer "")
		    (error-occurred (delete-buffer "Startup Error Messages"))
		)
	    )
	)
	(setq stack-trace-on-error 0)
	(message " ")
	(novalue)
    )
)

;
; initialize some variables
;

(setq vms-mail-hook "text-mode")
(setq-default logical-tab-size 8)
(setq-default tab-indents-region 1)
(setq enter-emacs-hook "enter-emacs-function")
(if (= operating-system-name "Windows")
    (setq backup-filename-format "%pa%fn._%1ft")
    (setq backup-filename-format "%pa%fn%ft~")
)
(novalue)
