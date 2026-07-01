(ql:quickload :cl-s3r.components.dialog :silent t)
(ql:quickload :cl-s3r.components.icon   :silent t)

(cl-s3r.component:define-component dialog-spec-demo
    (&key title content action1-label action2-label &allow-other-keys)
  (cl-s3r.component:let-component-state ((open t)
                                          (last-action ""))
    (cl-s3r.component:let-function
        ((do-action1 () (setf open nil) (setf last-action (or action1-label "OK")))
         (do-action2 () (setf open nil) (setf last-action (or action2-label "")))
         (reopen     () (setf open t)   (setf last-action "")))
      `(:div (@ (style "font-family:sans-serif;min-height:100vh;position:relative;background:#f5f5f5;"))
         (:div (@ (style "padding:20px;"))
           (:p (@ (style "margin:0;color:#666;font-size:14px;"))
               "Click an action button to close the dialog.")
           ,@(when (not (string= last-action ""))
               `((:p (@ (style "margin-top:12px;color:#333;font-size:14px;"))
                   "Last action: \"" ,last-action "\"")
                 (:button (@ (onclick (reopen))
                             (style "margin-top:8px;padding:6px 14px;border:1px solid #1976d2;border-radius:4px;background:#fff;color:#1976d2;cursor:pointer;font-size:13px;"))
                   "Reopen dialog"))))
         ,@(when open
             `((dialog
                 (dialog-title ,(or title "Dialog"))
                 (dialog-content
                   (:p ,(or content "Dialog content.")))
                 (dialog-actions
                   ,@(when (and action2-label (not (string= action2-label "")))
                       `((dialog-action (@ (onclick (do-action2))) ,action2-label)))
                   (dialog-action (@ (onclick (do-action1))) ,(or action1-label "OK"))))))))))

(spec-sheet:defspec dialog
  :description "Modal overlay dialog with header, content area, and footer action buttons"
  :component #'cl-s3r.components.dialog:dialog
  :render #'(lambda (&key title content action1-label action2-label)
              `(:div
                 (dialog-spec-demo (@ (title         ,(or title "Dialog"))
                                      (content       ,(or content "Dialog content."))
                                      (action1-label ,(or action1-label "OK"))
                                      (action2-label ,(or action2-label ""))))))
  :props '((title         :type string
                          :default "Dialog"
                          :description "Text shown in the dialog header")
           (content       :type string
                          :default "Dialog content."
                          :description "Text shown in the dialog body")
           (action1-label :type string
                          :default "OK"
                          :description "Primary action button label")
           (action2-label :type string
                          :default ""
                          :description "Secondary action button label (empty = hidden)")))

(spec-sheet:defsheet dialog alert
  :title "Alert (single button)"
  :params '(:title         "Alert"
            :content       "Something happened."
            :action1-label "OK"
            :action2-label ""))

(spec-sheet:defsheet dialog confirm
  :title "Confirm (two buttons)"
  :params '(:title         "Confirm"
            :content       "Are you sure? This action cannot be undone."
            :action1-label "Yes"
            :action2-label "No"))

(spec-sheet:defsheet dialog long-content
  :title "Long content"
  :params '(:title         "Terms of Service"
            :content       "By using this service you agree to the following terms. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
            :action1-label "Accept"
            :action2-label "Decline"))

;;; --- text input sheet ---

(cl-s3r.component:define-component dialog-input-demo (&key &allow-other-keys)
  (cl-s3r.component:let-component-state ((open t)
                                          (entered ""))
    (cl-s3r.component:let-function
        ((do-ok     (form-data)
           (let ((val (getf form-data :|text-input|)))
             (setf open nil)
             (when (and val (not (string= val "")))
               (setf entered val))))
         (do-cancel () (setf open nil))
         (reopen    () (setf open t) (setf entered "")))
      `(:div (@ (style "font-family:sans-serif;min-height:100vh;position:relative;background:#f5f5f5;"))
         (:div (@ (style "padding:20px;"))
           (:p (@ (style "margin:0;color:#666;font-size:14px;"))
               "Enter text and click OK.")
           ,@(when (not (string= entered ""))
               `((:p (@ (style "margin-top:12px;color:#333;font-size:14px;"))
                   "Entered: \"" ,entered "\"")
                 (:button (@ (onclick (reopen))
                             (style "margin-top:8px;padding:6px 14px;border:1px solid #1976d2;border-radius:4px;background:#fff;color:#1976d2;cursor:pointer;font-size:13px;"))
                   "Reopen dialog"))))
         ,@(when open
             `((dialog
                 (dialog-title "Enter your name")
                 (dialog-content
                   (:form (@ (id "spec-input-form") (onsubmit (do-ok)))
                     (:label (@ (style "display:block;margin-bottom:6px;font-size:14px;color:#555;font-weight:500;"))
                       "Name")
                     (:input (@ (type "text") (name "text-input")
                                (placeholder "e.g. John Doe")
                                (style "padding:8px 10px;border:1px solid #ccc;border-radius:4px;width:100%;box-sizing:border-box;font-size:14px;")))))
                 (dialog-actions
                   (dialog-action (@ (onclick (do-cancel))) "Cancel")
                   (dialog-action (@ (type "submit") (form "spec-input-form")) "OK")))))))))

(spec-sheet:defsheet dialog text-input
  :title "Text input"
  :render #'(lambda (&key &allow-other-keys)
              `(:div (dialog-input-demo))))

;;; --- rich content sheet ---

(cl-s3r.component:define-component dialog-rich-demo (&key &allow-other-keys)
  (cl-s3r.component:let-component-state ((open t))
    (cl-s3r.component:let-function
        ((do-close () (setf open nil))
         (reopen   () (setf open t)))
      `(:div (@ (style "font-family:sans-serif;min-height:100vh;position:relative;background:#f5f5f5;"))
         (:div (@ (style "padding:20px;"))
           (:p (@ (style "margin:0;color:#666;font-size:14px;"))
               "A dialog with rich content: h1, img, and icon.")
           ,@(when (not open)
               `((:button (@ (onclick (reopen))
                             (style "margin-top:8px;padding:6px 14px;border:1px solid #1976d2;border-radius:4px;background:#fff;color:#1976d2;cursor:pointer;font-size:13px;"))
                   "Reopen dialog"))))
         ,@(when open
             `((dialog
                 (dialog-title "Rich Content")
                 (dialog-content
                   (:h1 (@ (style "margin:0 0 12px;font-size:20px;color:#333;"))
                     "Hello, World!")
                   (:img (@ (src "https://picsum.photos/300/200")
                            (alt "Sample image")
                            (style "display:block;border-radius:4px;margin-bottom:12px;")))
                   (cl-s3r.components.icon:icon (@ (value "fa-star") (size "M")))
                   (:span (@ (style "margin-left:6px;font-size:14px;color:#555;")) "fa-star icon"))
                 (dialog-actions
                   (dialog-action (@ (onclick (do-close))) "Close")))))))))

(spec-sheet:defsheet dialog rich-content
  :title "Rich content (h1, img, icon)"
  :render #'(lambda (&key &allow-other-keys)
              `(:div (dialog-rich-demo))))
