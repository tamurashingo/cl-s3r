(defpackage #:cl-s3r.sample.login.test
  (:use #:cl
        #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*
                #:*pending-cookie-changes*)
  (:import-from #:cl-s3r.session
                #:*session-cookie-name*
                #:*session-secret*
                #:create-session-for-test
                #:reset-session-store!))

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

(defun reset-test-state ()
  "Reset shared state before each test."
  (reset-session-store!)
  ;; Use a fixed secret so HMAC values are stable within a test run
  (setf *session-secret* "test-secret"))

;;; ---- home-page ----

(deftest test-home-page-initial-render
  (reset-test-state)
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

  (reset-test-state)
  (testing "shows welcome message when already logged in"
    (let ((session-cookie (create-session-for-test '(:username "taro"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let* ((result (test-render-component "home-page" :args '()))
               (sexp   (getf result :sexp)))
          (ok (eq :div (car sexp)))
          (let ((h2 (find-element :h2 sexp)))
            (ok h2)
            (ok (equal "Welcome, taro!" (second h2))))
          (ok (find-element :button sexp))
          (ok (null (find-element :form sexp))))))))

;;; ---- do-login ----

(deftest test-do-login
  (reset-test-state)
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
        ;; A session cookie should have been queued
        (ok (not (null *pending-cookie-changes*)))
        (let ((cookie (first *pending-cookie-changes*)))
          (ok (string= *session-cookie-name* (getf cookie :name)))
          (ok (not (null (getf cookie :value)))))
        (ok (redirect-sexp-p (getf r2 :sexp))))))

  (reset-test-state)
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

  (reset-test-state)
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

  (reset-test-state)
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

  (reset-test-state)
  (testing "successful login stores username and last-login in session"
    (let ((*current-cookies* nil)
          (*pending-cookie-changes* nil))
      (let* ((before-login (get-universal-time))
             (r1 (test-render-component "home-page" :args '()))
             (dummy (test-call-action "home-page" "do-login"
                                      :state (getf r1 :state)
                                      :action-args (list (list :|username| "jiro"
                                                               :|password| "password2"))))
             (cookie-spec (first *pending-cookie-changes*))
             (cookie-value (getf cookie-spec :value)))
        (declare (ignore dummy))
        ;; Verify the session data via get-session with the new cookie
        (let ((*current-cookies* (list (cons *session-cookie-name* cookie-value)))
              (*pending-cookie-changes* nil))
          (let ((session (cl-s3r.session:get-session :username :last-login)))
            (ok (string= "jiro" (getf session :username)))
            (ok (>= (getf session :last-login) before-login))))))))

;;; ---- do-logout ----

(deftest test-do-logout
  (reset-test-state)
  (testing "logout sets redirect flag and queues cookie deletion"
    (let ((session-cookie (create-session-for-test '(:username "taro"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let* ((r1 (test-render-component "home-page" :args '()))
               (r2 (test-call-action "home-page" "do-logout"
                                     :state (getf r1 :state)
                                     :action-args '())))
          (ok (test-get-state (getf r2 :state) :redirect))
          (ok (not (null *pending-cookie-changes*)))
          (let ((cookie (first *pending-cookie-changes*)))
            (ok (string= *session-cookie-name* (getf cookie :name)))
            (ok (= 0 (getf cookie :max-age))))
          (ok (redirect-sexp-p (getf r2 :sexp))))))))

;;; ---- require-auth guard ----

(deftest test-require-auth
  (reset-test-state)
  (testing "redirects to / when no session cookie"
    (let ((*current-cookies* nil))
      (ok (string= "/" (cl-s3r.sample.login::require-auth nil)))))

  (reset-test-state)
  (testing "redirects to / when session cookie has invalid HMAC"
    (let ((*current-cookies* (list (cons *session-cookie-name* "fakeid.fakemac"))))
      (ok (string= "/" (cl-s3r.sample.login::require-auth nil)))))

  (reset-test-state)
  (testing "returns nil (passes) when valid session exists"
    (let ((session-cookie (create-session-for-test '(:username "taro"))))
      (let ((*current-cookies* (list session-cookie)))
        (ok (null (cl-s3r.sample.login::require-auth nil))))))

  (reset-test-state)
  (testing "returns nil for any valid user session"
    (dolist (user '("taro" "jiro" "saburo"))
      (let ((session-cookie (create-session-for-test (list :username user))))
        (let ((*current-cookies* (list session-cookie)))
          (ok (null (cl-s3r.sample.login::require-auth nil))
              (format nil "~A should pass guard" user)))))))

;;; ---- detail-page ----

(deftest test-detail-page
  (reset-test-state)
  (testing "shows username when logged in"
    (let ((session-cookie (create-session-for-test '(:username "saburo" :last-login 0))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let* ((result (test-render-component "detail-page" :args '()))
               (sexp   (getf result :sexp)))
          (ok (eq :div (car sexp)))
          (ok (null (find-element :script sexp)))
          (ok (member "saburo" (third sexp) :test #'equal))))))

  (reset-test-state)
  (testing "shows N/A when last-login is not stored in session"
    (let ((session-cookie (create-session-for-test '(:username "taro"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let* ((result (test-render-component "detail-page" :args '()))
               (sexp   (getf result :sexp)))
          (ok (member "N/A" (fourth sexp) :test #'equal))))))

  (reset-test-state)
  (testing "shows formatted last-login time when stored in session"
    (let* ((now (get-universal-time))
           (session-cookie (create-session-for-test (list :username "taro" :last-login now))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let* ((result (test-render-component "detail-page" :args '()))
               (sexp   (getf result :sexp))
               (last-login-str (cl-s3r.sample.login::format-datetime now)))
          (ok (member last-login-str (fourth sexp) :test #'equal)))))))
