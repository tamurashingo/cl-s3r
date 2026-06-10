(defsystem "04-login"
  :description "Login sample application for cl-s3r"
  :depends-on ("cl-s3r")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "04-login/test"))))

(defsystem "04-login/test"
  :description "Tests for 04-login"
  :depends-on ("04-login" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
