(ql:quickload :cl-s3r.components.accordion :silent t)

(spec-sheet:defspec accordion
  :description "Expandable content sections with animated open/close transitions"
  :component #'cl-s3r.components.accordion:accordion
  :render #'(lambda (&key default mode duration)
              `(:div
                 (:style "
body { font-family: sans-serif; padding: 1rem; }
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
")
                 (accordion (@ (default ,(or default ""))
                               (mode    ,(or mode "single"))
                               (duration ,(or duration "0.3s")))
                   (accordion-item (@ (name "sbcl"))
                     (accordion-header "SBCL")
                     (accordion-panel "Steel Bank Common Lisp"))
                   (accordion-item (@ (name "ccl"))
                     (accordion-header "CCL")
                     (accordion-panel "Clozure Common Lisp"))
                   (accordion-item (@ (name "ecl"))
                     (accordion-header "ECL")
                     (accordion-panel "Embeddable Common Lisp")))))
  :props '((default  :type string
                     :default ""
                     :description "Space-separated names of initially open items")
           (mode     :type (member "single" "multiple")
                     :default "single"
                     :description "Whether one or multiple items can be open at once")
           (duration :type string
                     :default "0.3s"
                     :description "CSS transition duration for open/close animation")))

(spec-sheet:defsheet accordion default
  :title "Default (all closed)"
  :params '())

(spec-sheet:defsheet accordion initially-open
  :title "Initially open"
  :params '(:default "sbcl"))

(spec-sheet:defsheet accordion multiple
  :title "Multiple mode"
  :params '(:mode "multiple"))

(spec-sheet:defsheet accordion multiple-open
  :title "Multiple mode (2 open)"
  :params '(:default "sbcl ccl" :mode "multiple"))

(spec-sheet:defsheet accordion slow
  :title "Slow animation (0.8s)"
  :params '(:duration "0.8s"))
