(defpackage #:cl-s3r.cookie
  (:use #:cl)
  (:export #:*current-cookies*
           #:*pending-cookie-changes*
           #:parse-cookies
           #:get-cookie
           #:get-cookie-from-env
           #:set-response-cookie
           #:delete-response-cookie
           #:format-set-cookie-header
           #:inject-set-cookie-headers))

(in-package #:cl-s3r.cookie)

(defvar *current-cookies* nil
  "Alist of (name . value) strings for cookies in the current request.")

(defvar *pending-cookie-changes* nil
  "List of cookie spec plists to emit as Set-Cookie headers in the current response.")

(defun split-by-char (str char)
  (loop for start = 0 then (1+ pos)
        for pos = (position char str :start start)
        collect (subseq str start pos)
        while pos))

(defun parse-cookies (cookie-header)
  "Parse 'name1=value1; name2=value2' into an alist of (name . value)."
  (when (and cookie-header (not (string= cookie-header "")))
    (loop for pair in (split-by-char cookie-header #\;)
          for trimmed = (string-trim '(#\Space) pair)
          for eq-pos = (position #\= trimmed)
          when eq-pos
          collect (cons (subseq trimmed 0 eq-pos)
                        (subseq trimmed (1+ eq-pos))))))

(defun get-cookie (name)
  "Return the value of cookie NAME from the current request, or nil if absent."
  (cdr (assoc name *current-cookies* :test #'string=)))

(defun get-cookie-from-env (env name)
  "Return the value of cookie NAME from the Clack ENV, or nil if absent."
  (let* ((headers (getf env :headers))
         (cookie-header (when headers (gethash "cookie" headers)))
         (cookies (parse-cookies cookie-header)))
    (cdr (assoc name cookies :test #'string=))))

(defun set-response-cookie (name value &key max-age (path "/") domain secure http-only same-site)
  "Queue a Set-Cookie header for the current response."
  (push (list :name name :value value
              :max-age max-age :path path
              :domain domain :secure secure
              :http-only http-only :same-site same-site)
        *pending-cookie-changes*))

(defun delete-response-cookie (name &key (path "/") domain)
  "Queue a cookie deletion by setting Max-Age=0."
  (push (list :name name :value "" :max-age 0 :path path :domain domain)
        *pending-cookie-changes*))

(defun format-set-cookie-header (spec)
  "Format a cookie spec plist into a Set-Cookie header value string."
  (let ((parts (list (format nil "~A=~A" (getf spec :name) (getf spec :value)))))
    (when (getf spec :max-age)
      (setf parts (append parts (list (format nil "Max-Age=~A" (getf spec :max-age))))))
    (when (getf spec :path)
      (setf parts (append parts (list (format nil "Path=~A" (getf spec :path))))))
    (when (getf spec :domain)
      (setf parts (append parts (list (format nil "Domain=~A" (getf spec :domain))))))
    (when (getf spec :secure)
      (setf parts (append parts (list "Secure"))))
    (when (getf spec :http-only)
      (setf parts (append parts (list "HttpOnly"))))
    (when (getf spec :same-site)
      (setf parts (append parts (list (format nil "SameSite=~A" (getf spec :same-site))))))
    (format nil "~{~A~^; ~}" parts)))

(defun inject-set-cookie-headers (response)
  "Add Set-Cookie headers from *pending-cookie-changes* to a Clack response tuple."
  (if (null *pending-cookie-changes*)
      response
      (destructuring-bind (status headers body) response
        (let ((cookie-headers
               (loop for spec in (reverse *pending-cookie-changes*)
                     nconc (list :set-cookie (format-set-cookie-header spec)))))
          `(,status ,(append headers cookie-headers) ,body)))))
