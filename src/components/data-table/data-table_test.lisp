(defpackage #:cl-s3r.components.data-table.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state))

(in-package #:cl-s3r.components.data-table.test)

(defun sample-rows ()
  '((:name "Alice" :status "active"   :age 30)
    (:name "Bob"   :status "inactive" :age 25)
    (:name "Carol" :status "active"   :age 35)
    (:name "Dave"  :status "inactive" :age 28)
    (:name "Eve"   :status "active"   :age 22)))

(defun sample-columns ()
  '(:name "Name" :status "Status" :age "Age"))

;;; --- initial state ---

(deftest test-data-table-initial-state
  (testing "initial page is 1"
    (let* ((result (test-render-component "data-table"
                                          :args (list :rows (sample-rows)
                                                      :page-size 2)))
           (state (getf result :state)))
      (ok (= 1 (test-get-state state :current-page)))))

  (testing "page prop sets the initial page"
    (let* ((result (test-render-component "data-table"
                                          :args (list :rows (sample-rows)
                                                      :page-size 2
                                                      :page 2)))
           (state (getf result :state)))
      (ok (= 2 (test-get-state state :current-page))))))

;;; --- next-page action ---

(deftest test-data-table-next-page
  (testing "next-page increments current-page by 1"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows) :page-size 2)))
           (r2 (test-call-action "data-table" "next-page"
                                 :state       (getf r1 :state)
                                 :args        (list :rows (sample-rows) :page-size 2)
                                 :action-args '())))
      (ok (= 2 (test-get-state (getf r2 :state) :current-page)))))

  (testing "repeated next-page reaches the last page"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows) :page-size 2)))
           (r2 (test-call-action "data-table" "next-page"
                                 :state (getf r1 :state)
                                 :args  (list :rows (sample-rows) :page-size 2)
                                 :action-args '()))
           (r3 (test-call-action "data-table" "next-page"
                                 :state (getf r2 :state)
                                 :args  (list :rows (sample-rows) :page-size 2)
                                 :action-args '())))
      (ok (= 3 (test-get-state (getf r3 :state) :current-page))))))

;;; --- prev-page action ---

(deftest test-data-table-prev-page
  (testing "prev-page decrements current-page by 1"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows)
                                                  :page-size 2
                                                  :page 3)))
           (r2 (test-call-action "data-table" "prev-page"
                                 :state       (getf r1 :state)
                                 :args        (list :rows (sample-rows)
                                                    :page-size 2
                                                    :page 3)
                                 :action-args '())))
      (ok (= 2 (test-get-state (getf r2 :state) :current-page)))))

  (testing "prev-page on page 1 stays at 1"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows) :page-size 2)))
           (r2 (test-call-action "data-table" "prev-page"
                                 :state       (getf r1 :state)
                                 :args        (list :rows (sample-rows) :page-size 2)
                                 :action-args '())))
      (ok (= 1 (test-get-state (getf r2 :state) :current-page))))))

;;; --- go-to-page action ---

(deftest test-data-table-go-to-page
  (testing "go-to-page navigates to the given page"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows) :page-size 2)))
           (r2 (test-call-action "data-table" "go-to-page"
                                 :state       (getf r1 :state)
                                 :args        (list :rows (sample-rows) :page-size 2)
                                 :action-args '(3))))
      (ok (= 3 (test-get-state (getf r2 :state) :current-page)))))

  (testing "go-to-page clamps value exceeding total-pages to total-pages"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows) :page-size 2)))
           (r2 (test-call-action "data-table" "go-to-page"
                                 :state       (getf r1 :state)
                                 :args        (list :rows (sample-rows) :page-size 2)
                                 :action-args '(999))))
      ;; 5 rows / page-size 2 = 3 pages
      (ok (= 3 (test-get-state (getf r2 :state) :current-page)))))

  (testing "go-to-page clamps value below 1 to 1"
    (let* ((r1 (test-render-component "data-table"
                                      :args (list :rows (sample-rows) :page-size 2)))
           (r2 (test-call-action "data-table" "go-to-page"
                                 :state       (getf r1 :state)
                                 :args        (list :rows (sample-rows) :page-size 2)
                                 :action-args '(0))))
      (ok (= 1 (test-get-state (getf r2 :state) :current-page))))))

;;; --- custom labels ---

(deftest test-data-table-labels
  (testing "next-label overrides the default Next button text"
    (let* ((result (test-render-component "data-table"
                                          :args (list :rows (sample-rows)
                                                      :page-size 2
                                                      :next-label "More")))
           (sexp (getf result :sexp)))
      (ok (search "More" (format nil "~A" sexp)))))

  (testing "prev-label overrides the default Previous button text"
    (let* ((result (test-render-component "data-table"
                                          :args (list :rows (sample-rows)
                                                      :page-size 2
                                                      :page 2
                                                      :prev-label "Back")))
           (sexp (getf result :sexp)))
      (ok (search "Back" (format nil "~A" sexp)))))

  (testing "empty-label overrides the default No data message"
    (let* ((result (test-render-component "data-table"
                                          :args (list :rows '()
                                                      :empty-label "Nothing here")))
           (sexp (getf result :sexp)))
      (ok (search "Nothing here" (format nil "~A" sexp))))))

;;; --- fetch-fn ---

(deftest test-data-table-fetch-fn
  (testing "fetch-fn takes priority over rows"
    (let* ((fetch-data '((:name "Fetch-Alice" :age 30)
                         (:name "Fetch-Bob"   :age 25)))
           (fetch-fn (lambda (&key (page 1) (page-size 10))
                       (declare (ignore page page-size))
                       (list :rows fetch-data
                             :total 2
                             :page 1
                             :has-prev nil
                             :has-next nil)))
           (result (test-render-component "data-table"
                                          :args (list :rows (sample-rows)
                                                      :fetch-fn fetch-fn)))
           (sexp (getf result :sexp)))
      (ok (search "Fetch-Alice" (format nil "~A" sexp)))))

  (testing "fetch-fn returning nil renders an empty table"
    (let* ((fetch-fn (lambda (&key page page-size)
                       (declare (ignore page page-size))
                       nil))
           (result (test-render-component "data-table"
                                          :args (list :fetch-fn fetch-fn)))
           (sexp (getf result :sexp)))
      (ok (search "No data" (format nil "~A" sexp)))))

  (testing "fetch-fn with has-next t renders an enabled next button"
    (let* ((fetch-fn (lambda (&key (page 1) (page-size 10))
                       (declare (ignore page page-size))
                       (list :rows '((:name "A"))
                             :total 20
                             :page 1
                             :has-prev nil
                             :has-next t)))
           (result (test-render-component "data-table"
                                          :args (list :fetch-fn fetch-fn)))
           (sexp (getf result :sexp)))
      ;; next button has onclick, not disabled
      (ok (search "next-page" (format nil "~A" sexp)))))

  (testing "fetch-fn with has-next nil hides the pager when has-prev is also nil"
    (let* ((fetch-fn (lambda (&key (page 1) (page-size 10))
                       (declare (ignore page page-size))
                       (list :rows '((:name "A"))
                             :total 1
                             :page 1
                             :has-prev nil
                             :has-next nil)))
           (result (test-render-component "data-table"
                                          :args (list :fetch-fn fetch-fn
                                                      :pager t)))
           (sexp (getf result :sexp)))
      ;; pager is hidden when both has-prev and has-next are nil
      (ok (not (search "data-table__pager" (format nil "~A" sexp)))))))
