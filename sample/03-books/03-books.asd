(defsystem "03-books"
  :description "Books/implementations sample application for cl-s3r"
  :depends-on ("cl-s3r")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "03-books/test"))))

(defsystem "03-books/test"
  :description "Tests for 03-books"
  :depends-on ("03-books" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
