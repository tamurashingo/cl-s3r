(defpackage #:cl-s3r.server
  (:use #:cl)
  (:import-from #:alexandria
                #:make-keyword)
  (:import-from #:cl-s3r.component
                #:*component-registry*
                #:*layout-registry*
                #:*error-page-registry*
                #:*component-args-registry*
                #:*current-render-registry*
                #:call-component-action
                #:render-component
                #:render-component-html
                #:render-layout-html
                #:normalize-state-keys
                #:call-metadata
                #:http-error
                #:http-error-status-code
                #:http-error-params)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*
                #:*pending-cookie-changes*
                #:parse-cookies
                #:inject-set-cookie-headers)
  (:import-from #:cl-s3r.config
                #:getenv
                #:getenv-integer
                #:getenv-boolean)
  (:import-from #:lack/middleware/static
                #:*lack-middleware-static*)
  (:export #:start-server
           #:stop-server
           #:configure-route
           #:configure-mount
           #:configure-root-page
           #:configure-default-layout
           #:configure-static-dir
           #:configure-token-expired-behavior
           #:asset-path
           #:define-error-page
           #:run-server))

(in-package #:cl-s3r.server)

(defvar *handler* nil)
(defvar *route-registry* (make-hash-table :test 'equal))
(defvar *root-component* nil)
(defvar *default-layout* nil)
(defvar *static-dir* nil
  "Directory from which static files are served. Defaults to \"public/\" when nil.")
(defvar *token-expired-mode* :reload
  "Global 409 behavior: :reload, :alert, or :confirm.")
(defvar *token-expired-message* nil
  "Optional dialog message for :alert and :confirm token-expired modes.")

(defvar *server-start-time* (get-universal-time)
  "Set once at load time; used as the default deploy-id when S3R_DEPLOY_ID is absent.")

(defun get-deploy-id ()
  (or (getenv "S3R_DEPLOY_ID") (write-to-string *server-start-time*)))

(defun get-secret-key ()
  (or (getenv "S3R_SECRET_KEY") "dev-secret-key-change-in-production"))

(defun generate-render-token ()
  "Return '<timestamp>.<hex-hmac>' signed with the secret key."
  (let* ((timestamp (get-universal-time))
         (message (format nil "~A|~A" (get-deploy-id) timestamp))
         (key-bytes (babel:string-to-octets (get-secret-key) :encoding :utf-8))
         (msg-bytes (babel:string-to-octets message :encoding :utf-8))
         (hmac (ironclad:make-hmac key-bytes :sha256)))
    (ironclad:update-hmac hmac msg-bytes)
    (format nil "~A.~A" timestamp
            (ironclad:byte-array-to-hex-string (ironclad:produce-mac hmac)))))

(defun validate-render-token (token &key (max-age-seconds 1800))
  "Return T if TOKEN is valid and not older than MAX-AGE-SECONDS, NIL otherwise."
  (when (and token (not (string= token "")))
    (let ((dot-pos (position #\. token :from-end t)))
      (when dot-pos
        (let* ((ts-str (subseq token 0 dot-pos))
               (provided-hmac (subseq token (1+ dot-pos)))
               (timestamp (handler-case (parse-integer ts-str) (error () nil))))
          (when timestamp
            (let* ((message (format nil "~A|~A" (get-deploy-id) timestamp))
                   (key-bytes (babel:string-to-octets (get-secret-key) :encoding :utf-8))
                   (msg-bytes (babel:string-to-octets message :encoding :utf-8))
                   (hmac (ironclad:make-hmac key-bytes :sha256)))
              (ironclad:update-hmac hmac msg-bytes)
              (let ((expected (ironclad:byte-array-to-hex-string
                               (ironclad:produce-mac hmac)))
                    (age (- (get-universal-time) timestamp)))
                (and (string= expected provided-hmac)
                     (<= 0 age max-age-seconds))))))))))

(defun find-state-by-component-id (state-tree component-id)
  "Recursively search STATE-TREE for the node whose component-id equals COMPONENT-ID.
STATE-TREE uses jonathan's :|key| keyword style. Returns the node plist or NIL."
  (when state-tree
    (if (equal (getf state-tree :|component-id|) component-id)
        state-tree
        (loop for child in (getf state-tree :|children|)
              for found = (find-state-by-component-id child component-id)
              when found return found))))

(defun configure-token-expired-behavior (mode &optional message)
  "Set the global behavior when the client receives a 409 render-token expired response.
MODE is one of :reload (default), :alert, or :confirm.
MESSAGE is the dialog text shown in :alert and :confirm modes."
  (setf *token-expired-mode* mode
        *token-expired-message* message))

(defun configure-static-dir (dir)
  "Set the directory from which static files are served.
DIR can be a string or pathname. When nil, defaults to \"public/\" relative to CWD.
Has no effect when S3R_ASSET_SERVING_DISABLED=true."
  (setf *static-dir* dir))

(defun asset-path (path)
  "Return the URL for a static asset at PATH.
When S3R_ASSET_BASE_URL is set, prepends it to PATH; otherwise returns PATH as-is."
  (let ((base-url (getenv "S3R_ASSET_BASE_URL")))
    (if (and base-url (not (string= base-url "")))
        (format nil "~A~A" (string-right-trim "/" base-url) path)
        path)))

(defun configure-root-page (&key component)
  "Deprecated. Use configure-default-layout with define-layout instead."
  (setf *root-component* component))

(defun configure-default-layout (layout-name)
  "Set the default layout applied to all routes.
LAYOUT-NAME is a symbol naming a layout defined with define-layout.
Overridden per route via the :layout keyword in configure-route."
  (setf *default-layout* layout-name))

(defmacro define-error-page (&key status component (layout :inherit))
  "Register COMPONENT as the error page for HTTP STATUS code.
LAYOUT controls the layout wrapping the error page:
  :inherit (default) — use the global *default-layout*
  nil                — no layout; render inside a minimal HTML wrapper
  'symbol            — use this specific layout, overriding the global default"
  `(setf (gethash ,status *error-page-registry*)
         (list :component ,component :layout ,layout)))

(defun http-status-message (code)
  (case code
    (400 "Bad Request")
    (401 "Unauthorized")
    (403 "Forbidden")
    (404 "Not Found")
    (408 "Request Timeout")
    (500 "Internal Server Error")
    (502 "Bad Gateway")
    (503 "Service Unavailable")
    (504 "Gateway Timeout")
    (t "Error")))

(defun generate-default-error-html (status)
  (format nil "<!DOCTYPE html>~%<html>~%<head><meta charset=\"UTF-8\"><title>~A ~A</title></head>~%<body>~%<h1>~A ~A</h1>~%</body>~%</html>~%"
          status (http-status-message status)
          status (http-status-message status)))

(defun render-error-response (status params)
  "Render the error page HTML for STATUS with PARAMS keyword args.
Looks up *error-page-registry* for a registered error page component.
Falls back to a minimal default HTML page when no page is registered."
  (let* ((error-page (gethash status *error-page-registry*))
         (component-name (getf error-page :component))
         (page-layout-setting (if error-page (getf error-page :layout) :inherit)))
    (if component-name
        (handler-case
          (let* ((effective-layout
                  (cond
                    ((eq page-layout-setting :inherit) *default-layout*)
                    ((null page-layout-setting) nil)
                    (t page-layout-setting)))
                 (html (if effective-layout
                           (let ((comp-sexp (apply #'render-component component-name nil params)))
                             (concatenate 'string
                                          "<!DOCTYPE html>" (string #\newline)
                                          (render-layout-html effective-layout :children comp-sexp)))
                           (let ((comp-html (apply #'render-component-html component-name nil params)))
                             (format nil "<!DOCTYPE html>~%<html><head><meta charset=\"UTF-8\"></head><body>~A</body></html>"
                                     comp-html)))))
            `(,status (:content-type "text/html") (,html)))
          (error (render-err)
            (format *error-output* "Error rendering error page for ~A: ~A~%" status render-err)
            `(,status (:content-type "text/html") (,(generate-default-error-html status)))))
        `(,status (:content-type "text/html") (,(generate-default-error-html status))))))

(defun configure-route (&key path (prefix nil) component props path-param
                              (target "#root") guard (layout :inherit))
  "Register a route.
GUARD is an optional function (env) => nil-or-redirect-path.
When GUARD returns a non-nil string, the server responds with HTTP 302 to that path.
LAYOUT controls which layout wraps the page HTML:
  :inherit (default) — use the global *default-layout* (or *root-component* as fallback)
  nil                — no layout; render a minimal HTML page
  'symbol            — use this specific layout, overriding the global default"
  (let ((effective-path (or path prefix "/")))
    (setf (gethash effective-path *route-registry*)
          (list :component component
                :props props
                :path-param path-param
                :target target
                :guard guard
                :layout layout))))

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

(defun percent-decode (string)
  "Decode a percent-encoded URL query parameter value.
Handles %XX sequences and + as space."
  (with-output-to-string (out)
    (let ((i 0)
          (len (length string)))
      (loop while (< i len) do
        (let ((c (char string i)))
          (cond
            ((and (char= c #\%)
                  (< (+ i 2) len))
             (let ((hex (subseq string (1+ i) (+ i 3))))
               (handler-case
                   (progn
                     (write-char (code-char (parse-integer hex :radix 16)) out)
                     (incf i 3))
                 (error ()
                   (write-char c out)
                   (incf i)))))
            ((char= c #\+)
             (write-char #\Space out)
             (incf i))
            (t
             (write-char c out)
             (incf i))))))))

(defun parse-query-string (query-string)
  "Parse 'a=1&b=2' into a plist with uppercase keyword keys."
  (when (and query-string (not (string= query-string "")))
    (loop for pair in (split-string-by-char query-string #\&)
          for eq-pos = (position #\= pair)
          when eq-pos
          nconc (list (make-keyword (string-upcase (subseq pair 0 eq-pos)))
                      (percent-decode (subseq pair (1+ eq-pos)))))))

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

(defun %render-with-layout (rendered app-js-url metadata)
  "Inject the app.js script tag and optional metadata title into RENDERED html."
  (let* ((script-tag (format nil "<script type=\"module\" src=\"~A\"></script>" app-js-url))
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
    (concatenate 'string "<!DOCTYPE html>" (string #\newline) with-meta)))

(defun render-root-html (app-js-url &key metadata layout-name no-layout)
  "Render the full page HTML.
LAYOUT-NAME is a symbol naming a defined layout to wrap the mount div.
NO-LAYOUT when true skips layout even if *root-component* is set (explicit :layout nil on route).
Falls back to *root-component* (deprecated) when LAYOUT-NAME is nil and NO-LAYOUT is nil."
  (let ((children '(:div (@ (id "root")))))
    (cond
      (layout-name
       (%render-with-layout
        (render-layout-html layout-name :children children)
        app-js-url metadata))
      ((and (not no-layout) *root-component*)
       (%render-with-layout
        (render-component-html *root-component* nil :children children)
        app-js-url metadata))
      (t
       (generate-index-html app-js-url)))))

(defun generate-app-js (config &key (api-prefix "") path-param-key param-value query-params)
  (let* ((target (getf config :target))
         (component (getf config :component))
         (base-props (getf config :props))
         (props (append base-props
                        (when (and path-param-key param-value)
                          (list path-param-key (parse-param-value param-value)))
                        query-params))
         (props-json (if props (jonathan:to-json props) "{}"))
         (token-expired-json
          (jonathan:to-json
           `(:|mode| ,(string-downcase (string *token-expired-mode*))
             ,@(when *token-expired-message*
                 `(:|message| ,*token-expired-message*))))))
    (format nil "import { mount } from '/cl-s3r.js';~%~%mount('~A', {~%  component: '~A',~%  props: ~A,~%  apiPrefix: '~A',~%  tokenExpired: ~A~%});~%"
            target component props-json api-prefix token-expired-json)))

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
  (let* ((action              (getf payload :|action|))
         (render-token        (getf payload :|render-token|))
         (target-component-id (getf payload :|component-id|))
         (root-state-node     (getf payload :|state|)))

    (unless (validate-render-token render-token)
      ;; Clean up stale registry entry on token expiry.
      (remhash render-token *component-args-registry*)
      (return-from handle-action
        '(409 (:content-type "application/json")
              ("{\"error\":\"render-token expired\"}"))))

    (let* ((target-node
            (if (and target-component-id (not (string= target-component-id "")))
                (or (find-state-by-component-id root-state-node target-component-id)
                    root-state-node)
                root-state-node))
           (component-name    (getf target-node :|component|))
           (current-state-raw (getf target-node :|state|))
           (action-name       (car action))
           (action-args       (cdr action)))
      (let* ((state-plist (normalize-state-keys
                           (loop for (k v) on current-state-raw by #'cddr
                                 append (list (make-keyword (string-upcase (string k))) v))))
             ;; Look up the stored init-args for this component instance.
             (render-registry   (gethash render-token *component-args-registry*))
             (component-init-args
              (when (and render-registry
                         target-component-id
                         (not (string= target-component-id "")))
                (gethash target-component-id render-registry))))
        (let ((result (call-component-action component-name action-name action-args
                                             state-plist
                                             :forced-component-id target-component-id
                                             :component-init-args component-init-args)))
          (jonathan:to-json
           `(:|html| ,(getf result :html)
             :|state| ,(getf result :state))))))))

(defun handle-render (env)
  (let* ((payload (parse-json-body env))
         (component-name (getf payload :|component|))
         (props-raw (getf payload :|props|)))
    ;; Convert jonathan's :|key| style to uppercase :KEY keywords
    (let ((props-plist (loop for (k v) on props-raw by #'cddr
                             nconc (list (make-keyword (string-upcase (string k))) v))))
      ;; Bind a fresh registry so define-component can register (component-id -> init-args)
      ;; entries as the component tree is rendered.
      (let ((*current-render-registry* (make-hash-table :test 'equal)))
        (let ((html  (apply #'render-component-html component-name nil props-plist))
              (token (generate-render-token)))
          ;; Persist the registry so handle-action can look up init-args by token.
          (setf (gethash token *component-args-registry*) *current-render-registry*)
          `(200 (:content-type "application/json")
                (,(jonathan:to-json `(:|html| ,html :|render-token| ,token)))))))))

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
                                         "/cl-runtime.js" "/cl-mount.js"
                                         "/cl-morph.js")
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
                                  (let ((guard-fn (getf config :guard)))
                                    (if guard-fn
                                        (let ((redirect-path (funcall guard-fn env)))
                                          (when redirect-path
                                            (return-from app
                                              `(302 (:location ,redirect-path
                                                     :content-type "text/plain")
                                                    ("")))))
                                        nil)
                                    (handler-case
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
                                             (metadata (call-metadata (getf config :component) meta-props))
                                             (route-layout (getf config :layout :inherit))
                                             (explicit-no-layout
                                              (and (not (eq route-layout :inherit))
                                                   (null route-layout)))
                                             (effective-layout-name
                                              (cond
                                                (explicit-no-layout nil)
                                                ((eq route-layout :inherit) *default-layout*)
                                                (t route-layout))))
                                        `(200 (:content-type "text/html")
                                              (,(render-root-html app-js-url
                                                                  :metadata metadata
                                                                  :layout-name effective-layout-name
                                                                  :no-layout explicit-no-layout))))
                                      (http-error (e)
                                        (render-error-response
                                         (http-error-status-code e)
                                         (http-error-params e)))
                                      (error (e)
                                        (format *error-output* "Unhandled error in GET ~A: ~A~%" path e)
                                        (render-error-response 500 (list :message (princ-to-string e))))))))

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
                              (handler-case
                                (handle-render env)
                                (http-error (e)
                                  (render-error-response
                                   (http-error-status-code e)
                                   (http-error-params e)))
                                (error (e)
                                  (format *error-output* "Unhandled error in /api/render: ~A~%" e)
                                  (render-error-response 500 (list :message (princ-to-string e))))))

                             ;; API: Action handler
                             ((and (eq method :post) (string= effective-subpath "/action"))
                              (let* ((payload (parse-json-body env))
                                     (result  (handle-action payload)))
                                (if (listp result)
                                    result
                                    `(200 (:content-type "application/json")
                                          (,result)))))

                             (t '(404 (:content-type "text/plain") ("Not Found")))))))))))))
      (inject-set-cookie-headers response))))

(defun build-app ()
  "Build the Clack app function, wrapping with static file middleware unless disabled.
Static serving is disabled when S3R_ASSET_SERVING_DISABLED=true.
The static root defaults to \"public/\" when *static-dir* is nil."
  (if (getenv-boolean "S3R_ASSET_SERVING_DISABLED")
      #'app
      (let* ((root (uiop:ensure-directory-pathname (or *static-dir* "public/")))
             (path-fn (lambda (path-info)
                        (let ((relative (if (and (> (length path-info) 0)
                                                 (char= (char path-info 0) #\/))
                                            (subseq path-info 1)
                                            path-info)))
                          (when (and (not (string= relative ""))
                                     (uiop:file-exists-p
                                      (merge-pathnames relative root)))
                            path-info)))))
        (funcall lack/middleware/static:*lack-middleware-static*
                 #'app
                 :path path-fn
                 :root root))))

(defun start-server (&key (port 5000) (address "0.0.0.0"))
  (format t "Starting server on ~A:~A...~%" address port)
  (setf *handler* (clack:clackup (build-app) :port port :address address)))

(defun stop-server ()
  (when *handler*
    (clack:stop *handler*)
    (setf *handler* nil)))

(defun run-server (&key port)
  "Start the server and block until interrupted. Stops the server cleanly on exit.
PORT defaults to the PORT environment variable (or .env file), then 5000."
  (let ((effective-port (or port
                            (getenv-integer "PORT" :default 5000))))
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
