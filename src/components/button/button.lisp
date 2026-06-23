(defpackage #:cl-s3r.components.button
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component)
  (:export #:button))

(in-package #:cl-s3r.components.button)

(defvar *button-css*
  (concatenate 'string
               ".cl-s3r-button{"
               "display:inline-flex;"
               "align-items:center;"
               "justify-content:center;"
               "gap:6px;"
               "border-radius:4px;"
               "font-size:14px;"
               "font-weight:500;"
               "line-height:1.75;"
               "cursor:pointer;"
               "text-decoration:none;"
               "box-sizing:border-box;"
               "transition:background-color 0.2s ease,border-color 0.2s ease,color 0.2s ease;}"
               ".cl-s3r-button--contained{"
               "border:1px solid;}"
               ".cl-s3r-button--contained:hover:not(:disabled){"
               "background-color:#1565c0;}"
               ".cl-s3r-button--outlined{"
               "border:1px solid;}"
               ".cl-s3r-button--outlined:hover:not(:disabled){"
               "background-color:rgba(25,118,210,0.08);}"
               ".cl-s3r-button--text{"
               "border-width:1px;"
               "border-style:solid;}"
               ".cl-s3r-button--text:hover:not(:disabled){"
               "background-color:rgba(25,118,210,0.08);}"
               ".cl-s3r-button--small{"
               "padding:3px 9px;"
               "font-size:13px;}"
               ".cl-s3r-button--medium{"
               "padding:5px 15px;}"
               ".cl-s3r-button--large{"
               "padding:7px 21px;"
               "font-size:15px;}"
               ".cl-s3r-button--disabled{"
               "opacity:0.38;"
               "cursor:not-allowed;}"))

(define-component button (&key variant prefix suffix size disabled background-color color children)
  (let* ((effective-variant          (or variant "contained"))
         (effective-size             (or size "medium"))
         (effective-background-color (or background-color "#1976d2"))
         (effective-color            (or color
                                         (if (string= effective-variant "contained")
                                             "#fff"
                                             "#1976d2")))
         (fill-color                 (if (string= effective-variant "contained")
                                         effective-background-color
                                         "transparent"))
         (border-color               (if (string= effective-variant "text")
                                         "transparent"
                                         effective-background-color))
         (button-style               (format nil "background-color:~A;color:~A;border-color:~A;"
                                             fill-color effective-color border-color))
         (class-name                 (format nil "cl-s3r-button cl-s3r-button--~A cl-s3r-button--~A~A"
                                             effective-variant
                                             effective-size
                                             (if disabled " cl-s3r-button--disabled" "")))
         (attrs                      `((class ,class-name)
                                       (style ,button-style)
                                       ,@(when disabled '((disabled "")))))
         (prefix-icon                (when (and prefix (not (string= prefix "")))
                                       `(icon (@ (value ,prefix) (size "S")))))
         (suffix-icon                (when (and suffix (not (string= suffix "")))
                                       `(icon (@ (value ,suffix) (size "S"))))))
    `(:button (@ ,@attrs)
       (:style ,*button-css*)
       ,@(when prefix-icon (list prefix-icon))
       ,@(when children (if (listp children) children (list children)))
       ,@(when suffix-icon (list suffix-icon)))))
