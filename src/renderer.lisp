(defpackage #:cl-s3r.renderer
  (:use #:cl)
  (:import-from #:alexandria
                #:starts-with-subseq)
  (:export #:render-html
           #:*component-expander*))

(in-package #:cl-s3r.renderer)

(defvar *component-expander* nil)

(defun escape-html (str)
  "Perform minimal HTML escaping."
  (typecase str
    (string
     (with-output-to-string (out)
       (loop for c across str do
         (case c
           (#\< (write-string "&lt;" out))
           (#\> (write-string "&gt;" out))
           (#\& (write-string "&amp;" out))
           (#\" (write-string "&quot;" out))
           (t (write-char c out))))))
    (null "")
    (t (princ-to-string str))))

(defun render-attribute (key value)
  "Render an attribute. Event handlers (on*) are converted to data-on-* with JSON value."
  (let ((attr-name (string-downcase (string key))))
    (cond
      ((starts-with-subseq "on" attr-name)
       ;; Event handler (e.g. :onclick -> data-on-click)
       (format nil " data-on-~A='~A'"
               (subseq attr-name 2)
               (jonathan:to-json value)))
      (t
       ;; Normal attribute
       (format nil " ~A=\"~A\""
               attr-name
               (escape-html value))))))

(defun render-html (sexp)
  "Convert an S-expression to an HTML string."
  (cond
    ((null sexp) "")
    ((stringp sexp) (escape-html sexp))
    ((numberp sexp) (write-to-string sexp))
    ((listp sexp)
     (let ((tag (car sexp))
           (rest (cdr sexp)))
       (cond
         ((keywordp tag)
          (let ((attrs "")
                (children rest))
            ;; Process attributes (@ (key value) ...)
            (let ((first-child (car rest)))
              (when (and (listp first-child)
                         (let ((sym (car first-child)))
                           (and (symbolp sym) (string= (string sym) "@"))))
                (setf attrs (with-output-to-string (s)
                              (loop for attr in (cdr first-child)
                                    do (write-string (render-attribute (car attr) (cadr attr)) s))))
                (setf children (cdr rest))))
            ;; Render the tag
            (format nil "<~A~A>~{~A~}</~A>"
                    (string-downcase (string tag))
                    attrs
                    (mapcar #'render-html children)
                    (string-downcase (string tag)))))
         ((and (symbolp tag) (string= (string tag) "@"))
          "") ; Ignore standalone attribute list
         ((symbolp tag)
          ;; Non-keyword symbol = child component call
          (if *component-expander*
              (funcall *component-expander* tag rest)
              (error "No component expander registered for ~A" tag)))
         (t
          ;; Render a plain list by concatenating its elements
          (format nil "~{~A~}" (mapcar #'render-html sexp))))))
    ((symbolp sexp) (string-downcase (string sexp)))
    (t (princ-to-string sexp))))

