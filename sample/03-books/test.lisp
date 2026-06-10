(defpackage #:cl-s3r.sample.books.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:cl-s3r.component
                #:call-metadata))

(in-package #:cl-s3r.sample.books.test)

(defun find-tag (tag sexp)
  "Find the first direct child of SEXP with the given TAG keyword."
  (find-if (lambda (x) (and (listp x) (eq (car x) tag))) (cdr sexp)))

(deftest test-impl-list
  (testing "no filter returns all 8 implementations"
    (let* ((result (test-render-component "impl-list" :args '(nil)))
           (ul (find-tag :ul (getf result :sexp))))
      (ok (= 8 (length (cdr ul))))))

  (testing "empty string filter returns all 8 implementations"
    (let* ((result (test-render-component "impl-list" :args '("")))
           (ul (find-tag :ul (getf result :sexp))))
      (ok (= 8 (length (cdr ul))))))

  (testing "filter by name narrows results"
    ;; "Clozure" appears only in CCL's name/description
    (let* ((result (test-render-component "impl-list" :args '("Clozure")))
           (ul (find-tag :ul (getf result :sexp))))
      (ok (= 1 (length (cdr ul))))))

  (testing "filter by license returns matching implementations"
    (let* ((result (test-render-component "impl-list" :args '("MIT")))
           (ul (find-tag :ul (getf result :sexp))))
      (ok (>= (length (cdr ul)) 1))))

  (testing "filter paragraph appears when filter is active"
    (let* ((result (test-render-component "impl-list" :args '("SBCL")))
           (sexp (getf result :sexp)))
      (ok (find-tag :p sexp))))

  (testing "no filter paragraph when filter is nil"
    (let* ((result (test-render-component "impl-list" :args '(nil)))
           (sexp (getf result :sexp)))
      (ok (null (find-tag :p sexp))))))

(deftest test-impl-detail
  (testing "valid id renders implementation name in h1"
    (let* ((result (test-render-component "impl-detail" :args '(1)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "SBCL") (find-tag :h1 sexp)))))

  (testing "another valid id renders correct name"
    (let* ((result (test-render-component "impl-detail" :args '(2)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "CCL") (find-tag :h1 sexp)))))

  (testing "invalid id renders not-found message"
    (let* ((result (test-render-component "impl-detail" :args '(999)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "Implementation not found") (find-tag :h1 sexp))))))

(deftest test-impl-detail-metadata
  (testing "valid id returns implementation name in title"
    (let ((meta (call-metadata "impl-detail" '(:id 1))))
      (ok (equal "SBCL - Common Lisp OSS Implementations"
                 (getf meta :title)))))

  (testing "another valid id returns correct title"
    (let ((meta (call-metadata "impl-detail" '(:id 2))))
      (ok (equal "CCL - Common Lisp OSS Implementations"
                 (getf meta :title)))))

  (testing "invalid id returns nil"
    (let ((meta (call-metadata "impl-detail" '(:id 999))))
      (ok (null meta))))

  (testing "impl-list has no metadata registered"
    (let ((meta (call-metadata "impl-list" '(:filter nil))))
      (ok (null meta)))))

(deftest test-inject-title
  (testing "replaces existing title tag"
    (let ((result (cl-s3r.server::inject-title
                   "<html><head><title>Old Title</title></head><body></body></html>"
                   "SBCL - Common Lisp OSS Implementations")))
      (ok (search "<title>SBCL - Common Lisp OSS Implementations</title>" result))
      (ok (null (search "<title>Old Title</title>" result)))))

  (testing "inserts title before </head> when none exists"
    (let ((result (cl-s3r.server::inject-title
                   "<html><head></head><body></body></html>"
                   "SBCL")))
      (ok (search "<title>SBCL</title>" result))))

  (testing "escapes HTML special characters in title"
    (let ((result (cl-s3r.server::inject-title
                   "<html><head><title>x</title></head></html>"
                   "<script>alert(1)</script>")))
      (ok (search "&lt;script&gt;alert(1)&lt;/script&gt;" result))
      (ok (null (search "<script>" result))))))
