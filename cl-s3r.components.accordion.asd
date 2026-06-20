(defsystem "cl-s3r.components.accordion"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/accordion"
                :components ((:file "accordion"))))
  :in-order-to ((test-op (test-op "cl-s3r.components.accordion/test")))
  :description "Accordion UI component for cl-s3r")

(defsystem "cl-s3r.components.accordion/test"
  :description "Tests for cl-s3r.components.accordion"
  :depends-on ("cl-s3r.components.accordion" "rove")
  :components ((:module "src/components/accordion"
                :components ((:file "accordion_test"))))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
