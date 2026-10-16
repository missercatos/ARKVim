" Emacs Lisp：沿用 Vim 自带 Lisp 的词法/注释/缩进设置，
" 再补上 elisp 常用的缩进形式（lispwords）。
"
" 注意：Neovim 的文件类型插件加载器在 source ftplugin 前就已设好 b:did_ftplugin，
" 所以这里不能直接 `runtime! ftplugin/lisp.vim`（会被它的 guard 挡掉），只能照抄设置。

setlocal comments=:;;;;,:;;;,:;;,:;,sr:#\|,mb:\|,ex:\|#
setlocal define=^\s*(def\k*
setlocal formatoptions-=t
setlocal iskeyword+=+,-,*,/,%,<,=,>,:,$,?,!,@-@,94
setlocal autoindent nosmartindent
setlocal lisp
setlocal commentstring=;\ %s
setlocal lispwords+=defcustom,defgroup,defface,defalias,defsubst,define-minor-mode,define-derived-mode,define-generic-mode,defadvice,condition-case,condition-case-unless-debug,with-current-buffer,with-temp-buffer,with-temp-file,with-eval-after-load,save-excursion,save-restriction,save-current-buffer,save-window-excursion,save-selected-window,pcase,pcase-let,pcase-let*,let-alist,seq-let,cl-labels,cl-flet,cl-letf,cl-dolist,cl-dotimes,cl-loop,when-let,when-let*,if-let,if-let*
