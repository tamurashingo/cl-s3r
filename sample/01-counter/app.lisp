(defpackage #:cl-s3r.sample.counter
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function)
  (:import-from #:cl-s3r.config
                #:getenv-integer))

(in-package #:cl-s3r.sample.counter)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "cl-s3r Counter"))
     (:body
       ,children)))

(configure-default-layout 'app-layout)

(define-component counter-app (&key initial-count &allow-other-keys)
  (let-component-state ((count initial-count))
    (let-function ((increment () (incf count))
                   (decrement () (decf count)))
      `(:div
         (:h1 "Counter App")
         (:p "Count: " ,count)
         (:button (@ (onclick (increment))) "+")
         (:button (@ (onclick (decrement))) "-")))))

;; INITIAL_COUNT env var controls the starting value (default: 0).
;; Set it in .env or as an OS environment variable.
(configure-route :path "/"
                 :component "counter-app"
                 :props (list :initial-count (getenv-integer "INITIAL_COUNT" :default 0)))
