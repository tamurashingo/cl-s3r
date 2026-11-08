(defpackage #:cl-s3r.actions.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function
                #:render-component-html
                #:*ancestor-actions*))

(in-package #:cl-s3r.actions.test)

;;; An action is identified by its name, and the name is all that reaches the
;;; browser. A callback handed to a child is therefore stamped with the id of the
;;; component that defines it, so that a child declaring the same name cannot
;;; capture it.

(defun stamp (props)
  (cl-s3r.component::stamp-callback-props props))

(deftest test-stamp-callback-props
  (let ((*ancestor-actions* '(("bump" . "root-0") ("toggle-done" . "todo-0"))))
    (testing "a callback naming an ancestor's action is qualified"
      (ok (equal '(:on-click ("bump@root-0"))
                 (stamp '(:on-click (bump))))))

    (testing "arguments are left alone"
      (ok (equal '(:on-toggle ("toggle-done@todo-0" 3))
                 (stamp '(:on-toggle (toggle-done 3))))))

    (testing "appending an id to a qualified callback still works"
      ;; this is how a middle component builds a per-item callback
      (let ((passed (getf (stamp '(:on-toggle (toggle-done))) :on-toggle)))
        (ok (equal '("toggle-done@todo-0" 7) (append passed (list 7))))))

    (testing "an already qualified callback is not stamped twice"
      (ok (equal '(:on-toggle ("toggle-done@todo-0" 7))
                 (stamp '(:on-toggle ("toggle-done@todo-0" 7))))))

    (testing "a name no ancestor defines is left alone"
      (ok (equal '(:on-click (whatever))
                 (stamp '(:on-click (whatever))))))

    (testing "props that are not callbacks are left alone"
      (ok (equal '(:title (bump) :rows ((bump)))
                 (stamp '(:title (bump) :rows ((bump))))))))

  (testing "with no ancestors nothing is stamped"
    (let ((*ancestor-actions* nil))
      (ok (equal '(:on-click (bump)) (stamp '(:on-click (bump))))))))

;;; ---------------------------------------------------------------------------
;;; The same thing through a real render
;;; ---------------------------------------------------------------------------

(define-component shadowing-child (&key on-bump &allow-other-keys)
  (let-component-state ((hits 0))
    (let-function ((bump () (incf hits)))
      `(:div
         (:button (@ (class "own") (onclick (bump))) "own")
         (:button (@ (class "passed") (onclick ,on-bump)) "passed")))))

(define-component shadowing-root (&key &allow-other-keys)
  (let-component-state ((count 0))
    (let-function ((bump () (incf count)))
      `(:div
         (:button (@ (class "root-own") (onclick (bump))) "root")
         (shadowing-child (@ (on-bump (bump))))))))

(deftest test-render-binds-a-passed-callback-to-its-owner
  (let ((html (render-component-html "shadowing-root" nil)))
    (testing "the root's own button keeps the bare name"
      (ok (search "class=\"root-own\" data-on-click='[\"BUMP\"]'" html)))

    (testing "the child's own button keeps the bare name"
      (ok (search "class=\"own\" data-on-click='[\"BUMP\"]'" html)))

    (testing "the passed callback names the root"
      (ok (search "class=\"passed\" data-on-click='[\"bump@shadowing-root-0\"]'" html)))

    (testing "both components advertise the bare name, as the client expects"
      (ok (search "data-component-id=\"shadowing-root-0\" data-actions=\"bump\"" html))
      (ok (search "data-component-id=\"shadowing-child-0.0\" data-actions=\"bump\"" html)))))

(deftest test-shadowing-is-reported
  (testing "a child declaring an ancestor's action name warns"
    (let ((output (with-output-to-string (*error-output*)
                    (render-component-html "shadowing-root" nil))))
      (ok (search "shadowing-child-0.0" output))
      (ok (search "shadowing-root-0" output))
      (ok (search "bump" output)))))
