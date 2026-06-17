(defpackage #:cl-s3r.session
  (:use #:cl)
  (:import-from #:cl-s3r.cookie
                #:get-cookie
                #:set-response-cookie
                #:delete-response-cookie)
  (:import-from #:cl-s3r.config
                #:getenv)
  (:export #:*session-cookie-name*
           #:*session-secret*
           #:*session-timeout*
           #:set-session-store-handler
           #:get-session
           #:set-session
           #:destroy-session
           ;; test utilities
           #:create-session-for-test
           #:reset-session-store!))

(in-package #:cl-s3r.session)

;;;; Configurable variables

(defvar *session-cookie-name* "cl-s3r-sid"
  "Name of the cookie used to store the signed session ID.")

(defvar *session-secret* nil
  "HMAC secret key (string). If nil, initialized lazily from the SESSION_SECRET environment
variable, or a random value is generated with a warning (development only).")

(defvar *session-timeout* 3600
  "Session lifetime in seconds from creation time. get-session returns nil after this.")

;;;; In-memory session store

(defvar *session-store* (make-hash-table :test 'equal)
  "Default in-memory session store: session-id -> (:data plist :created-at universal-time).")

(defvar *session-store-lock* (bt:make-lock "cl-s3r-session-store")
  "Mutex protecting the default in-memory session store.")

;;;; Pluggable store handler variables

(defvar *session-get-handler*
  (lambda (session-id)
    (bt:with-lock-held (*session-store-lock*)
      (gethash session-id *session-store*)))
  "Function (session-id) => record-plist-or-nil.")

(defvar *session-set-handler*
  (lambda (session-id record)
    (bt:with-lock-held (*session-store-lock*)
      (setf (gethash session-id *session-store*) record)))
  "Function (session-id record-plist) that stores the session record.")

(defvar *session-delete-handler*
  (lambda (session-id)
    (bt:with-lock-held (*session-store-lock*)
      (remhash session-id *session-store*)))
  "Function (session-id) that removes the session record.")

(defun set-session-store-handler (&key get-handler set-handler delete-handler)
  "Replace one or more session store handlers with custom implementations.
GET-HANDLER: (session-id) => (:data plist :created-at timestamp) or nil
SET-HANDLER: (session-id record) => stores the record
DELETE-HANDLER: (session-id) => removes the record"
  (when get-handler (setf *session-get-handler* get-handler))
  (when set-handler (setf *session-set-handler* set-handler))
  (when delete-handler (setf *session-delete-handler* delete-handler)))

;;;; Secret key initialization

(defun ensure-session-secret ()
  "Return *session-secret*, initializing it from SESSION_SECRET env var or a random value."
  (or *session-secret*
      (let ((env (getenv "SESSION_SECRET")))
        (setf *session-secret*
              (if (and env (not (string= env "")))
                  env
                  (progn
                    (warn "SESSION_SECRET not set; using a random HMAC secret. ~
Sessions will be invalidated on server restart.")
                    (ironclad:byte-array-to-hex-string
                     (ironclad:random-data 32))))))))

;;;; Cryptographic helpers

(defun compute-hmac (secret session-id)
  "Compute HMAC-SHA256 of SESSION-ID keyed with SECRET. Returns a hex string."
  (let* ((key-bytes (babel:string-to-octets secret :encoding :utf-8))
         (data-bytes (babel:string-to-octets session-id :encoding :ascii))
         (hmac (ironclad:make-hmac key-bytes :sha256)))
    (ironclad:update-hmac hmac data-bytes)
    (ironclad:byte-array-to-hex-string (ironclad:produce-mac hmac))))

(defun constant-time-string= (a b)
  "Compare A and B in constant time to prevent timing attacks."
  (let ((la (length a))
        (lb (length b)))
    (let ((diff (logxor la lb)))
      (dotimes (i (max la lb))
        (let ((ca (if (< i la) (char-code (char a i)) 0))
              (cb (if (< i lb) (char-code (char b i)) 0)))
          (setf diff (logior diff (logxor ca cb)))))
      (= diff 0))))

(defun generate-session-id ()
  "Generate a cryptographically random session ID (32 hex characters)."
  (ironclad:byte-array-to-hex-string (ironclad:random-data 16)))

(defun make-signed-cookie-value (session-id)
  "Return 'session-id.hmac' signed with the current secret."
  (let ((mac (compute-hmac (ensure-session-secret) session-id)))
    (format nil "~A.~A" session-id mac)))

(defun parse-signed-cookie-value (value)
  "Return (values session-id hmac) from 'session-id.hmac', or (values nil nil) on error."
  (let ((dot-pos (position #\. value :from-end t)))
    (if dot-pos
        (values (subseq value 0 dot-pos)
                (subseq value (1+ dot-pos)))
        (values nil nil))))

(defun verify-signed-cookie (cookie-value)
  "Return the session-id if COOKIE-VALUE has a valid HMAC, or nil if invalid/missing."
  (when (and cookie-value (not (string= cookie-value "")))
    (multiple-value-bind (session-id mac)
        (parse-signed-cookie-value cookie-value)
      (when (and session-id mac)
        (let ((expected (compute-hmac (ensure-session-secret) session-id)))
          (when (constant-time-string= expected mac)
            session-id))))))

;;;; Plist utilities

(defun merge-plists (base updates)
  "Return a copy of BASE with entries from UPDATES added or overwritten."
  (let ((result (copy-list base)))
    (loop for (key value) on updates by #'cddr
          do (setf (getf result key) value))
    result))

;;;; Public session API

(defun get-session (&rest keys)
  "Return a plist of KEYS from the current session.
Missing or expired sessions return nil for every key."
  (let* ((cookie-value (get-cookie *session-cookie-name*))
         (session-id (verify-signed-cookie cookie-value))
         (record (when session-id (funcall *session-get-handler* session-id))))
    (if (null record)
        (mapcan (lambda (k) (list k nil)) keys)
        (let* ((created-at (getf record :created-at))
               (now (get-universal-time)))
          (if (and created-at (> (- now created-at) *session-timeout*))
              (progn
                (funcall *session-delete-handler* session-id)
                (delete-response-cookie *session-cookie-name* :path "/")
                (mapcan (lambda (k) (list k nil)) keys))
              (let ((data (getf record :data)))
                (mapcan (lambda (k) (list k (getf data k))) keys)))))))

(defun set-session (data)
  "Store DATA (a plist) into the current session. Creates a new session when none exists."
  (let* ((cookie-value (get-cookie *session-cookie-name*))
         (existing-id (verify-signed-cookie cookie-value))
         (existing-record (when existing-id
                            (funcall *session-get-handler* existing-id)))
         ;; Treat expired sessions as absent
         (existing-record (when existing-record
                            (let* ((created-at (getf existing-record :created-at))
                                   (now (get-universal-time)))
                              (when (or (null created-at)
                                        (<= (- now created-at) *session-timeout*))
                                existing-record)))))
    (let* ((session-id (or (and existing-record existing-id)
                           (generate-session-id)))
           (created-at (or (and existing-record (getf existing-record :created-at))
                           (get-universal-time)))
           (merged-data (if existing-record
                            (merge-plists (getf existing-record :data) data)
                            data)))
      (funcall *session-set-handler* session-id
               (list :data merged-data :created-at created-at))
      ;; Set the cookie only when creating a new session
      (unless (and existing-record existing-id)
        (set-response-cookie *session-cookie-name*
                             (make-signed-cookie-value session-id)
                             :http-only t :path "/")))))

(defun destroy-session ()
  "Remove the current session from the store and delete the session cookie."
  (let* ((cookie-value (get-cookie *session-cookie-name*))
         (session-id (verify-signed-cookie cookie-value)))
    (when session-id
      (funcall *session-delete-handler* session-id))
    (delete-response-cookie *session-cookie-name* :path "/")))

;;;; Test utilities

(defun create-session-for-test (data)
  "Create a session with DATA for testing. Returns a (name . value) pair for *current-cookies*."
  (let ((session-id (generate-session-id)))
    (funcall *session-set-handler* session-id
             (list :data data :created-at (get-universal-time)))
    (cons *session-cookie-name* (make-signed-cookie-value session-id))))

(defun reset-session-store! ()
  "Clear all sessions from the default in-memory store. For use in tests only."
  (bt:with-lock-held (*session-store-lock*)
    (clrhash *session-store*)))
