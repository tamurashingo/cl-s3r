(defpackage #:cl-s3r.sample.carousel
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-root-page)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function))

(in-package #:cl-s3r.sample.carousel)

(define-component root (children)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "cl-s3r Carousel"))
     (:body
       ,children)))

(configure-root-page :component "root")

(define-component carousel-app ()
  (let-component-state ((current-index 0))
    (let-function ((next () (setf current-index (mod (1+ current-index) 5)))
                   (prev () (setf current-index (mod (+ current-index 4) 5))))
      (let* ((colors '("#e74c3c" "#e67e22" "#f1c40f" "#2ecc71" "#3498db"))
             (slide-labels '("Slide 1" "Slide 2" "Slide 3" "Slide 4" "Slide 5"))
             (offset (* current-index -100)))
        `(:div (@ (class "carousel-app"))
           (:style "
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: sans-serif; background: #1a1a2e; min-height: 100vh;
       display: flex; align-items: center; justify-content: center; }
.carousel-app { text-align: center; }
.carousel-wrapper { width: 560px; overflow: hidden; border-radius: 12px;
                    box-shadow: 0 8px 32px rgba(0,0,0,0.4); }
.carousel-track { display: flex; transition: transform 0.4s ease; }
.carousel-item { min-width: 100%; height: 320px; display: flex;
                 align-items: center; justify-content: center;
                 font-size: 4rem; font-weight: bold; color: white;
                 text-shadow: 0 2px 8px rgba(0,0,0,0.3); }
.carousel-controls { margin-top: 20px; display: flex; align-items: center;
                     justify-content: center; gap: 24px; }
.carousel-btn { width: 48px; height: 48px; border-radius: 50%; border: none;
                background: rgba(255,255,255,0.15); color: white; font-size: 1.5rem;
                cursor: pointer; transition: background 0.2s; }
.carousel-btn:hover { background: rgba(255,255,255,0.3); }
.carousel-indicator { color: rgba(255,255,255,0.7); font-size: 1.1rem; min-width: 48px; }
")
           (:div (@ (class "carousel-wrapper"))
             (:div (@ (class "carousel-track")
                      (style ,(format nil "transform: translateX(~A%);" offset)))
               ,@(mapcar (lambda (color label)
                           `(:div (@ (class "carousel-item")
                                     (style ,(format nil "background: ~A;" color)))
                              ,label))
                         colors slide-labels)))
           (:div (@ (class "carousel-controls"))
             (:button (@ (class "carousel-btn") (onclick (prev))) "<")
             (:span (@ (class "carousel-indicator"))
               ,(format nil "~A / 5" (1+ current-index)))
             (:button (@ (class "carousel-btn") (onclick (next))) ">")))))))

(configure-route :path "/"
                 :component "carousel-app"
                 :props '())
