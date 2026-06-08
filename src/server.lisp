(defpackage #:cl-s3r.server
  (:use #:cl)
  (:import-from #:alexandria
                #:make-keyword)
  (:import-from #:cl-s3r.component
                #:*component-registry*
                #:call-component-action
                #:render-component-html
                #:normalize-state-keys)
  (:export #:start-server
           #:stop-server
           #:configure-route
           #:configure-mount))

(in-package #:cl-s3r.server)

(defvar *handler* nil)
(defvar *route-registry* (make-hash-table :test 'equal))

(defun configure-route (&key (prefix "/") component props path-param
                              (target "#root") static-root)
  (setf (gethash prefix *route-registry*)
        (list :component component
              :props props
              :path-param path-param
              :target target
              :static-root (when static-root (pathname static-root)))))

(defun configure-mount (&key (target "#root") component props static-root)
  (configure-route :prefix "/" :component component :props props
                   :target target :static-root static-root))

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

(defun generate-index-html (app-js-url)
  (format nil
          "<!DOCTYPE html>~%<html>~%<head>~%  <meta charset=\"UTF-8\">~%</head>~%<body>~%  <div id=\"root\"></div>~%  <script type=\"module\" src=\"~A\"></script>~%</body>~%</html>~%"
          app-js-url))

(defun generate-app-js (config &key (api-prefix "") path-param-key param-value)
  (let* ((target (getf config :target))
         (component (getf config :component))
         (base-props (getf config :props))
         (props (if (and path-param-key param-value)
                    (append base-props
                            (list path-param-key (parse-param-value param-value)))
                    base-props))
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
                  ;; index.html
                  ((and (eq method :get)
                        (or (string= effective-subpath "/")
                            (string= effective-subpath "")))
                   (if path-param-key
                       (if param-value
                           `(200 (:content-type "text/html")
                                 (,(generate-index-html
                                    (format nil "~A/app.js" api-prefix))))
                           '(404 (:content-type "text/plain") ("Missing path parameter")))
                       (let ((index-path (merge-pathnames "index.html"
                                                          (getf config :static-root))))
                         (if (probe-file index-path)
                             `(200 (:content-type "text/html")
                                   (,(uiop:read-file-string index-path)))
                             '(404 (:content-type "text/plain") ("index.html not found"))))))

                  ;; Dynamically generated app.js
                  ((and (eq method :get) (string= effective-subpath "/app.js"))
                   `(200 (:content-type "application/javascript")
                         (,(generate-app-js config
                                            :api-prefix api-prefix
                                            :path-param-key path-param-key
                                            :param-value param-value))))

                  ;; API: Initial render
                  ((and (eq method :post) (string= effective-subpath "/api/render"))
                   (handle-render env))

                  ;; API: Action handler
                  ((and (eq method :post) (string= effective-subpath "/action"))
                   (let ((payload (parse-json-body env)))
                     `(200 (:content-type "application/json")
                           (,(handle-action payload)))))

                  (t '(404 (:content-type "text/plain") ("Not Found")))))))))))

(defun start-server (&key (port 5000) (address "0.0.0.0"))
  (format t "Starting server on ~A:~A...~%" address port)
  (setf *handler* (clack:clackup #'app :port port :address address)))

(defun stop-server ()
  (when *handler*
    (clack:stop *handler*)
    (setf *handler* nil)))
