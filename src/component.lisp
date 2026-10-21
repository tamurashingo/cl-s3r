(defpackage #:cl-s3r.component
  (:use #:cl)
  (:import-from :alexandria
                #:make-keyword)
  (:import-from #:cl-s3r.renderer
                #:render-html
                #:*component-expander*)
  (:export #:define-component
           #:let-component-state
           #:let-function
           #:*component-registry*
           #:*layout-registry*
           #:*metadata-registry*
           #:*error-page-registry*
           #:*current-component-state*
           #:*current-component-functions*
           #:*sync-component-state*
           #:*forced-component-id*
           #:*component-path*
           #:*client-state-tree*
           #:*component-args-registry*
           #:call-component-action
           #:render-component
           #:render-component-html
           #:render-component-tree-html
           #:render-layout-html
           #:normalize-state-keys
           #:define-layout
           #:define-metadata
           #:call-metadata
           #:http-error
           #:http-error-status-code
           #:http-error-params
           #:signal-http-error
           #:action-not-found
           #:action-not-found-action
           #:action-not-found-component
           #:action-not-found-available))

(in-package #:cl-s3r.component)

;; Component registry (keyed by component name string)
(defvar *component-registry* (make-hash-table :test 'equal))

;; Layout registry (keyed by layout name string)
(defvar *layout-registry* (make-hash-table :test 'equal))

;; Metadata registry (keyed by component name string)
(defvar *metadata-registry* (make-hash-table :test 'equal))

;; Error page registry (keyed by HTTP status code integer)
(defvar *error-page-registry* (make-hash-table))

(define-condition http-error (error)
  ((status-code :initarg :status-code :reader http-error-status-code)
   (params :initarg :params :initform nil :reader http-error-params))
  (:report (lambda (c s)
             (format s "HTTP ~A" (http-error-status-code c)))))

(define-condition action-not-found (error)
  ((action :initarg :action :reader action-not-found-action)
   (component :initarg :component :reader action-not-found-component)
   (available :initarg :available :initform nil :reader action-not-found-available))
  (:report (lambda (c s)
             (format s "Action ~A not found in component ~A (available: ~S)"
                     (action-not-found-action c)
                     (action-not-found-component c)
                     (action-not-found-available c)))))

(defun signal-http-error (code &rest params)
  "Signal an HTTP error condition with STATUS-CODE and optional PARAMS keyword args.
PARAMS are passed as-is to the registered error page component."
  (error 'http-error :status-code code :params params))

(defmacro define-metadata (name args &body body)
  "Register a metadata-generating function for a component.
ARGS is a keyword-argument lambda list like (&key id title &allow-other-keys).
BODY returns a plist like (:title \"...\") or nil."
  (let ((component-name (string-downcase (string name))))
    `(setf (gethash ,component-name *metadata-registry*)
           (lambda ,args
             ,@body))))

(defun call-metadata (component-name props)
  "Call the metadata function for COMPONENT-NAME with PROPS (a plist).
Returns a plist like (:title \"...\") or nil if no metadata is registered."
  (let ((fn (gethash (string-downcase (string component-name)) *metadata-registry*)))
    (when fn
      (apply fn props))))

;; Execution context
(defvar *current-component-state* nil)
(defvar *current-component-functions* nil)
(defvar *sync-component-state* nil)

;; Component instance ID tracking
(defvar *forced-component-id* nil)

;; Position of the component currently being rendered, outermost segment first.
;; The root is ("0"), and a child's path is its parent's path plus its own
;; segment, so an instance keeps the same path -- and therefore the same
;; component-id -- whether the whole page or just one subtree is re-rendered.
(defvar *component-path* nil)

;; Mutable cell holding the next child segment number inside the component
;; currently being rendered. Bound afresh for every component, so numbering is
;; relative to the parent instead of global to the render pass.
(defvar *child-index* nil)

;; Hash of component-id -> state plist, collected from the DOM by cl-runtime.js
;; and handed over by handle-action. nil during an initial render, when the
;; browser has no state yet.
(defvar *client-state-tree* nil)

;; Sentinel to distinguish "key not in state" from "key is nil in state".
;; nil is a valid state value (e.g. open-items=nil means all items closed);
;; we must not fall back to init-val when the key is explicitly nil.
(defvar *state-unset-sentinel* (list 'unset))

;; Init-args registry: populated during an initial render pass.
;; *current-component-init-args* holds the keyword args passed to the
;; currently-executing component function.
;; *current-render-registry*    is a hash (component-id -> (:args ... :path ...))
;;   that accumulates entries for the whole render tree; bound to a fresh hash by
;;   handle-render, nil at all other times.
;; *component-args-registry*    is the global store (render-token -> registry hash).
(defvar *current-component-init-args* nil)
(defvar *current-render-registry* nil)
(defvar *component-args-registry* (make-hash-table :test 'equal))

(defun format-component-id (component-name path)
  "Build the component-id for COMPONENT-NAME at PATH, e.g. \"counter-child-0.1\"."
  (format nil "~A-~{~A~^.~}" component-name path))

(defun next-child-segment (key)
  "Return the path segment for the next child of the component being rendered.
KEY, when given, is used instead of the positional index, so that the segment
follows the child around when siblings are re-ordered, inserted or removed."
  (cond
    (key (format nil "k~A" key))
    (*child-index* (prog1 (princ-to-string (car *child-index*))
                     (incf (car *child-index*))))
    (t "0")))

(defun client-state-for (component-id)
  "Return the state the browser reported for COMPONENT-ID, or nil."
  (when (and *client-state-tree* component-id)
    (gethash component-id *client-state-tree*)))

(defmacro let-function (definitions &body body)
  "Define local functions like flet, and register them in *current-component-functions*
   so they can be invoked by action name from the client."
  `(flet ,definitions
     (declare (ignorable ,@(loop for (name . nil) in definitions
                                 collect `#',name)))
     ,@(loop for (name args . func-body) in definitions
             collect `(push (cons (string-downcase (string ',name))
                                  (lambda ,args ,@func-body))
                            *current-component-functions*))
     ,@body))

(defmacro let-component-state (bindings &body body)
  (let ((vars (mapcar #'car bindings)))
    `(let* ,(loop for (var init-val) in bindings
                  collect `(,var (let ((val (getf *current-component-state*
                                                   (make-keyword (string ',var))
                                                   *state-unset-sentinel*)))
                                   (if (eq val *state-unset-sentinel*) ,init-val val))))
       ;; Initial state setup
       (unless *current-component-state* (setf *current-component-state* nil))
       ,@(loop for var in vars
               collect `(setf (getf *current-component-state* (make-keyword (string ',var))) ,var))

       (setf *sync-component-state*
             (lambda ()
               ,@(loop for var in vars
                       collect `(setf (getf *current-component-state* (make-keyword (string ',var))) ,var))))

       (multiple-value-prog1
           (progn ,@body)
         ;; Sync values back after execution
         ,@(loop for var in vars
                 collect `(setf (getf *current-component-state* (make-keyword (string ',var))) ,var))))))

(defmacro define-component (name args &body body)
  (let ((component-name (string-downcase (string name)))
        (mark (gensym "ACTION-MARK"))
        (own (gensym "OWN-ACTIONS")))
    `(progn
       (defun ,name ,args
         ;; MARK records where *current-component-functions* stood before the body
         ;; ran, so the functions this component registered -- and only those -- can
         ;; be advertised in data-actions for the client to route actions by.
         (let* ((,mark *current-component-functions*)
                (result (progn ,@body))
                (,own (remove-duplicates
                       (mapcar #'car (ldiff *current-component-functions* ,mark))
                       :test #'string= :from-end t)))
           (if (and (listp result) (keywordp (car result)))
               (let* ((tag (car result))
                      (rest (cdr result))
                      (state-json (if *current-component-state*
                                      (jonathan:to-json *current-component-state*)
                                      "{}"))
                      (has-attrs (and (listp (car rest))
                                      (symbolp (caar rest))
                                      (string= (string (caar rest)) "@")))
                      (path (or *component-path* (list "0")))
                      (component-id
                       (or (when *forced-component-id*
                             (prog1 *forced-component-id*
                               ;; Consume once: *forced-component-id* must only apply to
                               ;; the single target component of this render pass, not to
                               ;; every nested child component encountered afterward.
                               (setf *forced-component-id* nil)))
                           (when has-attrs
                             (second (assoc "id" (cdar rest)
                                            :test (lambda (a b)
                                                    (string= a (string-downcase (string b)))))))
                           (format-component-id ,component-name path))))
                 ;; Register this instance's init-args and tree position so that
                 ;; call-component-action can re-invoke it with the same args and
                 ;; re-render its subtree under the same paths.
                 (when *current-render-registry*
                   (setf (gethash component-id *current-render-registry*)
                         (list :args *current-component-init-args* :path path)))
                 (let ((actions-attr
                        (when ,own
                          `((data-actions ,(format nil "~{~A~^ ~}" ,own))))))
                   (if has-attrs
                       `(,tag (@ (data-state ,state-json)
                                 (data-component ,(string ,component-name))
                                 (data-component-id ,component-id)
                                 ,@actions-attr
                                 ,@(cdar rest))
                              ,@(cdr rest))
                       `(,tag (@ (data-state ,state-json)
                                 (data-component ,(string ,component-name))
                                 (data-component-id ,component-id)
                                 ,@actions-attr)
                              ,@rest))))
               result)))

       (setf (gethash ,component-name *component-registry*)
             (list :name ',name :args ',args)))))

(defmacro define-layout (name args &body body)
  "Define a stateless layout function.
ARGS should be a keyword lambda list like (&key children &allow-other-keys).
Unlike define-component, layouts do not inject data-state or data-component attributes.
Layouts can receive :children as a keyword arg and may call other layouts by symbol name."
  (let ((layout-name (string-downcase (string name))))
    `(progn
       (defun ,name ,args
         ,@body)
       (setf (gethash ,layout-name *layout-registry*)
             (list :name ',name :args ',args)))))

(defun call-component-action (component-name action-name args current-state
                             &key forced-component-id component-init-args
                                  component-path client-state-tree)
  (let* ((comp-info (gethash (string-downcase (string component-name)) *component-registry*))
         (func-name (getf comp-info :name)))
    (if func-name
        (let ((*current-component-state* current-state)
              (*current-component-functions* nil)
              (*sync-component-state* nil)
              ;; render-component binds this for nested children (via expand-child-component),
              ;; but the top-level action target is invoked directly via run-comp below, bypassing
              ;; render-component -- without this, *current-render-registry* would capture nil
              ;; instead of component-init-args when re-registering this component's own id,
              ;; corrupting the registry for the component's *next* action dispatch.
              (*current-component-init-args* component-init-args))

          ;; Dry-run to populate *current-component-functions* via let-function.
          ;; Pass the stored init-args so that non-state props (items, mode, etc.)
          ;; are available and closures capture the correct values.
          (labels ((run-comp ()
                     (apply (symbol-function func-name)
                            (or component-init-args nil))))

            ;; Run component to register action functions
            (run-comp)

            ;; Find and execute the action
            (let ((action-fn (cdr (assoc (string action-name)
                                        *current-component-functions*
                                        :test #'string-equal))))
              (unless action-fn
                ;; Signalled rather than logged: a dropped action used to look like a
                ;; successful request to the browser, which made a mis-routed callback
                ;; invisible. handle-action turns this into an error response.
                (error 'action-not-found
                       :action action-name
                       :component component-name
                       :available (mapcar #'car *current-component-functions*)))
              (apply action-fn args)
              (when *sync-component-state*
                (funcall *sync-component-state*)))

            ;; Re-render with updated state, preserving component ID.
            ;; COMPONENT-PATH is this instance's position in the page, replayed from
            ;; the registry, so every nested child below it is numbered exactly as it
            ;; was during the full-page render and keeps the component-id the browser
            ;; already holds. CLIENT-STATE-TREE lets those children pick their own
            ;; state back up instead of restarting from their props.
            (let* ((fresh-registry (make-hash-table :test 'equal))
                   (final-html
                    (let ((*component-path* (or component-path (list "0")))
                          (*child-index* (list 0))
                          (*client-state-tree* client-state-tree)
                          (*forced-component-id* forced-component-id)
                          (*current-render-registry* fresh-registry)
                          (*component-expander* #'expand-child-component))
                      (render-html (run-comp)))))
              (list :html final-html :state *current-component-state* :registry fresh-registry))))
        (error "Component ~A not found" component-name))))

(defun render-component (name state &rest args)
  (let* ((comp-info (gethash (string-downcase (string name)) *component-registry*))
         (func-name (getf comp-info :name)))
    (if func-name
        (let ((*current-component-state* state)
              (*current-component-init-args* args))
          (apply (symbol-function func-name) args))
        (error "Component ~A not found" name))))

(defun normalize-state-keys (value)
  "Recursively convert jonathan-parsed :|key| keywords to :KEY style."
  (cond
    ((null value) nil)
    ((and (listp value) (keywordp (car value)))
     (loop for (k v) on value by #'cddr
           append (list (make-keyword (string-upcase (string k)))
                        (normalize-state-keys v))))
    ((listp value) (mapcar #'normalize-state-keys value))
    (t value)))

(defun expand-child-component (tag rest)
  "Expand a child component or layout S-expression call into an HTML string.
For components: (tag (@ (prop val) ...)) — props come from the @ attribute list.
For layouts: (tag (@ (prop val) ...) body...) — @ props plus remaining sexps become :children.
A `key` prop is used as this child's path segment instead of its position, so a
keyed child keeps its component-id when siblings are re-ordered or removed."
  (let* ((has-attrs (and rest
                         (listp (car rest))
                         (symbolp (caar rest))
                         (string= (string (caar rest)) "@")))
         (attrs (when has-attrs (cdar rest)))
         (props-plist (loop for (k v) in attrs
                            append (list (make-keyword (string-upcase (string k))) v)))
         (comp-info (gethash (string-downcase (string tag)) *component-registry*))
         (layout-info (gethash (string-downcase (string tag)) *layout-registry*))
         ;; Position of this child inside its parent. Consumed for layouts too,
         ;; so that the numbering does not depend on what kind of call a sibling
         ;; happens to be.
         (path (append *component-path* (list (next-child-segment (getf props-plist :KEY))))))
    (cond
      (comp-info
       (let* ((content-sexps (if has-attrs (cdr rest) rest))
              (child-id (format-component-id (string-downcase (string tag)) path))
              ;; Restore the state the browser reported for this instance. nil on
              ;; an initial render, and nil whenever the instance is new, in which
              ;; case let-component-state falls back to its initial values.
              (child-state (client-state-for child-id))
              (*component-path* path)
              (*child-index* (list 0)))
         (render-html (apply #'render-component tag child-state
                             (if content-sexps
                                 (list* :children content-sexps props-plist)
                                 props-plist)))))
      (layout-info
       (let* ((content-sexps (if has-attrs (cdr rest) rest))
              (children (if (= (length content-sexps) 1)
                            (car content-sexps)
                            content-sexps))
              (layout-fn (symbol-function (getf layout-info :name)))
              (*component-path* path)
              (*child-index* (list 0)))
         (render-html (apply layout-fn :children children props-plist))))
      (t
       (error "Unknown component or layout: ~A" tag)))))

(defun render-component-tree-html (name state args
                                   &key client-state-tree component-path
                                        forced-component-id)
  "Render NAME to an HTML string, expanding nested component and layout calls.
STATE is the component's own state and ARGS its props, as a plist.
CLIENT-STATE-TREE, when given, is a hash of component-id -> state plist that
nested components restore their state from. COMPONENT-PATH places the component
in the page (the root position by default) and FORCED-COMPONENT-ID overrides its
component-id -- together they let a caller reproduce the render pass the server
performs for a single subtree."
  (let ((*component-path* (or component-path (list "0")))
        (*child-index* (list 0))
        (*client-state-tree* (or client-state-tree *client-state-tree*))
        (*forced-component-id* forced-component-id)
        (*component-expander* #'expand-child-component))
    (render-html (apply #'render-component name state args))))

(defun render-component-html (name state &rest args)
  "Render a component to an HTML string, expanding nested component and layout calls.
If *current-render-registry* is bound to a hash by the caller (e.g. handle-render),
each component's init-args are registered in it keyed by component-id."
  (render-component-tree-html name state args))

(defun render-layout-html (name &rest args)
  "Render a layout to an HTML string, expanding nested component and layout calls.
NAME is a symbol naming a defined layout. ARGS are keyword arguments passed to the layout."
  (let* ((layout-info (gethash (string-downcase (string name)) *layout-registry*))
         (func-name (getf layout-info :name)))
    (if func-name
        (let ((*component-path* (list "0"))
              (*child-index* (list 0))
              (*component-expander* #'expand-child-component))
          (render-html (apply (symbol-function func-name) args)))
        (error "Layout ~A not found" name))))
