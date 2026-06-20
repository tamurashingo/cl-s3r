(defpackage #:cl-s3r.components.accordion.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.components.accordion
                #:split-on-spaces
                #:parse-accordion-children))

(in-package #:cl-s3r.components.accordion.test)

;;; --- Helper functions ---

(defun panel-wrapper-class (sexp item-index)
  "Return the class string of the panel wrapper for ITEM-INDEX (0-based).
SEXP is the stripped accordion sexp. Layout: (:div attrs (:style) item0 item1 ...)."
  (let* ((item (nth (+ item-index 3) sexp))   ; +1 tag, +1 attrs, +1 style = offset 3
         (panel-wrapper (fourth item))          ; (:div attrs (:button) (:div panel-wrapper))
         (attrs (second panel-wrapper)))
    (cadr (find "class" (cdr attrs)
                :key  (lambda (a) (string-downcase (string (car a))))
                :test #'string=))))

(defun item-open-p (sexp item-index)
  "Return true if the accordion item at ITEM-INDEX has the open modifier class."
  (let ((cls (panel-wrapper-class sexp item-index)))
    (and cls (search "--open" cls))))

(defun three-items ()
  "Sample :items prop list used across tests."
  '((:value "sbcl" :header "SBCL" :panel "Steel Bank Common Lisp.")
    (:value "ccl"  :header "CCL"  :panel "Clozure Common Lisp.")
    (:value "ecl"  :header "ECL"  :panel "Embeddable Common Lisp.")))

;;; --- split-on-spaces ---

(deftest test-split-on-spaces
  (testing "nil returns nil"
    (ok (null (split-on-spaces nil))))

  (testing "empty string returns nil"
    (ok (null (split-on-spaces ""))))

  (testing "single token"
    (ok (equal '("sbcl") (split-on-spaces "sbcl"))))

  (testing "two tokens separated by one space"
    (ok (equal '("sbcl" "ccl") (split-on-spaces "sbcl ccl"))))

  (testing "three tokens"
    (ok (equal '("sbcl" "ccl" "ecl") (split-on-spaces "sbcl ccl ecl"))))

  (testing "multiple spaces between tokens are treated as single separator"
    (ok (equal '("sbcl" "ccl") (split-on-spaces "sbcl  ccl")))))

;;; --- parse-accordion-children ---

(deftest test-parse-accordion-children
  (testing "nil returns nil"
    (ok (null (parse-accordion-children nil))))

  (testing "single accordion-item is parsed"
    (let ((result (parse-accordion-children
                   '((accordion-item (@ (value "sbcl"))
                       (accordion-header "SBCL")
                       (accordion-panel "Steel Bank Common Lisp."))))))
      (ok (= 1 (length result)))
      (ok (equal "sbcl" (getf (first result) :value)))
      (ok (equal "SBCL" (getf (first result) :header)))
      (ok (equal "Steel Bank Common Lisp." (getf (first result) :panel)))))

  (testing "multiple accordion-items are all parsed"
    (let ((result (parse-accordion-children
                   '((accordion-item (@ (value "sbcl"))
                       (accordion-header "SBCL")
                       (accordion-panel "p1"))
                     (accordion-item (@ (value "ccl"))
                       (accordion-header "CCL")
                       (accordion-panel "p2"))
                     (accordion-item (@ (value "ecl"))
                       (accordion-header "ECL")
                       (accordion-panel "p3"))))))
      (ok (= 3 (length result)))
      (ok (equal "sbcl" (getf (first result)  :value)))
      (ok (equal "ccl"  (getf (second result) :value)))
      (ok (equal "ecl"  (getf (third result)  :value)))))

  (testing "non-accordion-item sexps are ignored"
    (let ((result (parse-accordion-children
                   '((accordion-item (@ (value "sbcl"))
                       (accordion-header "SBCL")
                       (accordion-panel "p1"))
                     (unknown-tag "ignored")))))
      (ok (= 1 (length result)))))

  (testing "bare accordion-item (unwrapped) is handled"
    (let ((result (parse-accordion-children
                   '(accordion-item (@ (value "sbcl"))
                      (accordion-header "SBCL")
                      (accordion-panel "p1")))))
      (ok (= 1 (length result)))
      (ok (equal "sbcl" (getf (first result) :value))))))

;;; --- accordion component rendering ---

(deftest test-accordion-render-initial
  (testing "no default: no item is open"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items))))
           (sexp   (getf result :sexp)))
      (ok (not (item-open-p sexp 0)))
      (ok (not (item-open-p sexp 1)))
      (ok (not (item-open-p sexp 2)))))

  (testing "default=sbcl: only the first item is open"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items)
                                                      :default "sbcl")))
           (sexp   (getf result :sexp)))
      (ok (item-open-p sexp 0))
      (ok (not (item-open-p sexp 1)))
      (ok (not (item-open-p sexp 2)))))

  (testing "default stores open-items in state"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items)
                                                      :default "ccl")))
           (state  (getf result :state)))
      (ok (equal '("ccl") (test-get-state state :open-items)))))

  (testing "mode is stored in state (defaults to single)"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items))))
           (state  (getf result :state)))
      (ok (equal "single" (test-get-state state :accordion-mode)))))

  (testing "explicit mode=multiple is stored in state"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items)
                                                      :mode "multiple")))
           (state  (getf result :state)))
      (ok (equal "multiple" (test-get-state state :accordion-mode)))))

  (testing "duration is stored in state (defaults to 0.3s)"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items))))
           (state  (getf result :state)))
      (ok (equal "0.3s" (test-get-state state :accordion-duration)))))

  (testing "explicit duration is stored in state"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items)
                                                      :duration "500ms")))
           (state  (getf result :state)))
      (ok (equal "500ms" (test-get-state state :accordion-duration)))))

  (testing "items are stored in state"
    (let* ((result (test-render-component "accordion"
                                          :args (list :items (three-items))))
           (state  (getf result :state)))
      (ok (= 3 (length (test-get-state state :accordion-items))))))

  (testing "children DSL is parsed into items"
    (let* ((result (test-render-component
                    "accordion"
                    :args '(:children
                            ((accordion-item (@ (value "sbcl"))
                               (accordion-header "SBCL")
                               (accordion-panel "p1"))
                             (accordion-item (@ (value "ccl"))
                               (accordion-header "CCL")
                               (accordion-panel "p2"))))))
           (state  (getf result :state)))
      (ok (= 2 (length (test-get-state state :accordion-items)))))))

