(defpackage #:cl-s3r.components.data-table
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function)
  (:export #:data-table))

(in-package #:cl-s3r.components.data-table)

(defvar *data-table-css*
  (concatenate 'string
               ".data-table{display:block;}"
               ".data-table__table{"
               "width:100%;"
               "border-collapse:collapse;"
               "font-size:14px;}"
               ".data-table__th{"
               "text-align:left;"
               "padding:8px 12px;"
               "border-bottom:2px solid #e0e0e0;"
               "font-weight:600;"
               "color:#424242;}"
               ".data-table__td{"
               "padding:8px 12px;"
               "border-bottom:1px solid #e0e0e0;}"
               ".data-table__tr:nth-child(even) .data-table__td{"
               "background-color:#f5f5f5;}"
               ".data-table__tr:hover .data-table__td{"
               "background-color:#e8f4fd;}"
               ".data-table__pager{"
               "display:flex;"
               "align-items:center;"
               "justify-content:flex-end;"
               "gap:8px;"
               "padding:8px 0;"
               "margin-top:4px;}"
               ".data-table__pager-btn{"
               "padding:4px 12px;"
               "border:1px solid #bdbdbd;"
               "border-radius:4px;"
               "background-color:#fff;"
               "cursor:pointer;"
               "font-size:13px;}"
               ".data-table__pager-btn:hover:not(:disabled){"
               "background-color:#e3f2fd;"
               "border-color:#90caf9;}"
               ".data-table__pager-btn:disabled{"
               "color:#bdbdbd;"
               "cursor:not-allowed;}"
               ".data-table__pager-info{"
               "font-size:13px;"
               "color:#616161;"
               "padding:0 4px;}"
               ".data-table__empty{"
               "padding:16px;"
               "text-align:center;"
               "color:#9e9e9e;"
               "font-size:14px;}"))

;; columns is a plist '(:key "Label" ...) mapping row keys to header labels

(defun render-column-headers (columns)
  "Generate <th> elements from columns plist '(:key label ...)."
  (loop for (key label) on columns by #'cddr
        collect `(:th (@ (class "data-table__th")) ,label)))

(defun render-data-row (row columns)
  "Generate a <tr> from row plist using columns plist for key order."
  `(:tr (@ (class "data-table__tr"))
     ,@(loop for (key label) on columns by #'cddr
             collect `(:td (@ (class "data-table__td"))
                         ,(let ((val (getf row key)))
                            (if (null val) "" val))))))

(defun render-raw-row (row)
  "Generate a <tr> from all values in row plist (no columns spec)."
  `(:tr (@ (class "data-table__tr"))
     ,@(loop for (k v) on row by #'cddr
             collect `(:td (@ (class "data-table__td"))
                         ,(if (null v) "" v)))))

(defun render-prev-btn (has-prev label)
  (if has-prev
      `(:button (@ (class "data-table__pager-btn") (onclick (prev-page))) ,label)
      `(:button (@ (class "data-table__pager-btn") (disabled "disabled")) ,label)))

(defun render-next-btn (has-next label)
  (if has-next
      `(:button (@ (class "data-table__pager-btn") (onclick (next-page))) ,label)
      `(:button (@ (class "data-table__pager-btn") (disabled "disabled")) ,label)))

(define-component data-table (&key rows columns page-size page pager fetch-fn
                                   next-label prev-label empty-label id
                                   &allow-other-keys)
  (let ((effective-page-size (or page-size 10))
        (show-pager          (if (null pager) t pager))
        (effective-next-label  (or next-label  "Next"))
        (effective-prev-label  (or prev-label  "Previous"))
        (effective-empty-label (or empty-label "No data")))
    (let-component-state ((current-page (or page 1)))
      (let* ((use-fetch-fn (not (null fetch-fn)))
             ;; call fetch-fn at render time (including after action re-renders)
             (fetch-result (when use-fetch-fn
                             (funcall fetch-fn
                                      :page current-page
                                      :page-size effective-page-size)))
             ;; rows to display for the current page
             (visible      (if use-fetch-fn
                               (or (getf fetch-result :rows) '())
                               (let* ((total-rows (length rows))
                                      (start (* (1- current-page) effective-page-size)))
                                 (subseq rows
                                         start
                                         (min (+ start effective-page-size) total-rows)))))
             ;; pagination metadata
             (total-pages  (if use-fetch-fn
                               (let ((total (or (getf fetch-result :total) 0)))
                                 (max 1 (ceiling total effective-page-size)))
                               (max 1 (ceiling (length rows) effective-page-size))))
             (has-prev     (if use-fetch-fn
                               (getf fetch-result :has-prev)
                               (> current-page 1)))
             (has-next     (if use-fetch-fn
                               (getf fetch-result :has-next)
                               (< current-page total-pages))))
        (let-function
            ((next-page ()
               (setf current-page (1+ current-page)))
             (prev-page ()
               (setf current-page (max (1- current-page) 1)))
             (go-to-page (n)
               (setf current-page (max 1 (min n total-pages)))))
          `(:div (@ (class "data-table")
                     ,@(when id `((id ,id))))
             (:style ,*data-table-css*)
             (:table (@ (class "data-table__table"))
               ,@(when columns
                   `((:thead
                       (:tr ,@(render-column-headers columns)))))
               (:tbody
                 ,@(cond
                     ((null visible)
                      `((:tr (:td (@ (class "data-table__empty")
                                     ,@(when columns
                                         `((colspan ,(/ (length columns) 2)))))
                               ,effective-empty-label))))
                     (columns
                      (mapcar (lambda (row) (render-data-row row columns)) visible))
                     (t
                      (mapcar #'render-raw-row visible)))))
             ,@(when (and show-pager (or has-next has-prev))
                 `((:div (@ (class "data-table__pager"))
                     ,(render-prev-btn has-prev effective-prev-label)
                     (:span (@ (class "data-table__pager-info"))
                       ,(format nil "~A / ~A" current-page total-pages))
                     ,(render-next-btn has-next effective-next-label))))))))))
