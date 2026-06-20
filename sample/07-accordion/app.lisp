(defpackage #:cl-s3r.sample.accordion
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout)
  (:import-from #:cl-s3r.components.accordion
                #:accordion))

(in-package #:cl-s3r.sample.accordion)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "cl-s3r Accordion")
       (:style "
body { font-family: sans-serif; max-width: 600px; margin: 2rem auto; padding: 0 1rem; }
.accordion { border: 1px solid #ccc; border-radius: 4px; overflow: hidden; }
.accordion-item + .accordion-item { border-top: 1px solid #ccc; }
.accordion-header {
  padding: 0.75rem 1rem;
  background: #f5f5f5;
  font-weight: bold;
  cursor: pointer;
  user-select: none;
}
.accordion-header:hover { background: #e8e8e8; }
.accordion-panel-content { padding: 0.75rem 1rem; background: #fff; }
.accordion-panel-content p { margin: 0 0 0.5rem; }
.accordion-panel-content ul { margin: 0; padding-left: 1.25rem; }
.accordion-panel-content li { margin-bottom: 0.25rem; }
code { background: #f0f0f0; padding: 0.1em 0.35em; border-radius: 3px; font-size: 0.9em; }
       "))
     (:body
       ,children)))

(configure-default-layout 'app-layout)

(define-component accordion-page (&key &allow-other-keys)
  `(:div (@ (class "accordion-page"))
     (:h1 "Accordion Examples")

     (:h2 "Single mode (default)")
     (:p "Only one item can be open at a time. Opening a new item closes the current one.")
     (accordion (@ (default "sbcl") (mode "single"))
       (accordion-item (@ (name "sbcl"))
         (accordion-header (:strong "SBCL") " — Steel Bank Common Lisp")
         (accordion-panel
           (:p "A high-performance open-source implementation featuring a "
             (:strong "native code compiler") " with strong type inference and optimization.")
           (:ul
             (:li "Widely used in production environments")
             (:li "Detailed condition system and comprehensive diagnostics")
             (:li (:code "sbcl --load app.lisp") " to get started"))))
       (accordion-item (@ (name "ccl"))
         (accordion-header (:strong "CCL") " — Clozure Common Lisp")
         (accordion-panel
           (:p "A fast, responsive implementation with excellent "
             (:strong "native thread support") " and quick startup times.")
           (:ul
             (:li "Runs on Mac, Linux, and Windows")
             (:li "Particularly favored for interactive development workflows"))))
       (accordion-item (@ (name "ecl"))
         (accordion-header (:strong "ECL") " — Embeddable Common Lisp")
         (accordion-panel
           (:p "An implementation designed to "
             (:strong "compile Lisp to C") " and embed seamlessly into existing C programs.")
           (:ul
             (:li "Minimal footprint, ideal for resource-constrained environments")
             (:li "Integration with other languages via C FFI")))))

     (:hr)

     (:h2 "Multiple mode")
     (:p "Multiple items can be open simultaneously. Each item toggles independently.")
     (accordion (@ (default "sbcl ccl") (mode "multiple"))
       (accordion-item (@ (name "sbcl"))
         (accordion-header (:strong "SBCL") " — Steel Bank Common Lisp")
         (accordion-panel
           (:p "A high-performance open-source implementation featuring a "
             (:strong "native code compiler") " with strong type inference and optimization.")
           (:ul
             (:li "Widely used in production environments")
             (:li "Detailed condition system and comprehensive diagnostics")
             (:li (:code "sbcl --load app.lisp") " to get started"))))
       (accordion-item (@ (name "ccl"))
         (accordion-header (:strong "CCL") " — Clozure Common Lisp")
         (accordion-panel
           (:p "A fast, responsive implementation with excellent "
             (:strong "native thread support") " and quick startup times.")
           (:ul
             (:li "Runs on Mac, Linux, and Windows")
             (:li "Particularly favored for interactive development workflows"))))
       (accordion-item (@ (name "ecl"))
         (accordion-header (:strong "ECL") " — Embeddable Common Lisp")
         (accordion-panel
           (:p "An implementation designed to "
             (:strong "compile Lisp to C") " and embed seamlessly into existing C programs.")
           (:ul
             (:li "Minimal footprint, ideal for resource-constrained environments")
             (:li "Integration with other languages via C FFI")))))

     (:hr)

     (:h2 "Slow transition (0.8s)")
     (:p "Same single mode, but the open/close animation takes 0.8 seconds.")
     (accordion (@ (default "sbcl") (mode "single") (duration "0.8s"))
       (accordion-item (@ (name "sbcl"))
         (accordion-header (:strong "SBCL") " — Steel Bank Common Lisp")
         (accordion-panel
           (:p "A high-performance open-source implementation featuring a "
             (:strong "native code compiler") " with strong type inference and optimization.")
           (:ul
             (:li "Widely used in production environments")
             (:li "Detailed condition system and comprehensive diagnostics")
             (:li (:code "sbcl --load app.lisp") " to get started"))))
       (accordion-item (@ (name "ccl"))
         (accordion-header (:strong "CCL") " — Clozure Common Lisp")
         (accordion-panel
           (:p "A fast, responsive implementation with excellent "
             (:strong "native thread support") " and quick startup times.")
           (:ul
             (:li "Runs on Mac, Linux, and Windows")
             (:li "Particularly favored for interactive development workflows"))))
       (accordion-item (@ (name "ecl"))
         (accordion-header (:strong "ECL") " — Embeddable Common Lisp")
         (accordion-panel
           (:p "An implementation designed to "
             (:strong "compile Lisp to C") " and embed seamlessly into existing C programs.")
           (:ul
             (:li "Minimal footprint, ideal for resource-constrained environments")
             (:li "Integration with other languages via C FFI")))))))

(configure-route :path "/"
                 :component "accordion-page"
                 :props '())
