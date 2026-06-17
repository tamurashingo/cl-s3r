(defpackage #:cl-s3r.sample.books
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function
                #:define-metadata))

(in-package #:cl-s3r.sample.books)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "Common Lisp OSS Implementations"))
     (:body
       (:style "
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; color: #333; min-height: 100vh;
       display: flex; flex-direction: column; }
header { background: #2c3e50; color: #fff; padding: 12px 24px;
         display: flex; align-items: center; gap: 16px; }
header h1 { font-size: 1.1rem; font-weight: 600; letter-spacing: 0.03em; }
header nav a { color: #ecf0f1; text-decoration: none; font-size: 0.9rem;
               padding: 4px 10px; border-radius: 4px; }
header nav a:hover { background: rgba(255,255,255,0.15); }
main { flex: 1; padding: 24px; max-width: 900px; width: 100%; margin: 0 auto; }
footer { background: #2c3e50; color: #95a5a6; text-align: center;
         padding: 12px 24px; font-size: 0.8rem; }
h1 { font-size: 1.6rem; margin-bottom: 16px; color: #2c3e50; }
ul { list-style: none; padding: 0; }
li { background: #fff; border: 1px solid #ddd; border-radius: 6px;
     padding: 12px 16px; margin-bottom: 10px; }
a { color: #2980b9; text-decoration: none; }
a:hover { text-decoration: underline; }
form { display: flex; gap: 8px; margin-bottom: 16px; }
input[type=text] { flex: 1; padding: 8px 12px; border: 1px solid #ccc;
                   border-radius: 4px; font-size: 0.95rem; }
button[type=submit] { padding: 8px 16px; background: #2980b9; color: #fff;
                      border: none; border-radius: 4px; cursor: pointer; font-size: 0.95rem; }
button[type=submit]:hover { background: #1a6ea8; }
p { margin-bottom: 8px; line-height: 1.6; }
")
       (:header
         (:h1 "cl-s3r Books")
         (:nav (:a (@ (href "/")) "Implementations")))
       (:main ,children)
       (:footer "Powered by cl-s3r — layout defined with define-layout"))))

(configure-default-layout 'app-layout)

(defparameter *implementations*
  '((:id 1 :name "SBCL"
     :description "Steel Bank Common Lisp. The most widely used high-performance implementation. Features a native-code compiler with excellent type inference and optimization."
     :license "MIT / BSD-style (Public Domain portions)"
     :repo "https://github.com/sbcl/sbcl")
    (:id 2 :name "CCL"
     :description "Clozure Common Lisp. Known for fast startup and low memory usage. Supports macOS, Linux, and Windows with strong 64-bit performance."
     :license "Apache License 2.0"
     :repo "https://github.com/Clozure/ccl")
    (:id 3 :name "ECL"
     :description "Embeddable Common Lisp. Compiles to C code and is designed to be embedded into C applications. Also suitable for mobile and embedded environments."
     :license "GNU LGPL v2.1+"
     :repo "https://gitlab.com/embeddable-common-lisp/ecl")
    (:id 4 :name "ABCL"
     :description "Armed Bear Common Lisp. Runs on the JVM, enabling seamless interoperability with Java libraries and the broader Java ecosystem."
     :license "GPL v2 (with Classpath Exception)"
     :repo "https://github.com/armedbear/abcl")
    (:id 5 :name "CLISP"
     :description "GNU CLISP. A bytecode-interpreter implementation with high portability across many platforms. Offers a user-friendly interactive environment via readline."
     :license "GNU GPL v2"
     :repo "https://gitlab.com/gnu-clisp/clisp")
    (:id 6 :name "Clasp"
     :description "A Common Lisp implementation backed by LLVM, designed for deep C++ interoperability. Targets scientific computing and HPC use cases."
     :license "GNU LGPL v2.1+"
     :repo "https://github.com/clasp-developers/clasp")
    (:id 7 :name "CMUCL"
     :description "Carnegie Mellon University Common Lisp. The predecessor to SBCL, with a powerful optimizing compiler and type inference system. Long used in research contexts."
     :license "Public Domain / BSD"
     :repo "https://gitlab.common-lisp.net/cmucl/cmucl")
    (:id 8 :name "GCL"
     :description "GNU Common Lisp. The official Common Lisp implementation of the GNU Project. Used as the runtime for GNU math software such as Maxima."
     :license "GNU LGPL v2"
     :repo "https://www.gnu.org/software/gcl/")))

(define-component impl-list (&key filter &allow-other-keys)
  (let* ((effective-filter (when (and filter (not (string= filter ""))) filter))
         (items (if effective-filter
                    (remove-if-not
                     (lambda (impl)
                       (flet ((contains (text)
                                (search (string-downcase effective-filter)
                                        (string-downcase text))))
                         (or (contains (getf impl :name))
                             (contains (getf impl :description))
                             (contains (getf impl :license)))))
                     *implementations*)
                    *implementations*)))
    `(:div
       (:h1 "Common Lisp OSS Implementations")
       (:form (@ (action "/") (method "get"))
         (:input (@ (type "text")
                    (name "filter")
                    (placeholder "Search implementations...")
                    ,@(when effective-filter `((value ,effective-filter)))))
         (:button (@ (type "submit")) "Search"))
       ,@(when effective-filter
           `((:p (:em ,(format nil "Filtered by: ~A (~A result~:P)"
                               effective-filter (length items))))))
       (:ul
         ,@(loop for impl in items
                 collect `(:li
                            (:a (@ (href ,(format nil "/detail/~A" (getf impl :id))))
                                ,(getf impl :name))
                            " — "
                            ,(getf impl :description)))))))

(define-component impl-detail (&key id &allow-other-keys)
  (let ((impl (find id *implementations* :key (lambda (x) (getf x :id)) :test #'=)))
    (if impl
        `(:div
           (:h1 ,(getf impl :name))
           (:p ,(getf impl :description))
           (:p (:strong "License: ") ,(getf impl :license))
           (:p (:strong "Repository: ")
               (:a (@ (href ,(getf impl :repo))) ,(getf impl :repo)))
           (:p (:a (@ (href "/")) "← Back to list")))
        `(:div
           (:h1 "Implementation not found")
           (:p (:a (@ (href "/")) "← Back to list"))))))

(define-metadata impl-detail (&key id &allow-other-keys)
  (let ((impl (find id *implementations*
                    :key (lambda (x) (getf x :id))
                    :test #'=)))
    (when impl
      (list :title (format nil "~A - Common Lisp OSS Implementations"
                           (getf impl :name))))))

(configure-route :path "/"
                 :component "impl-list"
                 :props '())

(configure-route :path "/detail"
                 :path-param :id
                 :component "impl-detail"
                 :props '())
