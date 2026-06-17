(defpackage #:cl-s3r.sample.todo
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function))

(in-package #:cl-s3r.sample.todo)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "cl-s3r Todo"))
     (:body
       ,children)))

(configure-default-layout 'app-layout)

;; todo-item: stateless — receives id/title/done/on-toggle/on-delete as props
(define-component todo-item (&key id title done on-toggle on-delete &allow-other-keys)
  `(:li (@ (data-id ,id))
     (:input (@ (type "checkbox")
                ,@(when done '((checked "checked")))
                (onclick ,on-toggle)))
     (:span ,title)
     (:button (@ (onclick ,on-delete)) "Delete")))

;; todo-list: stateless — receives todos list and callback templates
;; on-toggle = (TOGGLE-DONE), on-delete = (DELETE-TODO)
;; appends item id to construct per-item callbacks like (TOGGLE-DONE 1)
(define-component todo-list (&key todos on-toggle on-delete &allow-other-keys)
  `(:ul
     ,@(loop for todo in todos
             collect `(todo-item
                        (@ (id ,(getf todo :id))
                           (title ,(getf todo :title))
                           (done ,(getf todo :done))
                           (on-toggle ,(append on-toggle (list (getf todo :id))))
                           (on-delete ,(append on-delete (list (getf todo :id)))))))))

;; todo-input: stateless — receives on-add callback and renders an input form
(define-component todo-input (&key on-add &allow-other-keys)
  `(:form (@ (onsubmit ,on-add))
     (:input (@ (type "text") (name "todo-text") (placeholder "New todo...")))
     (:button (@ (type "submit")) "Add")))

;; todo: root component — owns the full todo list state
(define-component todo (&key &allow-other-keys)
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

(configure-route :path "/"
                 :component "todo"
                 :props '())
