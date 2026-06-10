(defpackage #:cl-s3r.sample.counter
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-root-page)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function))

(in-package #:cl-s3r.sample.counter)

(define-component root (children)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "cl-s3r Counter"))
     (:body
       ,children)))

(configure-root-page :component "root")

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
(configure-route :path "/"
                 :component "counter-app"
                 :props '(:initial-count 0))
