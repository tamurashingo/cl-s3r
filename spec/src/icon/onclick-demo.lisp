(ql:quickload :cl-s3r.components.icon :silent t)

(cl-s3r.component:define-component icon-onclick-demo (&key size)
  (cl-s3r.component:let-component-state ((liked nil))
    (cl-s3r.component:let-function
        ((toggle-like () (setf liked (not liked))))
      `(:div (@ (style "display:flex;flex-direction:column;align-items:center;gap:12px;padding:24px;"))
         (:p (@ (style "font-size:14px;margin:0;color:#666;"))
             ,(if liked "Liked!" "Click the icon"))
         (cl-s3r.components.icon:icon (@ (value "fa-heart")
                                        (size ,size)
                                        (color ,(if liked "#e91e63" "#ccc"))
                                        (onclick (toggle-like))))))))

(spec-sheet:defsheet icon onclick-like
  :title "onclick like"
  :render #'(lambda (&key size &allow-other-keys)
              `(icon-onclick-demo (@ (size ,size))))
  :params '(:size "XL"))
