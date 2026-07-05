(defsystem "10-checkbox"
  :description "Checkbox sample application for cl-s3r"
  :depends-on ("cl-s3r" "cl-s3r.components.checkbox")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "10-checkbox/test"))))

(defsystem "10-checkbox/test"
  :description "Tests for 10-checkbox"
  :depends-on ("10-checkbox" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
