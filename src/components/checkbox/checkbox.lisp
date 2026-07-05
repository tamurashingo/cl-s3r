(defpackage #:cl-s3r.components.checkbox
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function)
  (:export #:checkbox
           #:checkbox-render))

(in-package #:cl-s3r.components.checkbox)

(defvar *checkbox-css*
  (concatenate 'string
               ".cl-s3r-checkbox{"
               "display:inline-flex;"
               "align-items:center;"
               "gap:8px;"
               "cursor:pointer;"
               "vertical-align:middle;}"
               ".cl-s3r-checkbox--disabled{"
               "cursor:not-allowed;"
               "opacity:0.5;}"
               ".cl-s3r-checkbox--inert{"
               "pointer-events:none;}"
               ".cl-s3r-checkbox-native{"
               "position:absolute;"
               "width:1px;"
               "height:1px;"
               "margin:-1px;"
               "opacity:0;"
               "overflow:hidden;"
               "clip:rect(0,0,0,0);"
               "white-space:nowrap;}"
               ".cl-s3r-checkbox-box{"
               "box-sizing:border-box;"
               "display:inline-flex;"
               "align-items:center;"
               "justify-content:center;"
               "width:18px;"
               "height:18px;"
               "border:2px solid var(--checkbox-border-color,#1976d2);"
               "border-radius:3px;"
               "background:#fff;"
               "transition:background-color 0.15s ease,border-color 0.15s ease;}"
               ".cl-s3r-checkbox-box--checked{"
               "background:var(--checkbox-checked-bg,#1976d2);"
               "border-color:var(--checkbox-checked-bg,#1976d2);}"
               ".cl-s3r-checkbox-mark{"
               "display:block;}"))

(defvar *checkbox-checkmark*
  '(:svg (@ (class "cl-s3r-checkbox-mark")
            (xmlns "http://www.w3.org/2000/svg")
            (viewbox "0 0 16 16")
            (width "12")
            (height "12")
            (fill "none"))
     (:polyline (@ (points "3,8 7,12 13,4")
                   (stroke "#fff")
                   (stroke-width "2")
                   (stroke-linecap "round")
                   (stroke-linejoin "round")))))

(defun native-checkbox-input (checked disabled name value)
  "Build the visually-hidden native <input type=\"checkbox\"> that lets a
real HTML <form> pick this checkbox up via FormData/native submission.
Removed from tab order and the accessibility tree via tabindex=\"-1\" and
aria-hidden=\"true\" -- the outer <label role=\"checkbox\"> is already the
interactive/accessible surface."
  `(:input (@ (type "checkbox")
              (class "cl-s3r-checkbox-native")
              (name ,name)
              ,@(when value `((value ,value)))
              (tabindex "-1")
              (aria-hidden "true")
              ,@(when checked '((checked "")))
              ,@(when disabled '((disabled ""))))))

(defun checkbox-render (checked disabled onclick-action &optional children name value)
  "Build the checkbox's rendered <label> tree.
ONCLICK-ACTION, when non-nil, is spliced in verbatim as the onclick attribute;
when nil (or DISABLED is true), no onclick/data-on-click attribute is emitted.
Rendering the root as a <label> (rather than a bare <span>) means CHILDREN --
e.g. label text passed as trailing forms -- sits inside the same clickable
element as the box, so clicking the text toggles the checkbox exactly like
clicking the box itself.
NAME, when given, adds a hidden native <input type=\"checkbox\"> for real
HTML form submission. When NAME is given and there is no click handler
(disabled, or controlled with no onclick), the label gets the --inert class
so pointer-events:none stops label-click from forwarding a native toggle to
that hidden input, which would otherwise desync it from server-driven state."
  (let* ((has-handler-p (not (null onclick-action)))
         (box-class (if checked
                        "cl-s3r-checkbox-box cl-s3r-checkbox-box--checked"
                        "cl-s3r-checkbox-box"))
         (root-class (format nil "cl-s3r-checkbox~A~A"
                              (if disabled " cl-s3r-checkbox--disabled" "")
                              (if (and name (not has-handler-p))
                                  " cl-s3r-checkbox--inert" ""))))
    `(:label (@ (class ,root-class)
                (role "checkbox")
                (aria-checked ,(if checked "true" "false"))
                ,@(when disabled '((aria-disabled "true")))
                ,@(when (and onclick-action (not disabled))
                    `((onclick ,onclick-action))))
       (:style ,*checkbox-css*)
       (:span (@ (class ,box-class))
         ,@(when checked (list *checkbox-checkmark*)))
       ,@(when name (list (native-checkbox-input checked disabled name value)))
       ,@(when children (if (listp children) children (list children))))))

(define-component checkbox (&key initial-checked disabled
                                  (checked nil checked-p)
                                  onclick children name value
                                  &allow-other-keys)
  (if (or checked-p onclick)
      (let* ((effective-checked (if checked-p checked initial-checked))
             (effective-onclick (when (and onclick (not disabled))
                                   (append onclick
                                           (list (if effective-checked t :false))))))
        (checkbox-render effective-checked disabled effective-onclick children name value))
      (let-component-state ((is-checked initial-checked))
        (let-function
            ((toggle ()
               (unless disabled
                 (setf is-checked (not is-checked)))))
          (checkbox-render is-checked disabled
                            (unless disabled '(toggle))
                            children name value)))))
