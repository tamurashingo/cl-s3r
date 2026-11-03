(defpackage #:cl-s3r.sample.data-table
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.fetch
                #:define-fetcher
                #:invalidate-fetch)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-function
                #:let-component-state)
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

;; Stands in for the API this app would call. Counting the calls lets the demo
;; show that one render reaches the fetcher once per page, however many
;; components ask for it.
(defvar *fetch-calls* 0)

(define-fetcher fetch-users (&key (page 1) (page-size 10))
  (incf *fetch-calls*)
  (let* ((all-rows *sample-users*)
         (total (length all-rows))
         (total-pages (max 1 (ceiling total page-size)))
         (start (min (* (1- page) page-size) total))
         (end (min (+ start page-size) total))
         ;; Copy what is handed out, the way a real API client would: the caller
         ;; must not end up holding the store's own conses, or a write would be
         ;; visible through results that were fetched before it.
         (paged (mapcar #'copy-list (subseq all-rows start end))))
    (list :rows     paged
          :total    total
          :page     page
          :has-prev (> page 1)
          :has-next (< page total-pages))))

;; A write: renames the first user in the store. The read is memoised for the
;; rest of the request, so the write has to say what it invalidated or the
;; re-render that follows would show the old name.
(defun rename-first-user (name)
  (setf (getf (first *sample-users*) :name) name))

;; root component
(define-component data-table-demo (&key &allow-other-keys)
  (let-component-state ((renames 0))
    (let-function ((rename ()
                     (incf renames)
                     (rename-first-user (format nil "Renamed ~A" renames))
                     ;; Without this, the table below would still show the old
                     ;; name: the fetch for this page is already memoised.
                     (invalidate-fetch 'fetch-users)))
     (let* ((columns '(:name "Name" :status "Status" :age "Age" :email "Email"))
            (simple-rows '((:fruit "Apple"  :color "Red")
                           (:fruit "Banana" :color "Yellow")
                           (:fruit "Grape"  :color "Purple")))
            ;; Read in the root's body, which runs before the action does. That is
            ;; what makes the invalidation below load-bearing: without it, the
            ;; re-render after the write would be served this memoised page.
            (first-user (getf (first (getf (fetch-users :page 1) :rows)) :name)))
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

       ;; --- 4. refresh + pager
       (:section
         (:h2 "4. refresh + pagination")
         (:p "30 records paged at page-size=10. The table is given a "
             (:code "refresh") " function, so it fetches the page it is showing "
             "on every render instead of being handed rows.")
         (data-table (@ (id "demo-fetch")
                        (refresh ,#'fetch-users)
                        (columns (:id "ID" :name "Name" :status "Status" :age "Age" :email "Email"))
                        (page-size 10)
                        (pager t))))

       ;; --- 4b. a write, and what it has to invalidate
       (:section
         (:h2 "4b. Writing, then reading again")
         (:p "Renaming the first user writes to the store and calls "
             (:code "(invalidate-fetch 'fetch-users)") ". Without that call the "
             "table above would still show the old name, because the read for "
             "this page is memoised for the rest of the request.")
         (:p "first user, as read in the root's body: "
             (:strong (@ (id "first-user")) ,first-user))
         (:p "renames: " (:span (@ (id "rename-count")) ,renames)
             "  fetcher calls so far: " (:span (@ (id "fetch-calls")) ,*fetch-calls*))
         (:button (@ (id "rename-btn") (onclick (rename))) "rename first user"))

       ;; --- 5. empty data
       (:section
         (:h2 "5. Empty data")
         (:p "Display when there are no rows.")
         (data-table (@ (id "demo-empty")
                        (rows nil)
                        (columns (:name "Name" :age "Age"))
                        (pager t)))))))))

(configure-route :path "/"
                 :component "data-table-demo"
                 :props '())
