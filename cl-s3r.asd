(defsystem "cl-s3r"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("alexandria"
               "jonathan"
               "cl-json"
               "clack"
               "lack"
               "clack-handler-hunchentoot")
  :components ((:module "src"
                :components
                ((:file "renderer")
                 (:file "component")
                 (:file "testing")
                 (:file "server"))))
  :description "Server Side S-expression Renderer for Stateless Component-Driven Web Frontend")

