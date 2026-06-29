(ql:quickload :cl-s3r.components.data-table :silent t)

(defvar *spec-data-table-rows*
  (loop for i from 1 to 20
        collect (list :id     i
                      :name   (nth (mod (1- i) 5)
                                   '("Alice" "Bob" "Carol" "Dave" "Eve"))
                      :status (if (zerop (mod i 3)) "inactive" "active")
                      :age    (+ 20 (mod i 20))
                      :email  (format nil "user~A@example.com" i))))

(defvar *spec-data-table-columns*
  '(:id "ID" :name "Name" :status "Status" :age "Age" :email "Email"))

;;; --- main spec (rows-based) ---

(spec-sheet:defspec data-table
  :description "Paginated data table with optional column headers, pager controls, and customisable labels"
  :component #'cl-s3r.components.data-table:data-table
  :render #'(lambda (&key page-size pager show-columns next-label prev-label)
              (let* ((effective-page-size (let ((n (and page-size
                                                        (not (string= page-size ""))
                                                        (parse-integer page-size :junk-allowed t))))
                                            (or n 5)))
                     (show-pager    (not (string= pager "false")))
                     (show-cols     (not (string= show-columns "false")))
                     (next-lbl      (and next-label (not (string= next-label "")) next-label))
                     (prev-lbl      (and prev-label (not (string= prev-label "")) prev-label)))
                `(:div
                   (:style "body { font-family: sans-serif; padding: 1rem; }")
                   (data-table (@ (rows      ,*spec-data-table-rows*)
                                  ,@(when show-cols
                                      `((columns ,*spec-data-table-columns*)))
                                  (page-size ,effective-page-size)
                                  ,@(unless show-pager '((pager nil)))
                                  ,@(when next-lbl `((next-label ,next-lbl)))
                                  ,@(when prev-lbl `((prev-label ,prev-lbl))))))))
  :props '((page-size    :type string
                         :default "5"
                         :description "Number of rows per page")
           (pager        :type (member "true" "false")
                         :default "true"
                         :description "Show or hide pager controls")
           (show-columns :type (member "true" "false")
                         :default "true"
                         :description "Show column header row")
           (next-label   :type string
                         :default ""
                         :description "Custom label for the Next button (empty = default)")
           (prev-label   :type string
                         :default ""
                         :description "Custom label for the Previous button (empty = default)")))

(spec-sheet:defsheet data-table default
  :title "With columns and pager"
  :params '(:page-size "5" :pager "true" :show-columns "true"))

(spec-sheet:defsheet data-table no-columns
  :title "Without columns (raw mode)"
  :params '(:page-size "5" :pager "true" :show-columns "false"))

(spec-sheet:defsheet data-table no-pager
  :title "No pager (all rows visible)"
  :params '(:page-size "20" :pager "false" :show-columns "true"))

(spec-sheet:defsheet data-table small-page
  :title "Small page size (3 rows)"
  :params '(:page-size "3" :pager "true" :show-columns "true"))

(spec-sheet:defsheet data-table custom-labels
  :title "Custom pager labels"
  :params '(:page-size "5" :pager "true" :show-columns "true"
            :next-label "More →" :prev-label "← Back"))

;;; --- empty state spec ---

(spec-sheet:defspec data-table-empty
  :description "data-table empty state — no rows to display"
  :component #'cl-s3r.components.data-table:data-table
  :render #'(lambda (&key empty-label show-columns)
              (let* ((custom-msg  (and empty-label (not (string= empty-label "")) empty-label))
                     (show-cols   (not (string= show-columns "false"))))
                `(:div
                   (:style "body { font-family: sans-serif; padding: 1rem; }")
                   (data-table (@ (rows nil)
                                  ,@(when show-cols
                                      `((columns ,*spec-data-table-columns*)))
                                  ,@(when custom-msg `((empty-label ,custom-msg))))))))
  :props '((empty-label  :type string
                         :default ""
                         :description "Custom empty state message (empty = default)")
           (show-columns :type (member "true" "false")
                         :default "true"
                         :description "Show column header row")))

(spec-sheet:defsheet data-table-empty with-columns
  :title "Empty with columns"
  :params '(:show-columns "true"))

(spec-sheet:defsheet data-table-empty without-columns
  :title "Empty without columns"
  :params '(:show-columns "false"))

(spec-sheet:defsheet data-table-empty custom-message
  :title "Custom empty message"
  :params '(:show-columns "true" :empty-label "No records found"))

;;; --- fetch-fn spec ---

(spec-sheet:defspec data-table-fetch
  :description "data-table using fetch-fn for server-side pagination"
  :component #'cl-s3r.components.data-table:data-table
  :render #'(lambda (&key page-size)
              (let* ((effective-page-size (let ((n (and page-size
                                                        (not (string= page-size ""))
                                                        (parse-integer page-size :junk-allowed t))))
                                            (or n 5)))
                     (fetch-fn (lambda (&key (page 1) (page-size 10))
                                 (let* ((total       (length *spec-data-table-rows*))
                                        (total-pages (max 1 (ceiling total page-size)))
                                        (start       (min (* (1- page) page-size) total))
                                        (end         (min (+ start page-size) total)))
                                   (list :rows     (subseq *spec-data-table-rows* start end)
                                         :total    total
                                         :page     page
                                         :has-prev (> page 1)
                                         :has-next (< page total-pages))))))
                `(:div
                   (:style "body { font-family: sans-serif; padding: 1rem; }")
                   (data-table (@ (fetch-fn  ,fetch-fn)
                                  (columns   ,*spec-data-table-columns*)
                                  (page-size ,effective-page-size))))))
  :props '((page-size :type string
                      :default "5"
                      :description "Number of rows per page")))

(spec-sheet:defsheet data-table-fetch default
  :title "fetch-fn (5 rows/page)"
  :params '(:page-size "5"))

(spec-sheet:defsheet data-table-fetch large-page
  :title "fetch-fn (10 rows/page)"
  :params '(:page-size "10"))
