;;; Font Awesome Free - font-awesome-flag icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-font-awesome-flag
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-font-awesome-flag))

(in-package #:cl-s3r.components.fa-font-awesome-flag)

(define-component fa-font-awesome-flag (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M91.7 96C106.3 86.8 116 70.5 116 52 116 23.3 92.7 0 64 0S12 23.3 12 52c0 16.7 7.8 31.5 20 41l0 419 48 0 0-64 389.6 0c14.6 0 26.4-11.8 26.4-26.4 0-3.7-.8-7.3-2.3-10.7L432 272 493.7 133.1c1.5-3.4 2.3-7 2.3-10.7 0-14.6-11.8-26.4-26.4-26.4L91.7 96zM80 400l0-256 356.4 0-48.2 108.5c-5.5 12.4-5.5 26.6 0 39L436.4 400 80 400z"))))))
