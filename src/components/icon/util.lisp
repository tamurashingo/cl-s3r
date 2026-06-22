(defpackage #:cl-s3r.components.icon.util
  (:use #:cl)
  (:export #:size->css-dimension))

(in-package #:cl-s3r.components.icon.util)

(defun size->css-dimension (size)
  "Convert a named size string to a CSS dimension string.
Recognized sizes: XXS XS S M L XL XXL. Defaults to 24px for unknown values."
  (cond ((string-equal size "XXS") "12px")
        ((string-equal size "XS")  "16px")
        ((string-equal size "S")   "20px")
        ((string-equal size "M")   "24px")
        ((string-equal size "L")   "32px")
        ((string-equal size "XL")  "48px")
        ((string-equal size "XXL") "64px")
        (t "24px")))
