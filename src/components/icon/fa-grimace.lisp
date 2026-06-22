;;; Font Awesome Free - grimace icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-grimace
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-grimace))

(in-package #:cl-s3r.components.fa-grimace)

(define-component fa-grimace (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M256 48a208 208 0 1 0 0 416 208 208 0 1 0 0-416zM512 256a256 256 0 1 1 -512 0 256 256 0 1 1 512 0zM152 352c0 11.9 8.6 21.8 20 23.7l0-47.3c-11.4 1.9-20 11.8-20 23.7zm84 24l0-48-24 0 0 48 24 0zm64 0l0-48-24 0 0 48 24 0zm40-.3c11.4-1.9 20-11.8 20-23.7s-8.6-21.8-20-23.7l0 47.3zM176 288l160 0c35.3 0 64 28.7 64 64s-28.7 64-64 64l-160 0c-35.3 0-64-28.7-64-64s28.7-64 64-64zm0-112a32 32 0 1 1 0 64 32 32 0 1 1 0-64zm128 32a32 32 0 1 1 64 0 32 32 0 1 1 -64 0z"))))))
