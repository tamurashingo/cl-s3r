(defpackage #:cl-s3r.sample.nested.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-render-html
                #:test-get-state))

(in-package #:cl-s3r.sample.nested.test)

;;; ---------------------------------------------------------------------------
;;; Every case page renders
;;; ---------------------------------------------------------------------------

(deftest test-all-case-components-render
  (dolist (name '("nested-index" "case1-app" "case2-app" "case3-app" "case4-app"
                  "case5-app" "case6-app" "case7-app" "case8-app" "case9-app"
                  "case10-app"))
    (testing name
      (let ((result (test-render-component name :args '())))
        (ok (not (null (getf result :sexp))))))))

;;; ---------------------------------------------------------------------------
;;; Root-owned state
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
;;; Nested state is restored from what the browser reported (case 3, case 5)
;;; ---------------------------------------------------------------------------

(deftest test-nested-child-state-is-restored
  (testing "a child's state comes from the reported state tree, not from its props"
    (let ((html (test-render-html "case3-app"
                                  :state '(:parent-count 7)
                                  :client-state '(("counter-child-0.0" . (:count 2))))))
      (ok (search "&quot;PARENT-COUNT&quot;:7" html))
      (ok (search "&quot;COUNT&quot;:2" html))))

  (testing "a child with no reported state falls back to its initial value"
    (let ((html (test-render-html "case3-app" :state '(:parent-count 7))))
      (ok (search "&quot;COUNT&quot;:0" html))))

  (testing "sibling instances restore their own state independently"
    (let ((html (test-render-html "case5-app"
                                  :client-state '(("counter-child-0.0" . (:count 1))
                                                  ("counter-child-0.1" . (:count 102))))))
      (ok (search "&quot;COUNT&quot;:1" html))
      (ok (search "&quot;COUNT&quot;:102" html)))))

;;; ---------------------------------------------------------------------------
;;; component-ids are stable and unique (case 5, case 8)
;;; ---------------------------------------------------------------------------

(deftest test-component-ids-are-stable-across-render-passes
  (testing "a full render numbers children relative to their parent"
    (let ((html (test-render-html "case5-app")))
      (ok (search "data-component-id=\"case5-app-0\"" html))
      (ok (search "data-component-id=\"counter-child-0.0\"" html))
      (ok (search "data-component-id=\"counter-child-0.1\"" html))))

  (testing "an action re-render of the same tree produces the same ids"
    ;; This is the pass call-component-action performs: the root's path is replayed
    ;; from the registry and its id is forced.
    (let ((html (test-render-html "case5-app"
                                  :path '("0")
                                  :forced-id "case5-app-0")))
      (ok (search "data-component-id=\"counter-child-0.0\"" html))
      (ok (search "data-component-id=\"counter-child-0.1\"" html)))))

(deftest test-partial-re-render-keeps-ids-unique
  (testing "re-rendering only the wrapper subtree keeps its child's own id"
    ;; Case 8: outer A is counter-child-0.0 and the wrapper's inner child is
    ;; counter-child-0.1.0. Re-rendering the wrapper alone must not hand its inner
    ;; child outer A's id, which is what used to corrupt the init-args registry.
    (let ((full (test-render-html "case8-app"))
          (wrapper (test-render-html
                    "stateful-wrapper"
                    :args '(:children ((counter-child (@ (label "inner B")
                                                         (start 50)))))
                    :path '("0" "1")
                    :forced-id "stateful-wrapper-0.1")))
      (ok (search "data-component-id=\"counter-child-0.0\"" full))
      (ok (search "data-component-id=\"counter-child-0.1.0\"" full))
      (ok (search "data-component-id=\"counter-child-0.1.0\"" wrapper))
      (ng (search "data-component-id=\"counter-child-0.0\"" wrapper)))))

;;; ---------------------------------------------------------------------------
;;; key keeps an identity through list changes (case 9)
;;; ---------------------------------------------------------------------------

(deftest test-key-prop-identifies-list-children
  (testing "a key replaces the positional segment of the id"
    (let ((html (test-render-html "case9-app")))
      ;; upper row passes key, lower row does not
      (ok (search "data-component-id=\"counter-child-0.0.kalpha\"" html))
      (ok (search "data-component-id=\"counter-child-0.1.0\"" html))))

  (testing "a keyed child keeps its id when the list is re-ordered"
    (let* ((rotated (test-call-action "case9-app" "rotate"
                                      :state (getf (test-render-component "case9-app"
                                                                          :args '())
                                                   :state)))
           (html (test-render-html "case9-app" :state (getf rotated :state))))
      (ok (equal '("bravo" "charlie" "alpha")
                 (test-get-state (getf rotated :state) :items)))
      (ok (search "data-component-id=\"counter-child-0.0.kalpha\"" html))))

  (testing "a keyed child keeps the state reported for it after a re-order"
    (let* ((rotated (test-call-action "case9-app" "rotate"
                                      :state (getf (test-render-component "case9-app"
                                                                          :args '())
                                                   :state)))
           (html (test-render-html
                  "case9-app"
                  :state (getf rotated :state)
                  :client-state '(("counter-child-0.0.kalpha" . (:count 3))
                                  ("counter-child-0.1.0"      . (:count 5))))))
      ;; alpha moved to the end of the list but kept its count ...
      (ok (search "&quot;COUNT&quot;:3" html))
      ;; ... while the unkeyed row's first position kept the count of whatever
      ;; child used to sit there.
      (ok (search "&quot;COUNT&quot;:5" html)))))

;;; ---------------------------------------------------------------------------
;;; Actions are advertised and routed to the component that defines them (case 4)
;;; ---------------------------------------------------------------------------

(deftest test-components-advertise-their-own-actions
  (testing "each component lists only the actions its own let-function registered"
    (let ((html (test-render-html "case4-app")))
      (ok (search "data-actions=\"parent-bump\"" html))
      (ok (search "data-actions=\"wrapper-hit\"" html))))

  (testing "a stateless child advertises nothing"
    (let ((html (test-render-html "plain-child"
                                  :args '(:label "x" :on-click (parent-bump)))))
      (ok (search "data-component=\"plain-child\"" html))
      (ng (search "data-actions" html)))))

(deftest test-unknown-action-is-reported
  (testing "dispatching an action no component defines signals action-not-found"
    (let ((condition
            (handler-case
                (progn
                  (cl-s3r.component:call-component-action
                   "case1-app" "no-such-action" nil '(:parent-count 0))
                  nil)
              (cl-s3r.component:action-not-found (e) e))))
      (ok condition)
      (ok (string-equal "no-such-action"
                        (cl-s3r.component:action-not-found-action condition)))
      (ok (equal '("parent-bump")
                 (cl-s3r.component:action-not-found-available condition))))))
