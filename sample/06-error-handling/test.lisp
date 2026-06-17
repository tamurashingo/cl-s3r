(defpackage #:cl-s3r.sample.error-handling.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:cl-s3r.component
                #:http-error
                #:http-error-status-code
                #:http-error-params))

(in-package #:cl-s3r.sample.error-handling.test)

(defun find-tag (tag sexp)
  "Find the first direct child matching TAG in SEXP."
  (find-if (lambda (x) (and (listp x) (eq (car x) tag))) (cdr sexp)))

(deftest test-item-list
  (testing "renders all 3 items"
    (let* ((result (test-render-component "item-list" :args '()))
           (ul (find-tag :ul (getf result :sexp))))
      (ok (= 3 (length (cdr ul))))))

  (testing "each item has a link"
    (let* ((result (test-render-component "item-list" :args '()))
           (ul (find-tag :ul (getf result :sexp)))
           (first-li (car (cdr ul))))
      (ok (find-tag :a first-li)))))

(deftest test-item-detail
  (testing "valid id renders item name in h1"
    (let* ((result (test-render-component "item-detail" :args '(:id 1)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "Apple") (find-tag :h1 sexp)))))

  (testing "another valid id renders correct name"
    (let* ((result (test-render-component "item-detail" :args '(:id 2)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "Banana") (find-tag :h1 sexp)))))

  (testing "invalid id signals http-error with status 404"
    (let ((error-raised nil)
          (error-status nil))
      (handler-case
        (test-render-component "item-detail" :args '(:id 999))
        (http-error (e)
          (setf error-raised t)
          (setf error-status (http-error-status-code e))))
      (ok error-raised)
      (ok (= 404 error-status))))

  (testing "invalid id http-error carries message param"
    (handler-case
      (test-render-component "item-detail" :args '(:id 999))
      (http-error (e)
        (let ((params (http-error-params e)))
          (ok (search "999" (getf params :message))))))))

(deftest test-crash-page
  (testing "crash-page signals http-error with status 500"
    (let ((error-raised nil)
          (error-status nil))
      (handler-case
        (test-render-component "crash-page" :args '())
        (http-error (e)
          (setf error-raised t)
          (setf error-status (http-error-status-code e))))
      (ok error-raised)
      (ok (= 500 error-status)))))

(deftest test-error-pages
  (testing "not-found-page renders error heading"
    (let* ((result (test-render-component "not-found-page" :args '(:message "Item not found.")))
           (sexp (getf result :sexp)))
      (ok (find-tag :h1 sexp))
      (ok (search "404" (cadr (find-tag :h1 sexp))))))

  (testing "not-found-page renders message when provided"
    (let* ((result (test-render-component "not-found-page" :args '(:message "Custom message")))
           (sexp (getf result :sexp)))
      (ok (some (lambda (x) (and (listp x) (eq :p (car x))
                                 (equal "Custom message" (cadr x))))
                (cdr sexp)))))

  (testing "not-found-page renders without message"
    (let* ((result (test-render-component "not-found-page" :args '())))
      (ok (not (null result)))))

  (testing "server-error-page renders 500 heading"
    (let* ((result (test-render-component "server-error-page" :args '(:message "DB unavailable")))
           (sexp (getf result :sexp)))
      (ok (find-tag :h1 sexp))
      (ok (search "500" (cadr (find-tag :h1 sexp))))))

  (testing "server-error-page renders message when provided"
    (let* ((result (test-render-component "server-error-page" :args '(:message "DB unavailable")))
           (sexp (getf result :sexp)))
      (ok (some (lambda (x) (and (listp x) (eq :p (car x))
                                 (equal "DB unavailable" (cadr x))))
                (cdr sexp))))))
