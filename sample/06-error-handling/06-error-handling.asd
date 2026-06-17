(defsystem "06-error-handling"
  :description "Error handling sample application for cl-s3r"
  :depends-on ("cl-s3r")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "06-error-handling/test"))))

(defsystem "06-error-handling/test"
  :description "Tests for 06-error-handling"
  :depends-on ("06-error-handling" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
