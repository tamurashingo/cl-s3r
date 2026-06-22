;;; Font Awesome Free - copyright icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-copyright
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-copyright))

(in-package #:cl-s3r.components.fa-copyright)

(define-component fa-copyright (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M256 48a208 208 0 1 1 0 416 208 208 0 1 1 0-416zm0 464a256 256 0 1 0 0-512 256 256 0 1 0 0 512zM205.1 306.9c-28.1-28.1-28.1-73.7 0-101.8s73.7-28.1 101.8 0c9.4 9.4 24.6 9.4 33.9 0s9.4-24.6 0-33.9c-46.9-46.9-122.8-46.9-169.7 0s-46.9 122.8 0 169.7 122.8 46.9 169.7 0c9.4-9.4 9.4-24.6 0-33.9s-24.6-9.4-33.9 0c-28.1 28.1-73.7 28.1-101.8 0z"))))))
