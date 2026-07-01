(defpackage #:cl-s3r.sample.dialog.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state))

(in-package #:cl-s3r.sample.dialog.test)

;;; --- helpers ---

(defun contains-dialog-p (sexp)
  "Return true if SEXP contains a (dialog ...) child component call."
  (and (listp sexp)
       (some (lambda (item)
               (and (listp item)
                    (symbolp (car item))
                    (string-equal (string (car item)) "dialog")))
             sexp)))

;;; --- alert-dialog-demo ---

(deftest test-alert-dialog-demo
  (testing "renders without error on initial state"
    (let ((result (test-render-component "alert-dialog-demo" :args '())))
      (ok (not (null (getf result :sexp))))))

  (testing "dialog is closed on initial state"
    (let* ((result (test-render-component "alert-dialog-demo" :args '())))
      (ok (null (test-get-state (getf result :state) :dialog-open)))
      (ok (not (contains-dialog-p (getf result :raw-sexp))))))

  (testing "open-dialog action sets dialog-open to t"
    (let* ((r1 (test-render-component "alert-dialog-demo" :args '()))
           (r2 (test-call-action "alert-dialog-demo" "open-dialog"
                                 :state (getf r1 :state))))
      (ok (test-get-state (getf r2 :state) :dialog-open))
      (ok (contains-dialog-p (getf r2 :raw-sexp)))))

  (testing "handle-close action closes the dialog"
    (let* ((r1 (test-render-component "alert-dialog-demo" :args '()))
           (r2 (test-call-action "alert-dialog-demo" "open-dialog"
                                 :state (getf r1 :state)))
           (r3 (test-call-action "alert-dialog-demo" "handle-close"
                                 :state (getf r2 :state))))
      (ok (null (test-get-state (getf r3 :state) :dialog-open)))
      (ok (not (contains-dialog-p (getf r3 :raw-sexp)))))))

;;; --- confirm-dialog-demo ---

(deftest test-confirm-dialog-demo
  (testing "renders without error on initial state"
    (let ((result (test-render-component "confirm-dialog-demo" :args '())))
      (ok (not (null (getf result :sexp))))))

  (testing "open-dialog action opens the dialog"
    (let* ((r1 (test-render-component "confirm-dialog-demo" :args '()))
           (r2 (test-call-action "confirm-dialog-demo" "open-dialog"
                                 :state (getf r1 :state))))
      (ok (test-get-state (getf r2 :state) :dialog-open))
      (ok (contains-dialog-p (getf r2 :raw-sexp)))))

  (testing "handle-yes closes dialog and sets last-answer to yes"
    (let* ((r1 (test-render-component "confirm-dialog-demo" :args '()))
           (r2 (test-call-action "confirm-dialog-demo" "open-dialog"
                                 :state (getf r1 :state)))
           (r3 (test-call-action "confirm-dialog-demo" "handle-yes"
                                 :state (getf r2 :state))))
      (ok (string= "yes" (test-get-state (getf r3 :state) :last-answer)))
      (ok (null (test-get-state (getf r3 :state) :dialog-open)))))

  (testing "handle-no closes dialog and sets last-answer to no"
    (let* ((r1 (test-render-component "confirm-dialog-demo" :args '()))
           (r2 (test-call-action "confirm-dialog-demo" "open-dialog"
                                 :state (getf r1 :state)))
           (r3 (test-call-action "confirm-dialog-demo" "handle-no"
                                 :state (getf r2 :state))))
      (ok (string= "no" (test-get-state (getf r3 :state) :last-answer)))
      (ok (null (test-get-state (getf r3 :state) :dialog-open))))))

;;; --- input-dialog-demo ---

(deftest test-input-dialog-demo
  (testing "renders without error on initial state"
    (let ((result (test-render-component "input-dialog-demo" :args '())))
      (ok (not (null (getf result :sexp))))))

  (testing "open-dialog action opens the dialog"
    (let* ((r1 (test-render-component "input-dialog-demo" :args '()))
           (r2 (test-call-action "input-dialog-demo" "open-dialog"
                                 :state (getf r1 :state))))
      (ok (test-get-state (getf r2 :state) :dialog-open))
      (ok (contains-dialog-p (getf r2 :raw-sexp)))))

  (testing "handle-ok with form-data saves the name and closes dialog"
    (let* ((r1 (test-render-component "input-dialog-demo" :args '()))
           (r2 (test-call-action "input-dialog-demo" "open-dialog"
                                 :state (getf r1 :state)))
           (r3 (test-call-action "input-dialog-demo" "handle-ok"
                                 :state (getf r2 :state)
                                 :action-args (list '(:|name-input| "Taro")))))
      (ok (string= "Taro" (test-get-state (getf r3 :state) :entered-name)))
      (ok (null (test-get-state (getf r3 :state) :dialog-open)))))

  (testing "handle-ok with empty name does not update entered-name"
    (let* ((r1 (test-render-component "input-dialog-demo" :args '()))
           (r2 (test-call-action "input-dialog-demo" "open-dialog"
                                 :state (getf r1 :state)))
           (r3 (test-call-action "input-dialog-demo" "handle-ok"
                                 :state (getf r2 :state)
                                 :action-args (list '(:|name-input| "")))))
      (ok (string= "" (test-get-state (getf r3 :state) :entered-name)))
      (ok (null (test-get-state (getf r3 :state) :dialog-open)))))

  (testing "handle-cancel closes dialog without saving"
    (let* ((r1 (test-render-component "input-dialog-demo" :args '()))
           (r2 (test-call-action "input-dialog-demo" "open-dialog"
                                 :state (getf r1 :state)))
           (r3 (test-call-action "input-dialog-demo" "handle-cancel"
                                 :state (getf r2 :state))))
      (ok (null (test-get-state (getf r3 :state) :dialog-open)))
      (ok (string= "" (test-get-state (getf r3 :state) :entered-name))))))
