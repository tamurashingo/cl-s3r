(defsystem "cl-s3r"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("alexandria"
               "jonathan"
               "cl-json"
               "clack"
               "lack"
               "lack/middleware/static"
               "clack-handler-hunchentoot"
               "ironclad"
               "babel"
               "bordeaux-threads")
  :components ((:module "src"
                :components
                ((:file "renderer")
                 (:file "component")
                 (:file "testing")
                 (:file "cookie")
                 (:file "config")
                 (:file "session")
                 (:file "fetch")
                 (:file "server"))))
  :in-order-to ((test-op (test-op "cl-s3r/test")))
  :description "Server Side S-expression Renderer for Stateless Component-Driven Web Frontend")

(defsystem "cl-s3r/test"
  :description "Tests for the cl-s3r core"
  :depends-on ("cl-s3r" "rove")
  :components ((:module "test"
                :components ((:file "fetch")
                             (:file "actions"))))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))

