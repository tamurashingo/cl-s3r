(defpackage #:cl-s3r.sample.counter.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.config
                #:*dotenv-store*
                #:load-dotenv-file
                #:getenv
                #:getenv-integer
                #:getenv-boolean))

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

(deftest test-config
  (testing "getenv returns nil when variable is absent and no default given"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (ok (null (getenv "CL_S3R_TEST_ABSENT_VAR_XYZ")))))

  (testing "getenv returns :default when variable is absent"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (ok (equal "fallback" (getenv "CL_S3R_TEST_ABSENT_VAR_XYZ" :default "fallback")))))

  (testing "getenv reads from *dotenv-store*"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (setf (gethash "CL_S3R_TEST_KEY" *dotenv-store*) "hello")
      (ok (equal "hello" (getenv "CL_S3R_TEST_KEY")))))

  (testing "getenv signals error when :required t and variable is absent"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (ok (signals (getenv "CL_S3R_TEST_ABSENT_VAR_XYZ" :required t) 'error))))

  (testing "getenv-integer parses integer from *dotenv-store*"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (setf (gethash "CL_S3R_TEST_PORT" *dotenv-store*) "8080")
      (ok (= 8080 (getenv-integer "CL_S3R_TEST_PORT")))))

  (testing "getenv-integer returns default when variable is absent"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (ok (= 5000 (getenv-integer "CL_S3R_TEST_ABSENT_INT" :default 5000)))))

  (testing "getenv-integer signals error on non-integer value"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (setf (gethash "CL_S3R_TEST_BAD_INT" *dotenv-store*) "not-a-number")
      (ok (signals (getenv-integer "CL_S3R_TEST_BAD_INT") 'error))))

  (testing "getenv-boolean recognizes true"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (setf (gethash "CL_S3R_TEST_BOOL" *dotenv-store*) "true")
      (ok (eq t (getenv-boolean "CL_S3R_TEST_BOOL")))))

  (testing "getenv-boolean recognizes 1"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (setf (gethash "CL_S3R_TEST_BOOL" *dotenv-store*) "1")
      (ok (eq t (getenv-boolean "CL_S3R_TEST_BOOL")))))

  (testing "getenv-boolean returns nil for false string"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (setf (gethash "CL_S3R_TEST_BOOL" *dotenv-store*) "false")
      (ok (null (getenv-boolean "CL_S3R_TEST_BOOL")))))

  (testing "getenv-boolean returns default when variable is absent"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (ok (null (getenv-boolean "CL_S3R_TEST_ABSENT_BOOL")))
      (ok (eq t (getenv-boolean "CL_S3R_TEST_ABSENT_BOOL" :default t)))))

  (testing "load-dotenv-file parses KEY=VALUE pairs"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (uiop:with-temporary-file (:pathname tmp :stream s :keep nil :type "env")
        (format s "APP_HOST=localhost~%APP_PORT=9999~%# comment line~%EMPTY_LINE=~%~%")
        (finish-output s)
        (load-dotenv-file tmp))
      (ok (equal "localhost" (getenv "APP_HOST")))
      (ok (equal "9999" (getenv "APP_PORT")))
      (ok (equal "" (getenv "EMPTY_LINE")))))

  (testing "load-dotenv-file strips surrounding quotes"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (uiop:with-temporary-file (:pathname tmp :stream s :keep nil :type "env")
        (format s "QUOTED_DOUBLE=\"hello world\"~%QUOTED_SINGLE='foo bar'~%")
        (finish-output s)
        (load-dotenv-file tmp))
      (ok (equal "hello world" (getenv "QUOTED_DOUBLE")))
      (ok (equal "foo bar" (getenv "QUOTED_SINGLE")))))

  (testing "load-dotenv-file silently skips missing files"
    (let ((*dotenv-store* (make-hash-table :test 'equal)))
      (ok (null (load-dotenv-file #p"/nonexistent/.env.this.does.not.exist"))))))
