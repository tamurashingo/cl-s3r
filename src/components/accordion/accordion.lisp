(defpackage #:cl-s3r.components.accordion
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function)
  (:export #:accordion
           #:split-on-spaces
           #:parse-accordion-children))

(in-package #:cl-s3r.components.accordion)

(defvar *accordion-css*
  (concatenate 'string
               ".accordion-panel-wrapper{"
               "display:grid;"
               "grid-template-rows:0fr;"
               "transition:grid-template-rows var(--accordion-duration,0.3s) ease;}"
               ".accordion-panel-wrapper--open{"
               "grid-template-rows:1fr;}"
               ".accordion-panel{"
               "overflow:hidden;}"))

(defun split-on-spaces (str)
  "Split STR on space characters, returning a list of non-empty tokens."
  (when (and str (> (length str) 0))
    (loop with result = '()
          with start = 0
          with len = (length str)
          for i from 0 to len
          when (or (= i len) (char= (char str i) #\Space))
            do (when (> i start)
                 (push (subseq str start i) result))
               (setf start (1+ i))
          finally (return (nreverse result)))))

(defun find-dsl-child (tag-name items)
  "Return the body forms of the first child S-expression whose car string-equals TAG-NAME.
Returns a list of body forms (possibly containing tags, strings, or mixed content)."
  (let ((found (find tag-name items
                     :test (lambda (name item)
                             (and (listp item)
                                  (symbolp (car item))
                                  (string-equal (string (car item)) name))))))
    (when found
      (cdr found))))

(defun parse-accordion-children (children)
  "Parse a list of accordion-item S-expressions into a list of plists.
Each plist has :NAME, :HEADER, and :PANEL keys.
Accepts either a bare accordion-item sexp or a list of them."
  (let ((items (cond
                 ((null children) nil)
                 ;; Single unwrapped accordion-item
                 ((and (listp children)
                       (symbolp (car children))
                       (string-equal (string (car children)) "accordion-item"))
                  (list children))
                 (t children))))
    (loop for item in items
          when (and (listp item)
                    (symbolp (car item))
                    (string-equal (string (car item)) "accordion-item"))
            collect
            (let* ((rest      (cdr item))
                   (has-attrs (and rest
                                   (listp (car rest))
                                   (symbolp (caar rest))
                                   (string= (string (caar rest)) "@")))
                   (attrs     (when has-attrs (cdar rest)))
                   (name      (let ((attr (find "name" attrs
                                               :key  (lambda (a)
                                                       (string-downcase (string (car a))))
                                               :test #'string=)))
                                 (when attr (cadr attr))))
                   (sub-items (if has-attrs (cdr rest) rest)))
              (list :name   name
                    :header (find-dsl-child "accordion-header" sub-items)
                    :panel  (find-dsl-child "accordion-panel"  sub-items))))))

(define-component accordion (&key default mode duration items children &allow-other-keys)
  (let-component-state ((open-items (split-on-spaces default)))
    (let ((accordion-mode     (or mode "single"))
          (accordion-duration (or duration "0.3s"))
          (accordion-items    (or items (parse-accordion-children children))))
    (let-function
        ((toggle-item (name)
           (if (string= accordion-mode "multiple")
               ;; Multiple mode: add or remove from the open list
               (if (member name open-items :test #'string=)
                   (setf open-items (remove name open-items :test #'string=))
                   (push name open-items))
               ;; Single mode: open the clicked item, or close it if already open
               (if (member name open-items :test #'string=)
                   (setf open-items nil)
                   (setf open-items (list name))))))
      `(:div (@ (class "accordion")
                (style ,(format nil "--accordion-duration: ~A" accordion-duration)))
         (:style ,*accordion-css*)
         ,@(mapcar
             (lambda (item)
               (let* ((name    (getf item :name))
                      (header  (getf item :header))
                      (panel   (getf item :panel))
                      (is-open (member name open-items :test #'string=)))
                 `(:div (@ (class "accordion-item"))
                    (:div (@ (class "accordion-header")
                             (onclick (toggle-item ,name)))
                      ,@(if (listp header) header (list header)))
                    (:div (@ (class ,(if is-open
                                         "accordion-panel-wrapper accordion-panel-wrapper--open"
                                         "accordion-panel-wrapper")))
                      (:div (@ (class "accordion-panel"))
                        (:div (@ (class "accordion-panel-content"))
                          ,@(if (listp panel) panel (list panel))))))))
             accordion-items))))))
