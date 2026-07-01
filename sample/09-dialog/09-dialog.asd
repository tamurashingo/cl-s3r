(defsystem "09-dialog"
  :description "Dialog sample application for cl-s3r"
  :depends-on ("cl-s3r" "cl-s3r.components.dialog")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "09-dialog/test"))))

(defsystem "09-dialog/test"
  :description "Tests for 09-dialog"
  :depends-on ("09-dialog" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
