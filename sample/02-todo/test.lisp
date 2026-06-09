(defpackage #:cl-s3r.sample.todo.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state))

(in-package #:cl-s3r.sample.todo.test)

(deftest test-todo
  (testing "initial state has empty todos and next-id 0"
    (let* ((result (test-render-component "todo" :args '()))
           (state (getf result :state)))
      (ok (null (test-get-state state :todos)))
      (ok (= 0 (test-get-state state :next-id)))))

  (testing "add-todo adds an item with correct title and id"
    (let* ((r1 (test-render-component "todo" :args '()))
           (r2 (test-call-action "todo" "add-todo"
                                 :state (getf r1 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "Buy milk")))))
      (let ((todos (test-get-state (getf r2 :state) :todos)))
        (ok (= 1 (length todos)))
        (ok (string= "Buy milk" (getf (first todos) :title)))
        (ok (= 0 (getf (first todos) :id)))
        (ok (null (getf (first todos) :done))))))

  (testing "add-todo with empty string does not add"
    (let* ((r1 (test-render-component "todo" :args '()))
           (r2 (test-call-action "todo" "add-todo"
                                 :state (getf r1 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "")))))
      (ok (null (test-get-state (getf r2 :state) :todos)))))

  (testing "toggle-done changes done flag to t"
    (let* ((r1 (test-render-component "todo" :args '()))
           (r2 (test-call-action "todo" "add-todo"
                                 :state (getf r1 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "Buy milk"))))
           (r3 (test-call-action "todo" "toggle-done"
                                 :state (getf r2 :state)
                                 :args '()
                                 :action-args '(0))))
      (ok (getf (first (test-get-state (getf r3 :state) :todos)) :done))))

  (testing "toggle-done twice restores done to nil"
    (let* ((r1 (test-render-component "todo" :args '()))
           (r2 (test-call-action "todo" "add-todo"
                                 :state (getf r1 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "Buy milk"))))
           (r3 (test-call-action "todo" "toggle-done"
                                 :state (getf r2 :state)
                                 :args '()
                                 :action-args '(0)))
           (r4 (test-call-action "todo" "toggle-done"
                                 :state (getf r3 :state)
                                 :args '()
                                 :action-args '(0))))
      (ok (null (getf (first (test-get-state (getf r4 :state) :todos)) :done)))))

  (testing "delete-todo removes item"
    (let* ((r1 (test-render-component "todo" :args '()))
           (r2 (test-call-action "todo" "add-todo"
                                 :state (getf r1 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "Buy milk"))))
           (r3 (test-call-action "todo" "delete-todo"
                                 :state (getf r2 :state)
                                 :args '()
                                 :action-args '(0))))
      (ok (null (test-get-state (getf r3 :state) :todos)))))

  (testing "next-id increments with each add"
    (let* ((r1 (test-render-component "todo" :args '()))
           (r2 (test-call-action "todo" "add-todo"
                                 :state (getf r1 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "First"))))
           (r3 (test-call-action "todo" "add-todo"
                                 :state (getf r2 :state)
                                 :args '()
                                 :action-args (list (list :|todo-text| "Second")))))
      (ok (= 2 (test-get-state (getf r3 :state) :next-id)))
      (let ((todos (test-get-state (getf r3 :state) :todos)))
        (ok (= 2 (length todos)))
        (ok (= 0 (getf (first todos) :id)))
        (ok (= 1 (getf (second todos) :id)))))))
