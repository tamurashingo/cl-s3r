(defsystem "cl-s3r.components.badge"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/badge"
                :components ((:file "badge"))))
  :description "Badge UI component for cl-s3r")
