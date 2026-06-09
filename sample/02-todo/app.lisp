(ql:quickload :cl-s3r)

(defpackage #:cl-s3r.sample.todo
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-mount
                #:start-server)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function)
  (:export #:run))

(in-package #:cl-s3r.sample.todo)

;; todo-item: stateless — receives id/title/done/on-toggle/on-delete as props
(define-component todo-item (id title done on-toggle on-delete)
  `(:li (@ (data-id ,id))
     (:input (@ (type "checkbox")
                ,@(when done '((checked "checked")))
                (onclick ,on-toggle)))
     (:span ,title)
     (:button (@ (onclick ,on-delete)) "Delete")))

;; todo-list: stateless — receives todos list and callback templates
;; on-toggle = (TOGGLE-DONE), on-delete = (DELETE-TODO)
;; appends item id to construct per-item callbacks like (TOGGLE-DONE 1)
(define-component todo-list (todos on-toggle on-delete)
  `(:ul
     ,@(loop for todo in todos
             collect `(todo-item
                        (@ (id ,(getf todo :id))
                           (title ,(getf todo :title))
                           (done ,(getf todo :done))
                           (on-toggle ,(append on-toggle (list (getf todo :id))))
                           (on-delete ,(append on-delete (list (getf todo :id)))))))))

;; todo-input: stateless — receives on-add callback and renders an input form
(define-component todo-input (on-add)
  `(:form (@ (onsubmit ,on-add))
     (:input (@ (type "text") (name "todo-text") (placeholder "New todo...")))
     (:button (@ (type "submit")) "Add")))

;; todo: root component — owns the full todo list state
(define-component todo ()
  (let-component-state ((todos '()) (next-id 0))
    (let-function
        ((add-todo (form-data)
           (let ((title (getf form-data :|todo-text|)))
             (when (and title (not (string= title "")))
               (setf todos (append todos
                                   (list (list :id next-id :title title :done nil))))
               (incf next-id))))
         (toggle-done (id)
           (setf todos (mapcar (lambda (item)
                                 (if (= (getf item :id) id)
                                     (list :id id
                                           :title (getf item :title)
                                           :done (not (getf item :done)))
                                     item))
                               todos)))
         (delete-todo (id)
           (setf todos (remove-if (lambda (item) (= (getf item :id) id)) todos))))
      `(:div
         (:h1 "Todo App")
         (todo-input (@ (on-add (add-todo))))
         (todo-list (@ (todos ,todos)
                       (on-toggle (toggle-done))
                       (on-delete (delete-todo))))))))

(configure-mount :target "#root"
                 :component "todo"
                 :props '()
                 :static-root (asdf:system-relative-pathname
                               :cl-s3r "sample/02-todo/"))

(defun run ()
  (let ((port (parse-integer (or (uiop:getenv "PORT") "5000"))))
    (format t "Starting Todo Sample App on port ~A...~%" port)
    (start-server :port port)
    (loop (sleep 1000))))
