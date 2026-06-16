(defpackage #:cl-s3r.sample.login
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-root-page)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function)
  (:import-from #:cl-s3r.session
                #:get-session
                #:set-session
                #:destroy-session))

(in-package #:cl-s3r.sample.login)

;;; --- user data ---

(defvar *users*
  '(("taro"   . "password1")
    ("jiro"   . "password2")
    ("saburo" . "password3")))

(defun valid-credentials-p (username password)
  (let ((stored (cdr (assoc username *users* :test #'string=))))
    (and stored (string= stored password))))

(defun format-datetime (universal-time)
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time)
    (format nil "~4D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
            year month day hour min sec)))

;;; --- root component ---

(define-component root (&key children &allow-other-keys)
  (let* ((session (get-session :username))
         (username (getf session :username)))
    `(:html (@ (lang "ja"))
       (:head
         (:meta (@ (charset "UTF-8")))
         (:title "cl-s3r Login Sample"))
       (:body
         (:nav
           (:a (@ (href "/")) "Home")
           ,@(when username
               '(" | " (:a (@ (href "/detail")) "Detail"))))
         (:main ,children)))))

(configure-root-page :component "root")

;;; --- home page (/) ---

(define-component home-page (&key &allow-other-keys)
  (let-component-state ((error-msg nil)
                        (redirect nil))
    (let-function
        ((do-login (form-data)
           (let ((username (getf form-data :|username|))
                 (password (getf form-data :|password|)))
             (if (valid-credentials-p username password)
                 (progn
                   (set-session (list :username username
                                      :last-login (get-universal-time)))
                   (setf redirect t))
                 (setf error-msg "Invalid username or password"))))
         (do-logout ()
           (destroy-session)
           (setf redirect t)))
      (if redirect
          ;; redirect after login/logout via client-side navigation
          `(:div (@ (data-redirect "/")))
          (let* ((session (get-session :username))
                 (username (getf session :username)))
            (if username
                ;; logged in
                `(:div
                   (:h2 ,(format nil "Welcome, ~A!" username))
                   (:p "You are logged in.")
                   (:button (@ (onclick (do-logout))) "Logout"))
                ;; not logged in: show login form
                `(:div
                   (:h2 "Login")
                   ,@(when error-msg
                       `((:p (@ (style "color:red;margin:8px 0")) ,error-msg)))
                   (:form (@ (onsubmit (do-login)))
                     (:div
                       (:label "Username: ")
                       (:input (@ (type "text") (name "username") (placeholder "taro / jiro / saburo"))))
                     (:div (@ (style "margin-top:8px"))
                       (:label "Password: ")
                       (:input (@ (type "password") (name "password") (placeholder "password"))))
                     (:button (@ (type "submit") (style "margin-top:12px")) "Login")))))))))

(configure-route :path "/"
                 :component "home-page"
                 :props '())

;;; --- route guard ---

(defun require-auth (env)
  "Guard function: redirect to / when no valid session is present."
  (declare (ignore env))
  (let* ((session (get-session :username))
         (username (getf session :username)))
    (unless username "/")))

;;; --- detail page (/detail) ---

(define-component detail-page (&key &allow-other-keys)
  (let* ((session (get-session :username :last-login))
         (username (getf session :username))
         (last-login (getf session :last-login)))
    `(:div
       (:h2 "Detail")
       (:p (:strong "Username: ") ,username)
       (:p (:strong "Last Login: ")
           ,(if last-login
                (format-datetime last-login)
                "N/A")))))

(configure-route :path "/detail"
                 :component "detail-page"
                 :props '()
                 :guard #'require-auth)
