(ql:quickload :cl-s3r.components.button :silent t)

(cl-s3r.component:define-component button-onclick-counter (&key variant size disabled)
  (cl-s3r.component:let-component-state ((count 0))
    (cl-s3r.component:let-function
        ((on-click () (incf count)))
      `(:div (@ (style "display:flex;flex-direction:column;align-items:center;gap:16px;padding:24px;"))
         (:p (@ (style "font-size:18px;margin:0;color:#333;font-weight:500;"))
             ,(format nil "Count: ~A" count))
         (cl-s3r.components.button:button (@ (variant ,variant)
                                             (size ,size)
                                             (disabled ,disabled)
                                             (onclick (on-click))) "Click me!")))))

(spec-sheet:defsheet button onclick-counter
  :title "onclick counter"
  :render #'(lambda (&key variant size disabled &allow-other-keys)
              (let ((disabled-val (string= disabled "true")))
                `(button-onclick-counter (@ (variant ,variant)
                                           (size ,size)
                                           (disabled ,disabled-val)))))
  :params '(:variant "contained" :size "medium" :disabled "false"))
