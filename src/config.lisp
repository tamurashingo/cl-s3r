(defpackage #:cl-s3r.config
  (:use #:cl)
  (:export #:load-dotenv
           #:getenv
           #:getenv-integer
           #:getenv-boolean
           ;; exposed for testing (rebind with let to isolate tests)
           #:*dotenv-store*
           #:load-dotenv-file))

(in-package #:cl-s3r.config)

(defvar *dotenv-store* (make-hash-table :test 'equal)
  "Key-value pairs loaded from .env files. OS environment variables take precedence.")

(defun unquote-value (s)
  "Strip a matching pair of surrounding single or double quotes from S."
  (let ((len (length s)))
    (if (and (>= len 2)
             (or (and (char= (char s 0) #\") (char= (char s (1- len)) #\"))
                 (and (char= (char s 0) #\') (char= (char s (1- len)) #\'))))
        (subseq s 1 (1- len))
        s)))

(defun parse-dotenv-line (line)
  "Parse one line of a .env file. Returns (values key value) or (values nil nil).
Lines starting with # and lines without '=' are ignored."
  (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
    (if (or (= (length trimmed) 0)
            (char= (char trimmed 0) #\#))
        (values nil nil)
        (let ((eq-pos (position #\= trimmed)))
          (if (null eq-pos)
              (values nil nil)
              (let ((key (string-trim '(#\Space #\Tab) (subseq trimmed 0 eq-pos)))
                    (raw (string-trim '(#\Space #\Tab) (subseq trimmed (1+ eq-pos)))))
                (if (= (length key) 0)
                    (values nil nil)
                    (values key (unquote-value raw)))))))))

(defun load-dotenv-file (path)
  "Load all KEY=VALUE pairs from PATH into *dotenv-store*.
Silently skips missing files."
  (when (probe-file path)
    (with-open-file (stream path :direction :input)
      (loop for line = (read-line stream nil nil)
            while line
            do (multiple-value-bind (key value)
                   (parse-dotenv-line line)
                 (when key
                   (setf (gethash key *dotenv-store*) value)))))))

(defun load-dotenv (&key dir env-name)
  "Load .env files from DIR (defaults to *default-pathname-defaults*).

Files are loaded in this order, with later files overriding earlier ones:
  1. .env          -- shared base settings
  2. .env.<env>    -- environment-specific settings (when env-name is set)
  3. .env.local    -- personal overrides, always loaded

ENV-NAME defaults to the S3R_ENV environment variable if not supplied."
  (let* ((base-dir (or dir *default-pathname-defaults*))
         (effective-env (or env-name (uiop:getenv "S3R_ENV"))))
    (load-dotenv-file (merge-pathnames ".env" base-dir))
    (when (and effective-env (not (string= effective-env "")))
      (load-dotenv-file (merge-pathnames (format nil ".env.~A" effective-env) base-dir)))
    (load-dotenv-file (merge-pathnames ".env.local" base-dir))))

(defun getenv (name &key default required)
  "Return environment variable NAME as a string.

OS environment variables take precedence over values loaded from .env files.
If REQUIRED is true and no value is found, signals an error."
  (let ((value (or (uiop:getenv name)
                   (gethash name *dotenv-store*)
                   default)))
    (when (and required (null value))
      (error "Required environment variable ~S is not set." name))
    value))

(defun getenv-integer (name &key default required)
  "Return environment variable NAME as an integer.

Returns DEFAULT when the variable is absent or empty.
Signals an error if the value cannot be parsed as an integer."
  (let ((str (getenv name :required required)))
    (if (and str (not (string= str "")))
        (handler-case (parse-integer str)
          (error ()
            (error "Environment variable ~S must be an integer, got: ~S" name str)))
        default)))

(defun getenv-boolean (name &key (default nil))
  "Return environment variable NAME as a boolean.

\"true\" or \"1\" returns T; any other non-nil value returns NIL.
Returns DEFAULT when the variable is absent."
  (let ((str (getenv name)))
    (if str
        (or (string= str "true") (string= str "1"))
        default)))
