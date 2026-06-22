;;; Font Awesome Free - credit-card-alt icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-credit-card-alt
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-credit-card-alt))

(in-package #:cl-s3r.components.fa-credit-card-alt)

(define-component fa-credit-card-alt (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M448 112c8.8 0 16 7.2 16 16l0 32-416 0 0-32c0-8.8 7.2-16 16-16l384 0zm16 112l0 160c0 8.8-7.2 16-16 16L64 400c-8.8 0-16-7.2-16-16l0-160 416 0zM64 64C28.7 64 0 92.7 0 128L0 384c0 35.3 28.7 64 64 64l384 0c35.3 0 64-28.7 64-64l0-256c0-35.3-28.7-64-64-64L64 64zM80 344c0 13.3 10.7 24 24 24l48 0c13.3 0 24-10.7 24-24s-10.7-24-24-24l-48 0c-13.3 0-24 10.7-24 24zm144 0c0 13.3 10.7 24 24 24l64 0c13.3 0 24-10.7 24-24s-10.7-24-24-24l-64 0c-13.3 0-24 10.7-24 24z"))))))
