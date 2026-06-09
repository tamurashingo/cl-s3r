(defsystem "01-counter"
  :description "Counter sample application for cl-s3r"
  :depends-on ("cl-s3r")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "01-counter/test"))))

(defsystem "01-counter/test"
  :description "Tests for 01-counter"
  :depends-on ("01-counter" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
