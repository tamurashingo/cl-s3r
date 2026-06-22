(defpackage #:cl-s3r.components.badge
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component)
  (:export #:badge))

(in-package #:cl-s3r.components.badge)

(defvar *badge-css*
  (concatenate 'string
               ".cl-s3r-badge-container{"
               "position:relative;"
               "display:inline-flex;"
               "vertical-align:middle;}"
               ".cl-s3r-badge{"
               "display:inline-flex;"
               "align-items:center;"
               "justify-content:center;"
               "border-radius:10px;"
               "min-width:20px;"
               "height:20px;"
               "padding:0 6px;"
               "font-size:12px;"
               "font-weight:600;"
               "color:currentColor;"
               "box-sizing:border-box;"
               "white-space:nowrap;"
               "line-height:1;}"
               ".cl-s3r-badge-container>.cl-s3r-badge{"
               "position:absolute;"
               "top:0;"
               "right:0;"
               "transform:translate(50%,-50%);}"
               ".cl-s3r-badge--dot{"
               "min-width:10px;"
               "width:10px;"
               "height:10px;"
               "border-radius:50%;"
               "padding:0;}"))

(define-component badge (&key count overflow-count show-zero background-color color variant children)
  (let* ((effective-count            (or count 0))
         (effective-overflow-count   (or overflow-count 99))
         (effective-background-color (or background-color "red"))
         (effective-color            (or color "white"))
         (effective-variant          (or variant "standard"))
         (show-badge                 (or show-zero (not (zerop effective-count))))
         (has-children               (not (null children)))
         (display-text               (when (string= effective-variant "standard")
                                       (if (> effective-count effective-overflow-count)
                                           (format nil "~A+" effective-overflow-count)
                                           (write-to-string effective-count))))
         (badge-style                (format nil "background-color:~A;color:~A;"
                                             effective-background-color effective-color)))
    (if has-children
        `(:span (@ (class "cl-s3r-badge-container"))
           (:style ,*badge-css*)
           ,@children
           ,(when show-badge
              `(:span (@ (class ,(if (string= effective-variant "dot")
                                     "cl-s3r-badge cl-s3r-badge--dot"
                                     "cl-s3r-badge"))
                         (style ,badge-style))
                 ,display-text)))
        `(:span (@ (class "cl-s3r-badge-wrapper"))
           (:style ,*badge-css*)
           ,(when show-badge
              `(:span (@ (class ,(if (string= effective-variant "dot")
                                     "cl-s3r-badge cl-s3r-badge--dot"
                                     "cl-s3r-badge"))
                         (style ,badge-style))
                 ,display-text))))))
