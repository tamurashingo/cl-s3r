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
           #:*component-render-counter*
           #:*forced-component-id*
           #:call-component-action
           #:render-component
           #:render-component-html
           #:render-layout-html
           #:normalize-state-keys
           #:define-layout
           #:define-metadata
           #:call-metadata
           #:http-error
           #:http-error-status-code
           #:http-error-params
           #:signal-http-error))

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
(defvar *component-render-counter* 0)
(defvar *forced-component-id* nil)

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
                  collect `(,var (let ((val (getf *current-component-state* (make-keyword (string ',var)))))
                                   (if (not (eq val nil)) val ,init-val))))
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
  (let ((component-name (string-downcase (string name))))
    `(progn
       (defun ,name ,args
         (let ((result (progn ,@body)))
           (if (and (listp result) (keywordp (car result)))
               (let* ((tag (car result))
                      (rest (cdr result))
                      (state-json (if *current-component-state*
                                      (jonathan:to-json *current-component-state*)
                                      "{}"))
                      (has-attrs (and (listp (car rest))
                                      (symbolp (caar rest))
                                      (string= (string (caar rest)) "@")))
                      (component-id
                       (or *forced-component-id*
                           (when has-attrs
                             (second (assoc "id" (cdar rest)
                                            :test (lambda (a b)
                                                    (string= a (string-downcase (string b)))))))
                           (format nil "~A-~A" ,component-name
                                   (incf *component-render-counter*)))))
                 (if has-attrs
                     `(,tag (@ (data-state ,state-json)
                               (data-component ,(string ,component-name))
                               (data-component-id ,component-id)
                               ,@(cdar rest))
                            ,@(cdr rest))
                     `(,tag (@ (data-state ,state-json)
                               (data-component ,(string ,component-name))
                               (data-component-id ,component-id))
                            ,@rest)))
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
                             &key forced-component-id)
  (let* ((comp-info (gethash (string-downcase (string component-name)) *component-registry*))
         (func-name (getf comp-info :name)))
    (if func-name
        (let ((*current-component-state* current-state)
              (*current-component-functions* nil)
              (*sync-component-state* nil))

          ;; Dry-run with no args to populate *current-component-functions* via let-function.
          ;; State is already in *current-component-state*; all keyword args default to nil.
          (labels ((run-comp ()
                     (funcall (symbol-function func-name))))

            ;; Run component to register action functions
            (run-comp)

            ;; Find and execute the action
            (let ((action-fn (cdr (assoc (string action-name)
                                        *current-component-functions*
                                        :test #'string-equal))))
              (if action-fn
                  (progn
                    (apply action-fn args)
                    (when *sync-component-state*
                      (funcall *sync-component-state*)))
                  (format t "Warning: Action ~A not found in component ~A (Available: ~S)~%"
                          action-name component-name (mapcar #'car *current-component-functions*))))

            ;; Re-render with updated state, preserving component ID
            (let ((final-html
                   (let ((*component-render-counter* 0)
                         (*forced-component-id* forced-component-id)
                         (*component-expander* #'expand-child-component))
                     (render-html (run-comp)))))
              (list :html final-html :state *current-component-state*))))
        (error "Component ~A not found" component-name))))

(defun render-component (name state &rest args)
  (let* ((comp-info (gethash (string-downcase (string name)) *component-registry*))
         (func-name (getf comp-info :name)))
    (if func-name
        (let ((*current-component-state* state))
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
For components: (tag (@ (key val) ...)) — props come from the @ attribute list.
For layouts: (tag (@ (key val) ...) body...) — @ props plus remaining sexps become :children."
  (let* ((has-attrs (and rest
                         (listp (car rest))
                         (symbolp (caar rest))
                         (string= (string (caar rest)) "@")))
         (attrs (when has-attrs (cdar rest)))
         (props-plist (loop for (k v) in attrs
                            append (list (make-keyword (string-upcase (string k))) v)))
         (comp-info (gethash (string-downcase (string tag)) *component-registry*))
         (layout-info (gethash (string-downcase (string tag)) *layout-registry*)))
    (cond
      (comp-info
       (let ((content-sexps (if has-attrs (cdr rest) rest)))
         (render-html (apply #'render-component tag nil
                             (if content-sexps
                                 (list* :children content-sexps props-plist)
                                 props-plist)))))
      (layout-info
       (let* ((content-sexps (if has-attrs (cdr rest) rest))
              (children (if (= (length content-sexps) 1)
                            (car content-sexps)
                            content-sexps))
              (layout-fn (symbol-function (getf layout-info :name))))
         (render-html (apply layout-fn :children children props-plist))))
      (t
       (error "Unknown component or layout: ~A" tag)))))

(defun render-component-html (name state &rest args)
  "Render a component to an HTML string, expanding nested component and layout calls."
  (let ((*component-render-counter* 0)
        (*forced-component-id* nil)
        (*component-expander* #'expand-child-component))
    (render-html (apply #'render-component name state args))))

(defun render-layout-html (name &rest args)
  "Render a layout to an HTML string, expanding nested component and layout calls.
NAME is a symbol naming a defined layout. ARGS are keyword arguments passed to the layout."
  (let* ((layout-info (gethash (string-downcase (string name)) *layout-registry*))
         (func-name (getf layout-info :name)))
    (if func-name
        (let ((*component-expander* #'expand-child-component))
          (render-html (apply (symbol-function func-name) args)))
        (error "Layout ~A not found" name))))

