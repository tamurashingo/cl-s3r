(defsystem "cl-s3r.components.checkbox"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/checkbox"
                :components ((:file "checkbox"))))
  :in-order-to ((test-op (test-op "cl-s3r.components.checkbox/test")))
  :description "Checkbox UI component for cl-s3r")

(defsystem "cl-s3r.components.checkbox/test"
  :description "Tests for cl-s3r.components.checkbox"
  :depends-on ("cl-s3r.components.checkbox" "rove")
  :components ((:module "src/components/checkbox"
                :components ((:file "checkbox_test"))))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
