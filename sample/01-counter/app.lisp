(defpackage #:cl-s3r.sample.counter
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-mount)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function))

(in-package #:cl-s3r.sample.counter)

;; カウンタコンポーネントの定義
(define-component counter-app (initial-count)
  (let-component-state ((count initial-count))
    (let-function ((increment () (incf count))
                   (decrement () (decf count)))
      `(:div
         (:h1 "Counter App")
         (:p "Count: " ,count)
         (:button (@ (onclick (increment))) "+")
         (:button (@ (onclick (decrement))) "-")))))

;; マウント設定
(configure-mount :target "#root"
                 :component "counter-app"
                 :props '(:initial-count 0)
                 :static-root (asdf:system-relative-pathname
                               :cl-s3r-sample-counter ""))
