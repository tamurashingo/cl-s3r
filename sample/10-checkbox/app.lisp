(defpackage #:cl-s3r.sample.checkbox
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function)
  (:import-from #:cl-s3r.components.checkbox
                #:checkbox))

(in-package #:cl-s3r.sample.checkbox)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:meta (@ (name "viewport") (content "width=device-width, initial-scale=1")))
       (:title "cl-s3r Checkbox")
       (:style "body{font-family:sans-serif;max-width:800px;margin:40px auto;padding:0 20px;}"
               "h1{color:#333;}"
               "h2{color:#555;margin-top:2em;}"
               "section{margin-bottom:3em;border-bottom:1px solid #eee;padding-bottom:2em;}"))
     (:body ,children)))

(configure-default-layout 'app-layout)

;;; --- 1. uncontrolled checkbox (self-contained toggle) ---

(define-component uncontrolled-checkbox-demo (&key &allow-other-keys)
  `(:section
     (:h2 "1. Uncontrolled checkbox")
     (:p "Self-contained toggle; clicking flips its own internal state. "
         "Clicking the label text works too, not just the box.")
     (checkbox "Subscribe to newsletter (starts unchecked)")
     (:br)
     (checkbox (@ (initial-checked t)) "Remember me (starts checked)")))

;;; --- 2. disabled checkbox ---

(define-component disabled-checkbox-demo (&key &allow-other-keys)
  `(:section
     (:h2 "2. Disabled checkbox")
     (:p "Clicking has no effect; no click handler is attached at all.")
     (checkbox (@ (disabled t)) "Disabled, unchecked")))

;;; --- 3. uncontrolled + disabled ---

(define-component uncontrolled-disabled-checkbox-demo (&key &allow-other-keys)
  `(:section
     (:h2 "3. Uncontrolled + disabled")
     (:p "Starts checked via " (:code "initial-checked t") " but cannot be toggled.")
     (checkbox (@ (initial-checked t) (disabled t)) "Disabled, checked")))

;;; --- 4. controlled checkbox: parent owns and reads the on/off state ---

(define-component controlled-state-checkbox-demo (&key &allow-other-keys)
  (let-component-state ((is-subscribed nil))
    (let-function
        ((toggle-subscribed (current-value) (setf is-subscribed (not current-value))))
      `(:section
         (:h2 "4. Controlled checkbox (parent reads on/off state)")
         (:p "Passing both " (:code "checked") " and " (:code "onclick") " makes the checkbox "
             "fully controlled: it keeps no state of its own. The parent defines "
             (:code "is-subscribed") " via " (:code "let-component-state") ", feeds it back "
             "via " (:code "checked") " so the box visually toggles, and its " (:code "onclick")
             " handler receives the checkbox's pre-click value to flip it.")
         (checkbox (@ (checked ,is-subscribed) (onclick (toggle-subscribed)))
           "Subscribe to newsletter")
         (:p "current state: " (:strong ,(format nil "~A" is-subscribed)))))))

;;; --- 5. native form submission ---

(define-component form-checkbox-demo (&key &allow-other-keys)
  (let-component-state ((last-submitted "(not submitted yet)"))
    (let-function
        ((on-submit (form-data)
           (setf last-submitted (if (getf form-data :|agree|) "agree=on" "agree not sent"))))
      `(:section
         (:h2 "5. Native form submission")
         (:p "Passing " (:code "name") " adds a hidden native "
             (:code "<input type=\"checkbox\">") " so a real "
             (:code "<form>") " picks it up via " (:code "FormData") " on submit.")
         (:form (@ (id "agree-form") (onsubmit (on-submit)))
           (checkbox (@ (name "agree") (value "on")) "I agree to the terms")
           (:br)
           (:button (@ (type "submit")) "Submit"))
         (:p "last submit payload: " (:strong ,last-submitted))))))

;;; --- root page ---

(define-component checkbox-page (&key &allow-other-keys)
  `(:div
     (:h1 "Checkbox Component Examples")
     (uncontrolled-checkbox-demo)
     (disabled-checkbox-demo)
     (uncontrolled-disabled-checkbox-demo)
     (controlled-state-checkbox-demo)
     (form-checkbox-demo)))

(configure-route :path "/"
                 :component "checkbox-page"
                 :props '())
