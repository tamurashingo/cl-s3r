(defpackage #:cl-s3r.components.dialog
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component)
  (:export #:dialog
           #:find-dsl-child
           #:parse-dialog-actions))

(in-package #:cl-s3r.components.dialog)

(defvar *dialog-css*
  (concatenate 'string
               ".cl-s3r-dialog-overlay{"
               "position:fixed;"
               "inset:0;"
               "background:var(--dialog-overlay-bg,rgba(0,0,0,0.5));"
               "display:flex;"
               "align-items:center;"
               "justify-content:center;"
               "z-index:1000;}"
               ".cl-s3r-dialog-box{"
               "background:#fff;"
               "border-radius:4px;"
               "box-shadow:0 4px 24px rgba(0,0,0,0.18);"
               "min-width:320px;"
               "max-width:560px;"
               "width:100%;"
               "display:flex;"
               "flex-direction:column;"
               "overflow:hidden;}"
               ".cl-s3r-dialog-header{"
               "padding:16px 24px;"
               "font-size:18px;"
               "font-weight:600;"
               "border-bottom:1px solid #e0e0e0;}"
               ".cl-s3r-dialog-main{"
               "padding:16px 24px;"
               "flex:1;}"
               ".cl-s3r-dialog-footer{"
               "padding:12px 24px;"
               "display:flex;"
               "justify-content:flex-end;"
               "gap:8px;"
               "border-top:1px solid #e0e0e0;}"
               ".cl-s3r-dialog-action{"
               "padding:6px 18px;"
               "border:1px solid #1976d2;"
               "border-radius:4px;"
               "background:#1976d2;"
               "color:#fff;"
               "font-size:14px;"
               "font-weight:500;"
               "cursor:pointer;}"
               ".cl-s3r-dialog-action:hover{"
               "background:#1565c0;}"))

(defun find-dsl-child (tag-name items)
  "Return the body forms of the first child S-expression whose car string-equals TAG-NAME."
  (let ((found (find tag-name items
                     :test (lambda (name item)
                             (and (listp item)
                                  (symbolp (car item))
                                  (string-equal (string (car item)) name))))))
    (when found
      (cdr found))))

(defun parse-dialog-actions (action-items)
  "Parse items inside a dialog-actions block into a list of plists.
Each (dialog-action (@ (onclick ...) ...) content...) becomes
  (:attrs ((onclick ...) ...) :body (content...)).
Signals an error if ACTION-ITEMS is nil or contains no dialog-action forms."
  (let ((actions
         (loop for item in action-items
               when (and (listp item)
                         (symbolp (car item))
                         (string-equal (string (car item)) "dialog-action"))
               collect
               (let* ((rest      (cdr item))
                      (has-attrs (and rest
                                      (listp (car rest))
                                      (symbolp (caar rest))
                                      (string= (string (caar rest)) "@")))
                      (attrs     (when has-attrs (cdar rest)))
                      (body      (if has-attrs (cdr rest) rest)))
                 (list :attrs attrs :body body)))))
    (when (null actions)
      (error "dialog: dialog-actions must contain at least one dialog-action form"))
    actions))

(define-component dialog (&key children &allow-other-keys)
  (let* ((title-forms   (find-dsl-child "dialog-title"   children))
         (content-forms (find-dsl-child "dialog-content" children))
         (actions-items (find-dsl-child "dialog-actions" children))
         (actions       (parse-dialog-actions actions-items)))
    `(:div (@ (class "cl-s3r-dialog-overlay"))
       (:style ,*dialog-css*)
       (:div (@ (class "cl-s3r-dialog-box"))
         (:header (@ (class "cl-s3r-dialog-header"))
           (:span ,@(if (listp title-forms) title-forms (list title-forms))))
         (:main (@ (class "cl-s3r-dialog-main"))
           ,@(or content-forms '()))
         (:footer (@ (class "cl-s3r-dialog-footer"))
           ,@(mapcar
               (lambda (action)
                 (let ((attrs (getf action :attrs))
                       (body  (getf action :body)))
                   `(:button (@ (class "cl-s3r-dialog-action")
                                ,@attrs)
                      ,@body)))
               actions))))))
