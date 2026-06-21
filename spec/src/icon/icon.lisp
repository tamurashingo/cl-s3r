(ql:quickload :cl-s3r.components.icon :silent t)

(spec-sheet:defspec icon
  :description "Font Awesome SVG icons rendered inline"
  :component #'cl-s3r.components.icon:icon
  :render #'(lambda (&key color size)
              (let ((color-attrs (when (and color (plusp (length color)))
                                   `((color ,color))))
                    (size-val (or size "M")))
                `(:div
                   (:style "
body { font-family: sans-serif; padding: 1.5rem; }
.icon-grid { display: flex; flex-wrap: wrap; gap: 2rem; }
.icon-item { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; width: 80px; }
.icon-label { font-size: 11px; color: #666; text-align: center; word-break: break-all; }
")
                   (:div (@ (class "icon-grid"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-address-book")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-address-book"))))))
  :props '((color :type string
                  :default ""
                  :description "CSS color value (e.g. #333, red, currentColor)")
           (size  :type (member "XXS" "XS" "S" "M" "L" "XL" "XXL")
                  :default "M"
                  :description "Icon size: XXS=12px XS=16px S=20px M=24px L=32px XL=48px XXL=64px")))

(spec-sheet:defsheet icon all-icons
  :title "All icons"
  :params '())
