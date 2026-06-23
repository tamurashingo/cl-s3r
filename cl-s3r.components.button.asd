(defsystem "cl-s3r.components.button"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/button"
                :components ((:file "button"))))
  :description "Button UI component for cl-s3r")
