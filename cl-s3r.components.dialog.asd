(defsystem "cl-s3r.components.dialog"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/dialog"
                :components ((:file "dialog"))))
  :in-order-to ((test-op (test-op "cl-s3r.components.dialog/test")))
  :description "Dialog UI component for cl-s3r")

(defsystem "cl-s3r.components.dialog/test"
  :description "Tests for cl-s3r.components.dialog"
  :depends-on ("cl-s3r.components.dialog" "rove")
  :components ((:module "src/components/dialog"
                :components ((:file "dialog_test"))))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
