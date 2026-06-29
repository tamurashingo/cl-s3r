(defpackage #:cl-s3r.sample.data-table.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.sample.data-table
                #:make-fetch-fn
                #:*sample-users*))

(in-package #:cl-s3r.sample.data-table.test)

(defun demo-rows ()
  '((:name "Alice" :status "active"   :age 30)
    (:name "Bob"   :status "inactive" :age 25)
    (:name "Carol" :status "active"   :age 35)
    (:name "Dave"  :status "inactive" :age 28)
    (:name "Eve"   :status "active"   :age 22)))

(deftest test-data-table-demo-initial
  (testing "renders without error"
    (let* ((result (test-render-component "data-table-demo" :args '())))
      ;; data-table-demo is stateless; just verify the sexp is produced
      (ok (not (null (getf result :sexp))))))

  (testing "sexp contains the data-table component"
    (let* ((result (test-render-component "data-table-demo" :args '()))
           (sexp   (getf result :sexp)))
      (ok (search "data-table" (format nil "~A" sexp))))))

(deftest test-make-fetch-fn
  (testing "returns paginated rows and correct metadata"
    (let* ((fn (make-fetch-fn (demo-rows)))
           (result (funcall fn :page 1 :page-size 2)))
      (ok (= 2 (length (getf result :rows))))
      (ok (= 5 (getf result :total)))
      (ok (null (getf result :has-prev)))
      (ok (getf result :has-next))))

  (testing "last page has has-next nil"
    (let* ((fn (make-fetch-fn (demo-rows)))
           (result (funcall fn :page 3 :page-size 2)))
      (ok (= 1 (length (getf result :rows))))
      (ok (getf result :has-prev))
      (ok (null (getf result :has-next)))))

  (testing "out-of-range page returns empty rows"
    (let* ((fn (make-fetch-fn (demo-rows)))
           (result (funcall fn :page 99 :page-size 2)))
      (ok (null (getf result :rows))))))
