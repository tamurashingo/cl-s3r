(defpackage #:cl-s3r.sample.checkbox.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state))

(in-package #:cl-s3r.sample.checkbox.test)

(deftest test-uncontrolled-checkbox-demo
  (testing "renders without error"
    (let ((result (test-render-component "uncontrolled-checkbox-demo" :args '())))
      (ok (not (null (getf result :sexp)))))))

(deftest test-disabled-checkbox-demo
  (testing "renders without error"
    (let ((result (test-render-component "disabled-checkbox-demo" :args '())))
      (ok (not (null (getf result :sexp)))))))

(deftest test-uncontrolled-disabled-checkbox-demo
  (testing "renders without error"
    (let ((result (test-render-component "uncontrolled-disabled-checkbox-demo" :args '())))
      (ok (not (null (getf result :sexp)))))))

(deftest test-controlled-state-checkbox-demo
  (testing "renders without error"
    (let ((result (test-render-component "controlled-state-checkbox-demo" :args '())))
      (ok (not (null (getf result :sexp))))))

  (testing "starts unsubscribed"
    (let ((result (test-render-component "controlled-state-checkbox-demo" :args '())))
      (ok (not (test-get-state (getf result :state) :is-subscribed)))))

  (testing "toggle-subscribed(nil) flips is-subscribed to true"
    (let* ((r1 (test-render-component "controlled-state-checkbox-demo" :args '()))
           (r2 (test-call-action "controlled-state-checkbox-demo" "toggle-subscribed"
                                 :state       (getf r1 :state)
                                 :action-args '(nil))))
      (ok (test-get-state (getf r2 :state) :is-subscribed))))

  (testing "toggle-subscribed(t) flips is-subscribed back to false"
    (let* ((r1 (test-render-component "controlled-state-checkbox-demo" :args '()))
           (r2 (test-call-action "controlled-state-checkbox-demo" "toggle-subscribed"
                                 :state       (getf r1 :state)
                                 :action-args '(nil)))
           (r3 (test-call-action "controlled-state-checkbox-demo" "toggle-subscribed"
                                 :state       (getf r2 :state)
                                 :action-args '(t))))
      (ok (not (test-get-state (getf r3 :state) :is-subscribed))))))
