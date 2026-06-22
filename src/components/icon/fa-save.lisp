;;; Font Awesome Free - save icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-save
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-save))

(in-package #:cl-s3r.components.fa-save)

(define-component fa-save (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 448 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M64 80c-8.8 0-16 7.2-16 16l0 320c0 8.8 7.2 16 16 16l320 0c8.8 0 16-7.2 16-16l0-242.7c0-4.2-1.7-8.3-4.7-11.3L320 86.6 320 176c0 17.7-14.3 32-32 32l-160 0c-17.7 0-32-14.3-32-32l0-96-32 0zm80 0l0 80 128 0 0-80-128 0zM0 96C0 60.7 28.7 32 64 32l242.7 0c17 0 33.3 6.7 45.3 18.7L429.3 128c12 12 18.7 28.3 18.7 45.3L448 416c0 35.3-28.7 64-64 64L64 480c-35.3 0-64-28.7-64-64L0 96zM160 320a64 64 0 1 1 128 0 64 64 0 1 1 -128 0z"))))))
