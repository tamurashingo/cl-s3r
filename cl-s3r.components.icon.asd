(defsystem "cl-s3r.components.icon"
  :version "0.1.0"
  :author "tamurashingo"
  :license "MIT"
  :depends-on ("cl-s3r")
  :components ((:module "src/components/icon"
                :components ((:file "util")
                             (:file "fa-address-book" :depends-on ("util"))
                             (:file "fa-address-card" :depends-on ("util"))
                             (:file "fa-alarm-clock" :depends-on ("util"))
                             (:file "fa-angry" :depends-on ("util"))
                             (:file "fa-arrow-alt-circle-down" :depends-on ("util"))
                             (:file "fa-arrow-alt-circle-left" :depends-on ("util"))
                             (:file "fa-arrow-alt-circle-right" :depends-on ("util"))
                             (:file "fa-arrow-alt-circle-up" :depends-on ("util"))
                             (:file "fa-bar-chart" :depends-on ("util"))
                             (:file "fa-bell-slash" :depends-on ("util"))
                             (:file "fa-bell" :depends-on ("util"))
                             (:file "fa-bookmark" :depends-on ("util"))
                             (:file "fa-building" :depends-on ("util"))
                             (:file "fa-calendar-alt" :depends-on ("util"))
                             (:file "fa-calendar-check" :depends-on ("util"))
                             (:file "fa-calendar-days" :depends-on ("util"))
                             (:file "fa-calendar-minus" :depends-on ("util"))
                             (:file "fa-calendar-plus" :depends-on ("util"))
                             (:file "fa-calendar" :depends-on ("util"))
                             (:file "fa-calendar-times" :depends-on ("util"))
                             (:file "fa-calendar-xmark" :depends-on ("util"))
                             (:file "fa-camera-alt" :depends-on ("util"))
                             (:file "fa-camera" :depends-on ("util"))
                             (:file "fa-caret-square-down" :depends-on ("util"))
                             (:file "fa-caret-square-left" :depends-on ("util"))
                             (:file "fa-caret-square-right" :depends-on ("util"))
                             (:file "fa-caret-square-up" :depends-on ("util"))
                             (:file "fa-chart-bar" :depends-on ("util"))
                             (:file "fa-check-circle" :depends-on ("util"))
                             (:file "fa-check-square" :depends-on ("util"))
                             (:file "fa-chess-bishop" :depends-on ("util"))
                             (:file "fa-chess-king" :depends-on ("util"))
                             (:file "fa-chess-knight" :depends-on ("util"))
                             (:file "fa-chess-pawn" :depends-on ("util"))
                             (:file "fa-chess-queen" :depends-on ("util"))
                             (:file "fa-chess-rook" :depends-on ("util"))
                             (:file "fa-circle-check" :depends-on ("util"))
                             (:file "fa-circle-dot" :depends-on ("util"))
                             (:file "fa-circle-down" :depends-on ("util"))
                             (:file "fa-circle-left" :depends-on ("util"))
                             (:file "fa-circle-pause" :depends-on ("util"))
                             (:file "fa-circle-play" :depends-on ("util"))
                             (:file "fa-circle-question" :depends-on ("util"))
                             (:file "fa-circle-right" :depends-on ("util"))
                             (:file "fa-circle-stop" :depends-on ("util"))
                             (:file "fa-circle" :depends-on ("util"))
                             (:file "fa-circle-up" :depends-on ("util"))
                             (:file "fa-circle-user" :depends-on ("util"))
                             (:file "fa-circle-xmark" :depends-on ("util"))
                             (:file "fa-clipboard" :depends-on ("util"))
                             (:file "fa-clock-four" :depends-on ("util"))
                             (:file "fa-clock" :depends-on ("util"))
                             (:file "fa-clone" :depends-on ("util"))
                             (:file "fa-closed-captioning" :depends-on ("util"))
                             (:file "fa-cloud" :depends-on ("util"))
                             (:file "fa-comment-alt" :depends-on ("util"))
                             (:file "fa-comment-dots" :depends-on ("util"))
                             (:file "fa-commenting" :depends-on ("util"))
                             (:file "fa-comments" :depends-on ("util"))
                             (:file "fa-comment" :depends-on ("util"))
                             (:file "fa-compass" :depends-on ("util"))
                             (:file "fa-contact-book" :depends-on ("util"))
                             (:file "fa-contact-card" :depends-on ("util"))
                             (:file "fa-copyright" :depends-on ("util"))
                             (:file "fa-copy" :depends-on ("util"))
                             (:file "fa-credit-card-alt" :depends-on ("util"))
                             (:file "fa-credit-card" :depends-on ("util"))
                             (:file "fa-dizzy" :depends-on ("util"))
                             (:file "fa-dot-circle" :depends-on ("util"))
                             (:file "fa-drivers-license" :depends-on ("util"))
                             (:file "fa-edit" :depends-on ("util"))
                             (:file "fa-envelope-open" :depends-on ("util"))
                             (:file "fa-envelope" :depends-on ("util"))
                             (:file "fa-eye-slash" :depends-on ("util"))
                             (:file "fa-eye" :depends-on ("util"))
                             (:file "fa-face-angry" :depends-on ("util"))
                             (:file "fa-face-dizzy" :depends-on ("util"))
                             (:file "fa-face-flushed" :depends-on ("util"))
                             (:file "fa-face-frown-open" :depends-on ("util"))
                             (:file "fa-face-frown" :depends-on ("util"))
                             (:file "fa-face-grimace" :depends-on ("util"))
                             (:file "fa-face-grin-beam" :depends-on ("util"))
                             (:file "fa-face-grin-beam-sweat" :depends-on ("util"))
                             (:file "fa-face-grin-hearts" :depends-on ("util"))
                             (:file "fa-face-grin-squint" :depends-on ("util"))
                             (:file "fa-face-grin-squint-tears" :depends-on ("util"))
                             (:file "fa-face-grin-stars" :depends-on ("util"))
                             (:file "fa-face-grin" :depends-on ("util"))
                             (:file "fa-face-grin-tears" :depends-on ("util"))
                             (:file "fa-face-grin-tongue-squint" :depends-on ("util"))
                             (:file "fa-face-grin-tongue" :depends-on ("util"))
                             (:file "fa-face-grin-tongue-wink" :depends-on ("util"))
                             (:file "fa-face-grin-wide" :depends-on ("util"))
                             (:file "fa-face-grin-wink" :depends-on ("util"))
                             (:file "fa-face-kiss-beam" :depends-on ("util"))
                             (:file "fa-face-kiss" :depends-on ("util"))
                             (:file "fa-face-kiss-wink-heart" :depends-on ("util"))
                             (:file "fa-face-laugh-beam" :depends-on ("util"))
                             (:file "fa-face-laugh-squint" :depends-on ("util"))
                             (:file "fa-face-laugh" :depends-on ("util"))
                             (:file "fa-face-laugh-wink" :depends-on ("util"))
                             (:file "fa-face-meh-blank" :depends-on ("util"))
                             (:file "fa-face-meh" :depends-on ("util"))
                             (:file "fa-face-rolling-eyes" :depends-on ("util"))
                             (:file "fa-face-sad-cry" :depends-on ("util"))
                             (:file "fa-face-sad-tear" :depends-on ("util"))
                             (:file "fa-face-smile-beam" :depends-on ("util"))
                             (:file "fa-face-smile" :depends-on ("util"))
                             (:file "fa-face-smile-wink" :depends-on ("util"))
                             (:file "fa-face-surprise" :depends-on ("util"))
                             (:file "fa-face-tired" :depends-on ("util"))
                             (:file "fa-file-alt" :depends-on ("util"))
                             (:file "fa-file-archive" :depends-on ("util"))
                             (:file "fa-file-audio" :depends-on ("util"))
                             (:file "fa-file-clipboard" :depends-on ("util"))
                             (:file "fa-file-code" :depends-on ("util"))
                             (:file "fa-file-excel" :depends-on ("util"))
                             (:file "fa-file-image" :depends-on ("util"))
                             (:file "fa-file-lines" :depends-on ("util"))
                             (:file "fa-file-pdf" :depends-on ("util"))
                             (:file "fa-file-powerpoint" :depends-on ("util"))
                             (:file "fa-file" :depends-on ("util"))
                             (:file "fa-file-text" :depends-on ("util"))
                             (:file "fa-file-video" :depends-on ("util"))
                             (:file "fa-file-word" :depends-on ("util"))
                             (:file "fa-file-zipper" :depends-on ("util"))
                             (:file "fa-flag" :depends-on ("util"))
                             (:file "fa-floppy-disk" :depends-on ("util"))
                             (:file "fa-flushed" :depends-on ("util"))
                             (:file "fa-folder-blank" :depends-on ("util"))
                             (:file "fa-folder-closed" :depends-on ("util"))
                             (:file "fa-folder-open" :depends-on ("util"))
                             (:file "fa-folder" :depends-on ("util"))
                             (:file "fa-font-awesome-flag" :depends-on ("util"))
                             (:file "fa-font-awesome-logo-full" :depends-on ("util"))
                             (:file "fa-font-awesome" :depends-on ("util"))
                             (:file "fa-frown-open" :depends-on ("util"))
                             (:file "fa-frown" :depends-on ("util"))
                             (:file "fa-futbol-ball" :depends-on ("util"))
                             (:file "fa-futbol" :depends-on ("util"))
                             (:file "fa-gem" :depends-on ("util"))
                             (:file "fa-grimace" :depends-on ("util"))
                             (:file "fa-grin-alt" :depends-on ("util"))
                             (:file "fa-grin-beam" :depends-on ("util"))
                             (:file "fa-grin-beam-sweat" :depends-on ("util"))
                             (:file "fa-grin-hearts" :depends-on ("util"))
                             (:file "fa-grin-squint" :depends-on ("util"))
                             (:file "fa-grin-squint-tears" :depends-on ("util"))
                             (:file "fa-grin-stars" :depends-on ("util"))
                             (:file "fa-grin" :depends-on ("util"))
                             (:file "fa-grin-tears" :depends-on ("util"))
                             (:file "fa-grin-tongue-squint" :depends-on ("util"))
                             (:file "fa-grin-tongue" :depends-on ("util"))
                             (:file "fa-grin-tongue-wink" :depends-on ("util"))
                             (:file "fa-grin-wink" :depends-on ("util"))
                             (:file "fa-hand-back-fist" :depends-on ("util"))
                             (:file "fa-hand-lizard" :depends-on ("util"))
                             (:file "fa-hand-paper" :depends-on ("util"))
                             (:file "fa-hand-peace" :depends-on ("util"))
                             (:file "fa-hand-point-down" :depends-on ("util"))
                             (:file "fa-hand-pointer" :depends-on ("util"))
                             (:file "fa-hand-point-left" :depends-on ("util"))
                             (:file "fa-hand-point-right" :depends-on ("util"))
                             (:file "fa-hand-point-up" :depends-on ("util"))
                             (:file "fa-hand-rock" :depends-on ("util"))
                             (:file "fa-hand-scissors" :depends-on ("util"))
                             (:file "fa-handshake-alt" :depends-on ("util"))
                             (:file "fa-handshake-simple" :depends-on ("util"))
                             (:file "fa-handshake" :depends-on ("util"))
                             (:file "fa-hand-spock" :depends-on ("util"))
                             (:file "fa-hand" :depends-on ("util"))
                             (:file "fa-hard-drive" :depends-on ("util"))
                             (:file "fa-hdd" :depends-on ("util"))
                             (:file "fa-headphones-alt" :depends-on ("util"))
                             (:file "fa-headphones-simple" :depends-on ("util"))
                             (:file "fa-headphones" :depends-on ("util"))
                             (:file "fa-heart" :depends-on ("util"))
                             (:file "fa-home-alt" :depends-on ("util"))
                             (:file "fa-home-lg-alt" :depends-on ("util"))
                             (:file "fa-home" :depends-on ("util"))
                             (:file "fa-hospital-alt" :depends-on ("util"))
                             (:file "fa-hospital" :depends-on ("util"))
                             (:file "fa-hospital-wide" :depends-on ("util"))
                             (:file "fa-hourglass-2" :depends-on ("util"))
                             (:file "fa-hourglass-empty" :depends-on ("util"))
                             (:file "fa-hourglass-half" :depends-on ("util"))
                             (:file "fa-hourglass" :depends-on ("util"))
                             (:file "fa-house" :depends-on ("util"))
                             (:file "fa-id-badge" :depends-on ("util"))
                             (:file "fa-id-card" :depends-on ("util"))
                             (:file "fa-images" :depends-on ("util"))
                             (:file "fa-image" :depends-on ("util"))
                             (:file "fa-keyboard" :depends-on ("util"))
                             (:file "fa-kiss-beam" :depends-on ("util"))
                             (:file "fa-kiss" :depends-on ("util"))
                             (:file "fa-kiss-wink-heart" :depends-on ("util"))
                             (:file "fa-laugh-beam" :depends-on ("util"))
                             (:file "fa-laugh-squint" :depends-on ("util"))
                             (:file "fa-laugh" :depends-on ("util"))
                             (:file "fa-laugh-wink" :depends-on ("util"))
                             (:file "fa-lemon" :depends-on ("util"))
                             (:file "fa-life-ring" :depends-on ("util"))
                             (:file "fa-lightbulb" :depends-on ("util"))
                             (:file "fa-list-alt" :depends-on ("util"))
                             (:file "fa-map" :depends-on ("util"))
                             (:file "fa-meh-blank" :depends-on ("util"))
                             (:file "fa-meh-rolling-eyes" :depends-on ("util"))
                             (:file "fa-meh" :depends-on ("util"))
                             (:file "fa-message" :depends-on ("util"))
                             (:file "fa-minus-square" :depends-on ("util"))
                             (:file "fa-money-bill-1" :depends-on ("util"))
                             (:file "fa-money-bill-alt" :depends-on ("util"))
                             (:file "fa-moon" :depends-on ("util"))
                             (:file "fa-newspaper" :depends-on ("util"))
                             (:file "fa-note-sticky" :depends-on ("util"))
                             (:file "fa-object-group" :depends-on ("util"))
                             (:file "fa-object-ungroup" :depends-on ("util"))
                             (:file "fa-paper-plane" :depends-on ("util"))
                             (:file "fa-paste" :depends-on ("util"))
                             (:file "fa-pause-circle" :depends-on ("util"))
                             (:file "fa-pen-to-square" :depends-on ("util"))
                             (:file "fa-play-circle" :depends-on ("util"))
                             (:file "fa-plus-square" :depends-on ("util"))
                             (:file "fa-question-circle" :depends-on ("util"))
                             (:file "fa-rectangle-list" :depends-on ("util"))
                             (:file "fa-rectangle-times" :depends-on ("util"))
                             (:file "fa-rectangle-xmark" :depends-on ("util"))
                             (:file "fa-registered" :depends-on ("util"))
                             (:file "fa-sad-cry" :depends-on ("util"))
                             (:file "fa-sad-tear" :depends-on ("util"))
                             (:file "fa-save" :depends-on ("util"))
                             (:file "fa-share-from-square" :depends-on ("util"))
                             (:file "fa-share-square" :depends-on ("util"))
                             (:file "fa-smile-beam" :depends-on ("util"))
                             (:file "fa-smile" :depends-on ("util"))
                             (:file "fa-smile-wink" :depends-on ("util"))
                             (:file "fa-snowflake" :depends-on ("util"))
                             (:file "fa-soccer-ball" :depends-on ("util"))
                             (:file "fa-square-caret-down" :depends-on ("util"))
                             (:file "fa-square-caret-left" :depends-on ("util"))
                             (:file "fa-square-caret-right" :depends-on ("util"))
                             (:file "fa-square-caret-up" :depends-on ("util"))
                             (:file "fa-square-check" :depends-on ("util"))
                             (:file "fa-square-full" :depends-on ("util"))
                             (:file "fa-square-minus" :depends-on ("util"))
                             (:file "fa-square-plus" :depends-on ("util"))
                             (:file "fa-square" :depends-on ("util"))
                             (:file "fa-star-half-alt" :depends-on ("util"))
                             (:file "fa-star-half-stroke" :depends-on ("util"))
                             (:file "fa-star-half" :depends-on ("util"))
                             (:file "fa-star" :depends-on ("util"))
                             (:file "fa-sticky-note" :depends-on ("util"))
                             (:file "fa-stop-circle" :depends-on ("util"))
                             (:file "fa-sun" :depends-on ("util"))
                             (:file "fa-surprise" :depends-on ("util"))
                             (:file "fa-thumbs-down" :depends-on ("util"))
                             (:file "fa-thumbs-up" :depends-on ("util"))
                             (:file "fa-times-circle" :depends-on ("util"))
                             (:file "fa-times-rectangle" :depends-on ("util"))
                             (:file "fa-tired" :depends-on ("util"))
                             (:file "fa-trash-alt" :depends-on ("util"))
                             (:file "fa-trash-can" :depends-on ("util"))
                             (:file "fa-truck" :depends-on ("util"))
                             (:file "fa-user-alt" :depends-on ("util"))
                             (:file "fa-user-circle" :depends-on ("util"))
                             (:file "fa-user-large" :depends-on ("util"))
                             (:file "fa-user" :depends-on ("util"))
                             (:file "fa-vcard" :depends-on ("util"))
                             (:file "fa-window-close" :depends-on ("util"))
                             (:file "fa-window-maximize" :depends-on ("util"))
                             (:file "fa-window-minimize" :depends-on ("util"))
                             (:file "fa-window-restore" :depends-on ("util"))
                             (:file "fa-xmark-circle" :depends-on ("util"))
                             (:file "icon" :depends-on ("util"
                                                        "fa-address-book"
                                                        "fa-address-card"
                                                        "fa-alarm-clock"
                                                        "fa-angry"
                                                        "fa-arrow-alt-circle-down"
                                                        "fa-arrow-alt-circle-left"
                                                        "fa-arrow-alt-circle-right"
                                                        "fa-arrow-alt-circle-up"
                                                        "fa-bar-chart"
                                                        "fa-bell-slash"
                                                        "fa-bell"
                                                        "fa-bookmark"
                                                        "fa-building"
                                                        "fa-calendar-alt"
                                                        "fa-calendar-check"
                                                        "fa-calendar-days"
                                                        "fa-calendar-minus"
                                                        "fa-calendar-plus"
                                                        "fa-calendar"
                                                        "fa-calendar-times"
                                                        "fa-calendar-xmark"
                                                        "fa-camera-alt"
                                                        "fa-camera"
                                                        "fa-caret-square-down"
                                                        "fa-caret-square-left"
                                                        "fa-caret-square-right"
                                                        "fa-caret-square-up"
                                                        "fa-chart-bar"
                                                        "fa-check-circle"
                                                        "fa-check-square"
                                                        "fa-chess-bishop"
                                                        "fa-chess-king"
                                                        "fa-chess-knight"
                                                        "fa-chess-pawn"
                                                        "fa-chess-queen"
                                                        "fa-chess-rook"
                                                        "fa-circle-check"
                                                        "fa-circle-dot"
                                                        "fa-circle-down"
                                                        "fa-circle-left"
                                                        "fa-circle-pause"
                                                        "fa-circle-play"
                                                        "fa-circle-question"
                                                        "fa-circle-right"
                                                        "fa-circle-stop"
                                                        "fa-circle"
                                                        "fa-circle-up"
                                                        "fa-circle-user"
                                                        "fa-circle-xmark"
                                                        "fa-clipboard"
                                                        "fa-clock-four"
                                                        "fa-clock"
                                                        "fa-clone"
                                                        "fa-closed-captioning"
                                                        "fa-cloud"
                                                        "fa-comment-alt"
                                                        "fa-comment-dots"
                                                        "fa-commenting"
                                                        "fa-comments"
                                                        "fa-comment"
                                                        "fa-compass"
                                                        "fa-contact-book"
                                                        "fa-contact-card"
                                                        "fa-copyright"
                                                        "fa-copy"
                                                        "fa-credit-card-alt"
                                                        "fa-credit-card"
                                                        "fa-dizzy"
                                                        "fa-dot-circle"
                                                        "fa-drivers-license"
                                                        "fa-edit"
                                                        "fa-envelope-open"
                                                        "fa-envelope"
                                                        "fa-eye-slash"
                                                        "fa-eye"
                                                        "fa-face-angry"
                                                        "fa-face-dizzy"
                                                        "fa-face-flushed"
                                                        "fa-face-frown-open"
                                                        "fa-face-frown"
                                                        "fa-face-grimace"
                                                        "fa-face-grin-beam"
                                                        "fa-face-grin-beam-sweat"
                                                        "fa-face-grin-hearts"
                                                        "fa-face-grin-squint"
                                                        "fa-face-grin-squint-tears"
                                                        "fa-face-grin-stars"
                                                        "fa-face-grin"
                                                        "fa-face-grin-tears"
                                                        "fa-face-grin-tongue-squint"
                                                        "fa-face-grin-tongue"
                                                        "fa-face-grin-tongue-wink"
                                                        "fa-face-grin-wide"
                                                        "fa-face-grin-wink"
                                                        "fa-face-kiss-beam"
                                                        "fa-face-kiss"
                                                        "fa-face-kiss-wink-heart"
                                                        "fa-face-laugh-beam"
                                                        "fa-face-laugh-squint"
                                                        "fa-face-laugh"
                                                        "fa-face-laugh-wink"
                                                        "fa-face-meh-blank"
                                                        "fa-face-meh"
                                                        "fa-face-rolling-eyes"
                                                        "fa-face-sad-cry"
                                                        "fa-face-sad-tear"
                                                        "fa-face-smile-beam"
                                                        "fa-face-smile"
                                                        "fa-face-smile-wink"
                                                        "fa-face-surprise"
                                                        "fa-face-tired"
                                                        "fa-file-alt"
                                                        "fa-file-archive"
                                                        "fa-file-audio"
                                                        "fa-file-clipboard"
                                                        "fa-file-code"
                                                        "fa-file-excel"
                                                        "fa-file-image"
                                                        "fa-file-lines"
                                                        "fa-file-pdf"
                                                        "fa-file-powerpoint"
                                                        "fa-file"
                                                        "fa-file-text"
                                                        "fa-file-video"
                                                        "fa-file-word"
                                                        "fa-file-zipper"
                                                        "fa-flag"
                                                        "fa-floppy-disk"
                                                        "fa-flushed"
                                                        "fa-folder-blank"
                                                        "fa-folder-closed"
                                                        "fa-folder-open"
                                                        "fa-folder"
                                                        "fa-font-awesome-flag"
                                                        "fa-font-awesome-logo-full"
                                                        "fa-font-awesome"
                                                        "fa-frown-open"
                                                        "fa-frown"
                                                        "fa-futbol-ball"
                                                        "fa-futbol"
                                                        "fa-gem"
                                                        "fa-grimace"
                                                        "fa-grin-alt"
                                                        "fa-grin-beam"
                                                        "fa-grin-beam-sweat"
                                                        "fa-grin-hearts"
                                                        "fa-grin-squint"
                                                        "fa-grin-squint-tears"
                                                        "fa-grin-stars"
                                                        "fa-grin"
                                                        "fa-grin-tears"
                                                        "fa-grin-tongue-squint"
                                                        "fa-grin-tongue"
                                                        "fa-grin-tongue-wink"
                                                        "fa-grin-wink"
                                                        "fa-hand-back-fist"
                                                        "fa-hand-lizard"
                                                        "fa-hand-paper"
                                                        "fa-hand-peace"
                                                        "fa-hand-point-down"
                                                        "fa-hand-pointer"
                                                        "fa-hand-point-left"
                                                        "fa-hand-point-right"
                                                        "fa-hand-point-up"
                                                        "fa-hand-rock"
                                                        "fa-hand-scissors"
                                                        "fa-handshake-alt"
                                                        "fa-handshake-simple"
                                                        "fa-handshake"
                                                        "fa-hand-spock"
                                                        "fa-hand"
                                                        "fa-hard-drive"
                                                        "fa-hdd"
                                                        "fa-headphones-alt"
                                                        "fa-headphones-simple"
                                                        "fa-headphones"
                                                        "fa-heart"
                                                        "fa-home-alt"
                                                        "fa-home-lg-alt"
                                                        "fa-home"
                                                        "fa-hospital-alt"
                                                        "fa-hospital"
                                                        "fa-hospital-wide"
                                                        "fa-hourglass-2"
                                                        "fa-hourglass-empty"
                                                        "fa-hourglass-half"
                                                        "fa-hourglass"
                                                        "fa-house"
                                                        "fa-id-badge"
                                                        "fa-id-card"
                                                        "fa-images"
                                                        "fa-image"
                                                        "fa-keyboard"
                                                        "fa-kiss-beam"
                                                        "fa-kiss"
                                                        "fa-kiss-wink-heart"
                                                        "fa-laugh-beam"
                                                        "fa-laugh-squint"
                                                        "fa-laugh"
                                                        "fa-laugh-wink"
                                                        "fa-lemon"
                                                        "fa-life-ring"
                                                        "fa-lightbulb"
                                                        "fa-list-alt"
                                                        "fa-map"
                                                        "fa-meh-blank"
                                                        "fa-meh-rolling-eyes"
                                                        "fa-meh"
                                                        "fa-message"
                                                        "fa-minus-square"
                                                        "fa-money-bill-1"
                                                        "fa-money-bill-alt"
                                                        "fa-moon"
                                                        "fa-newspaper"
                                                        "fa-note-sticky"
                                                        "fa-object-group"
                                                        "fa-object-ungroup"
                                                        "fa-paper-plane"
                                                        "fa-paste"
                                                        "fa-pause-circle"
                                                        "fa-pen-to-square"
                                                        "fa-play-circle"
                                                        "fa-plus-square"
                                                        "fa-question-circle"
                                                        "fa-rectangle-list"
                                                        "fa-rectangle-times"
                                                        "fa-rectangle-xmark"
                                                        "fa-registered"
                                                        "fa-sad-cry"
                                                        "fa-sad-tear"
                                                        "fa-save"
                                                        "fa-share-from-square"
                                                        "fa-share-square"
                                                        "fa-smile-beam"
                                                        "fa-smile"
                                                        "fa-smile-wink"
                                                        "fa-snowflake"
                                                        "fa-soccer-ball"
                                                        "fa-square-caret-down"
                                                        "fa-square-caret-left"
                                                        "fa-square-caret-right"
                                                        "fa-square-caret-up"
                                                        "fa-square-check"
                                                        "fa-square-full"
                                                        "fa-square-minus"
                                                        "fa-square-plus"
                                                        "fa-square"
                                                        "fa-star-half-alt"
                                                        "fa-star-half-stroke"
                                                        "fa-star-half"
                                                        "fa-star"
                                                        "fa-sticky-note"
                                                        "fa-stop-circle"
                                                        "fa-sun"
                                                        "fa-surprise"
                                                        "fa-thumbs-down"
                                                        "fa-thumbs-up"
                                                        "fa-times-circle"
                                                        "fa-times-rectangle"
                                                        "fa-tired"
                                                        "fa-trash-alt"
                                                        "fa-trash-can"
                                                        "fa-truck"
                                                        "fa-user-alt"
                                                        "fa-user-circle"
                                                        "fa-user-large"
                                                        "fa-user"
                                                        "fa-vcard"
                                                        "fa-window-close"
                                                        "fa-window-maximize"
                                                        "fa-window-minimize"
                                                        "fa-window-restore"
                                                        "fa-xmark-circle")))))
  :description "Icon component (Font Awesome SVG) for cl-s3r")
