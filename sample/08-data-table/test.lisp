(defpackage #:cl-s3r.sample.data-table.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.fetch
                #:with-fetch-scope
                #:invalidate-fetch)
  (:import-from #:cl-s3r.sample.data-table
                #:fetch-users
                #:rename-first-user
                #:*sample-users*))

(in-package #:cl-s3r.sample.data-table.test)

(deftest test-data-table-demo-initial
  (testing "renders without error"
    (let ((result (with-fetch-scope
                    (test-render-component "data-table-demo" :args '()))))
      (ok (not (null (getf result :sexp))))))

  (testing "sexp contains the data-table component"
    (let* ((result (with-fetch-scope
                     (test-render-component "data-table-demo" :args '())))
           (sexp   (getf result :sexp)))
      (ok (search "data-table" (format nil "~A" sexp))))))

;;; ---------------------------------------------------------------------------
;;; The fetcher this sample stands its tables on
;;; ---------------------------------------------------------------------------

(deftest test-fetch-users
  (testing "returns the page asked for, with its metadata"
    (with-fetch-scope
      (let ((result (fetch-users :page 1 :page-size 2)))
        (ok (= 2 (length (getf result :rows))))
        (ok (= (length *sample-users*) (getf result :total)))
        (ok (null (getf result :has-prev)))
        (ok (getf result :has-next)))))

  (testing "the last page has no next"
    (with-fetch-scope
      (let* ((page-size 10)
             (last-page (ceiling (length *sample-users*) page-size))
             (result (fetch-users :page last-page :page-size page-size)))
        (ok (getf result :has-prev))
        (ok (null (getf result :has-next))))))

  (testing "a page past the end is empty"
    (with-fetch-scope
      (ok (null (getf (fetch-users :page 99 :page-size 10) :rows)))))

  (testing "rows are copies, so a later write is not visible through them"
    (with-fetch-scope
      (let* ((before (getf (fetch-users :page 1 :page-size 1) :rows))
             (name (getf (first before) :name)))
        (rename-first-user "Written")
        (ok (equal name (getf (first before) :name)))
        ;; put the store back for the tests that follow
        (rename-first-user name)))))

;;; ---------------------------------------------------------------------------
;;; A write has to invalidate what was read before it
;;; ---------------------------------------------------------------------------

(deftest test-rename-invalidates-the-read
  (testing "without invalidation the memoised answer is served"
    (with-fetch-scope
      (let ((original (getf (first (getf (fetch-users :page 1) :rows)) :name)))
        (rename-first-user "Renamed once")
        (ok (equal original
                   (getf (first (getf (fetch-users :page 1) :rows)) :name)))
        (rename-first-user original))))

  (testing "after invalidate-fetch the next read sees the write"
    (with-fetch-scope
      (let ((original (getf (first (getf (fetch-users :page 1) :rows)) :name)))
        (rename-first-user "Renamed twice")
        (invalidate-fetch 'fetch-users)
        (ok (equal "Renamed twice"
                   (getf (first (getf (fetch-users :page 1) :rows)) :name)))
        (rename-first-user original)))))

(deftest test-rename-action
  (testing "the action bumps its counter and writes through"
    (with-fetch-scope
      (let* ((original (getf (first *sample-users*) :name))
             (r0 (test-render-component "data-table-demo" :args '()))
             (r1 (test-call-action "data-table-demo" "rename"
                                   :state (getf r0 :state))))
        (ok (= 0 (test-get-state (getf r0 :state) :renames)))
        (ok (= 1 (test-get-state (getf r1 :state) :renames)))
        (ok (equal "Renamed 1" (getf (first *sample-users*) :name)))
        (rename-first-user original)))))
