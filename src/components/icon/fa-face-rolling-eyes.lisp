;;; Font Awesome Free - face-rolling-eyes icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-face-rolling-eyes
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-face-rolling-eyes))

(in-package #:cl-s3r.components.fa-face-rolling-eyes)

(define-component fa-face-rolling-eyes (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M256 48a208 208 0 1 1 0 416 208 208 0 1 1 0-416zm0 464a256 256 0 1 0 0-512 256 256 0 1 0 0 512zM176 376c0 13.3 10.7 24 24 24l112 0c13.3 0 24-10.7 24-24s-10.7-24-24-24l-112 0c-13.3 0-24 10.7-24 24zM160 264c-22.1 0-40-17.9-40-40 0-9.5 3.3-18.1 8.8-25 3.2 14.3 16 25 31.2 25s28-10.7 31.2-25c5.5 6.8 8.8 15.5 8.8 25 0 22.1-17.9 40-40 40zm0 40a80 80 0 1 0 0-160 80 80 0 1 0 0 160zm192-40c-22.1 0-40-17.9-40-40 0-9.5 3.3-18.1 8.8-25 3.2 14.3 16 25 31.2 25s28-10.7 31.2-25c5.5 6.8 8.8 15.5 8.8 25 0 22.1-17.9 40-40 40zm0 40a80 80 0 1 0 0-160 80 80 0 1 0 0 160z"))))))
