(defsystem "02-todo"
  :description "Todo sample application for cl-s3r"
  :depends-on ("cl-s3r")
  :components ((:file "app"))
  :in-order-to ((test-op (test-op "02-todo/test"))))

(defsystem "02-todo/test"
  :description "Tests for 02-todo"
  :depends-on ("02-todo" "rove")
  :components ((:file "test"))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
