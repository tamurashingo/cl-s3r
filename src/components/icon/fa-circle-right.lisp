;;; Font Awesome Free - circle-right icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-circle-right
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-circle-right))

(in-package #:cl-s3r.components.fa-circle-right)

(define-component fa-circle-right (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M464 256a208 208 0 1 1 -416 0 208 208 0 1 1 416 0zM0 256a256 256 0 1 0 512 0 256 256 0 1 0 -512 0zm387.3 11.3c6.2-6.2 6.2-16.4 0-22.6l-104-104c-4.6-4.6-11.5-5.9-17.4-3.5S256 145.5 256 152l0 72-104 0c-13.3 0-24 10.7-24 24l0 16c0 13.3 10.7 24 24 24l104 0 0 72c0 6.5 3.9 12.3 9.9 14.8s12.9 1.1 17.4-3.5l104-104z"))))))
