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
           #:configure-mount))

(in-package #:cl-s3r.server)

(defvar *handler* nil)
(defvar *mount-config* nil)
(defvar *static-root* nil)

(defun configure-mount (&key (target "#root") component props)
  (setf *mount-config*
        (list :target target
              :component component
              :props props)))

(defun generate-app-js ()
  (let* ((target (getf *mount-config* :target))
         (component (getf *mount-config* :component))
         (props (getf *mount-config* :props))
         (props-json (if props (jonathan:to-json props) "{}")))
    (format nil "import { mount } from '/cl-s3r.js';~%~%mount('~A', {~%  component: '~A',~%  props: ~A~%});~%"
            target component props-json)))

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
    (cond
      ;; Serve static index.html
      ((and (string= path "/") (eq method :get))
       (if *static-root*
           (let ((index-path (merge-pathnames "index.html" *static-root*)))
             (if (probe-file index-path)
                 `(200 (:content-type "text/html")
                       (,(uiop:read-file-string index-path)))
                 `(404 (:content-type "text/plain") ("index.html not found"))))
           `(404 (:content-type "text/plain") ("No static root configured"))))

      ;; Dynamically generated app.js
      ((and (string= path "/app.js") (eq method :get))
       (if *mount-config*
           `(200 (:content-type "application/javascript")
                 (,(generate-app-js)))
           `(404 (:content-type "text/plain") ("No mount configuration"))))

      ;; cl-s3r client JS files
      ((and (eq method :get)
            (member path '("/cl-s3r.js" "/cl-component.js" "/cl-runtime.js" "/cl-mount.js")
                    :test #'string=))
       (serve-client-js path))

      ;; API: Initial render
      ((and (string= path "/api/render") (eq method :post))
       (handle-render env))

      ;; API: Action handler
      ((and (string= path "/action") (eq method :post))
       (let ((payload (parse-json-body env)))
         `(200 (:content-type "application/json")
               (,(handle-action payload)))))

      (t `(404 (:content-type "text/plain") ("Not Found"))))))

(defun start-server (&key (port 5000) (address "0.0.0.0") static-root)
  (when static-root
    (setf *static-root* (pathname static-root)))
  (format t "Starting server on ~A:~A...~%" address port)
  (setf *handler* (clack:clackup #'app :port port :address address)))

(defun stop-server ()
  (when *handler*
    (clack:stop *handler*)
    (setf *handler* nil)))
