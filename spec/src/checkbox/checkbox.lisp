(ql:quickload :cl-s3r.components.checkbox :silent t)

(spec-sheet:defspec checkbox
  :description "Boolean checkbox rendered as a custom label/box, supporting uncontrolled and controlled (parent-owned) modes"
  :component #'cl-s3r.components.checkbox:checkbox
  :render #'(lambda (&key initial-checked disabled label)
              (let* ((initial-checked-val (string= initial-checked "true"))
                     (disabled-val        (string= disabled "true")))
                `(:div
                   (:style "
body { font-family: sans-serif; }
.checkbox-demo {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 3rem;
}
")
                   (:div (@ (class "checkbox-demo"))
                     (checkbox (@ (initial-checked ,initial-checked-val)
                                  (disabled        ,disabled-val))
                       ,(or label "Subscribe to newsletter"))))))
  :props '((initial-checked :type (member "false" "true")
                            :default "false"
                            :description "Initial value in uncontrolled mode")
           (disabled        :type (member "false" "true")
                            :default "false"
                            :description "Disables the checkbox; no click handler is attached at all")
           (label           :type string
                            :default "Subscribe to newsletter"
                            :description "Label text rendered next to the box")))

(spec-sheet:defsheet checkbox unchecked
  :title "Uncontrolled, unchecked"
  :params '(:initial-checked "false" :label "Subscribe to newsletter"))

(spec-sheet:defsheet checkbox checked
  :title "Uncontrolled, checked"
  :params '(:initial-checked "true" :label "Remember me"))

(spec-sheet:defsheet checkbox disabled-unchecked
  :title "Disabled, unchecked"
  :params '(:disabled "true" :label "Disabled, unchecked"))

(spec-sheet:defsheet checkbox disabled-checked
  :title "Disabled, checked"
  :params '(:initial-checked "true" :disabled "true" :label "Disabled, checked"))

;;; --- controlled (parent reads on/off state) sheet ---

(cl-s3r.component:define-component checkbox-controlled-demo (&key &allow-other-keys)
  (cl-s3r.component:let-component-state ((is-subscribed nil))
    (cl-s3r.component:let-function
        ((toggle-subscribed (current-value) (setf is-subscribed (not current-value))))
      `(:div (@ (style "font-family:sans-serif;padding:2rem;"))
         (:p (@ (style "margin:0 0 12px;color:#666;font-size:14px;"))
             "Passing both " (:code "checked") " and " (:code "onclick") " makes the checkbox "
             "fully controlled: the parent feeds " (:code "checked") " back so the box visually "
             "toggles, and its " (:code "onclick") " handler receives the pre-click value to flip it.")
         (cl-s3r.components.checkbox:checkbox (@ (checked ,is-subscribed) (onclick (toggle-subscribed)))
           "Subscribe to newsletter")
         (:p (@ (style "margin-top:12px;color:#333;font-size:14px;"))
             "current state: " (:strong ,(format nil "~A" is-subscribed)))))))

(spec-sheet:defsheet checkbox controlled
  :title "Controlled (parent reads on/off state)"
  :render #'(lambda (&key &allow-other-keys)
              `(:div (checkbox-controlled-demo)))
  :params '())

;;; --- native form submission sheet ---

(cl-s3r.component:define-component checkbox-form-demo (&key &allow-other-keys)
  (cl-s3r.component:let-component-state ((last-submitted "(not submitted yet)"))
    (cl-s3r.component:let-function
        ((on-submit (form-data)
           (setf last-submitted (if (getf form-data :|agree|) "agree=on" "agree not sent"))))
      `(:div (@ (style "font-family:sans-serif;padding:2rem;"))
         (:p (@ (style "margin:0 0 12px;color:#666;font-size:14px;"))
             "Passing " (:code "name") " adds a hidden native "
             (:code "<input type=\"checkbox\">") " so a real " (:code "<form>")
             " picks it up via " (:code "FormData") " on submit.")
         (:form (@ (id "agree-form") (onsubmit (on-submit)))
           (cl-s3r.components.checkbox:checkbox (@ (name "agree") (value "on")) "I agree to the terms")
           (:br)
           (:button (@ (type "submit")) "Submit"))
         (:p (@ (style "margin-top:12px;color:#333;font-size:14px;"))
             "last submit payload: " (:strong ,last-submitted))))))

(spec-sheet:defsheet checkbox form-submission
  :title "Native form submission"
  :render #'(lambda (&key &allow-other-keys)
              `(:div (checkbox-form-demo)))
  :params '())
