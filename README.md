# cl-s3r

**Server Side S-expression Renderer** for Stateless Component-Driven Web Frontend.

cl-s3r is a Common Lisp web framework that lets you build reactive web UIs using S-expressions. Components are defined entirely in Lisp, rendered server-side to HTML, and kept alive through a stateless request/response cycle -- the server holds no state between requests.

## How It Works

1. **S-expressions as HTML** -- Write UI with keyword symbols (`:div`, `:p`, `:button`) and Lisp's backquote/comma syntax for dynamic values.
2. **Completely stateless server** -- Component state is serialized into `data-state` attributes on the client. The server retains nothing between requests.
3. **Unidirectional data flow** -- On user interaction, the client POSTs the entire state tree to the server. The server executes the action, re-renders the component, and returns the new HTML.
4. **Decoupled components** -- Child components never reference parent functions directly. Callbacks are passed as S-expression data through props.

## Quick Start

This section walks through building a counter app from scratch.

### Prerequisites

- [Roswell](https://github.com/roswell/roswell)
- [SBCL](https://www.sbcl.org/) (installable via Roswell: `ros install sbcl`)

### Install s3rup

```sh
ros install tamurashingo/cl-s3r
```

Verify the installation:

```sh
s3rup --help
```

### Create the Project

```sh
mkdir counter
cd counter
```

### 1. ASDF System File

Create `counter.asd`:

```lisp
(defsystem "counter"
  :depends-on (:cl-s3r)
  :components ((:file "app")))
```

### 2. Component and Route

Create `app.lisp`:

```lisp
(defpackage :counter
  (:use :cl)
  (:import-from :cl-s3r.server
                :configure-root-page
                :configure-route)
  (:import-from :cl-s3r.component
                :define-component
                :let-component-state
                :let-function))

(in-package :counter)

(define-component root (children)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "Counter"))
     (:body
       ,children)))

(configure-root-page :component "root")

(define-component counter-app (initial-count)
  (let-component-state ((count initial-count))
    (let-function ((increment () (incf count))
                   (decrement () (decf count)))
      `(:div
         (:h1 "Counter App")
         (:p "Count: " ,count)
         (:button (@ (onclick (increment))) "+")
         (:button (@ (onclick (decrement))) "-")))))

(configure-route :path "/"
                 :component "counter-app"
                 :props '(:initial-count 0))
```

### 3. Run

```sh
s3rup ./counter.asd
```

Open `http://localhost:5000` in your browser.

To use a different port:

```sh
s3rup --port 8080 ./counter.asd
# or
PORT=8080 s3rup ./counter.asd
```

Press Ctrl+C to stop the server.

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
         (todo-input (@ (on-add (add-todo))))
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

## Routing and Mounting

### Root Layout (`configure-root-page`)

Use `configure-root-page` to define the layout component that wraps every page. The server renders this component to produce the initial full HTML document. The framework automatically injects a `<div id="root">` (as the `children` argument) and the `<script type="module" src="/app.js">` tag into the rendered HTML.

```lisp
(define-component root (children)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "My App"))
     (:body
       ,children)))

(configure-root-page :component "root")
```

`children` can be placed anywhere in the layout body:

```lisp
(define-component root (children)
  `(:html
     (:body
       (:header "My App")
       ,children
       (:footer "© 2026"))))
