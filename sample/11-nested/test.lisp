(defpackage #:cl-s3r.sample.nested.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.component
                #:render-component-html))

(in-package #:cl-s3r.sample.nested.test)

;;; ---------------------------------------------------------------------------
;;; Every case page renders
;;; ---------------------------------------------------------------------------

(deftest test-all-case-components-render
  (dolist (name '("nested-index" "case1-app" "case2-app" "case3-app" "case4-app"
                  "case5-app" "case6-app" "case7-app" "case8-app"))
    (testing name
      (let ((result (test-render-component name :args '())))
        (ok (not (null (getf result :sexp))))))))

;;; ---------------------------------------------------------------------------
;;; Root-owned state behaves normally (this part of the model is sound)
;;; ---------------------------------------------------------------------------

(deftest test-root-action-updates-root-state
  (testing "parent-bump increments the root's own state"
    (let* ((r1 (test-render-component "case3-app" :args '()))
           (r2 (test-call-action "case3-app" "parent-bump" :state (getf r1 :state))))
      (ok (= 0 (test-get-state (getf r1 :state) :parent-count)))
      (ok (= 1 (test-get-state (getf r2 :state) :parent-count))))))

(deftest test-stateful-child-action-in-isolation
  (testing "counter-child increments its own state when addressed directly"
    (let* ((r1 (test-render-component "counter-child"
                                      :args '(:label "child" :start 5)))
           (r2 (test-call-action "counter-child" "child-inc"
                                 :state (getf r1 :state)
                                 :args  '(:label "child" :start 5))))
      (ok (= 5 (test-get-state (getf r1 :state) :count)))
      (ok (= 6 (test-get-state (getf r2 :state) :count))))))

(deftest test-lifted-state-case7
  (testing "inc-at bumps only the selected index"
    (let* ((r1 (test-render-component "case7-app" :args '()))
           (r2 (test-call-action "case7-app" "inc-at"
                                 :state (getf r1 :state) :action-args '(1))))
      (ok (equal '(0 0) (test-get-state (getf r1 :state) :counts)))
      (ok (equal '(0 1) (test-get-state (getf r2 :state) :counts)))))

  (testing "parent-bump keeps every child value"
    (let* ((r1 (test-render-component "case7-app" :args '()))
           (r2 (test-call-action "case7-app" "inc-at"
                                 :state (getf r1 :state) :action-args '(0)))
           (r3 (test-call-action "case7-app" "parent-bump"
                                 :state (getf r2 :state))))
      (ok (equal '(11 10) (test-get-state (getf r3 :state) :counts))))))

;;; ---------------------------------------------------------------------------
;;; Characterisation tests for the nested-component problems.
;;; These lock in the behaviour observed today so that a future fix shows up
;;; here as a failure. See README.md in this directory for the full write-up.
;;; ---------------------------------------------------------------------------

(deftest test-nested-child-state-is-dropped-on-a-parent-render
  (testing "the parent's own state is carried into the render"
    (let ((html (render-component-html "case3-app" '(:parent-count 7))))
      (ok (search "&quot;PARENT-COUNT&quot;:7" html))))

  (testing "the nested child is re-initialised instead of keeping its state"
    ;; expand-child-component calls (render-component tag NIL ...), so a nested
    ;; component never receives the state the client collected for it. A child
    ;; that starts at 0 therefore always renders as 0, no matter what the browser
    ;; had in its data-state attribute.
    (let ((html (render-component-html "case3-app" '(:parent-count 7))))
      (ok (search "&quot;COUNT&quot;:0" html))
      (ng (search "&quot;COUNT&quot;:2" html)))))

(defun render-with-forced-root-id (name state id &rest args)
  "Mimic the render pass that call-component-action performs for an action:
the counter restarts at 0 and the target component's id is forced.
ARGS are the init-args the server would replay from its registry."
  (let ((cl-s3r.component:*component-render-counter* 0)
        (cl-s3r.component:*forced-component-id* id)
        (cl-s3r.renderer:*component-expander*
          #'cl-s3r.component::expand-child-component))
    (cl-s3r.renderer:render-html
     (apply #'cl-s3r.component:render-component name state args))))

(deftest test-component-ids-shift-between-render-passes
  (testing "a full render numbers the root first, then its children"
    (let ((html (render-component-html "case5-app" '())))
      (ok (search "data-component-id=\"case5-app-1\"" html))
      (ok (search "data-component-id=\"counter-child-2\"" html))
      (ok (search "data-component-id=\"counter-child-3\"" html))))

  (testing "an action re-render of the same tree numbers the children one lower"
    ;; call-component-action resets *component-render-counter* to 0 and forces the
    ;; target's id, so the forced id no longer consumes a number and every child
    ;; shifts down by one. The id a child instance is addressed by is therefore not
    ;; stable across render passes.
    (let ((html (render-with-forced-root-id "case5-app" nil "case5-app-1")))
      (ok (search "data-component-id=\"case5-app-1\"" html))
      (ok (search "data-component-id=\"counter-child-1\"" html))
      (ok (search "data-component-id=\"counter-child-2\"" html))
      (ng (search "data-component-id=\"counter-child-3\"" html)))))

(deftest test-partial-re-render-can-duplicate-a-component-id
  (testing "re-rendering only the wrapper subtree re-uses an id already taken"
    ;; Case 8: after a root re-render, outer A owns "counter-child-1". When the
    ;; wrapper alone is re-rendered for its own action, its inner child is also
    ;; numbered 1 -- two live instances then share one component-id, and the
    ;; server-side init-args registry keeps only the last one.
    (let ((root-pass    (render-with-forced-root-id "case8-app" nil "case8-app-1"))
          (wrapper-pass (render-with-forced-root-id
                         "stateful-wrapper"
                         nil
                         "stateful-wrapper-2"
                         :children '((counter-child (@ (label "inner B")
                                                       (start 50)))))))
      (ok (search "data-component-id=\"counter-child-1\"" root-pass))
      (ok (search "outer A" root-pass))
      (ok (search "data-component-id=\"counter-child-1\"" wrapper-pass)))))
