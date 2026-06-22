;;; Font Awesome Free - registered icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-registered
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-registered))

(in-package #:cl-s3r.components.fa-registered)

(define-component fa-registered (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M256 48a208 208 0 1 1 0 416 208 208 0 1 1 0-416zm0 464a256 256 0 1 0 0-512 256 256 0 1 0 0 512zM200 144c-13.3 0-24 10.7-24 24l0 176c0 13.3 10.7 24 24 24s24-10.7 24-24l0-56 34.4 0 41 68.3c6.8 11.4 21.6 15 32.9 8.2s15-21.6 8.2-32.9l-30.2-50.3c24.6-11.5 41.6-36.4 41.6-65.3 0-39.8-32.2-72-72-72l-80 0zm72 96l-48 0 0-48 56 0c13.3 0 24 10.7 24 24s-10.7 24-24 24l-8 0z"))))))
