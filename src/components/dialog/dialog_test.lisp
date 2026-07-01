(defpackage #:cl-s3r.components.dialog.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:cl-s3r.components.dialog
                #:find-dsl-child
                #:parse-dialog-actions))

(in-package #:cl-s3r.components.dialog.test)

;;; --- find-dsl-child ---

(deftest test-find-dsl-child
  (testing "returns nil when items is nil"
    (ok (null (find-dsl-child "dialog-title" nil))))

  (testing "returns nil when tag not present"
    (ok (null (find-dsl-child "dialog-title"
                              '((dialog-content (:p "text")))))))

  (testing "returns body forms when found"
    (let ((result (find-dsl-child "dialog-title"
                                  '((dialog-title "Hello")))))
      (ok (equal '("Hello") result))))

  (testing "is case-insensitive"
    (let ((result (find-dsl-child "DIALOG-TITLE"
                                  '((dialog-title "Hello")))))
      (ok (equal '("Hello") result))))

  (testing "returns multiple body forms"
    (let ((result (find-dsl-child "dialog-content"
                                  '((dialog-content (:h1 "Title") (:p "Body"))))))
      (ok (equal '((:h1 "Title") (:p "Body")) result)))))

;;; --- parse-dialog-actions ---

(deftest test-parse-dialog-actions
  (testing "errors when action-items is nil"
    (ok (signals (parse-dialog-actions nil) 'error)))

  (testing "errors when no dialog-action forms present"
    (ok (signals (parse-dialog-actions '((other-thing "x"))) 'error)))

  (testing "parses a single dialog-action without attrs"
    (let ((result (parse-dialog-actions
                   '((dialog-action "ok")))))
      (ok (= 1 (length result)))
      (ok (null (getf (first result) :attrs)))
      (ok (equal '("ok") (getf (first result) :body)))))

  (testing "parses a single dialog-action with onclick attr"
    (let ((result (parse-dialog-actions
                   '((dialog-action (@ (onclick (handle-close))) "ok")))))
      (ok (= 1 (length result)))
      (ok (not (null (getf (first result) :attrs))))
      (ok (equal '("ok") (getf (first result) :body)))))

  (testing "parses multiple dialog-action forms"
    (let ((result (parse-dialog-actions
                   '((dialog-action (@ (onclick (handle-yes))) "yes")
                     (dialog-action (@ (onclick (handle-no)))  "no")))))
      (ok (= 2 (length result)))))

  (testing "ignores non-dialog-action items in the list"
    (let ((result (parse-dialog-actions
                   '((dialog-action (@ (onclick (handle-close))) "ok")
                     (some-other-thing "ignored")))))
      (ok (= 1 (length result))))))

;;; --- dialog component rendering ---

(defun make-alert-children ()
  '((dialog-title "My Dialog")
    (dialog-content (:p "Dialog body."))
    (dialog-actions
      (dialog-action (@ (onclick (handle-close))) "ok"))))

(defun make-confirm-children ()
  '((dialog-title "Confirm")
    (dialog-content (:p "Are you sure?"))
    (dialog-actions
      (dialog-action (@ (onclick (handle-yes))) "yes")
      (dialog-action (@ (onclick (handle-no)))  "no"))))

(deftest test-dialog-render
  (testing "renders without error given valid children"
    (let ((result (test-render-component "dialog"
                                         :args (list :children (make-alert-children)))))
      (ok (not (null (getf result :sexp))))))

  (testing "rendered sexp root tag is :div"
    (let* ((result (test-render-component "dialog"
                                          :args (list :children (make-alert-children))))
           (sexp   (getf result :sexp)))
      (ok (eq :div (car sexp)))))

  (testing "state is empty (stateless component)"
    (let* ((result (test-render-component "dialog"
                                          :args (list :children (make-alert-children))))
           (state  (getf result :state)))
      (ok (null state))))

  (testing "renders two action buttons for confirm dialog"
    (let* ((result (test-render-component "dialog"
                                          :args (list :children (make-confirm-children))))
           (sexp   (getf result :raw-sexp))
           (html   (format nil "~A" sexp)))
      (ok (not (null (search "handle-yes" html))))
      (ok (not (null (search "handle-no"  html))))))

  (testing "errors when dialog-actions is missing"
    (ok (signals
          (test-render-component "dialog"
                                 :args (list :children
                                             '((dialog-title "t")
                                               (dialog-content (:p "c")))))
          'error)))

  (testing "errors when dialog-actions has no dialog-action items"
    (ok (signals
          (test-render-component "dialog"
                                 :args (list :children
                                             '((dialog-title "t")
                                               (dialog-content (:p "c"))
                                               (dialog-actions))))
          'error))))
