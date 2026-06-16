(defpackage #:cl-s3r.sample.counter.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state))

(in-package #:cl-s3r.sample.counter.test)

(deftest test-counter
  (testing "initial count reflects args"
    (let* ((result (test-render-component "counter-app" :args '(:initial-count 0)))
           (state (getf result :state)))
      (ok (= 0 (test-get-state state :count))))
    (let* ((result (test-render-component "counter-app" :args '(:initial-count 10)))
           (state (getf result :state)))
      (ok (= 10 (test-get-state state :count)))))

  (testing "sexp contains count in paragraph"
    (let* ((result (test-render-component "counter-app" :args '(:initial-count 3)))
           (sexp (getf result :sexp)))
      (ok (equal '(:p "Count: " 3) (third sexp)))))

  (testing "increment increases count by 1"
    (let* ((r1 (test-render-component "counter-app" :args '(:initial-count 0)))
           (r2 (test-call-action "counter-app" "increment"
                                 :state (getf r1 :state)
                                 :args '(:initial-count 0))))
      (ok (= 1 (test-get-state (getf r2 :state) :count)))
      (ok (equal '(:p "Count: " 1) (third (getf r2 :sexp))))))

  (testing "decrement decreases count by 1"
    (let* ((r1 (test-render-component "counter-app" :args '(:initial-count 0)))
           (r2 (test-call-action "counter-app" "decrement"
                                 :state (getf r1 :state)
                                 :args '(:initial-count 0))))
      (ok (= -1 (test-get-state (getf r2 :state) :count)))
      (ok (equal '(:p "Count: " -1) (third (getf r2 :sexp))))))

  (testing "chained actions: increment twice then decrement"
    (let* ((r1 (test-render-component "counter-app" :args '(:initial-count 0)))
           (r2 (test-call-action "counter-app" "increment"
                                 :state (getf r1 :state) :args '(:initial-count 0)))
           (r3 (test-call-action "counter-app" "increment"
                                 :state (getf r2 :state) :args '(:initial-count 0)))
           (r4 (test-call-action "counter-app" "decrement"
                                 :state (getf r3 :state) :args '(:initial-count 0))))
      (ok (= 1 (test-get-state (getf r4 :state) :count)))))

  (testing "raw-sexp contains data-state with correct count"
    (let* ((r1 (test-render-component "counter-app" :args '(:initial-count 5)))
           (r2 (test-call-action "counter-app" "increment"
                                 :state (getf r1 :state) :args '(:initial-count 5)))
           ;; raw-sexp = (:div (@ (data-state "...") (data-component "...")) ...)
           (data-state-json (second (second (second (getf r2 :raw-sexp))))))
      (ok (stringp data-state-json))
      (ok (search "6" data-state-json)))))
