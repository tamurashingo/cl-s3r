(defpackage #:cl-s3r.sample.dialog
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function)
  (:import-from #:cl-s3r.components.dialog
                #:dialog))

(in-package #:cl-s3r.sample.dialog)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:meta (@ (name "viewport") (content "width=device-width, initial-scale=1")))
       (:title "cl-s3r Dialog")
       (:style "body{font-family:sans-serif;max-width:800px;margin:40px auto;padding:0 20px;}"
               "h1{color:#333;}"
               "h2{color:#555;margin-top:2em;}"
               "section{margin-bottom:3em;border-bottom:1px solid #eee;padding-bottom:2em;}"))
     (:body ,children)))

(configure-default-layout 'app-layout)

;;; --- alert-style dialog (single ok button) ---

(define-component alert-dialog-demo (&key &allow-other-keys)
  (let-component-state ((dialog-open nil))
    (let-function
        ((open-dialog  () (setf dialog-open t))
         (handle-close () (setf dialog-open nil)))
      `(:section
         (:h2 "Alert dialog")
         (:p "A simple alert-style dialog with a single ok button.")
         (:button (@ (onclick (open-dialog))) "Open alert dialog")
         ,@(when dialog-open
             `((dialog
                 (dialog-title "dialog")
                 (dialog-content
                   (:h1 "dialog")
                   (:p "This is an alert-style dialog."))
                 (dialog-actions
                   (dialog-action (@ (onclick (handle-close)))
                     "ok")))))))))

;;; --- confirm-style dialog (yes / no buttons) ---

(define-component confirm-dialog-demo (&key &allow-other-keys)
  (let-component-state ((dialog-open nil)
                        (last-answer ""))
    (let-function
        ((open-dialog () (setf dialog-open t))
         (handle-yes  () (setf dialog-open nil) (setf last-answer "yes"))
         (handle-no   () (setf dialog-open nil) (setf last-answer "no")))
      `(:section
         (:h2 "Confirm dialog")
         (:p "A confirm-style dialog with yes and no action buttons.")
         (:button (@ (onclick (open-dialog))) "Open confirm dialog")
         ,@(when (not (string= last-answer ""))
             `((:p "Last answer: " ,last-answer)))
         ,@(when dialog-open
             `((dialog
                 (dialog-title "dialog")
                 (dialog-content
                   (:h1 "dialog")
                   (:p "This is a yes / no confirm dialog."))
                 (dialog-actions
                   (dialog-action (@ (onclick (handle-yes))) "yes")
                   (dialog-action (@ (onclick (handle-no)))  "no")))))))))

;;; --- input dialog ---

(define-component input-dialog-demo (&key &allow-other-keys)
  (let-component-state ((dialog-open nil)
                        (entered-name ""))
    (let-function
        ((open-dialog   () (setf dialog-open t))
         (handle-ok     (form-data)
           (let ((name (getf form-data :|name-input|)))
             (setf dialog-open nil)
             (when (and name (not (string= name "")))
               (setf entered-name name))))
         (handle-cancel () (setf dialog-open nil)))
      `(:section
         (:h2 "Input dialog")
         (:p "A dialog with a text input field.")
         (:button (@ (onclick (open-dialog))) "Open input dialog")
         ,@(when (not (string= entered-name ""))
             `((:p "Entered name: " ,entered-name)))
         ,@(when dialog-open
             `((dialog
                 (dialog-title "input your name")
                 (dialog-content
                   (:form (@ (id "name-form") (onsubmit (handle-ok)))
                     (:input (@ (type "text") (name "name-input")
                                (placeholder "your name")
                                (style "padding:6px 10px;border:1px solid #ccc;border-radius:4px;width:100%;box-sizing:border-box;")))))
                 (dialog-actions
                   (dialog-action (@ (type "submit") (form "name-form")) "ok")
                   (dialog-action (@ (onclick (handle-cancel))) "cancel")))))))))

;;; --- root page ---

(define-component dialog-page (&key &allow-other-keys)
  `(:div
     (:h1 "Dialog Component Examples")
     (alert-dialog-demo)
     (confirm-dialog-demo)
     (input-dialog-demo)))

(configure-route :path "/"
                 :component "dialog-page"
                 :props '())
