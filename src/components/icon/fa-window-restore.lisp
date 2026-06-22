;;; Font Awesome Free - window-restore icon
;;; License: CC BY 4.0 License
;;; Project: https://fontawesome.com/

(defpackage #:cl-s3r.components.fa-window-restore
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:export #:fa-window-restore))

(in-package #:cl-s3r.components.fa-window-restore)

(define-component fa-window-restore (&key color size width height)
  (let* ((dim (when size (size->css-dimension size)))
         (effective-width  (or dim width))
         (effective-height (or dim height)))
    `(:svg (@ (xmlns "http://www.w3.org/2000/svg")
              (viewbox "0 0 576 512")
              ,@(when effective-width  `((width  ,effective-width)))
              ,@(when effective-height `((height ,effective-height)))
              ,@(when color `((style ,(format nil "color: ~A;" color)))))
       (:path (@ (fill "currentColor")
                 (d "M512 80L224 80c-8.8 0-16 7.2-16 16l0 16-48 0 0-16c0-35.3 28.7-64 64-64l288 0c35.3 0 64 28.7 64 64l0 192c0 35.3-28.7 64-64 64l-48 0 0-48 48 0c8.8 0 16-7.2 16-16l0-192c0-8.8-7.2-16-16-16zM368 288l-320 0 0 128c0 8.8 7.2 16 16 16l288 0c8.8 0 16-7.2 16-16l0-128zM64 160l288 0c35.3 0 64 28.7 64 64l0 192c0 35.3-28.7 64-64 64L64 480c-35.3 0-64-28.7-64-64L0 224c0-35.3 28.7-64 64-64z"))))))
