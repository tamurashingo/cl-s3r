(defpackage #:cl-s3r.components.checkbox.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.components.checkbox
                #:checkbox-render))

(in-package #:cl-s3r.components.checkbox.test)

;;; --- helpers ---

(defun root-attrs (sexp)
  "Return the (@ ...) attribute alist of the checkbox root <label>."
  (cdr (second sexp)))

(defun attr-value (attrs name)
  (let ((pair (find name attrs
                    :key  (lambda (a) (string-downcase (string (car a))))
                    :test #'string=)))
    (when pair (second pair))))

(defun checked-p (sexp)
  (string= "true" (attr-value (root-attrs sexp) "aria-checked")))

(defun has-onclick-p (sexp)
  (not (null (attr-value (root-attrs sexp) "onclick"))))

(defun onclick-value (sexp)
  (attr-value (root-attrs sexp) "onclick"))

(defun action-equal (expected actual)
  "Compare action S-exprs by symbol NAME rather than symbol identity,
since the checkbox component's own package interns its action symbols
(e.g. TOGGLE) separately from this test package's literals."
  (and (= (length expected) (length actual))
       (every (lambda (e a)
                (if (and (symbolp e) (symbolp a))
                    (string-equal (string e) (string a))
                    (equal e a)))
              expected actual)))

(defun native-input (sexp)
  "Return the (:input ...) child sexp of the checkbox root, or nil if absent."
  (find :input (cddr sexp) :key (lambda (x) (and (consp x) (car x)))))

(defun root-class (sexp)
  (attr-value (root-attrs sexp) "class"))

(defun has-class-p (sexp class)
  (let ((classes (root-class sexp)))
    (and classes (search class classes))))

;;; --- checkbox-render helper (pure function) ---

(deftest test-checkbox-render
  (testing "unchecked: no checkmark child, aria-checked=false"
    (let ((sexp (checkbox-render nil nil nil)))
      (ok (not (checked-p sexp)))
      (ok (not (has-onclick-p sexp)))))

  (testing "checked: checkmark svg present"
    (let* ((sexp (checkbox-render t nil nil))
           (box  (fourth sexp)))
      (ok (checked-p sexp))
      (ok (not (null (find :svg (cddr box) :key #'car))))))

  (testing "disabled adds aria-disabled"
    (let ((sexp (checkbox-render nil t nil)))
      (ok (equal "true" (attr-value (root-attrs sexp) "aria-disabled")))))

  (testing "not disabled: no aria-disabled attribute"
    (let ((sexp (checkbox-render nil nil nil)))
      (ok (null (attr-value (root-attrs sexp) "aria-disabled")))))

  (testing "onclick-action is spliced in when given"
    (let ((sexp (checkbox-render nil nil '(toggle))))
      (ok (action-equal '(toggle) (onclick-value sexp)))))

  (testing "onclick-action is omitted when disabled, even if passed"
    (let ((sexp (checkbox-render nil t '(toggle))))
      (ok (not (has-onclick-p sexp)))))

  (testing "root tag is a <label>, so children share its clickable element"
    (let ((sexp (checkbox-render nil nil '(toggle))))
      (ok (eq :label (first sexp)))))

  (testing "children are spliced in after the box, inside the same label"
    (let ((sexp (checkbox-render nil nil '(toggle) '("Subscribe"))))
      (ok (member "Subscribe" sexp :test #'equal)))))

;;; --- uncontrolled mode ---

(deftest test-checkbox-uncontrolled-render
  (testing "default render: unchecked, has its own toggle onclick"
    (let* ((result (test-render-component "checkbox" :args nil))
           (sexp   (getf result :sexp)))
      (ok (not (checked-p sexp)))
      (ok (has-onclick-p sexp))
      (ok (action-equal '(toggle) (onclick-value sexp)))))

  (testing "initial-checked=t: renders checked"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :initial-checked t)))
           (sexp   (getf result :sexp)))
      (ok (checked-p sexp))
      (ok (test-get-state (getf result :state) :is-checked))))

  (testing "disabled: no onclick attribute"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :disabled t)))
           (sexp   (getf result :sexp)))
      (ok (not (has-onclick-p sexp))))))

(deftest test-checkbox-toggle-action
  (testing "toggle flips is-checked from false to true"
    (let* ((r1 (test-render-component "checkbox" :args nil))
           (r2 (test-call-action "checkbox" "toggle"
                                 :args nil
                                 :state (getf r1 :state))))
      (ok (checked-p (getf r2 :sexp)))
      (ok (test-get-state (getf r2 :state) :is-checked))))

  (testing "toggle flips is-checked back to false on a second call"
    (let* ((r1 (test-render-component "checkbox" :args nil))
           (r2 (test-call-action "checkbox" "toggle"
                                 :args nil
                                 :state (getf r1 :state)))
           (r3 (test-call-action "checkbox" "toggle"
                                 :args nil
                                 :state (getf r2 :state))))
      (ok (not (checked-p (getf r3 :sexp))))
      (ok (not (test-get-state (getf r3 :state) :is-checked)))))

  (testing "disabled: calling toggle directly does not flip state"
    (let* ((r1 (test-render-component "checkbox" :args (list :disabled t)))
           (r2 (test-call-action "checkbox" "toggle"
                                 :args (list :disabled t)
                                 :state (getf r1 :state))))
      (ok (not (checked-p (getf r2 :sexp))))
      (ok (not (test-get-state (getf r2 :state) :is-checked))))))

;;; --- controlled mode ---

(deftest test-checkbox-controlled
  (testing "checked=t: stateless (matches dialog's nil-state convention)"
    (let* ((result (test-render-component "checkbox" :args (list :checked t)))
           (sexp   (getf result :sexp)))
      (ok (null (getf result :state)))
      (ok (checked-p sexp))
      (ok (not (has-onclick-p sexp)))))

  (testing "checked=nil explicitly passed still counts as controlled"
    (let* ((result (test-render-component "checkbox" :args (list :checked nil))))
      (ok (null (getf result :state)))
      (ok (not (checked-p (getf result :sexp))))))

  (testing "onclick given, no checked/initial-checked: falls back to unchecked, appends :false"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :onclick '(on-change))))
           (sexp   (getf result :sexp)))
      (ok (null (getf result :state)))
      (ok (not (checked-p sexp)))
      (ok (action-equal '(on-change :false) (onclick-value sexp)))))

  (testing "onclick + checked t: appends literal T, not :true"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :onclick '(on-change) :checked t)))
           (sexp   (getf result :sexp)))
      (ok (action-equal '(on-change t) (onclick-value sexp)))))

  (testing "onclick + initial-checked t (no checked passed): appends T"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :onclick '(on-change) :initial-checked t)))
           (sexp   (getf result :sexp)))
      (ok (checked-p sexp))
      (ok (action-equal '(on-change t) (onclick-value sexp)))))

  (testing "onclick + disabled: onclick attribute is omitted entirely"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :onclick '(on-change) :disabled t)))
           (sexp   (getf result :sexp)))
      (ok (not (has-onclick-p sexp))))))

;;; --- native input (name/value, form submission) ---

(deftest test-checkbox-render-native-input
  (testing "name omitted: no native input, no --inert class"
    (let ((sexp (checkbox-render nil nil '(toggle))))
      (ok (null (native-input sexp)))
      (ok (not (has-class-p sexp "cl-s3r-checkbox--inert")))))

  (testing "name given: native input present with type checkbox and matching name"
    (let* ((sexp  (checkbox-render nil nil '(toggle) nil "agree"))
           (input (native-input sexp)))
      (ok (not (null input)))
      (ok (equal "checkbox" (attr-value (cdr (second input)) "type")))
      (ok (equal "agree" (attr-value (cdr (second input)) "name")))))

  (testing "native input always carries tabindex=-1 and aria-hidden=true"
    (let* ((sexp  (checkbox-render nil nil '(toggle) nil "agree"))
           (input (native-input sexp)))
      (ok (equal "-1" (attr-value (cdr (second input)) "tabindex")))
      (ok (equal "true" (attr-value (cdr (second input)) "aria-hidden")))))

  (testing "checked=t: native input gets checked=\"\" attribute"
    (let* ((sexp  (checkbox-render t nil '(toggle) nil "agree"))
           (input (native-input sexp)))
      (ok (equal "" (attr-value (cdr (second input)) "checked")))))

  (testing "checked=nil: native input has no checked attribute"
    (let* ((sexp  (checkbox-render nil nil '(toggle) nil "agree"))
           (input (native-input sexp)))
      (ok (null (attr-value (cdr (second input)) "checked")))))

  (testing "disabled=t: native input gets disabled=\"\" attribute"
    (let* ((sexp  (checkbox-render nil t nil nil "agree"))
           (input (native-input sexp)))
      (ok (equal "" (attr-value (cdr (second input)) "disabled")))))

  (testing "value given: native input has matching value attribute"
    (let* ((sexp  (checkbox-render nil nil '(toggle) nil "agree" "yes"))
           (input (native-input sexp)))
      (ok (equal "yes" (attr-value (cdr (second input)) "value")))))

  (testing "value omitted: native input has no value attribute at all"
    (let* ((sexp  (checkbox-render nil nil '(toggle) nil "agree"))
           (input (native-input sexp)))
      (ok (null (attr-value (cdr (second input)) "value")))))

  (testing "name given + onclick-action present: no --inert class"
    (let ((sexp (checkbox-render nil nil '(toggle) nil "agree")))
      (ok (not (has-class-p sexp "cl-s3r-checkbox--inert")))))

  (testing "name given + no onclick-action: --inert class present"
    (let ((sexp (checkbox-render nil nil nil nil "agree")))
      (ok (has-class-p sexp "cl-s3r-checkbox--inert")))))

(deftest test-checkbox-native-input-component
  (testing "uncontrolled + name: native input checked flips in lockstep with toggle"
    (let* ((r1     (test-render-component "checkbox" :args (list :name "agree")))
           (input1 (native-input (getf r1 :sexp)))
           (r2     (test-call-action "checkbox" "toggle"
                                     :args (list :name "agree")
                                     :state (getf r1 :state)))
           (input2 (native-input (getf r2 :sexp))))
      (ok (null (attr-value (cdr (second input1)) "checked")))
      (ok (equal "" (attr-value (cdr (second input2)) "checked")))))

  (testing "controlled + checked + onclick + name: native input mirrors state, no --inert"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :checked t :onclick '(on-change)
                                                       :name "agree")))
           (sexp   (getf result :sexp))
           (input  (native-input sexp)))
      (ok (equal "" (attr-value (cdr (second input)) "checked")))
      (ok (not (has-class-p sexp "cl-s3r-checkbox--inert")))))

  (testing "controlled + checked + name only (no onclick): --inert present"
    (let* ((result (test-render-component "checkbox"
                                          :args (list :checked t :name "agree")))
           (sexp   (getf result :sexp)))
      (ok (has-class-p sexp "cl-s3r-checkbox--inert")))))
