;;; Font Awesome Free - window-close icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-window-close
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-window-close))

(in-package #:cl-s3r.components.fa-window-close)

(define-component fa-window-close (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 512 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M64 112c-8.8 0-16 7.2-16 16l0 256c0 8.8 7.2 16 16 16l384 0c8.8 0 16-7.2 16-16l0-256c0-8.8-7.2-16-16-16L64 112zM0 128C0 92.7 28.7 64 64 64l384 0c35.3 0 64 28.7 64 64l0 256c0 35.3-28.7 64-64 64L64 448c-35.3 0-64-28.7-64-64L0 128zm334.1 49.9c9.4 9.4 9.4 24.6 0 33.9l-44.1 44.1 44.1 44.1c9.4 9.4 9.4 24.6 0 33.9s-24.6 9.4-33.9 0l-44.1-44.1-44.1 44.1c-9.4 9.4-24.6 9.4-33.9 0s-9.4-24.6 0-33.9l44.1-44.1-44.1-44.1c-9.4-9.4-9.4-24.6 0-33.9s24.6-9.4 33.9 0l44.1 44.1 44.1-44.1c9.4-9.4 24.6-9.4 33.9 0z"))))))
