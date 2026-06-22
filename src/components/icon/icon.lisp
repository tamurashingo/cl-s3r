(defpackage #:cl-s3r.components.icon
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.components.icon.util #:size->css-dimension)
  (:import-from #:cl-s3r.components.fa-address-book #:fa-address-book)
  (:export #:icon))

(in-package #:cl-s3r.components.icon)

(define-component icon (&key value color size)
  (let ((dim (size->css-dimension (or size "M"))))
    (format t "[icon] value=~S color=~S size=~S dim=~S~%" value color size dim)
    (cond
      ((string= value "fa-address-book")
       `(fa-address-book (@ (color ,color) (width ,dim) (height ,dim))))
      (t nil))))
