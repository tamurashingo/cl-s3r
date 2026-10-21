(defpackage #:cl-s3r.sample.nested
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-route
                #:configure-default-layout)
  (:import-from #:cl-s3r.component
                #:define-component
                #:define-layout
                #:let-component-state
                #:let-function))

(in-package #:cl-s3r.sample.nested)

;;; ---------------------------------------------------------------------------
;;; Layout
;;; ---------------------------------------------------------------------------

(defparameter *cases*
  '(("/"      . "Index")
    ("/case1" . "1. stateless child -> parent action")
    ("/case2" . "2. stateful child, own action")
    ("/case3" . "3. child state across a parent re-render")
    ("/case4" . "4. parent action inside a stateful child")
    ("/case5" . "5. two instances of the same stateful child")
    ("/case6" . "6. depth-3 nesting")
    ("/case7" . "7. lifted state (recommended pattern)")
    ("/case8" . "8. component-id reuse across partial re-renders")
    ("/case9" . "9. stateful children in a list, with and without key")))

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "cl-s3r nested components"))
     (:body
       (:style "
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; color: #222; }
header { background: #2c3e50; color: #fff; padding: 12px 24px; }
header h1 { font-size: 1.05rem; }
nav { background: #34495e; padding: 8px 24px; display: flex; flex-wrap: wrap; gap: 8px; }
nav a { color: #ecf0f1; text-decoration: none; font-size: 0.82rem;
        padding: 3px 8px; border-radius: 4px; background: rgba(255,255,255,0.08); }
nav a:hover { background: rgba(255,255,255,0.22); }
main { padding: 24px; max-width: 880px; margin: 0 auto; }
h2 { font-size: 1.25rem; margin-bottom: 8px; color: #2c3e50; }
.steps { background: #fffbe6; border: 1px solid #f0d890; border-radius: 6px;
         padding: 10px 14px; margin-bottom: 16px; font-size: 0.86rem; line-height: 1.6; }
.steps b { color: #8a6d00; }
.parent { background: #fff; border: 2px solid #2980b9; border-radius: 8px; padding: 14px; }
.parent-head { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.parent-head .tag { background: #2980b9; color: #fff; font-size: 0.7rem;
                    padding: 2px 6px; border-radius: 3px; }
.child { background: #f2f9f2; border: 2px dashed #27ae60; border-radius: 6px;
         padding: 10px; display: flex; align-items: center; gap: 10px; margin: 8px 0; }
.child--stateless { border-color: #95a5a6; background: #f6f6f6; }
.wrapper { background: #fdf3ff; border: 2px solid #8e44ad; border-radius: 6px;
           padding: 10px; margin: 8px 0; }
.wrapper-head { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.mid { background: #eef4ff; border: 2px dotted #2c3e50; border-radius: 6px;
       padding: 10px; margin: 8px 0; }
.mid h3 { font-size: 0.9rem; margin-bottom: 6px; }
.count { font-family: monospace; font-size: 1.1rem; font-weight: 700;
         background: #222; color: #0f0; padding: 1px 8px; border-radius: 3px; }
.label { font-size: 0.85rem; color: #555; }
button { padding: 5px 12px; border: none; border-radius: 4px; background: #2980b9;
         color: #fff; cursor: pointer; font-size: 0.85rem; }
button:hover { background: #1a6ea8; }
ul.index { list-style: none; }
ul.index li { background: #fff; border: 1px solid #ddd; border-radius: 6px;
              padding: 10px 14px; margin-bottom: 8px; }
ul.index a { color: #2980b9; text-decoration: none; }
")
       (:header (:h1 "cl-s3r / nested component behaviour"))
       (:nav
         ,@(loop for (path . title) in *cases*
                 collect `(:a (@ (href ,path)) ,title)))
       (:main ,children))))

(configure-default-layout 'app-layout)

;;; ---------------------------------------------------------------------------
;;; Reusable child components
;;; ---------------------------------------------------------------------------

;; Stateless child. Renders whatever callback S-expression the parent passed in.
(define-component plain-child (&key label on-click &allow-other-keys)
  `(:div (@ (class "child child--stateless"))
     (:span (@ (class "label")) ,label)
     (:button (@ (class "parent-action")
                 (onclick ,on-click))
       "call parent action")))

;; Stateful child. Owns a counter in its own let-component-state.
(define-component counter-child (&key label start &allow-other-keys)
  (let-component-state ((count (or start 0)))
    (let-function ((child-inc ()
                     (incf count)))
      `(:div (@ (class "child child--stateful"))
         (:span (@ (class "label")) ,label)
         (:span (@ (class "child-count count")) ,count)
         (:button (@ (class "child-inc") (onclick (child-inc))) "child +1")))))

;; Stateful child that wraps parent-supplied children inside its own subtree.
(define-component stateful-wrapper (&key children &allow-other-keys)
  (let-component-state ((hits 0))
    (let-function ((wrapper-hit ()
                     (incf hits)))
      `(:div (@ (class "wrapper"))
         (:div (@ (class "wrapper-head"))
           (:span (@ (class "label")) "stateful wrapper hits")
           (:span (@ (class "wrapper-hits count")) ,hits)
           (:button (@ (class "wrapper-inc") (onclick (wrapper-hit))) "wrapper +1"))
         (:div (@ (class "wrapper-body"))
           ,@(if (listp children) children (list children)))))))

;; Stateless middle layer, used to add depth without adding state.
(define-component mid-section (&key title children &allow-other-keys)
  `(:section (@ (class "mid"))
     (:h3 ,title)
     ,@(if (listp children) children (list children))))

;; Stateless counter display: value and callback both come from the parent.
(define-component display-child (&key label value on-inc &allow-other-keys)
  `(:div (@ (class "child child--stateless"))
     (:span (@ (class "label")) ,label)
     (:span (@ (class "child-count count")) ,value)
     (:button (@ (class "child-inc") (onclick ,on-inc)) "+1")))

;;; ---------------------------------------------------------------------------
;;; Index
;;; ---------------------------------------------------------------------------

(define-component nested-index (&key &allow-other-keys)
  `(:div
     (:h2 "Nested component cases")
     (:p (@ (class "steps"))
       "Each case lives on its own route so that one root component's re-render "
       "cannot disturb another case. Open a case and follow the steps printed on it.")
     (:ul (@ (class "index"))
       ,@(loop for (path . title) in (cdr *cases*)
               collect `(:li (:a (@ (href ,path)) ,title))))))

;;; ---------------------------------------------------------------------------
;;; Case 1: stateless child calls a parent action (baseline)
;;; ---------------------------------------------------------------------------

(define-component case1-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 1: stateless child -> parent action")
         (:p (@ (class "steps"))
           (:b "Steps: ") "click \"call parent action\" twice. "
           (:b "Expected: ") "parent-count becomes 2.")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count))
           (plain-child (@ (label "stateless child")
                           (on-click (parent-bump)))))))))

;;; ---------------------------------------------------------------------------
;;; Case 2: stateful child drives its own action
;;; ---------------------------------------------------------------------------

(define-component case2-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 2: stateful child, own action")
         (:p (@ (class "steps"))
           (:b "Steps: ") "click \"child +1\" three times. "
           (:b "Expected: ") "the child's own count becomes 3 and parent-count stays 0.")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count))
           (counter-child (@ (label "stateful child") (start 0))))))))

;;; ---------------------------------------------------------------------------
;;; Case 3: does the child's own state survive a parent re-render?
;;; ---------------------------------------------------------------------------

(define-component case3-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 3: child state across a parent re-render")
         (:p (@ (class "steps"))
           (:b "Steps: ") "click \"child +1\" twice (child count = 2), then click "
           "\"parent +1\" once. "
           (:b "Question: ") "is the child's count still 2 after the parent re-rendered?")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count)
             (:button (@ (class "parent-inc") (onclick (parent-bump))) "parent +1"))
           (counter-child (@ (label "stateful child") (start 0))))))))

