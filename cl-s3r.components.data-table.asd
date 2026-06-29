(defsystem "cl-s3r.components.data-table"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/data-table"
                :components ((:file "data-table"))))
  :in-order-to ((test-op (test-op "cl-s3r.components.data-table/test")))
  :description "Data table UI component for cl-s3r")

(defsystem "cl-s3r.components.data-table/test"
  :description "Tests for cl-s3r.components.data-table"
  :depends-on ("cl-s3r.components.data-table" "rove")
  :components ((:module "src/components/data-table"
                :components ((:file "data-table_test"))))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
