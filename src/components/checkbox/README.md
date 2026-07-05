# checkbox

Boolean checkbox component for the cl-s3r framework.
Renders as a custom `<label role="checkbox">` driven purely by CSS classes, not a native `<input type="checkbox">` — clicks are suppressed from triggering the browser's own toggle (`cl-runtime.js` calls `preventDefault()` on the delegated click), and `cl-morph.js`'s DOM morphing explicitly syncs the live `.checked` IDL property on every render, so the box never desyncs from server state even after user interaction (the "dirty checkedness flag" problem). Pass `name` to additionally render a hidden native `<input type="checkbox">` alongside the box for real HTML `<form>` submission — see [Native `<input>` for form submission](#native-input-for-form-submission) below.

Any trailing forms passed after the attribute list become `children`, rendered next to the box *inside* the same `<label>` — so clicking that label text toggles the checkbox exactly like clicking the box itself:

```lisp
(checkbox "Subscribe to newsletter")                     ; text is clickable too
(checkbox (@ (initial-checked t)) "Remember me")
```

The component supports two modes, mirroring `dialog`'s `open`/`open-p` idiom:

- **Uncontrolled** (neither `checked` nor `onclick` is passed): the checkbox owns its own boolean state internally, initialized from `initial-checked`, and toggles itself on click.
- **Controlled** (`checked` is passed explicitly, and/or `onclick` is passed): the checkbox is stateless. Its displayed value is `checked` if given, else `initial-checked` (static). Clicking dispatches directly to whichever ancestor defines the `onclick` action.

**Mental model:** passing `checked` and/or `onclick` hands state management to the caller — the checkbox itself keeps no state and must be driven entirely by the parent. For simple display or native `<form>` usage, leave both out and let the checkbox control itself.

## Installation

Add `cl-s3r.components.checkbox` to your system's `:depends-on`:

```lisp
(defsystem "my-app"
  :depends-on ("cl-s3r" "cl-s3r.components.checkbox")
  ...)
```

Load at runtime:

```lisp
(ql:quickload "cl-s3r.components.checkbox")
```

Import the component into your package:

```lisp
(defpackage #:my-app
  (:use #:cl)
  (:import-from #:cl-s3r.components.checkbox #:checkbox))
```

## Usage

### Uncontrolled checkbox (self-managed)

```lisp
(checkbox)                              ; starts unchecked, toggles itself
(checkbox (@ (initial-checked t)))      ; starts checked, toggles itself
```

### Disabled checkbox

```lisp
(checkbox (@ (disabled t)))
(checkbox (@ (initial-checked t) (disabled t)))
```

No click handler is attached at all when `disabled` is true.

### Controlled checkbox (parent fully owns the value)

```lisp
(define-component my-app (&key &allow-other-keys)
  (let-component-state ((is-subscribed t))
    `(:div
       (checkbox (@ (checked ,is-subscribed))))))
```

Since no `onclick` is given here, the checkbox can never be unchecked by clicking — the parent is the only thing that can change `checked`.

### Controlled checkbox notifying a parent action

```lisp
(define-component my-app (&key &allow-other-keys)
  (let-component-state ((last-value "none"))
    (let-function
        ((on-change (state) (setf last-value (if state "true" "false"))))
      `(:div
         (checkbox (@ (onclick (on-change))))
         (:p "last value: " ,last-value)))))
```

Clicking calls `on-change` with the checkbox's *current* effective-checked value appended as the first argument (`(on-change)` becomes `(on-change t)` or `(on-change :false)` on the wire, decoded back to `T`/`NIL` on the server).

### Self-toggle + drive ancestor state

To make the box visually toggle on click *and* have that click drive other state in the same
component (e.g. show/hide a sibling element), feed `checked` back from the parent's own state and
toggle it in the handler using the value the handler receives (the checkbox's *pre-click* value):

```lisp
(define-component my-app (&key &allow-other-keys)
  (let-component-state ((show-submenu-p nil))
    (let-function
        ((set-show-submenu (param) (setf show-submenu-p (not param))))
      `(:div
         ,@(when show-submenu-p
             '((:select (@ (name "name"))
                 (:option (@ (value "taro")) "taro")
                 (:option (@ (value "jiro")) "jiro"))))
         (checkbox (@ (checked ,show-submenu-p) (onclick (set-show-submenu)))
           "set default name")))))