```

### Routes (`configure-route`)

Use `configure-route` to map URL paths to page components. Routes are matched by longest prefix:

```lisp
(configure-route :path "/"
                 :component "impl-list"
                 :props '())

(configure-route :path "/detail"
                 :path-param :id
                 :component "impl-detail"
                 :props '())
```

#### Path Parameters

When `:path-param` is specified, the URL segment immediately after the path (e.g. `1` in `/detail/1`) is extracted and passed to the component as a prop under that keyword.

URL flow for `GET /detail/1`:

```
GET /detail/1            → server renders root component; script src="/detail/1/app.js"
GET /detail/1/app.js     → mount('impl-detail', { props: {ID: 1}, apiPrefix: '/detail/1' })
POST /detail/1/api/render → render impl-detail with id=1
```

#### Query Parameters

Query string parameters are automatically parsed and merged into the component props passed via `app.js`. Each parameter name is converted to an uppercase keyword (e.g. `?filter=foo` becomes `:FILTER "foo"`).

```lisp
;; Component receives :filter as a prop
(define-component impl-list (filter)
  ...)

;; Route needs no special configuration — query params are picked up automatically
(configure-route :path "/"
                 :component "impl-list"
                 :props '())
```

Visiting `/?filter=MIT` causes the server to serve `app.js` with `props: { FILTER: "MIT" }`, which is then passed to the initial render call.

#### Name Conflicts Between Path and Query Parameters

When a path parameter and a query parameter share the same name, **the path parameter takes priority**. Props are merged in order — `configure-route :props` first, then the path parameter, then query parameters — and `getf` returns the first match:

```
/detail/1?id=99  →  props: { ID: 1 }   ; path-param wins, query-param is ignored
```

## Page Metadata

Use `define-metadata` to generate page-level metadata (such as `<title>`) dynamically from route parameters. This is analogous to Next.js's `generateMetadata`.

### How It Works

`define-metadata` is registered under the same component name used in `configure-route`. When the server handles an initial `GET` request, it looks up the metadata function by the route's `:component` name, calls it with the resolved props (path parameters and query parameters), and uses the result to update the `<title>` tag in the HTML document before sending the response.

Only the component named in `configure-route :component` is looked up. Metadata functions defined for child components rendered inside the page component are never called.

### Syntax

```lisp
(define-metadata component-name (prop1 prop2 ...)
  ;; Returns a plist such as (:title "..."), or NIL to leave the layout title unchanged.
  ...)
```

The argument list must match the props that the route component receives (path parameter + query parameters). Extra props passed by the framework are silently ignored.

### Example

```lisp
;; Route: GET /detail/:id → component "impl-detail"
(configure-route :path "/detail"
                 :path-param :id
                 :component "impl-detail"
                 :props '())

;; Metadata for "impl-detail" — same component name as configure-route
(define-metadata impl-detail (id)
  (let ((impl (find id *implementations*
                    :key (lambda (x) (getf x :id))
                    :test #'=)))
    (when impl
      (list :title (format nil "~A - My Site" (getf impl :name))))))
```

When visiting `/detail/1`, the server calls `(impl-detail :id 1)` and the response HTML contains:

```html
<title>SBCL - My Site</title>
```

When visiting `/` (no `define-metadata` for `impl-list`), the root layout's original `<title>` is left unchanged.

### Supported Metadata Fields

| Key | Effect |
|---|---|
| `:title` | Replaces (or inserts) the `<title>` tag in `<head>` |

### Import

```lisp
(:import-from #:cl-s3r.component
              #:define-metadata)
```

## Cookie Support

`cl-s3r` provides a `cl-s3r.cookie` package for reading request cookies and writing response cookies inside component code. Cookie state is bound per-request via dynamic variables — no global session state.

### Import

```lisp
(:import-from #:cl-s3r.cookie
              #:get-cookie
              #:set-response-cookie
              #:delete-response-cookie)
```

### API

| Function | Purpose |
|---|---|
| `(get-cookie name)` | Return the value of cookie `name` from the current request, or `nil` |
| `(set-response-cookie name value &key max-age path domain secure http-only same-site)` | Queue a `Set-Cookie` header for the current response |
| `(delete-response-cookie name &key path domain)` | Queue a cookie deletion (`Max-Age=0`) |

### Example

```lisp
(define-component my-page ()
  (let-function
      ((do-login (form-data)
         (when (valid-credentials-p (getf form-data :|username|)
                                    (getf form-data :|password|))
           (set-response-cookie "session" (getf form-data :|username|)
                                :http-only t :path "/")))
       (do-logout ()
         (delete-response-cookie "session" :path "/")))
    (let ((session (get-cookie "session")))
      (if session
          `(:div (:p ,(format nil "Welcome, ~A!" session))
                 (:button (@ (onclick (do-logout))) "Logout"))
          `(:form (@ (onsubmit (do-login)))
             (:input (@ (type "text") (name "username")))
             (:input (@ (type "password") (name "password")))
             (:button (@ (type "submit")) "Login"))))))
```

### How It Works

At the start of every request, `*current-cookies*` is bound to the parsed `Cookie:` header. `get-cookie` reads from this binding. `set-response-cookie` and `delete-response-cookie` push entries onto `*pending-cookie-changes*`. After the handler returns, `Set-Cookie` headers are injected into the response automatically.

### Testing with Cookies

Bind `*current-cookies*` and `*pending-cookie-changes*` in tests to simulate request cookies and capture queued cookie changes:

```lisp
;; Import in your test package:
;;   (:import-from #:cl-s3r.cookie #:*current-cookies* #:*pending-cookie-changes*)

(let ((*current-cookies* '(("session" . "taro")))
      (*pending-cookie-changes* nil))
  (let* ((r1 (test-render-component "my-page" :args '()))
         (r2 (test-call-action "my-page" "do-logout"
                               :state (getf r1 :state)
                               :action-args '())))
    ;; Check that a cookie deletion was queued
    (assert (= 0 (getf (first *pending-cookie-changes*) :max-age)))))
```

## Testing Components

`cl-s3r` provides a `cl-s3r.testing` package for unit-testing components without an HTTP server. It follows the library's stateless philosophy: state is passed explicitly between calls.

### API

```lisp
;; Render a component. Returns a plist with :SEXP, :RAW-SEXP, and :STATE.
(test-render-component component-name &key args initial-state)

;; Execute an action against a state. Returns the same plist shape.
(test-call-action component-name action-name &key state args action-args)

;; Extract a key from a state plist (case-insensitive). Returns the full plist when KEY is omitted.
(test-get-state state &optional key)
```

Return value shape:

| Key | Content |
|---|---|
| `:SEXP` | Rendered S-expression with `data-state` / `data-component` stripped — use this for structural assertions |
| `:RAW-SEXP` | Rendered S-expression as-is — use this to verify serialized state JSON |
| `:STATE` | Component state as a plist, e.g. `(:COUNT 5)` |

### Usage Example

```lisp
(ql:quickload :cl-s3r-sample-counter)

(let* ((r1 (cl-s3r.testing:test-render-component "counter-app" :args '(0)))
       (r2 (cl-s3r.testing:test-call-action "counter-app" "increment"
                                            :state (getf r1 :state)
                                            :args  '(0))))
  (cl-s3r.testing:test-get-state (getf r2 :state) :count))
;; => 1
```

### Notes on `let-function` and Unused Parameters

When an action parameter is unused, declare it ignored inside the function body:

```lisp
(let-function ((on-click (event)
                 (declare (ignore event))
                 (incf count)))
  ...)
```

The `let-function` macro automatically suppresses the "unused flet function" note that SBCL emits for action functions not called by name within the component body.

## Architecture

```
Browser                          Server (Common Lisp)
  |                                |
  |  GET /                         |
  |------------------------------->|  Render root component to HTML
  |<-------------------------------|  (includes <div id="root"> + <script src="/app.js">)
  |                                |
  |  GET /app.js                   |
  |------------------------------->|  Generate mount script (with apiPrefix)
  |<-------------------------------|
  |                                |
  |  POST /api/render              |
  |  { component, props }          |
  |------------------------------->|  Render page component to HTML
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

All API endpoints are relative to the route's `apiPrefix`. For a root route the prefix is empty; for `/detail/1` the prefix is `/detail/1`, so the endpoints become `/detail/1/api/render` and `/detail/1/action`.

### Key Macros

| Macro | Purpose |
|---|---|
| `define-component` | Define a named component with props |
| `let-component-state` | Declare state variables serialized to the client |
| `let-function` | Register action functions callable from the client |
| `define-metadata` | Register a metadata function for a route component (e.g. page title) |

### Server API

| Function | Purpose |
|---|---|
| `configure-root-page` | Register the layout component that renders the full HTML document shell |
| `configure-route` | Map a URL path to a page component; supports `:path-param` |
| `configure-mount` | Shorthand for `configure-route :path "/"` |
| `run-server` | Start the server, block until interrupted, then stop cleanly. Port defaults to `PORT` env var or 5000. Called by `s3rup`. |
| `start-server` | Start the HTTP server on a given port (low-level) |
| `stop-server` | Stop the running server (low-level) |

### Server Endpoints (per route prefix)

| Endpoint | Method | Description |
|---|---|---|
| `<prefix>/` | GET | Render root component and return full HTML document |
| `<prefix>/app.js` | GET | Dynamically generated mount entry point |
| `<prefix>/api/render` | POST | Initial page component render |
| `<prefix>/action` | POST | Execute action and return updated HTML |
| `/cl-s3r.js` | GET | Client runtime module (shared, prefix-independent) |

## Sample Apps

Each sample runs via Docker and requires Docker Compose.

### Counter (`sample/01-counter`)

```sh
cd sample/01-counter
make image && make up
```

Open `http://localhost:5001`.

### Todo (`sample/02-todo`)

```sh
cd sample/02-todo
make image && make up
```

Open `http://localhost:5002`.

### Implementations List/Detail (`sample/03-books`)

```sh
cd sample/03-books
make image && make up
```

Open `http://localhost:5003`.

### Login / Session (`sample/04-login`)

Demonstrates cookie-based authentication: a login form at `/`, a session-protected `/detail` page, and server-side last-login tracking.

```sh
cd sample/04-login
make image && make up
```

Open `http://localhost:5004`. Test credentials: `taro/password1`, `jiro/password2`, `saburo/password3`.

To stop any sample:

```sh
make down
```

### Running Sample Tests

Each sample has a `make test` target. It uses the pre-built Docker image but mounts the current source tree, so tests always run against the latest code without rebuilding the image.

```sh
cd sample/01-counter && make test
cd sample/02-todo    && make test
cd sample/03-books   && make test
cd sample/04-login   && make test
```

`make image` must have been run at least once before running tests.

## Project Structure

```
cl-s3r/
  cl-s3r.asd              -- System definition
  ros/
    s3rup.ros              -- Roswell script: s3rup <app.asd>
  src/
    renderer.lisp          -- S-expression to HTML converter
    component.lisp         -- Component macros and action dispatch
    testing.lisp           -- Test utilities (cl-s3r.testing package)
    cookie.lisp            -- Per-request cookie read/write (cl-s3r.cookie package)
    server.lisp            -- HTTP server, prefix routing, path-param support
    client/
      cl-s3r.js            -- Client entry module (barrel)
      cl-mount.js          -- mount() with apiPrefix support
      cl-runtime.js        -- State collection and server communication
      cl-component.js      -- Custom Element base class
  sample/
    01-counter/
      app.lisp             -- Root layout, counter component, and route configuration
      test.lisp            -- Rove tests
      cl-s3r-sample-counter.asd  -- App system (loaded by s3rup)
      01-counter.asd       -- Test system definition
      Dockerfile
      docker-compose.yml   -- Port 5001
      Makefile             -- make test runs tests via Docker volume mount
    02-todo/
      app.lisp             -- Root layout, todo app (nested components, form submission)
      test.lisp            -- Rove tests
      cl-s3r-sample-todo.asd     -- App system (loaded by s3rup)
      02-todo.asd          -- Test system definition
      Dockerfile
      docker-compose.yml   -- Port 5002
      Makefile
    03-books/
      app.lisp             -- Root layout, list/detail pattern with path parameters
      test.lisp            -- Rove tests
      cl-s3r-sample-books.asd    -- App system (loaded by s3rup)
      03-books.asd         -- Test system definition
      Dockerfile
      docker-compose.yml   -- Port 5003
      Makefile
    04-login/
      app.lisp             -- Root layout, cookie-based login, session-protected detail page
      test.lisp            -- Rove tests
      04-login.asd         -- App and test system definition
      Dockerfile
      docker-compose.yml   -- Port 5004
      Makefile
```

## Dependencies

- [Alexandria](https://alexandria.common-lisp.dev/) -- Common Lisp utilities
- [Jonathan](https://github.com/Rudolph-Miller/jonathan) -- JSON encoder/decoder
- [Clack](https://github.com/fukamachi/clack) -- Web application environment
- [Hunchentoot](https://edicl.github.io/hunchentoot/) -- HTTP server (via clack-handler-hunchentoot)

## Roadmap

### Phase 1: MVP
- [x] Single counter component with working state management
- [x] S-expression to HTML renderer
- [x] Client-server action round-trip with `innerHTML` replacement
- [x] Mount-based initialization (`configure-mount` + static HTML)

### Phase 2: Nested Components and Forms
- [x] Parent-child component nesting with S-expression callback props
- [x] Automatic `FormData` mapping to server-side action arguments
- [x] Full state tree collection from root component
- [x] Todo sample app (`sample/02-todo`)

### Phase 3: Prefix-Based Routing
- [x] `configure-route` for URL-prefix-to-component mapping
- [x] Longest-prefix match routing in the server
- [x] `apiPrefix` propagation through `app.js` to client fetch calls
- [x] Dynamic path parameters (`:path-param`) with auto-generated HTML and props injection
- [x] List/detail sample app (`sample/03-books`)

### Phase 4: Command-Line Tool
- [x] `run-server` in the cl-s3r core for server lifecycle management
- [x] `s3rup` Roswell command: loads an ASDF system and starts the server
- [x] Samples refactored to ASDF systems — no more server boilerplate in app code

### Phase 5: Server-Side Root Rendering
- [x] `configure-root-page` — root layout component replaces static `index.html`
- [x] Server renders full HTML document from Lisp S-expressions on every initial request
- [x] `<script>` tag injected automatically; no static files required

### Phase 6: Page Metadata
- [x] `define-metadata` — generate page-level metadata (title etc.) from route props
- [x] Server injects metadata into the HTML document on initial render

### Phase 7: Cookie Support
- [x] `cl-s3r.cookie` package — per-request `*current-cookies*` and `*pending-cookie-changes*` dynamic variables
- [x] `parse-cookies` reads the `Cookie:` request header (via Clack `:headers` hash table)
- [x] `get-cookie`, `set-response-cookie`, `delete-response-cookie` for component-level cookie access
- [x] `inject-set-cookie-headers` appends `Set-Cookie` headers to the Clack response automatically
- [x] Login/session sample app (`sample/04-login`) with protected routes and last-login tracking

### Phase 8: UX Optimization
- [ ] DOM diffing (virtual DOM or morphdom) to replace full `innerHTML` swap
- [ ] State encryption and HMAC signing for tamper protection

## License

MIT
