(defpackage #:cl-s3r.server
  (:use #:cl)
  (:import-from #:alexandria
                #:make-keyword)
  (:import-from #:cl-s3r.component
                #:*component-registry*
                #:call-component-action
                #:render-component-html
                #:normalize-state-keys
                #:call-metadata)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*
                #:*pending-cookie-changes*
                #:parse-cookies
                #:inject-set-cookie-headers)
  (:export #:start-server
           #:stop-server
           #:configure-route
           #:configure-mount
           #:configure-root-page
           #:run-server))

(in-package #:cl-s3r.server)

(defvar *handler* nil)
(defvar *route-registry* (make-hash-table :test 'equal))
(defvar *root-component* nil)

(defun configure-root-page (&key component)
  (setf *root-component* component))

(defun configure-route (&key path (prefix nil) component props path-param
                              (target "#root"))
  (let ((effective-path (or path prefix "/")))
    (setf (gethash effective-path *route-registry*)
          (list :component component
                :props props
                :path-param path-param
                :target target))))

(defun configure-mount (&key (target "#root") component props)
  (configure-route :path "/" :component component :props props :target target))

(defun starts-with-p (prefix path)
  (let ((plen (length prefix)))
    (and (>= (length path) plen)
         (string= prefix (subseq path 0 plen))
         (or (= (length path) plen)
             (char= (char prefix (1- plen)) #\/)
             (char= (char path plen) #\/)))))

(defun find-route-for-path (path)
  "Longest-prefix match. Returns (values prefix config) or (values nil nil)."
  (let ((best-prefix nil) (best-config nil))
    (maphash (lambda (prefix config)
               (when (and (or (string= path prefix)
                              (starts-with-p prefix path))
                          (or (null best-prefix)
                              (> (length prefix) (length best-prefix))))
                 (setf best-prefix prefix best-config config)))
             *route-registry*)
    (values best-prefix best-config)))

(defun extract-path-param (subpath)
  "'/1/app.js' -> (values \"1\" \"/app.js\"), '/' -> (values nil \"/\")"
  (if (or (string= subpath "/") (string= subpath ""))
      (values nil "/")
      (let* ((s (subseq subpath 1))
             (slash-pos (position #\/ s)))
        (if slash-pos
            (values (subseq s 0 slash-pos) (subseq s slash-pos))
            (values s "/")))))

(defun parse-param-value (str)
  "Convert string to integer if possible, otherwise return as string."
  (handler-case (parse-integer str)
    (error () str)))

(defun split-string-by-char (str char)
  (loop for start = 0 then (1+ pos)
        for pos = (position char str :start start)
        collect (subseq str start pos)
        while pos))

(defun parse-query-string (query-string)
  "Parse 'a=1&b=2' into a plist with uppercase keyword keys."
  (when (and query-string (not (string= query-string "")))
    (loop for pair in (split-string-by-char query-string #\&)
          for eq-pos = (position #\= pair)
          when eq-pos
          nconc (list (make-keyword (string-upcase (subseq pair 0 eq-pos)))
                      (subseq pair (1+ eq-pos))))))

(defun escape-html-string (str)
  (with-output-to-string (out)
    (loop for c across str do
      (case c
        (#\< (write-string "&lt;" out))
        (#\> (write-string "&gt;" out))
        (#\& (write-string "&amp;" out))
        (#\" (write-string "&quot;" out))
        (t (write-char c out))))))

(defun inject-title (html title)
  "HTML 文字列中の <title> を TITLE で置換。なければ </head> 前に挿入する。"
  (let* ((safe-title (escape-html-string title))
         (new-tag (format nil "<title>~A</title>" safe-title))
         (existing-open (search "<title>" html))
         (existing-close (search "</title>" html)))
    (if (and existing-open existing-close)
        (concatenate 'string
                     (subseq html 0 existing-open)
                     new-tag
                     (subseq html (+ existing-close (length "</title>"))))
        (let ((head-close (search "</head>" html)))
          (if head-close
              (concatenate 'string
                           (subseq html 0 head-close)
                           new-tag
                           (subseq html head-close))
              html)))))

(defun generate-index-html (app-js-url)
  (format nil
          "<!DOCTYPE html>~%<html>~%<head>~%  <meta charset=\"UTF-8\">~%</head>~%<body>~%  <div id=\"root\"></div>~%  <script type=\"module\" src=\"~A\"></script>~%</body>~%</html>~%"
          app-js-url))

(defun render-root-html (app-js-url &key metadata)
  (if *root-component*
      (let* ((children '(:div (@ (id "root"))))
             (rendered (render-component-html *root-component* nil children))
             (script-tag (format nil "<script type=\"module\" src=\"~A\"></script>" app-js-url))
             (body-close-pos (search "</body>" rendered))
             (with-script (if body-close-pos
                              (concatenate 'string
                                           (subseq rendered 0 body-close-pos)
                                           script-tag
                                           (subseq rendered body-close-pos))
                              (concatenate 'string rendered script-tag)))
             (with-meta (let ((title (and metadata (getf metadata :title))))
                          (if title
                              (inject-title with-script title)
                              with-script))))
        (concatenate 'string "<!DOCTYPE html>" (string #\newline) with-meta))
      (generate-index-html app-js-url)))

(defun generate-app-js (config &key (api-prefix "") path-param-key param-value query-params)
  (let* ((target (getf config :target))
         (component (getf config :component))
         (base-props (getf config :props))
         (props (append base-props
                        (when (and path-param-key param-value)
                          (list path-param-key (parse-param-value param-value)))
                        query-params))
         (props-json (if props (jonathan:to-json props) "{}")))
    (format nil "import { mount } from '/cl-s3r.js';~%~%mount('~A', {~%  component: '~A',~%  props: ~A,~%  apiPrefix: '~A'~%});~%"
            target component props-json api-prefix)))

(defun parse-json-body (env)
  (let ((content-length (getf env :content-length))
        (body (getf env :raw-body)))
    (if (and content-length body)
        (let ((buf (make-array content-length :element-type '(unsigned-byte 8))))
          (read-sequence buf body)
          (let ((json-str (babel:octets-to-string buf)))
            (jonathan:parse json-str)))
        nil)))

(defun handle-action (payload)
  (let* ((action (getf payload :|action|))
         (root-state-node (getf payload :|state|))
         (component-name (getf root-state-node :|component|))
         (current-state-raw (getf root-state-node :|state|))
         (action-name (car action))
         (action-args (cdr action)))
    (let ((state-plist (normalize-state-keys
                        (loop for (k v) on current-state-raw by #'cddr
                              append (list (make-keyword (string-upcase (string k))) v)))))
      (let ((result (call-component-action component-name action-name action-args state-plist)))
        (jonathan:to-json
         `(:|html| ,(getf result :html)
           :|state| ,(getf result :state)))))))

(defun handle-render (env)
  (let* ((payload (parse-json-body env))
         (component-name (getf payload :|component|))
         (props-raw (getf payload :|props|)))
    (let* ((comp-info (gethash (string-downcase (string component-name))
                               *component-registry*))
           (comp-args (getf comp-info :args))
           (arg-values (loop for arg-sym in comp-args
                             collect (getf props-raw
                                          (make-keyword
                                           (string-upcase (string arg-sym)))))))
      (let ((html (apply #'render-component-html
                         component-name
                         nil
                         arg-values)))
        `(200 (:content-type "application/json")
              (,(jonathan:to-json `(:|html| ,html))))))))

(defun serve-client-js (path)
  (let* ((filename (subseq path 1))
         (base-dir (asdf:system-relative-pathname :cl-s3r "src/client/"))
         (filepath (merge-pathnames filename base-dir)))
    (if (probe-file filepath)
        `(200 (:content-type "application/javascript")
              (,(uiop:read-file-string filepath)))
        `(404 (:content-type "text/plain") ("Not Found")))))

(defun app (env)
  (let ((*current-cookies* (parse-cookies (gethash "cookie" (getf env :headers))))
        (*pending-cookie-changes* nil))
    (let ((response
           (block app
             (let ((path (getf env :path-info))
                   (method (getf env :request-method)))

               ;; Shared JS files served unconditionally before route matching
               (when (and (eq method :get)
                          (member path '("/cl-s3r.js" "/cl-component.js"
                                         "/cl-runtime.js" "/cl-mount.js")
                                  :test #'string=))
                 (return-from app (serve-client-js path)))

               ;; Longest-prefix route match
               (multiple-value-bind (prefix config)
                   (find-route-for-path path)
                 (if (null config)
                     '(404 (:content-type "text/plain") ("Not Found"))
                     (let* ((path-param-key (getf config :path-param))
                            (raw-subpath (if (string= prefix "/")
                                             path
                                             (subseq path (length prefix))))
                            (raw-subpath (if (string= raw-subpath "") "/" raw-subpath)))
                       (multiple-value-bind (param-value effective-subpath)
                           (if path-param-key
                               (extract-path-param raw-subpath)
                               (values nil raw-subpath))
                         (let ((api-prefix (cond
                                             ((and path-param-key param-value)
                                              (format nil "~A/~A" prefix param-value))
                                             ((string= prefix "/") "")
                                             (t prefix))))
                           (cond
                             ;; initial HTML (rendered from root component)
                             ((and (eq method :get)
                                   (or (string= effective-subpath "/")
                                       (string= effective-subpath "")))
                              (if (and path-param-key (null param-value))
                                  '(404 (:content-type "text/plain") ("Missing path parameter"))
                                  (let* ((qs (getf env :query-string))
                                         (has-qs (and qs (not (string= qs ""))))
                                         (app-js-url (if has-qs
                                                         (format nil "~A/app.js?~A" api-prefix qs)
                                                         (format nil "~A/app.js" api-prefix)))
                                         (meta-props (append (getf config :props)
                                                             (when (and path-param-key param-value)
                                                               (list path-param-key
                                                                     (parse-param-value param-value)))
                                                             (parse-query-string qs)))
                                         (metadata (call-metadata (getf config :component) meta-props)))
                                    `(200 (:content-type "text/html")
                                          (,(render-root-html app-js-url :metadata metadata))))))

                             ;; Dynamically generated app.js
                             ((and (eq method :get) (string= effective-subpath "/app.js"))
                              (let ((query-params (parse-query-string (getf env :query-string))))
                                `(200 (:content-type "application/javascript")
                                      (,(generate-app-js config
                                                         :api-prefix api-prefix
                                                         :path-param-key path-param-key
                                                         :param-value param-value
                                                         :query-params query-params)))))

                             ;; API: Initial render
                             ((and (eq method :post) (string= effective-subpath "/api/render"))
                              (handle-render env))

                             ;; API: Action handler
                             ((and (eq method :post) (string= effective-subpath "/action"))
                              (let ((payload (parse-json-body env)))
                                `(200 (:content-type "application/json")
                                      (,(handle-action payload)))))

                             (t '(404 (:content-type "text/plain") ("Not Found")))))))))))))
      (inject-set-cookie-headers response))))

(defun start-server (&key (port 5000) (address "0.0.0.0"))
  (format t "Starting server on ~A:~A...~%" address port)
  (setf *handler* (clack:clackup #'app :port port :address address)))

(defun stop-server ()
  (when *handler*
    (clack:stop *handler*)
    (setf *handler* nil)))

(defun run-server (&key port)
  "Start the server and block until interrupted. Stops the server cleanly on exit.
PORT defaults to the PORT environment variable, then 5000."
  (let ((effective-port (or port
                            (let ((env (uiop:getenv "PORT")))
                              (when (and env (not (string= env "")))
                                (parse-integer env)))
                            5000)))
    (start-server :port effective-port)
    (format t "Server running on port ~A. Press Ctrl+C to stop.~%" effective-port)
    (handler-case
        (loop (sleep 1))
      #+sbcl
      (sb-sys:interactive-interrupt ()
        (format t "~%Shutting down...~%")
        (stop-server)
        (uiop:quit 0))
      (error (e)
        (format *error-output* "~%Unexpected error: ~A~%" e)
        (stop-server)
        (uiop:quit 1)))))
