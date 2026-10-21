(defpackage #:cl-s3r.testing
  (:use #:cl)
  (:import-from #:alexandria
                #:make-keyword)
  (:import-from #:cl-s3r.component
                #:*component-registry*
                #:*current-component-state*
                #:*current-component-functions*
                #:*sync-component-state*
                #:*forced-component-id*
                #:*component-path*
                #:render-component-tree-html)
  (:export #:test-render-component
           #:test-call-action
           #:test-render-html
           #:test-get-state))

(in-package #:cl-s3r.testing)

(defun strip-component-metadata (sexp)
  "Remove the framework-injected attributes from the outermost (@ ...) list only."
  (if (and (listp sexp) (keywordp (car sexp)))
      (let* ((tag (car sexp))
             (rest (cdr sexp))
             (first-child (car rest))
             (body (cdr rest)))
        (if (and (listp first-child)
                 (symbolp (car first-child))
                 (string= (string (car first-child)) "@"))
            (let* ((attrs (cdr first-child))
                   (filtered (remove-if
                               (lambda (attr)
                                 (member (string-downcase (string (car attr)))
                                         '("data-state" "data-component" "data-component-id"
                                           "data-actions")
                                         :test #'string=))
                               attrs)))
              (if filtered
                  `(,tag (@ ,@filtered) ,@body)
                  `(,tag ,@body)))
            sexp))
      sexp))

(defun test-render-component (component-name &key args (initial-state nil))
  "Run component-name with ARGS (a keyword plist) under INITIAL-STATE.
Returns a plist with :SEXP (metadata stripped), :RAW-SEXP (as-is), and :STATE."
  (let* ((name-str (string-downcase (string component-name)))
         (comp-info (gethash name-str *component-registry*))
         (func-name (getf comp-info :name)))
    (unless func-name
      (error "cl-s3r.testing: component ~S not found" component-name))
    (let ((*current-component-state* (copy-list initial-state))
          (*current-component-functions* nil)
          (*sync-component-state* nil)
          (*component-path* (list "0"))
          (*forced-component-id* nil))
      (let ((raw-sexp (apply (symbol-function func-name) args)))
        (list :sexp     (strip-component-metadata raw-sexp)
              :raw-sexp raw-sexp
              :state    (copy-list *current-component-state*))))))

(defun test-call-action (component-name action-name &key state args action-args)
  "Execute ACTION-NAME on COMPONENT-NAME with the given STATE and ARGS (a keyword plist).
Uses a two-phase approach (dry-run + re-render) matching call-component-action.
Returns a plist with :SEXP (metadata stripped), :RAW-SEXP (as-is), and :STATE."
  (let* ((name-str (string-downcase (string component-name)))
         (comp-info (gethash name-str *component-registry*))
         (func-name (getf comp-info :name)))
    (unless func-name
      (error "cl-s3r.testing: component ~S not found" component-name))
    (let ((*current-component-state* (copy-list state))
          (*current-component-functions* nil)
          (*sync-component-state* nil)
          (*component-path* (list "0"))
          (*forced-component-id* nil))
      ;; Phase 1: dry-run with stored args to populate *current-component-functions*.
      ;; Passing args ensures closures inside let-function capture the correct prop values.
      (apply (symbol-function func-name) (or args nil))
      ;; Find and execute the action
      (let ((action-fn (cdr (assoc (string-downcase (string action-name))
                                   *current-component-functions*
                                   :test #'string=))))
        (unless action-fn
          (error "cl-s3r.testing: action ~S not found in ~S. Available: ~S"
                 action-name component-name
                 (mapcar #'car *current-component-functions*)))
        (apply action-fn action-args)
        (when *sync-component-state*
          (funcall *sync-component-state*)))
      ;; Phase 2: re-render with updated state, reset function registry
      (let ((*current-component-functions* nil)
            (*sync-component-state* nil))
        (let ((raw-sexp (apply (symbol-function func-name) args)))
          (list :sexp     (strip-component-metadata raw-sexp)
                :raw-sexp raw-sexp
                :state    (copy-list *current-component-state*)))))))

(defun test-render-html (component-name &key args state client-state
                                            path forced-id)
  "Render COMPONENT-NAME to an HTML string with nested components expanded.
ARGS is the prop plist and STATE the component's own state plist.
CLIENT-STATE stands in for the state the browser would have reported for nested
components: an alist of (component-id . state-plist), e.g.

  :client-state \'((\"counter-child-0.0\" . (:count 2)))

PATH is the component's position in the page -- a list of path segments,
defaulting to the root position -- and FORCED-ID overrides its component-id.
Pass both to reproduce the render pass the server performs when it re-renders a
single subtree in response to an action."
  (let ((table (when client-state
                 (let ((h (make-hash-table :test 'equal)))
                   (loop for (id . state-plist) in client-state
                         do (setf (gethash id h) state-plist))
                   h))))
    (render-component-tree-html component-name state args
                                :client-state-tree table
                                :component-path path
                                :forced-component-id forced-id)))

(defun test-get-state (state &optional key)
  "Return STATE plist or a specific KEY's value (case-insensitive)."
  (if key
      (getf state (if (keywordp key) key
                      (make-keyword (string-upcase (string key)))))
      state))
