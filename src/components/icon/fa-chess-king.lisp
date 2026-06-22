;;; Font Awesome Free - chess-king icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-chess-king
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-chess-king))

(in-package #:cl-s3r.components.fa-chess-king)

(define-component fa-chess-king (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 448 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M224-32c13.3 0 24 10.7 24 24l0 40 48 0c13.3 0 24 10.7 24 24s-10.7 24-24 24l-48 0 0 80 161.8 0c21.1 0 38.2 17.1 38.2 38.2 0 6.4-1.6 12.7-4.7 18.3L357.2 374.5 405.6 435c6.7 8.4 10.4 18.8 10.4 29.6 0 26.2-21.2 47.4-47.4 47.4L79.4 512c-26.2 0-47.4-21.2-47.4-47.4 0-10.8 3.7-21.2 10.4-29.6L90.8 374.5 4.7 216.6C1.6 210.9 0 204.6 0 198.2 0 177.1 17.1 160 38.2 160l161.8 0 0-80-48 0c-13.3 0-24-10.7-24-24s10.7-24 24-24l48 0 0-40c0-13.3 10.7-24 24-24zM131.8 400l-3.6 4.4-47.6 59.6 286.6 0-47.6-59.6-3.6-4.4-184.3 0zm1.1-48.5l.3 .5 181.6 0 .3-.5 78.3-143.5-338.7 0 78.3 143.5z"))))))
