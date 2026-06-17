(defpackage #:cl-s3r.sample.error-handling
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout
                #:define-error-page)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-function
                #:signal-http-error))

(in-package #:cl-s3r.sample.error-handling)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "Error Handling Demo"))
     (:body
       (:style "
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: sans-serif; background: #f5f5f5; color: #333; min-height: 100vh; }
header { background: #2c3e50; color: #fff; padding: 12px 24px; }
header h1 { font-size: 1.1rem; }
main { padding: 24px; max-width: 800px; margin: 0 auto; }
nav a { color: #ecf0f1; margin-left: 16px; text-decoration: none; }
nav a:hover { text-decoration: underline; }
h1 { font-size: 1.6rem; margin-bottom: 16px; color: #2c3e50; }
ul { list-style: none; padding: 0; }
li { background: #fff; border: 1px solid #ddd; border-radius: 6px;
     padding: 12px 16px; margin-bottom: 10px; }
a { color: #2980b9; }
a:hover { text-decoration: underline; }
p { margin-bottom: 8px; line-height: 1.6; }
.error-box { background: #ffeef0; border: 1px solid #f5c6cb; border-radius: 8px;
             padding: 24px; margin-top: 24px; }
.error-box h1 { color: #c0392b; }
button { padding: 8px 16px; background: #e74c3c; color: #fff; border: none;
         border-radius: 4px; cursor: pointer; margin-top: 8px; }
button:hover { background: #c0392b; }
")
       (:header
         (:h1 "Error Handling Demo")
         (:nav
           (:a (@ (href "/")) "Items")
           (:a (@ (href "/item/999")) "Missing Item (404)")
           (:a (@ (href "/crash")) "Server Error (500)")))
       (:main ,children))))

(configure-default-layout 'app-layout)

;; --- Error page components ---

(define-component not-found-page (&key message &allow-other-keys)
  `(:div (@ (class "error-box"))
     (:h1 "404 - Page Not Found")
     ,@(when message `((:p ,message)))
     (:p (:a (@ (href "/")) "← Back to top"))))

(define-component server-error-page (&key message &allow-other-keys)
  `(:div (@ (class "error-box"))
     (:h1 "500 - Internal Server Error")
     ,@(when message `((:p ,message)))
     (:p (:a (@ (href "/")) "← Back to top"))))

(define-error-page :status 404 :component "not-found-page")
(define-error-page :status 500 :component "server-error-page")

;; --- Sample data ---

(defparameter *items*
  '((:id 1 :name "Apple" :description "A red fruit")
    (:id 2 :name "Banana" :description "A yellow fruit")
    (:id 3 :name "Cherry" :description "A small red fruit")))

(defun find-item (id)
  (find id *items* :key (lambda (x) (getf x :id)) :test #'=))

;; --- Page components ---

(define-component item-list (&key &allow-other-keys)
  `(:div
     (:h1 "Items")
     (:ul
       ,@(loop for item in *items*
               collect `(:li
                          (:a (@ (href ,(format nil "/item/~A" (getf item :id))))
                              ,(getf item :name))
                          " — "
                          ,(getf item :description))))))

(define-component item-detail (&key id &allow-other-keys)
  (let ((item (find-item id)))
    (unless item
      (signal-http-error 404 :message (format nil "Item ~A not found." id)))
    `(:div
       (:h1 ,(getf item :name))
       (:p ,(getf item :description))
       (:p (:a (@ (href "/")) "← Back to list")))))

(define-component crash-page (&key &allow-other-keys)
  (signal-http-error 500 :message "This page intentionally triggers a server error.")
  `(:div))

(configure-route :path "/"
                 :component "item-list"
                 :props '())

(configure-route :path "/item"
                 :path-param :id
                 :component "item-detail"
                 :props '())

(configure-route :path "/crash"
                 :component "crash-page"
                 :props '())