;;; --- toggle-item action (single mode) ---

(deftest test-accordion-toggle-single
  (testing "toggle-item opens a closed item"
    (let* ((r1 (test-render-component "accordion"
                                      :args (list :items (three-items))))
           (r2 (test-call-action "accordion" "toggle-item"
                                 :state      (getf r1 :state)
                                 :action-args '("sbcl"))))
      (ok (item-open-p (getf r2 :sexp) 0))
      (ok (equal '("sbcl") (test-get-state (getf r2 :state) :open-items)))))

  (testing "toggle-item closes an already-open item"
    (let* ((r1 (test-render-component "accordion"
                                      :args (list :items (three-items)
                                                  :default "sbcl")))
           (r2 (test-call-action "accordion" "toggle-item"
                                 :state      (getf r1 :state)
                                 :action-args '("sbcl"))))
      (ok (not (item-open-p (getf r2 :sexp) 0)))
      (ok (null (test-get-state (getf r2 :state) :open-items)))))

  (testing "toggle-item switches to a different item (single mode)"
    (let* ((r1 (test-render-component "accordion"
                                      :args (list :items (three-items)
                                                  :default "sbcl")))
           (r2 (test-call-action "accordion" "toggle-item"
                                 :state      (getf r1 :state)
                                 :action-args '("ccl"))))
      (ok (not (item-open-p (getf r2 :sexp) 0)))
      (ok (item-open-p     (getf r2 :sexp) 1))
      (ok (equal '("ccl") (test-get-state (getf r2 :state) :open-items))))))

;;; --- toggle-item action (multiple mode) ---

(deftest test-accordion-toggle-multiple
  (testing "toggle-item opens a second item without closing the first"
    (let* ((r1 (test-render-component "accordion"
                                      :args (list :items (three-items)
                                                  :default "sbcl"
                                                  :mode "multiple")))
           (r2 (test-call-action "accordion" "toggle-item"
                                 :state      (getf r1 :state)
                                 :action-args '("ccl"))))
      (ok (item-open-p (getf r2 :sexp) 0))
      (ok (item-open-p (getf r2 :sexp) 1))
      (ok (= 2 (length (test-get-state (getf r2 :state) :open-items))))))

  (testing "toggle-item closes one item while others remain open"
    (let* ((r1 (test-render-component "accordion"
                                      :args (list :items (three-items)
                                                  :default "sbcl"
                                                  :mode "multiple")))
           (r2 (test-call-action "accordion" "toggle-item"
                                 :state      (getf r1 :state)
                                 :action-args '("ccl")))
           (r3 (test-call-action "accordion" "toggle-item"
                                 :state      (getf r2 :state)
                                 :action-args '("sbcl"))))
      (ok (not (item-open-p (getf r3 :sexp) 0)))
      (ok (item-open-p     (getf r3 :sexp) 1))
      (ok (= 1 (length (test-get-state (getf r3 :state) :open-items)))))))
