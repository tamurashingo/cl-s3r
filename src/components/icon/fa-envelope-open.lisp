;;; Font Awesome Free - envelope-open icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-envelope-open
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-envelope-open))

(in-package #:cl-s3r.components.fa-envelope-open)

(define-component fa-envelope-open (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M512 416c0 35.3-28.5 64-63.9 64L64 480c-35.4 0-64-28.7-64-64L0 164c.1-15.5 7.8-30 20.5-38.8L206-2.7c30.1-20.7 69.8-20.7 99.9 0L491.5 125.2c12.8 8.8 20.4 23.3 20.5 38.8l0 252zM64 432l384.1 0c8.8 0 15.9-7.1 15.9-16l0-191.7-154.8 117.4c-31.4 23.9-74.9 23.9-106.4 0L48 224.3 48 416c0 8.9 7.2 16 16 16zM463.6 164.4L278.7 36.8c-13.7-9.4-31.7-9.4-45.4 0L48.4 164.4 231.8 303.5c14.3 10.8 34.1 10.8 48.4 0L463.6 164.4z"))))))
