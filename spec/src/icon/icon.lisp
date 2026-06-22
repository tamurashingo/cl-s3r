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
                       (:span (@ (class "icon-label")) "fa-address-book"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-address-card")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-address-card"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-alarm-clock")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-alarm-clock"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-angry")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-angry"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-arrow-alt-circle-down")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-arrow-alt-circle-down"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-arrow-alt-circle-left")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-arrow-alt-circle-left"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-arrow-alt-circle-right")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-arrow-alt-circle-right"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-arrow-alt-circle-up")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-arrow-alt-circle-up"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-bar-chart")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-bar-chart"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-bell-slash")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-bell-slash"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-bell")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-bell"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-bookmark")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-bookmark"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-building")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-building"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-check")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-check"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-days")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-days"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-minus")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-minus"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-plus")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-plus"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-times")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-times"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-calendar-xmark")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-calendar-xmark"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-camera-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-camera-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-camera")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-camera"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-caret-square-down")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-caret-square-down"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-caret-square-left")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-caret-square-left"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-caret-square-right")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-caret-square-right"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-caret-square-up")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-caret-square-up"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chart-bar")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chart-bar"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-check-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-check-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-check-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-check-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chess-bishop")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chess-bishop"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chess-king")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chess-king"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chess-knight")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chess-knight"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chess-pawn")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chess-pawn"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chess-queen")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chess-queen"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-chess-rook")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-chess-rook"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-check")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-check"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-dot")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-dot"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-down")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-down"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-left")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-left"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-pause")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-pause"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-play")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-play"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-question")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-question"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-right")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-right"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-stop")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-stop"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-up")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-up"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-user")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-user"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-circle-xmark")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-circle-xmark"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-clipboard")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-clipboard"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-clock-four")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-clock-four"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-clock")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-clock"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-clone")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-clone"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-closed-captioning")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-closed-captioning"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-cloud")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-cloud"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-comment-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-comment-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-comment-dots")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-comment-dots"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-commenting")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-commenting"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-comments")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-comments"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-comment")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-comment"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-compass")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-compass"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-contact-book")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-contact-book"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-contact-card")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-contact-card"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-copyright")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-copyright"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-copy")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-copy"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-credit-card-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-credit-card-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-credit-card")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-credit-card"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-dizzy")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-dizzy"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-dot-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-dot-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-drivers-license")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-drivers-license"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-edit")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-edit"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-envelope-open")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-envelope-open"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-envelope")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-envelope"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-eye-slash")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-eye-slash"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-eye")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-eye"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-angry")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-angry"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-dizzy")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-dizzy"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-flushed")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-flushed"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-frown-open")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-frown-open"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-frown")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-frown"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grimace")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grimace"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-beam-sweat")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-beam-sweat"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-hearts")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-hearts"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-squint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-squint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-squint-tears")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-squint-tears"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-stars")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-stars"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-tears")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-tears"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-tongue-squint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-tongue-squint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-tongue")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-tongue"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-tongue-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-tongue-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-wide")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-wide"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-grin-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-grin-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-kiss-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-kiss-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-kiss")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-kiss"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-kiss-wink-heart")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-kiss-wink-heart"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-laugh-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-laugh-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-laugh-squint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-laugh-squint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-laugh")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-laugh"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-laugh-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-laugh-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-meh-blank")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-meh-blank"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-meh")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-meh"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-rolling-eyes")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-rolling-eyes"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-sad-cry")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-sad-cry"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-sad-tear")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-sad-tear"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-smile-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-smile-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-smile")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-smile"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-smile-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-smile-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-surprise")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-surprise"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-face-tired")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-face-tired"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-archive")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-archive"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-audio")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-audio"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-clipboard")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-clipboard"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-code")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-code"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-excel")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-excel"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-image")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-image"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-lines")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-lines"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-pdf")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-pdf"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-powerpoint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-powerpoint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-text")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-text"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-video")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-video"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-word")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-word"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-file-zipper")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-file-zipper"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-flag")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-flag"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-floppy-disk")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-floppy-disk"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-flushed")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-flushed"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-folder-blank")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-folder-blank"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-folder-closed")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-folder-closed"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-folder-open")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-folder-open"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-folder")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-folder"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-font-awesome-flag")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-font-awesome-flag"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-font-awesome-logo-full")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-font-awesome-logo-full"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-font-awesome")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-font-awesome"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-frown-open")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-frown-open"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-frown")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-frown"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-futbol-ball")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-futbol-ball"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-futbol")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-futbol"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-gem")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-gem"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grimace")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grimace"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-beam-sweat")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-beam-sweat"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-hearts")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-hearts"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-squint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-squint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-squint-tears")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-squint-tears"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-stars")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-stars"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-tears")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-tears"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-tongue-squint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-tongue-squint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-tongue")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-tongue"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-tongue-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-tongue-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-grin-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-grin-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-back-fist")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-back-fist"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-lizard")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-lizard"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-paper")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-paper"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-peace")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-peace"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-point-down")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-point-down"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-pointer")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-pointer"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-point-left")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-point-left"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-point-right")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-point-right"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-point-up")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-point-up"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-rock")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-rock"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-scissors")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-scissors"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-handshake-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-handshake-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-handshake-simple")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-handshake-simple"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-handshake")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-handshake"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand-spock")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand-spock"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hand")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hand"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hard-drive")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hard-drive"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hdd")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hdd"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-headphones-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-headphones-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-headphones-simple")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-headphones-simple"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-headphones")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-headphones"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-heart")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-heart"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-home-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-home-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-home-lg-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-home-lg-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-home")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-home"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hospital-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hospital-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hospital")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hospital"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hospital-wide")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hospital-wide"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hourglass-2")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hourglass-2"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hourglass-empty")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hourglass-empty"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hourglass-half")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hourglass-half"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-hourglass")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-hourglass"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-house")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-house"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-id-badge")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-id-badge"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-id-card")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-id-card"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-images")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-images"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-image")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-image"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-keyboard")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-keyboard"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-kiss-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-kiss-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-kiss")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-kiss"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-kiss-wink-heart")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-kiss-wink-heart"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-laugh-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-laugh-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-laugh-squint")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-laugh-squint"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-laugh")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-laugh"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-laugh-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-laugh-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-lemon")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-lemon"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-life-ring")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-life-ring"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-lightbulb")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-lightbulb"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-list-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-list-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-map")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-map"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-meh-blank")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-meh-blank"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-meh-rolling-eyes")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-meh-rolling-eyes"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-meh")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-meh"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-message")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-message"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-minus-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-minus-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-money-bill-1")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-money-bill-1"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-money-bill-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-money-bill-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-moon")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-moon"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-newspaper")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-newspaper"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-note-sticky")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-note-sticky"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-object-group")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-object-group"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-object-ungroup")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-object-ungroup"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-paper-plane")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-paper-plane"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-paste")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-paste"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-pause-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-pause-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-pen-to-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-pen-to-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-play-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-play-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-plus-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-plus-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-question-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-question-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-rectangle-list")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-rectangle-list"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-rectangle-times")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-rectangle-times"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-rectangle-xmark")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-rectangle-xmark"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-registered")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-registered"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-sad-cry")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-sad-cry"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-sad-tear")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-sad-tear"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-save")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-save"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-share-from-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-share-from-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-share-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-share-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-smile-beam")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-smile-beam"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-smile")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-smile"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-smile-wink")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-smile-wink"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-snowflake")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-snowflake"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-soccer-ball")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-soccer-ball"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-caret-down")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-caret-down"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-caret-left")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-caret-left"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-caret-right")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-caret-right"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-caret-up")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-caret-up"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-check")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-check"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-full")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-full"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-minus")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-minus"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square-plus")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square-plus"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-square")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-square"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-star-half-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-star-half-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-star-half-stroke")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-star-half-stroke"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-star-half")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-star-half"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-star")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-star"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-sticky-note")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-sticky-note"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-stop-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-stop-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-sun")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-sun"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-surprise")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-surprise"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-thumbs-down")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-thumbs-down"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-thumbs-up")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-thumbs-up"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-times-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-times-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-times-rectangle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-times-rectangle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-tired")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-tired"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-trash-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-trash-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-trash-can")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-trash-can"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-truck")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-truck"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-user-alt")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-user-alt"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-user-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-user-circle"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-user-large")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-user-large"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-user")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-user"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-vcard")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-vcard"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-window-close")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-window-close"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-window-maximize")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-window-maximize"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-window-minimize")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-window-minimize"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-window-restore")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-window-restore"))
                     (:div (@ (class "icon-item"))
                       (icon (@ (value "fa-xmark-circle")
                                ,@color-attrs
                                (size ,size-val)))
                       (:span (@ (class "icon-label")) "fa-xmark-circle"))))))
  :props '((color :type string
                  :default ""
                  :description "CSS color value (e.g. #333, red, currentColor)")
           (size  :type (member "XXS" "XS" "S" "M" "L" "XL" "XXL")
                  :default "M"
                  :description "Icon size: XXS=12px XS=16px S=20px M=24px L=32px XL=48px XXL=64px")))

(spec-sheet:defsheet icon all-icons
  :title "All icons"
  :params '())
