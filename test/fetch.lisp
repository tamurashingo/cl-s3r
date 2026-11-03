(defpackage #:cl-s3r.fetch.test
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.fetch
                #:define-fetcher
                #:invalidate-fetch
                #:with-fetch-scope
                #:fetch-failed))

(in-package #:cl-s3r.fetch.test)

(defvar *calls* 0)

(defun reset-calls () (setf *calls* 0))

(define-fetcher fetch-rows (&key (page 1))
  (incf *calls*)
  (list :page page))

(define-fetcher (fetch-broken :on-error :signal) ()
  (error "upstream is down"))

(define-fetcher (fetch-broken-quietly :on-error :nil) ()
  (error "upstream is down"))

(define-fetcher (fetch-slow :timeout 1) ()
  (sleep 5)
  :never)

;;; ---------------------------------------------------------------------------
;;; Memoisation is per request and per argument list
;;; ---------------------------------------------------------------------------

(deftest test-memoised-within-a-scope
  (testing "the same call is made once however many components ask for it"
    (reset-calls)
    (with-fetch-scope
      (ok (equal '(:page 2) (fetch-rows :page 2)))
      (ok (equal '(:page 2) (fetch-rows :page 2)))
      (ok (equal '(:page 2) (fetch-rows :page 2))))
    (ok (= 1 *calls*)))

  (testing "different arguments are different calls"
    (reset-calls)
    (with-fetch-scope
      (fetch-rows :page 1)
      (fetch-rows :page 2)
      (fetch-rows :page 1))
    (ok (= 2 *calls*)))

  (testing "a new scope starts empty"
    (reset-calls)
    (with-fetch-scope (fetch-rows :page 1))
    (with-fetch-scope (fetch-rows :page 1))
    (ok (= 2 *calls*)))

  (testing "with no scope bound, every call goes through"
    (reset-calls)
    (fetch-rows :page 1)
    (fetch-rows :page 1)
    (ok (= 2 *calls*))))

;;; ---------------------------------------------------------------------------
;;; Invalidation, which a write has to do for the read after it
;;; ---------------------------------------------------------------------------

(deftest test-invalidate-fetch
  (testing "by name, every result of that fetcher is forgotten"
    (reset-calls)
    (with-fetch-scope
      (fetch-rows :page 1)
      (fetch-rows :page 2)
      (invalidate-fetch 'fetch-rows)
      (fetch-rows :page 1)
      (fetch-rows :page 2))
    (ok (= 4 *calls*)))

  (testing "by name and arguments, only that call is forgotten"
    (reset-calls)
    (with-fetch-scope
      (fetch-rows :page 1)
      (fetch-rows :page 2)
      (invalidate-fetch 'fetch-rows :page 1)
      (fetch-rows :page 1)
      (fetch-rows :page 2))
    (ok (= 3 *calls*)))

  (testing "with no arguments, the whole scope is forgotten"
    (reset-calls)
    (with-fetch-scope
      (fetch-rows :page 1)
      (invalidate-fetch)
      (fetch-rows :page 1))
    (ok (= 2 *calls*)))

  (testing "a name given as a string works too"
    (reset-calls)
    (with-fetch-scope
      (fetch-rows :page 1)
      (invalidate-fetch "FETCH-ROWS")
      (fetch-rows :page 1))
    (ok (= 2 *calls*)))

  (testing "outside a scope it is a no-op"
    (ok (null (invalidate-fetch 'fetch-rows)))))

;;; ---------------------------------------------------------------------------
;;; Failures
;;; ---------------------------------------------------------------------------

(deftest test-failure-policies
  (testing ":signal raises fetch-failed, which the server answers with 502"
    (ok (handler-case (progn (with-fetch-scope (fetch-broken)) nil)
          (fetch-failed () t))))

  (testing ":nil returns nil and lets the component decide"
    (ok (null (with-fetch-scope (fetch-broken-quietly)))))

  (testing "a nil result is still memoised, rather than retried all render"
    (reset-calls)
    (with-fetch-scope
      (fetch-broken-quietly)
      (fetch-broken-quietly))
    (ok (= 0 *calls*)))

  (testing "a fetcher that outlasts its timeout fails instead of hanging"
    (let ((started (get-internal-real-time)))
      (ok (handler-case (progn (with-fetch-scope (fetch-slow)) nil)
            (fetch-failed () t)))
      (ok (< (/ (- (get-internal-real-time) started) internal-time-units-per-second)
             4)))))
