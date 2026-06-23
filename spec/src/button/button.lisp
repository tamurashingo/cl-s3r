(ql:quickload :cl-s3r.components.button :silent t)
(ql:quickload :cl-s3r.components.icon   :silent t)

(spec-sheet:defspec button
  :description "Clickable button with variant, size, optional prefix/suffix icons, and disabled state"
  :component #'cl-s3r.components.button:button
  :render #'(lambda (&key variant prefix suffix size disabled background-color color)
              (let* ((effective-variant (if (and variant (not (string= variant "")))
                                            variant
                                            "contained"))
                     (effective-size    (if (and size (not (string= size "")))
                                            size
                                            "medium"))
                     (disabled-val      (string= disabled "true"))
                     (effective-bg      (if (and background-color (not (string= background-color "")))
                                            background-color
                                            nil))
                     (effective-color   (if (and color (not (string= color "")))
                                            color
                                            nil))
                     (button-attrs      `((variant ,effective-variant)
                                          (size    ,effective-size)
                                          ,@(when (and prefix (not (string= prefix "")))
                                              `((prefix ,prefix)))
                                          ,@(when (and suffix (not (string= suffix "")))
                                              `((suffix ,suffix)))
                                          ,@(when disabled-val
                                              `((disabled t)))
                                          ,@(when effective-bg
                                              `((background-color ,effective-bg)))
                                          ,@(when effective-color
                                              `((color ,effective-color))))))
                `(:div
                   (:style "
body { font-family: sans-serif; }
.button-demo {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 3rem;
  gap: 1rem;
  flex-wrap: wrap;
}
")
                   (:div (@ (class "button-demo"))
                     (button (@ ,@button-attrs) "Button")))))
  :props '((variant  :type (member "contained" "outlined" "text")
                     :default "contained"
                     :description "Visual style: contained=filled, outlined=border only, text=no border")
           (prefix   :type string
                     :default ""
                     :description "FontAwesome icon value shown before the label (e.g. fa-bell)")
           (suffix   :type string
                     :default ""
                     :description "FontAwesome icon value shown after the label (e.g. fa-bell)")
           (size     :type (member "small" "medium" "large")
                     :default "medium"
                     :description "Button size: small=3px 9px padding, medium=5px 15px, large=7px 21px")
           (disabled :type (member "false" "true")
                     :default "false"
                     :description "When true, renders disabled attribute and applies muted styling")
           (background-color :type string
                             :default ""
                             :description "Button background color (empty = variant default)")
           (color :type string
                  :default ""
                  :description "Button text color (empty = variant default)")))

(spec-sheet:defsheet button contained-default
  :title "Contained (default)"
  :params '(:variant "contained"))

(spec-sheet:defsheet button outlined-default
  :title "Outlined"
  :params '(:variant "outlined"))

(spec-sheet:defsheet button text-default
  :title "Text"
  :params '(:variant "text"))

(spec-sheet:defsheet button with-prefix-icon
  :title "With prefix icon"
  :params '(:variant "contained" :prefix "fa-bell"))

(spec-sheet:defsheet button with-suffix-icon
  :title "With suffix icon"
  :params '(:variant "outlined" :suffix "fa-paper-plane"))

(spec-sheet:defsheet button small-size
  :title "Small size"
  :params '(:size "small"))

(spec-sheet:defsheet button medium-size
  :title "Medium size"
  :params '(:size "medium"))

(spec-sheet:defsheet button large-size
  :title "Large size"
  :params '(:size "large"))

(spec-sheet:defsheet button disabled-state
  :title "Disabled"
  :params '(:variant "contained" :disabled "true"))
