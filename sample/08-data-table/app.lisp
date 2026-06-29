(defpackage #:cl-s3r.sample.data-table
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function)
  (:import-from #:cl-s3r.components.data-table
                #:data-table))

(in-package #:cl-s3r.sample.data-table)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:meta (@ (name "viewport") (content "width=device-width, initial-scale=1")))
       (:title "cl-s3r Data Table")
       (:style "body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:0 20px;}"
               "h2{margin-top:2em;color:#333;}"
               "section{margin-bottom:3em;}"))
     (:body
       ,children)))

(configure-default-layout 'app-layout)

;; 30 sample user records
(defvar *sample-users*
  (loop for i from 1 to 30
        collect (list :id i
                      :name (nth (mod (1- i) 5)
                                 '("Alice" "Bob" "Carol" "Dave" "Eve"))
                      :status (if (zerop (mod i 3)) "inactive" "active")
                      :age (+ 20 (mod i 30))
                      :email (format nil "user~A@example.com" i))))

;; fetch-fn stub: pages through all-rows in memory
(defun make-fetch-fn (all-rows)
  (lambda (&key (page 1) (page-size 10))
    (let* ((total (length all-rows))
           (total-pages (max 1 (ceiling total page-size)))
           (start (min (* (1- page) page-size) total))
           (end (min (+ start page-size) total))
           (paged (subseq all-rows start end)))
      (list :rows     paged
            :total    total
            :page     page
            :has-prev (> page 1)
            :has-next (< page total-pages)))))

;; root component
(define-component data-table-demo (&key &allow-other-keys)
  (let ((columns '(:name "Name" :status "Status" :age "Age" :email "Email"))
        (simple-rows '((:fruit "Apple"  :color "Red")
                       (:fruit "Banana" :color "Yellow")
                       (:fruit "Grape"  :color "Purple")))
        (fetch-fn (make-fetch-fn *sample-users*)))
    `(:div
       (:h1 "data-table Demo")

       ;; --- 1. no columns (raw mode)
       (:section
         (:h2 "1. No columns (raw mode)")
         (:p "Without columns, all field values are rendered without a header row.")
         (data-table (@ (id "demo-raw")
                        (rows ,simple-rows)
                        (pager nil))))

       ;; --- 2. with columns
       (:section
         (:h2 "2. With columns")
         (:p "Specifying columns renders a header row.")
         (data-table (@ (id "demo-columns")
                        (rows ,simple-rows)
                        (columns (:fruit "Fruit" :color "Color"))
                        (pager nil))))

       ;; --- 3. rows + pager
       (:section
         (:h2 "3. rows + pagination")
         (:p "30 records paged at page-size=5 using rows directly.")
         (data-table (@ (id "demo-rows-pager")
                        (rows ,*sample-users*)
                        (columns (:id "ID" :name "Name" :status "Status" :age "Age"))
                        (page-size 5)
                        (pager t))))

       ;; --- 4. fetch-fn + pager
       (:section
         (:h2 "4. fetch-fn + pagination")
         (:p "30 records paged at page-size=10 via fetch-fn.")
         (data-table (@ (id "demo-fetch")
                        (fetch-fn ,fetch-fn)
                        (columns (:id "ID" :name "Name" :status "Status" :age "Age" :email "Email"))
                        (page-size 10)
                        (pager t))))

       ;; --- 5. empty data
       (:section
         (:h2 "5. Empty data")
         (:p "Display when there are no rows.")
         (data-table (@ (id "demo-empty")
                        (rows nil)
                        (columns (:name "Name" :age "Age"))
                        (pager t)))))))

(configure-route :path "/"
                 :component "data-table-demo"
                 :props '())