;;; ---------------------------------------------------------------------------
;;; Case 4: a parent action rendered *inside* a stateful child
;;; ---------------------------------------------------------------------------

(define-component case4-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 4: parent action inside a stateful child")
         (:p (@ (class "steps"))
           (:b "Steps: ") "click \"call parent action\" (it sits inside the stateful "
           "wrapper). "
           (:b "Question: ") "does parent-count increase? Also try \"wrapper +1\".")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count))
           (stateful-wrapper
             (plain-child (@ (label "stateless child inside a stateful wrapper")
                             (on-click (parent-bump))))))))))

;;; ---------------------------------------------------------------------------
;;; Case 5: two instances of the same stateful child
;;; ---------------------------------------------------------------------------

(define-component case5-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 5: two instances of the same stateful child")
         (:p (@ (class "steps"))
           (:b "Steps: ") "click \"child +1\" on B twice, then on A once. "
           (:b "Question: ") "do A and B keep separate counts? Then click \"parent +1\" "
           "and watch both.")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count)
             (:button (@ (class "parent-inc") (onclick (parent-bump))) "parent +1"))
           (counter-child (@ (label "child A") (start 0)))
           (counter-child (@ (label "child B") (start 100))))))))

;;; ---------------------------------------------------------------------------
;;; Case 6: depth-3 nesting
;;; ---------------------------------------------------------------------------

