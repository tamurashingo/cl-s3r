(defpackage #:cl-s3r.fetch
  (:use #:cl)
  (:export #:define-fetcher
           #:invalidate-fetch
           #:with-fetch-scope
           #:*default-fetch-timeout*
           #:*fetch-scope*
           #:fetch-failed
           #:fetch-failed-fetcher
           #:fetch-failed-cause))

(in-package #:cl-s3r.fetch)

;;; Data fetching happens inside the render: a component's body calls a fetcher
;;; the way it would call any function. That keeps the server free of per-client
;;; state -- nothing about the page is remembered between requests -- at the cost
;;; of the same fetch being reachable several times in one render, and of being
;;; re-run when an action re-renders. The scope below absorbs the first; a
;;; fetcher is called at most once per key per request.

(defvar *fetch-scope* nil
  "Hash of (fetcher-name . args) -> value for the request in flight, or NIL when
there is none. Bound once per HTTP request, so a fetcher reached from several
components during one render goes out once and every component sees the same
snapshot. With no scope bound (unit tests, the REPL) every call goes through.")

(defvar *default-fetch-timeout* 10
  "Seconds a fetcher may take before it is treated as failed. NIL waits forever.")

(define-condition fetch-failed (error)
  ((fetcher :initarg :fetcher :reader fetch-failed-fetcher)
   (cause :initarg :cause :initform nil :reader fetch-failed-cause))
  (:report (lambda (c s)
             (format s "Fetcher ~A failed: ~A"
                     (fetch-failed-fetcher c)
                     (fetch-failed-cause c)))))

(defmacro with-fetch-scope (&body body)
  "Run BODY with a fresh memo table for fetchers. The server wraps each request
in one; wrap a test in one to assert on how often a fetcher is reached."
  `(let ((*fetch-scope* (make-hash-table :test 'equal)))
     ,@body))

(defun fetch-key (name args)
  (cons (string (if (symbolp name) name (string name))) args))

(defun run-fetch (name timeout on-error thunk)
  "Call THUNK under TIMEOUT, turning a failure into ON-ERROR's answer."
  (flet ((fail (cause)
           (ecase on-error
             (:signal (error 'fetch-failed :fetcher name :cause cause))
             (:nil nil))))
    (handler-case
        (if timeout
            (bt:with-timeout (timeout) (funcall thunk))
            (funcall thunk))
      ;; bt:timeout is a serious-condition rather than an error, so it needs its
      ;; own clause: a slow API must not hang the render.
      (bt:timeout () (fail (format nil "timed out after ~A s" timeout)))
      (error (e) (fail e)))))

(defun fetch-memoized (name args timeout on-error thunk)
  "Return the value for NAME called with ARGS, reaching THUNK once per request."
  (if (null *fetch-scope*)
      (run-fetch name timeout on-error thunk)
      (let ((key (fetch-key name args)))
        (multiple-value-bind (value found) (gethash key *fetch-scope*)
          (if found
              value
              (setf (gethash key *fetch-scope*)
                    (run-fetch name timeout on-error thunk)))))))

(defmacro define-fetcher (name-and-options lambda-list &body body)
  "Define a data-fetch function that is called at most once per request per
argument list.

NAME-AND-OPTIONS is a symbol, or (name . options):

  :timeout   seconds before the call is treated as failed
             (default *default-fetch-timeout*; NIL waits forever)
  :on-error  :signal (default) to raise CL-S3R.FETCH:FETCH-FAILED, which the
             server answers with 502, or :nil to return NIL and let the
             component decide what to render

Call it like any function from a component body. Results are memoised on the
arguments compared with EQUAL, so pass plain data; after writing through to the
API, call INVALIDATE-FETCH so the next read goes out again."
  (let* ((name (if (consp name-and-options) (first name-and-options) name-and-options))
         (options (if (consp name-and-options) (rest name-and-options) nil))
         (timeout (if (member :timeout options)
                      (getf options :timeout)
                      '*default-fetch-timeout*))
         (on-error (getf options :on-error :signal))
         (args (gensym "ARGS")))
    `(defun ,name (&rest ,args)
       (labels ((fetch-body ,lambda-list ,@body))
         (fetch-memoized ',name ,args ,timeout ,on-error
                         (lambda () (apply #'fetch-body ,args)))))))

(defun invalidate-fetch (&optional name &rest args)
  "Forget memoised results so the next call goes out to the API again.

With no arguments, forgets everything fetched during this request; with NAME,
every result of that fetcher; with NAME and ARGS, exactly that call. Call it
right where you write, so a re-render after the write reads fresh data:

  (let-function ((add-user (form-data)
                   (post-user form-data)
                   (invalidate-fetch 'fetch-users))))"
  (when *fetch-scope*
    (cond
      ((null name) (clrhash *fetch-scope*))
      (args (remhash (fetch-key name args) *fetch-scope*))
      (t (let ((wanted (car (fetch-key name nil))))
           (loop for key being the hash-keys of *fetch-scope*
                 when (string= (car key) wanted)
                   do (remhash key *fetch-scope*)))))))
