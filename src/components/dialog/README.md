# dialog

Modal overlay dialog component for the cl-s3r framework.  
Renders a fixed-position overlay with a centered dialog box containing a header, content area, and footer action buttons.  
The component is **stateless** — open/close state is managed by the parent component.

## Installation

Add `cl-s3r.components.dialog` to your system's `:depends-on`:

```lisp
(defsystem "my-app"
  :depends-on ("cl-s3r" "cl-s3r.components.dialog")
  ...)
```

Load at runtime:

```lisp
(ql:quickload "cl-s3r.components.dialog")
```

Import the component into your package:

```lisp
(defpackage #:my-app
  (:use #:cl)
  (:import-from #:cl-s3r.components.dialog #:dialog))
```

## Usage

### Alert-style dialog (single button)

```lisp
(define-component my-app (&key &allow-other-keys)
  (let-component-state ((dialog-open nil))
    (let-function
        ((open-dialog  () (setf dialog-open t))
         (handle-close () (setf dialog-open nil)))
      `(:div
         (:button (@ (onclick (open-dialog))) "Open")
         ,@(when dialog-open
             `((dialog
                 (dialog-title "Alert")
                 (dialog-content (:p "Something happened."))
                 (dialog-actions
                   (dialog-action (@ (onclick (handle-close))) "OK")))))))))
```

### Confirm-style dialog (two buttons)

```lisp
(define-component my-app (&key &allow-other-keys)
  (let-component-state ((dialog-open nil)
                        (last-answer ""))
    (let-function
        ((open-dialog () (setf dialog-open t))
         (handle-yes  () (setf dialog-open nil) (setf last-answer "yes"))
         (handle-no   () (setf dialog-open nil) (setf last-answer "no")))
      `(:div
         (:button (@ (onclick (open-dialog))) "Confirm")
         ,@(when (not (string= last-answer ""))
             `((:p "Last answer: " ,last-answer)))
         ,@(when dialog-open
             `((dialog
                 (dialog-title "Confirm")
                 (dialog-content (:p "Are you sure?"))
                 (dialog-actions
                   (dialog-action (@ (onclick (handle-yes))) "Yes")
                   (dialog-action (@ (onclick (handle-no)))  "No")))))))))
```

### Input dialog (form submission)

Use an HTML `<form>` inside `dialog-content` and the `form=` attribute on the submit button to associate them.  
The `onsubmit` handler receives a `form-data` plist whose keys are the `name` attributes of the input fields.

```lisp
(define-component my-app (&key &allow-other-keys)
  (let-component-state ((dialog-open nil)
                        (entered ""))
    (let-function
        ((open-dialog () (setf dialog-open t))
         (handle-ok (form-data)
           (setf dialog-open nil)
           (setf entered (or (getf form-data :|name-input|) "")))
         (handle-cancel () (setf dialog-open nil)))
      `(:div
         (:button (@ (onclick (open-dialog))) "Open")
         ,@(when (not (string= entered ""))
             `((:p "Entered: " ,entered)))
         ,@(when dialog-open
             `((dialog
                 (dialog-title "Enter your name")
                 (dialog-content
                   (:form (@ (id "my-form") (onsubmit (handle-ok)))
                     (:input (@ (type "text") (name "name-input")
                                (placeholder "your name")))))
                 (dialog-actions
                   (dialog-action (@ (onclick (handle-cancel))) "Cancel")
                   (dialog-action (@ (type "submit") (form "my-form")) "OK")))))))))
```

## DSL structure

```
(dialog
  (dialog-title  <title-forms...>)
  (dialog-content <content-forms...>)
  (dialog-actions
    (dialog-action (@ <attrs...>) <label-forms...>)
    ...))
```

| Element | Required | Description |
|---------|----------|-------------|
| `dialog-title` | no | Forms rendered inside the `<header>`. |
| `dialog-content` | no | Forms rendered inside `<main>`. Accepts any HTML S-expressions. |
| `dialog-actions` | **yes** | Must contain at least one `dialog-action`. Signals a runtime error otherwise. |
| `dialog-action` | **yes** (≥1) | Rendered as a `<button>`. Accepts optional `(@ ...)` attribute list. |

### `dialog-action` attribute list

```lisp
(dialog-action (@ (onclick (handler-fn))) "Label")
(dialog-action (@ (type "submit") (form "form-id")) "Submit")
```

Any HTML attributes can be passed inside `(@ ...)`. Common patterns:
- `(onclick (fn))` — dispatches `fn` to the nearest stateful ancestor
- `(type "submit") (form "id")` — submits a form elsewhere in `dialog-content`

## Action handling

`dialog` is **stateless** (`data-state="{}"`).  
The cl-s3r runtime's `findActionTarget` skips components with empty state and walks up to the nearest stateful ancestor. This means action handlers (`onclick`, `onsubmit`) defined inside `dialog-actions` are automatically dispatched to the **parent component** without any extra wiring.

The parent component is responsible for:
- Holding the `dialog-open` state variable.
- Defining action handlers (`handle-close`, `handle-yes`, etc.) via `let-function`.
- Conditionally rendering the `dialog` form with `(when dialog-open ...)`.

## CSS customization

The overlay background color can be overridden with the `--dialog-overlay-bg` CSS variable:

```css
/* global override */
:root {
  --dialog-overlay-bg: rgba(0, 0, 128, 0.4);
}
```

```lisp
;; per-component override via inline style on a parent element
`(:div (@ (style "--dialog-overlay-bg:rgba(255,0,0,0.3);"))
   ,@(when open `((dialog ...))))
```

## HTML structure

```html
<div class="cl-s3r-dialog-overlay">
  <style>/* embedded CSS */</style>
  <div class="cl-s3r-dialog-box">
    <header class="cl-s3r-dialog-header">
      <span>Dialog title</span>
    </header>
    <main class="cl-s3r-dialog-main">
      <!-- dialog-content forms -->
    </main>
    <footer class="cl-s3r-dialog-footer">
      <button class="cl-s3r-dialog-action" data-on-click='["handle-close"]'>OK</button>
    </footer>
  </div>
</div>
```

## CSS classes

| Class | Element | Notes |
|-------|---------|-------|
| `cl-s3r-dialog-overlay` | root `<div>` | Fixed full-screen overlay; background controlled by `--dialog-overlay-bg` |
| `cl-s3r-dialog-box` | `<div>` | Centered dialog box; `min-width: 320px`, `max-width: 560px` |
| `cl-s3r-dialog-header` | `<header>` | Title area; `font-size: 18px`, `font-weight: 600`, bottom border |
| `cl-s3r-dialog-main` | `<main>` | Content area; `padding: 16px 24px` |
| `cl-s3r-dialog-footer` | `<footer>` | Action button row; flex, `justify-content: flex-end`, top border |
| `cl-s3r-dialog-action` | `<button>` | Action button; blue fill style with hover effect |
