;;; Font Awesome Free - hourglass-half icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-hourglass-half
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-hourglass-half))

(in-package #:cl-s3r.components.fa-hourglass-half)

(define-component fa-hourglass-half (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 384 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M0 24C0 10.7 10.7 0 24 0L360 0c13.3 0 24 10.7 24 24s-10.7 24-24 24l-8 0 0 19c0 40.3-16 79-44.5 107.5l-81.5 81.5 81.5 81.5C336 366 352 404.7 352 445l0 19 8 0c13.3 0 24 10.7 24 24s-10.7 24-24 24L24 512c-13.3 0-24-10.7-24-24s10.7-24 24-24l8 0 0-19c0-40.3 16-79 44.5-107.5l81.5-81.5-81.5-81.5C48 146 32 107.3 32 67l0-19-8 0C10.7 48 0 37.3 0 24zM110.5 371.5c-3.9 3.9-7.5 8.1-10.7 12.5l184.4 0c-3.2-4.4-6.8-8.6-10.7-12.5l-81.5-81.5-81.5 81.5zM80.8 432c-.5 4.3-.8 8.6-.8 13l0 19 224 0 0-19c0-4.4-.3-8.7-.8-13L80.8 432zM254.1 160l-124.1 0 62.1 62.1 62.1-62.1zm39.7-48C300.4 98.1 304 82.7 304 67l0-19-224 0 0 19c0 15.7 3.6 31.1 10.2 45l203.5 0z"))))))
