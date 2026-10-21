(defsystem "11-nested"
  :description "Nested component behaviour sample application for cl-s3r"
  :depends-on ("cl-s3r")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "11-nested/test"))))

(defsystem "11-nested/test"
  :description "Tests for 11-nested"
  :depends-on ("11-nested" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
