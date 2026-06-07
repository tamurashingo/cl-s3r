# cl-s3r

**Server Side S-expression Renderer** for Stateless Component-Driven Web Frontend.

cl-s3r is a Common Lisp web framework that lets you build reactive web UIs using S-expressions. Components are defined entirely in Lisp, rendered server-side to HTML, and kept alive through a stateless request/response cycle -- the server holds no state between requests.

## How It Works

1. **S-expressions as HTML** -- Write UI with keyword symbols (`:div`, `:p`, `:button`) and Lisp's backquote/comma syntax for dynamic values.
2. **Completely stateless server** -- Component state is serialized into `data-state` attributes on the client. The server retains nothing between requests.
3. **Unidirectional data flow** -- On user interaction, the client POSTs the entire state tree to the server. The server executes the action, re-renders the component, and returns the new HTML.
4. **Decoupled components** -- Child components never reference parent functions directly. Callbacks are passed as S-expression data through props.

## Quick Start

### Prerequisites

- Docker and Docker Compose

### Running the Counter Sample

```sh
cd sample/01-counter
make image
make up
```

Open `http://localhost:5001` in your browser.

### Running the Todo Sample

```sh
cd sample/02-todo
make image
make up
```

Open `http://localhost:5002` in your browser.

To stop:

```sh
make down
```

## Defining Components

### Single Component (Stateful)

A component is defined with `define-component`, declares its state with `let-component-state`, and registers client-callable actions with `let-function`:

```lisp
(define-component counter-app (initial-count)
  (let-component-state ((count initial-count))
    (let-function ((increment () (incf count))
                   (decrement () (decf count)))
      `(:div
         (:h1 "Counter App")
         (:p "Count: " ,count)
         (:button (@ (onclick (increment))) "+")
         (:button (@ (onclick (decrement))) "-")))))
```

### Nested Components (Parent-Child)

Child components are written as non-keyword symbols in the parent's S-expression. Props (including callbacks) are passed via `(@ ...)` attribute blocks:

```lisp
;; Stateless child — receives props only
(define-component todo-item (id title done on-toggle on-delete)
  `(:li
     (:input (@ (type "checkbox")
                ,@(when done '((checked "checked")))
                (onclick ,on-toggle)))
     (:span ,title)
     (:button (@ (onclick ,on-delete)) "Delete")))

;; Root component — owns all state and defines all actions
(define-component todo ()
  (let-component-state ((todos '()) (next-id 0))
    (let-function
        ((add-todo (form-data)
           (let ((title (getf form-data :|todo-text|)))
             (when (and title (not (string= title "")))
               (setf todos (append todos
                                   (list (list :id next-id :title title :done nil))))
               (incf next-id))))
         (toggle-done (id)
           (setf todos (mapcar (lambda (item)
                                 (if (= (getf item :id) id)
                                     (list :id id :title (getf item :title)
                                           :done (not (getf item :done)))
                                     item))
                               todos)))
         (delete-todo (id)
           (setf todos (remove-if (lambda (item) (= (getf item :id) id)) todos))))
      `(:div
         (:h1 "Todo App")
         ;; Pass callback as S-expression prop
         (todo-input (@ (on-add (add-todo))))
         ;; Pass data and callback templates; child appends item id per row
         (todo-list (@ (todos ,todos)
                       (on-toggle (toggle-done))
                       (on-delete (delete-todo))))))))
```

**Design principle:** All actions are defined in the root component. Child components are purely presentational — they receive data and callback S-expressions as props, emit them as `data-on-click` / `data-on-submit` attributes, and the client always routes actions to the root component.

### Form Submission

Wrap the submit event in `onsubmit`. The client collects `FormData` automatically and appends it as the last argument to the action:

```lisp
(define-component todo-input (on-add)
  `(:form (@ (onsubmit ,on-add))
     (:input (@ (type "text") (name "todo-text") (placeholder "New todo...")))
     (:button (@ (type "submit")) "Add")))
```

The action handler receives form fields as a plist keyed by field name:

```lisp
(add-todo (form-data)
  (let ((title (getf form-data :|todo-text|)))
    ...))
```

### Mounting

A static HTML page provides the shell:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>My App</title>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/app.js"></script>
</body>
</html>
```

The server dynamically generates `app.js` based on the mount configuration:

```lisp
(configure-mount :target "#root"
                 :component "counter-app"
                 :props '(:initial-count 0))

(start-server :port 5001
              :static-root (asdf:system-relative-pathname
                            :cl-s3r "sample/01-counter/"))
```

## Architecture

```
Browser                          Server (Common Lisp)
  |                                |
  |  GET /                         |
  |------------------------------->|  Serve static index.html
  |<-------------------------------|
  |                                |
  |  GET /app.js                   |
  |------------------------------->|  Generate mount script
  |<-------------------------------|
  |                                |
  |  POST /api/render              |
  |  { component, props }          |
  |------------------------------->|  Render component to HTML
  |<-------------------------------|
  |                                |
  |  User clicks a button          |
  |                                |
  |  POST /action                  |
  |  { action, state }             |
  |------------------------------->|  Execute action, re-render
  |  { html, state }               |
  |<-------------------------------|
  |                                |
  |  Replace DOM                   |
```

### Key Macros

| Macro | Purpose |
|---|---|
| `define-component` | Define a named component with props |
| `let-component-state` | Declare state variables serialized to the client |
| `let-function` | Register action functions callable from the client |

### Server Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/` | GET | Serve static `index.html` |
| `/app.js` | GET | Dynamically generated mount entry point |
| `/api/render` | POST | Initial component render |
| `/action` | POST | Execute action and return updated HTML |
| `/cl-s3r.js` | GET | Client runtime module |

## Project Structure

```
cl-s3r/
  cl-s3r.asd              -- System definition
  src/
    renderer.lisp          -- S-expression to HTML converter
    component.lisp         -- Component macros and action dispatch
    server.lisp            -- HTTP server and routing
    client/
      cl-s3r.js            -- Client entry module (barrel)
      cl-mount.js          -- mount() function
      cl-runtime.js        -- State collection and server communication
      cl-component.js      -- Custom Element base class
  sample/
    01-counter/
      app.lisp             -- Counter component definition and server setup
      index.html           -- Static HTML shell
      Dockerfile
      docker-compose.yml
      Makefile
    02-todo/
      app.lisp             -- Todo app (nested components, form submission)
      index.html           -- Static HTML shell
      Dockerfile
      docker-compose.yml
      Makefile
```

## Dependencies

- [Alexandria](https://alexandria.common-lisp.dev/) -- Common Lisp utilities
- [Jonathan](https://github.com/Rudolph-Miller/jonathan) -- JSON encoder/decoder
- [Clack](https://github.com/fukamachi/clack) -- Web application environment
- [Hunchentoot](https://edicl.github.io/hunchentoot/) -- HTTP server (via clack-handler-hunchentoot)

## Roadmap

### Phase 1: MVP (current)
- [x] Single counter component with working state management
- [x] S-expression to HTML renderer
- [x] Client-server action round-trip with `innerHTML` replacement
- [x] Mount-based initialization (`configure-mount` + static HTML)

### Phase 2: Nested Components and Forms (current)
- [x] Parent-child component nesting with S-expression callback props
- [x] Automatic `FormData` mapping to server-side action arguments
- [x] Full state tree collection from root component
- [x] Todo sample app (`sample/02-todo`)

### Phase 3: UX Optimization
- [ ] DOM diffing (virtual DOM or morphdom) to replace full `innerHTML` swap
- [ ] State encryption and HMAC signing for tamper protection

## License

MIT
