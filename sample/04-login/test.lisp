(defpackage #:cl-s3r.sample.login.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*
                #:*pending-cookie-changes*))

(in-package #:cl-s3r.sample.login.test)

;;; ---- helpers ----

(defun find-element (tag sexp)
  "Return the first direct child of SEXP whose car is TAG."
  (find-if (lambda (x) (and (listp x) (eq tag (car x)))) sexp))

(defun redirect-sexp-p (sexp)
  "Return true if SEXP is a (:div (@ (data-redirect ...))) redirect element."
  (and (listp sexp)
       (eq :div (car sexp))
       (let ((second (second sexp)))
         (and (listp second)
              (symbolp (car second))
              (string= (string (car second)) "@")
              (find-if (lambda (attr)
                         (and (listp attr)
                              (symbolp (car attr))
                              (string-equal (string (car attr)) "DATA-REDIRECT")))
                       (cdr second))))))

;;; ---- home-page ----

(deftest test-home-page-initial-render
  (testing "shows login form when not logged in"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (let* ((result (test-render-component "home-page" :args '()))
             (sexp   (getf result :sexp))
             (state  (getf result :state)))
        (ok (null (test-get-state state :error-msg)))
        (ok (null (test-get-state state :redirect)))
        (ok (eq :div (car sexp)))
        (ok (find-element :form sexp)))))

  (testing "shows welcome message when already logged in"
    (let ((*current-cookies* '(("session" . "taro")))
          (*pending-cookie-changes* nil))
      (let* ((result (test-render-component "home-page" :args '()))
             (sexp   (getf result :sexp)))
        (ok (eq :div (car sexp)))
        (let ((h2 (find-element :h2 sexp)))
          (ok h2)
          (ok (equal "Welcome, taro!" (second h2))))
        (ok (find-element :button sexp))
        (ok (null (find-element :form sexp)))))))

;;; ---- do-login ----

(deftest test-do-login
  (testing "valid credentials set redirect flag and queue session cookie"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (let* ((r1 (test-render-component "home-page" :args '()))
             (r2 (test-call-action "home-page" "do-login"
                                   :state (getf r1 :state)
                                   :action-args (list (list :|username| "taro"
                                                            :|password| "password1")))))
        (ok (test-get-state (getf r2 :state) :redirect))
        (ok (null (test-get-state (getf r2 :state) :error-msg)))
        (ok (not (null *pending-cookie-changes*)))
        (let ((cookie (first *pending-cookie-changes*)))
          (ok (string= "session" (getf cookie :name)))
          (ok (string= "taro" (getf cookie :value))))
        (ok (redirect-sexp-p (getf r2 :sexp))))))

  (testing "all users can log in"
    (loop for (username . password) in '(("taro"   . "password1")
                                         ("jiro"   . "password2")
                                         ("saburo" . "password3"))
          do (let ((*current-cookies* nil)
                   (*pending-cookie-changes* nil))
               (let* ((r1 (test-render-component "home-page" :args '()))
                      (r2 (test-call-action "home-page" "do-login"
                                            :state (getf r1 :state)
                                            :action-args (list (list :|username| username
                                                                     :|password| password)))))
                 (ok (test-get-state (getf r2 :state) :redirect)
                     (format nil "~A should login successfully" username))))))

  (testing "wrong password sets error-msg"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (let* ((r1 (test-render-component "home-page" :args '()))
             (r2 (test-call-action "home-page" "do-login"
                                   :state (getf r1 :state)
                                   :action-args (list (list :|username| "taro"
                                                            :|password| "wrongpassword")))))
        (ok (null (test-get-state (getf r2 :state) :redirect)))
        (ok (string= "Invalid username or password"
                     (test-get-state (getf r2 :state) :error-msg)))
        (ok (null *pending-cookie-changes*))
        (ok (find-element :form (getf r2 :sexp))))))

  (testing "unknown username sets error-msg"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (let* ((r1 (test-render-component "home-page" :args '()))
             (r2 (test-call-action "home-page" "do-login"
                                   :state (getf r1 :state)
                                   :action-args (list (list :|username| "nobody"
                                                            :|password| "password1")))))
        (ok (string= "Invalid username or password"
                     (test-get-state (getf r2 :state) :error-msg))))))

  (testing "successful login updates last-login time"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (remhash "jiro" cl-s3r.sample.login::*last-login-times*)
      (let ((r1 (test-render-component "home-page" :args '())))
        (test-call-action "home-page" "do-login"
                          :state (getf r1 :state)
                          :action-args (list (list :|username| "jiro"
                                                   :|password| "password2")))
        (ok (gethash "jiro" cl-s3r.sample.login::*last-login-times*))))))

;;; ---- do-logout ----

(deftest test-do-logout
  (testing "logout sets redirect flag and queues cookie deletion"
    (let ((*current-cookies* '(("session" . "taro")))
          (*pending-cookie-changes* nil))
      (let* ((r1 (test-render-component "home-page" :args '()))
             (r2 (test-call-action "home-page" "do-logout"
                                   :state (getf r1 :state)
                                   :action-args '())))
        (ok (test-get-state (getf r2 :state) :redirect))
        (ok (not (null *pending-cookie-changes*)))
        (let ((cookie (first *pending-cookie-changes*)))
          (ok (string= "session" (getf cookie :name)))
          (ok (= 0 (getf cookie :max-age))))
        (ok (redirect-sexp-p (getf r2 :sexp)))))))

;;; ---- detail-page ----

(deftest test-detail-page
  (testing "shows redirect script when not logged in"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (let* ((result (test-render-component "detail-page" :args '()))
             (sexp   (getf result :sexp)))
        (ok (redirect-sexp-p sexp)))))

  (testing "shows username when logged in"
    (let ((*current-cookies* '(("session" . "saburo")))
          (*pending-cookie-changes* nil))
      (let* ((result (test-render-component "detail-page" :args '()))
             (sexp   (getf result :sexp)))
        ;; sexp = (:div (:h2 "Detail") (:p (:strong "Username: ") "saburo") (:p ...))
        (ok (eq :div (car sexp)))
        (ok (null (find-element :script sexp)))
        (ok (member "saburo" (third sexp) :test #'equal)))))

  (testing "shows N/A when last-login time is not set"
    (remhash "taro" cl-s3r.sample.login::*last-login-times*)
    (let ((*current-cookies* '(("session" . "taro")))
          (*pending-cookie-changes* nil))
      (let* ((result (test-render-component "detail-page" :args '()))
             (sexp   (getf result :sexp)))
        ;; "N/A" is inside (:p (:strong "Last Login: ") "N/A")
        (ok (member "N/A" (fourth sexp) :test #'equal)))))

  (testing "shows formatted last-login time after login"
    (let ((now (get-universal-time)))
      (setf (gethash "taro" cl-s3r.sample.login::*last-login-times*) now)
      (let ((*current-cookies* '(("session" . "taro")))
            (*pending-cookie-changes* nil))
        (let* ((result (test-render-component "detail-page" :args '()))
               (sexp   (getf result :sexp))
               (last-login-str (cl-s3r.sample.login::format-datetime now)))
          ;; formatted time is inside (:p (:strong "Last Login: ") "...")
          (ok (member last-login-str (fourth sexp) :test #'equal)))))))
