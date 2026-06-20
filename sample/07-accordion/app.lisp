(defpackage #:cl-s3r.sample.accordion
  (:use :cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
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
       "))
     (:body
       ,children)))

(configure-default-layout 'app-layout)

(configure-route :path "/"
                 :component "accordion"
                 :props '(:default "sbcl"
                          :mode "single"
                          :duration "0.4s"
                          :items ((:value  "sbcl"
                                   :header "SBCL (Steel Bank Common Lisp)"
                                   :panel  "A high-performance open-source implementation featuring a native code compiler with strong type inference and optimization. It is widely used in production environments and is known for its detailed condition system and comprehensive diagnostics.")
                                  (:value  "ccl"
                                   :header "CCL (Clozure Common Lisp)"
                                   :panel  "A fast, responsive implementation with excellent native thread support and quick startup times. It runs on Mac, Linux, and Windows, and is particularly favored for interactive development workflows.")
                                  (:value  "ecl"
                                   :header "ECL (Embeddable Common Lisp)"
                                   :panel  "An implementation designed to compile Lisp to C and embed seamlessly into existing C programs. Its minimal footprint makes it ideal for resource-constrained environments and integration with other languages."))))