```

Because `checked` is supplied here, the checkbox is stateless and the click dispatches straight to
`my-app` in a single request — the response re-renders the checkbox's box (via the new
`show-submenu-p`) and the conditionally-rendered submenu together, in one round trip. The handler
must explicitly negate the received value (`(not param)`), not just assign it, since `param` is the
checkbox's state *before* this click.

## Action handling

`checkbox` in controlled mode (`checked` and/or `onclick` given) is **stateless** (`data-state="{}"`), exactly like `dialog`. The runtime's `findActionTarget` skips components with empty state, so the click is dispatched to the nearest stateful ancestor — normally the parent that defines the `onclick` action.

**Important caveat:** in this mode, clicking does **not** make the checkbox's own box visually toggle. The click only invokes the parent's action. The box only changes appearance on a subsequent render where the parent explicitly feeds back an updated `checked` value. This is standard controlled-component behavior — if you want the box to visually respond immediately on every click, use the uncontrolled mode instead (omit both `checked` and `onclick`).

In uncontrolled mode, the checkbox owns non-empty state (`is-checked`), so clicks are always routed to its own internal `toggle` action — an uncontrolled checkbox's `onclick` prop, if given, is ignored.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `initial-checked` | boolean | `nil` | Initial value in uncontrolled mode |
| `checked` | boolean | unset | Passing it explicitly switches to controlled mode (omitted vs. explicit `nil` are distinguished) |
| `disabled` | boolean | `nil` | Disables the checkbox when `t`; no click handler is emitted at all |
| `onclick` | action expression | `nil` | Passing it switches to controlled mode. The current boolean value is appended as the last argument on click (e.g. `(on-change)` becomes `(on-change t)`) |
| `children` | list of S-expressions (automatic) | `nil` | Body forms passed after the attribute list are expanded as label text inside the `<label>`. Since they share the same element as the box, clicking the text has the same effect as clicking the checkbox |
| `name` | string | `nil` | When given, adds a hidden native `<input type="checkbox">` so a normal HTML `<form>` submission (`FormData`) can pick it up |
| `value` | string | `nil` | The `value` attribute of the hidden native `input`. Falls back to the browser default `"on"` when omitted. Ignored if `name` is not given |

### Native `<input>` for form submission

Passing `name` adds a hidden native `<input type="checkbox">` alongside the visible box inside the
same `<label>`; `checked`/`disabled` always share the same value as the visible box. This hidden
`input` is removed from the tab order and accessibility tree via `tabindex="-1"` and
`aria-hidden="true"`, so the outer `<label role="checkbox">` remains the sole interactive element.

```lisp
(:form (@ (onsubmit (on-submit)))
  (checkbox (@ (initial-checked t) (name "agree") (value "yes")) "I agree")
  (:button (@ (type "submit")) "Submit"))
```

When `name` is given in a mode with neither `onclick` nor the default toggle (`disabled`, or fully
controlled with only `checked` passed), the label gets a `cl-s3r-checkbox--inert` class that
disables clicking entirely via `pointer-events:none`. This prevents the browser from forwarding a
click on a handler-less label to the native input, which would toggle the hidden `input` on its own
regardless of server-side state (the checkbox's "dirty checkedness flag" problem).

## CSS customization

Override the border and checked-fill colors with CSS custom properties:

```css
:root {
  --checkbox-border-color: #888;
  --checkbox-checked-bg: #2e7d32;
}
```

## CSS classes

| Class | Element | Notes |
|-------|---------|-------|
| `cl-s3r-checkbox` | root `<label>` | `role="checkbox"`, `aria-checked` |
| `cl-s3r-checkbox--disabled` | root `<label>` | Added when `disabled` is true; dims opacity, `aria-disabled="true"` |
| `cl-s3r-checkbox-box` | inner `<span>` | The visible box; border color from `--checkbox-border-color` |
| `cl-s3r-checkbox-box--checked` | inner `<span>` | Added when checked; fill color from `--checkbox-checked-bg` |
| `cl-s3r-checkbox-mark` | `<svg>` | The checkmark, only rendered when checked |
| `cl-s3r-checkbox--inert` | root `<label>` | Added when `name` is given and there is no click handler (disabled, or controlled with no `onclick`); `pointer-events:none` blocks clicks from reaching the hidden native input |
| `cl-s3r-checkbox-native` | hidden `<input type="checkbox">` | Only rendered when `name` is given; visually hidden, removed from tab order/AT tree |
