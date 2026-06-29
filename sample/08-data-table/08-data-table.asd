(defsystem "08-data-table"
  :description "Data table sample application for cl-s3r"
  :depends-on ("cl-s3r" "cl-s3r.components.data-table")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "08-data-table/test"))))

(defsystem "08-data-table/test"
  :description "Tests for 08-data-table"
  :depends-on ("08-data-table" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
