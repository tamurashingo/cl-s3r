(load (merge-pathnames "src/accordion/accordion.lisp"       *load-truename*))
(load (merge-pathnames "src/badge/badge.lisp"               *load-truename*))
(load (merge-pathnames "src/button/button.lisp"             *load-truename*))
(load (merge-pathnames "src/button/onclick-demo.lisp"       *load-truename*))
(load (merge-pathnames "src/data-table/data-table.lisp"     *load-truename*))
(load (merge-pathnames "src/dialog/dialog.lisp"             *load-truename*))
(load (merge-pathnames "src/icon/icon.lisp"                 *load-truename*))
(load (merge-pathnames "src/icon/onclick-demo.lisp"         *load-truename*))

(spec-sheet:add-head-element
  '(:link (@ (rel "icon") (type "image/svg+xml") (href "/favicon.svg"))))

(spec-sheet:add-static-dir
  (merge-pathnames "public/"
    (uiop:pathname-directory-pathname *load-truename*)))

(spec-sheet:configure-spec-sheet)
