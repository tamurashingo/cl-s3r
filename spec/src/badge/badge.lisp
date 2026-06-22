(ql:quickload :cl-s3r.components.badge :silent t)
(ql:quickload :cl-s3r.components.icon  :silent t)

(spec-sheet:defspec badge
  :description "Small status indicator; floats over a child icon or stands alone"
  :component #'cl-s3r.components.badge:badge
  :render #'(lambda (&key count overflow-count show-zero background-color color variant with-icon)
              (let* ((count-val              (if (and count (not (string= count "")))
                                                 (parse-integer count :junk-allowed t)
                                                 0))
                     (overflow-count-val     (if (and overflow-count (not (string= overflow-count "")))
                                                 (parse-integer overflow-count :junk-allowed t)
                                                 99))
                     (show-zero-val          (string= show-zero "true"))
                     (effective-bg-color     (if (and background-color (not (string= background-color "")))
                                                 background-color
                                                 nil))
                     (effective-color        (if (and color (not (string= color "")))
                                                 color
                                                 nil))
                     (effective-variant      (or variant "standard"))
                     (with-icon-p            (string= with-icon "true"))
                     (badge-attrs            `((count          ,count-val)
                                               (overflow-count ,overflow-count-val)
                                               (show-zero      ,show-zero-val)
                                               ,@(when effective-bg-color
                                                   `((background-color ,effective-bg-color)))
                                               ,@(when effective-color
                                                   `((color ,effective-color)))
                                               (variant        ,effective-variant))))
                `(:div
                   (:style "
body { font-family: sans-serif; }
.badge-demo {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 3rem;
}
")
                   (:div (@ (class "badge-demo"))
                     ,(if with-icon-p
                          `(badge (@ ,@badge-attrs)
                             (icon (@ (value "fa-bell")
                                      (size "L"))))
                          `(badge (@ ,@badge-attrs)))))))
  :props '((count            :type string
                             :default "0"
                             :description "Number to display")
           (overflow-count   :type string
                             :default "99"
                             :description "Values above this show as N+")
           (show-zero        :type (member "false" "true")
                             :default "true"
                             :description "Show badge even when count is 0")
           (background-color :type string
                             :default ""
                             :description "Badge background color (empty = red)")
           (color            :type string
                             :default ""
                             :description "Badge text color (empty = white)")
           (variant        :type (member "standard" "dot")
                           :default "standard"
                           :description "standard = number circle / dot = small dot")
           (with-icon      :type (member "false" "true")
                           :default "false"
                           :description "Render badge overlaid on an icon")))

(spec-sheet:defsheet badge standard-alone
  :title "Standard circle"
  :params '(:count "3" :variant "standard" :with-icon "false"))

(spec-sheet:defsheet badge dot-alone
  :title "Standard dot"
  :params '(:count "3" :variant "dot" :with-icon "false"))

(spec-sheet:defsheet badge overflow-alone
  :title "Standard circle 99+"
  :params '(:count "100" :overflow-count "99" :variant "standard" :with-icon "false"))

(spec-sheet:defsheet badge standard-icon
  :title "Icon circle"
  :params '(:count "3" :variant "standard" :with-icon "true"))

(spec-sheet:defsheet badge dot-icon
  :title "Icon dot"
  :params '(:count "3" :variant "dot" :with-icon "true"))

(spec-sheet:defsheet badge overflow-icon
  :title "Icon circle 99+"
  :params '(:count "100" :overflow-count "99" :variant "standard" :with-icon "true"))