(define-component case6-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 6: depth-3 nesting")
         (:p (@ (class "steps"))
           (:b "Steps: ") "the stateless child and the stateful child both sit two "
           "levels below the root. Click each button. "
           (:b "Question: ") "does depth change where the action is dispatched?")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count))
           (mid-section (@ (title "stateless mid-section (level 2)"))
             (plain-child (@ (label "stateless child (level 3)")
                             (on-click (parent-bump))))
             (counter-child (@ (label "stateful child (level 3)") (start 0)))))))))

;;; ---------------------------------------------------------------------------
;;; Case 7: state lifted to the root (the pattern the README recommends)
;;; ---------------------------------------------------------------------------

(define-component case7-app (&key &allow-other-keys)
  (let-component-state ((counts '(0 0)))
    (let-function ((inc-at (index)
                     (setf counts
                           (loop for v in counts
                                 for i from 0
                                 collect (if (= i index) (1+ v) v))))
                   (parent-bump ()
                     (setf counts (mapcar (lambda (v) (+ v 10)) counts))))
      `(:div
         (:h2 "Case 7: lifted state (recommended pattern)")
         (:p (@ (class "steps"))
           (:b "Steps: ") "both children are stateless; the root owns every count. "
           "Click the children, then \"parent +10 to all\". "
           (:b "Expected: ") "no value is ever lost.")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "root-owned counts")
             (:button (@ (class "parent-inc") (onclick (parent-bump))) "parent +10 to all"))
           (mid-section (@ (title "stateless mid-section"))
             ,@(loop for v in counts
                     for i from 0
                     collect `(display-child
                                (@ (label ,(format nil "child ~A (stateless)" i))
                                   (value ,v)
                                   (on-inc (inc-at ,i)))))))))))

;;; ---------------------------------------------------------------------------
;;; Case 8: component-id reuse between a full render and a partial re-render
;;; ---------------------------------------------------------------------------

(define-component case8-app (&key &allow-other-keys)
  (let-component-state ((parent-count 0))
    (let-function ((parent-bump ()
                     (incf parent-count)))
      `(:div
         (:h2 "Case 8: component-id reuse across partial re-renders")
         (:p (@ (class "steps"))
           (:b "Steps: ") "(1) click \"parent +1\" once, (2) click \"wrapper +1\" once, "
           "(3) click \"child +1\" on " (:b "outer A") ". "
           (:b "Question: ") "is outer A still labelled \"outer A\" after step 3?")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "parent-count")
             (:span (@ (class "parent-count count")) ,parent-count)
             (:button (@ (class "parent-inc") (onclick (parent-bump))) "parent +1"))
           (counter-child (@ (label "outer A") (start 0)))
           (stateful-wrapper
             (counter-child (@ (label "inner B") (start 50)))))))))

;;; ---------------------------------------------------------------------------
;;; Case 9: stateful children inside a list, with and without a key prop
;;; ---------------------------------------------------------------------------

(define-component case9-app (&key &allow-other-keys)
  (let-component-state ((items '("alpha" "bravo" "charlie")))
    (let-function ((rotate ()
                     (when (cdr items)
                       (setf items (append (cdr items) (list (car items))))))
                   (drop-first ()
                     (when items
                       (setf items (cdr items)))))
      `(:div
         (:h2 "Case 9: stateful children in a list, with and without key")
         (:p (@ (class "steps"))
           (:b "Steps: ") "give a few children different counts, then click "
           "\"rotate\" or \"drop first\". "
           (:b "Question: ") "does each count stay with its own item? The upper row "
           "passes " (:b "key") ", the lower row does not.")
         (:div (@ (class "parent"))
           (:div (@ (class "parent-head"))
             (:span (@ (class "tag")) "root")
             (:span (@ (class "label")) "items")
             (:button (@ (class "rotate") (onclick (rotate))) "rotate")
             (:button (@ (class "drop-first") (onclick (drop-first))) "drop first"))
           (mid-section (@ (title "with key"))
             ,@(loop for name in items
                     collect `(counter-child (@ (key ,name)
                                                (label ,name)
                                                (start 0)))))
           (mid-section (@ (title "without key"))
             ,@(loop for name in items
                     collect `(counter-child (@ (label ,name)
                                                (start 0))))))))))

;;; ---------------------------------------------------------------------------
;;; Routes
;;; ---------------------------------------------------------------------------

(configure-route :path "/"      :component "nested-index" :props '())
(configure-route :path "/case1" :component "case1-app"    :props '())
(configure-route :path "/case2" :component "case2-app"    :props '())
(configure-route :path "/case3" :component "case3-app"    :props '())
(configure-route :path "/case4" :component "case4-app"    :props '())
(configure-route :path "/case5" :component "case5-app"    :props '())
(configure-route :path "/case6" :component "case6-app"    :props '())
(configure-route :path "/case7" :component "case7-app"    :props '())
(configure-route :path "/case8" :component "case8-app"    :props '())
(configure-route :path "/case9" :component "case9-app"    :props '())
