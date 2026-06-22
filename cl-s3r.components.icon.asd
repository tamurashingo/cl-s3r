(defsystem "cl-s3r.components.icon"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/icon"
                :components ((:file "util")
                             (:file "fa-address-book" :depends-on ("util"))
                             (:file "icon" :depends-on ("util" "fa-address-book")))))
  :description "Icon component (Font Awesome SVG) for cl-s3r")
