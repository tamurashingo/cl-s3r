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

### 2. Layout, Component, and Route

Create `app.lisp`:

```lisp
(defpackage :counter
  (:use :cl)
  (:import-from :cl-s3r.server
                :configure-default-layout
                :configure-route)
  (:import-from :cl-s3r.component
                :define-component
                :define-layout
                :let-component-state
                :let-function))

(in-package :counter)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "en"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "Counter"))
     (:body
       ,children)))

(configure-default-layout 'app-layout)

(define-component counter-app (&key initial-count &allow-other-keys)
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

A component is defined with `define-component`, declares its state with `let-component-state`, and registers client-callable actions with `let-function`. All props are received as keyword arguments:

```lisp
(define-component counter-app (&key initial-count &allow-other-keys)
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
(define-component todo-item (&key id title done on-toggle on-delete &allow-other-keys)
  `(:li
     (:input (@ (type "checkbox")
                ,@(when done '((checked "checked")))
                (onclick ,on-toggle)))
     (:span ,title)
     (:button (@ (onclick ,on-delete)) "Delete")))

;; Root component — owns all state and defines all actions
(define-component todo (&key &allow-other-keys)
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
(define-component todo-input (&key on-add &allow-other-keys)
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

## Layout System

Layouts define the HTML document shell (the `<html>`, `<head>`, and `<body>` structure). Unlike components, layouts have no state and no `data-state` attribute.

### Defining a Layout

```lisp
(define-layout app-layout (&key children &allow-other-keys)
  `(:html (@ (lang "ja"))
     (:head
       (:meta (@ (charset "UTF-8")))
       (:title "My App"))
     (:body
       (:header "My Site")
       ,children
       (:footer "© 2026"))))
```

`children` receives the `<div id="root">` and `<script>` tag automatically injected by the framework.

### Setting the Default Layout

```lisp
(configure-default-layout 'app-layout)
```

This layout is applied to all routes unless overridden.

### Nested Layouts

Layouts can embed other layouts by using the layout name as a non-keyword symbol:

```lisp
(define-layout admin-layout (&key children &allow-other-keys)
  `(app-layout
     (:div (@ (class "admin-wrapper"))
       (:nav (:a (@ (href "/admin")) "Dashboard"))
       (:main ,children))))
```

### Per-Route Layout Override

Use the `:layout` keyword in `configure-route` to override the default:

```lisp
;; Use a specific layout for this route
(configure-route :path "/admin"
                 :component "admin-dashboard"
                 :layout 'admin-layout)

;; No layout — emit only the minimal HTML the framework injects
(configure-route :path "/embed"
                 :component "embed-widget"
                 :layout nil)
```

`:layout` defaults to `:inherit`, which uses the layout set by `configure-default-layout`.

### Import

```lisp
(:import-from #:cl-s3r.component #:define-layout)
(:import-from #:cl-s3r.server    #:configure-default-layout)
```

## Routing and Mounting

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
GET /detail/1            → server renders layout + root; script src="/detail/1/app.js"
GET /detail/1/app.js     → mount('impl-detail', { props: {ID: 1}, apiPrefix: '/detail/1' })
POST /detail/1/api/render → render impl-detail with id=1
```

#### Query Parameters

Query string parameters are automatically parsed and merged into the component props passed via `app.js`. Each parameter name is converted to an uppercase keyword (e.g. `?filter=foo` becomes `:FILTER "foo"`).

```lisp
;; Component receives :filter as a prop
(define-component impl-list (&key filter &allow-other-keys)
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

### Route Guards

Use `:guard` to protect a route with an authentication check. The guard function receives the Clack `env` and must return `nil` to allow access, or a redirect path string to reject:

```lisp
(defun require-auth (env)
  (unless (cl-s3r.cookie:get-cookie-from-env env "session")
    "/"))

(configure-route :path "/detail"
                 :component "detail-page"
                 :props '()
                 :guard #'require-auth)
```

When the guard returns a non-`nil` string, the server responds with HTTP 302 to that path without rendering the component.

## Page Metadata

Use `define-metadata` to generate page-level metadata (such as `<title>`) dynamically from route parameters.

### How It Works

`define-metadata` is registered under the same component name used in `configure-route`. When the server handles an initial `GET` request, it calls the metadata function with the resolved props and uses the result to update the `<title>` tag in the HTML document.

### Syntax

```lisp
(define-metadata component-name (&key prop1 prop2 &allow-other-keys)
  ;; Returns a plist such as (:title "..."), or NIL to leave the layout title unchanged.
  ...)
```

### Example

```lisp
;; Route: GET /detail/:id → component "impl-detail"
(configure-route :path "/detail"
                 :path-param :id
                 :component "impl-detail"
                 :props '())

;; Metadata for "impl-detail" — same component name as configure-route
(define-metadata impl-detail (&key id &allow-other-keys)
  (let ((impl (find id *implementations*
                    :key (lambda (x) (getf x :id))
                    :test #'=)))
    (when impl
      (list :title (format nil "~A - My Site" (getf impl :name))))))
```

When visiting `/detail/1`, the response HTML contains:

```html
<title>SBCL - My Site</title>
```

### Supported Metadata Fields

| Key | Effect |
|---|---|
| `:title` | Replaces (or inserts) the `<title>` tag in `<head>` |

### Import

```lisp
(:import-from #:cl-s3r.component #:define-metadata)
```

## Error Handling

Use `define-error-page` to register custom error pages for specific HTTP status codes, and `signal-http-error` to raise errors from within components.

### API

```lisp
;; Register a component as an error page for a status code
(define-error-page :status 404 :component "not-found-page")

;; :layout controls the layout used for the error page (same options as configure-route)
(define-error-page :status 500 :component "server-error-page" :layout 'minimal-layout)
(define-error-page :status 503 :component "maintenance-page"  :layout nil)

;; Raise an HTTP error from a component (signals cl-s3r.component:http-error)
(signal-http-error 404 :message "Item not found.")
```

When no matching error page is registered, the framework falls back to a minimal built-in HTML response.

### Example

```lisp
(define-component not-found-page (&key message &allow-other-keys)
  `(:div (@ (class "error"))
     (:h1 "404 - Not Found")
     ,@(when message `((:p ,message)))
     (:a (@ (href "/")) "Back to top")))

(define-error-page :status 404 :component "not-found-page")

(define-component item-detail (&key id &allow-other-keys)
  (let ((item (find-item id)))
    (unless item
      (signal-http-error 404 :message (format nil "Item ~A not found." id)))
    `(:div (:h1 ,(getf item :name)))))
```

### Import

```lisp
(:import-from #:cl-s3r.server    #:define-error-page)
(:import-from #:cl-s3r.component #:signal-http-error)
```

## Session Management

`cl-s3r.session` provides a high-level session API built on top of `cl-s3r.cookie`. Sessions are identified by a cryptographically signed cookie and backed by an in-memory store by default.

### Import

```lisp
(:import-from #:cl-s3r.session
              #:get-session
              #:set-session
              #:destroy-session
              #:set-session-store-handler)
```

### API

| Function | Description |
|---|---|
| `(get-session :key1 :key2 ...)` | Return a plist of the specified session keys |
| `(set-session plist)` | Merge `plist` into the current session (creates a session if none exists) |
| `(destroy-session)` | Delete the session and clear the cookie |
| `(set-session-store-handler ...)` | Replace the storage backend |

### Example

```lisp
(define-component home-page (&key &allow-other-keys)
  (let-function
      ((do-login (form-data)
         (when (valid-credentials-p (getf form-data :|username|)
                                    (getf form-data :|password|))
           (set-session (list :username (getf form-data :|username|)
                              :last-login (get-universal-time)))))
       (do-logout ()
         (destroy-session)))
    (let* ((session  (get-session :username))
           (username (getf session :username)))
      ...)))
```

### Security

- Session ID: 16-byte cryptographic random value (32-char hex).
- Cookie value: `{session-id}.{HMAC-SHA256}` — tamper-evident.
- Constant-time comparison against timing attacks.
- Secret key read from `SESSION_SECRET` env var; a random value is generated with a warning when unset.

### Session Timeout

The default timeout is 3600 seconds. Override with `*session-timeout*`:

```lisp
(setf cl-s3r.session:*session-timeout* 7200)
```

### Custom Session Store

```lisp
(cl-s3r.session:set-session-store-handler
  :get    (lambda (id) ...)
  :set    (lambda (id data) ...)
  :delete (lambda (id) ...))
```

Timeout enforcement always happens in the `cl-s3r` layer regardless of the backend.

### Testing with Sessions

```lisp
(:import-from #:cl-s3r.session #:create-session-for-test #:reset-session-store!)

;; Create a test session and bind it as the current request cookie
(let ((cookie (cl-s3r.session:create-session-for-test '(:username "taro"))))
  (let ((cl-s3r.cookie:*current-cookies* (list cookie)))
    (test-render-component "home-page" :args '())))

;; Reset the in-memory store between tests
(cl-s3r.session:reset-session-store!)
```

## Cookie Support

`cl-s3r.cookie` provides low-level access to request cookies and response cookie headers. For most use cases, prefer `cl-s3r.session` instead.

### Import

```lisp
(:import-from #:cl-s3r.cookie
              #:get-cookie
              #:get-cookie-from-env
              #:set-response-cookie
              #:delete-response-cookie)
```

### API

| Function | Purpose |
|---|---|
| `(get-cookie name)` | Return the value of cookie `name` from the current request, or `nil` |
| `(get-cookie-from-env env name)` | Read a cookie from a Clack `env` directly (useful in guard functions) |
| `(set-response-cookie name value &key max-age path domain secure http-only same-site)` | Queue a `Set-Cookie` header for the current response |
| `(delete-response-cookie name &key path domain)` | Queue a cookie deletion (`Max-Age=0`) |

### How It Works

At the start of every request, `*current-cookies*` is bound to the parsed `Cookie:` header. `get-cookie` reads from this binding. `set-response-cookie` and `delete-response-cookie` push entries onto `*pending-cookie-changes*`. After the handler returns, `Set-Cookie` headers are injected into the response automatically.

### Testing with Cookies

```lisp
;; (:import-from #:cl-s3r.cookie #:*current-cookies* #:*pending-cookie-changes*)

(let ((*current-cookies* '(("session" . "taro")))
      (*pending-cookie-changes* nil))
  (let* ((r1 (test-render-component "my-page" :args '()))
         (r2 (test-call-action "my-page" "do-logout"
                               :state (getf r1 :state)
                               :action-args '())))
    (assert (= 0 (getf (first *pending-cookie-changes*) :max-age)))))
```

## Configuration and Environment Variables

`cl-s3r.config` loads `.env` files automatically and provides type-converting helpers for reading environment variables.

### Import

```lisp
(:import-from #:cl-s3r.config
              #:getenv
              #:getenv-integer
              #:getenv-boolean)
```

### API

```lisp
;; String — optional default, or :required t to error when unset
(cl-s3r.config:getenv "DATABASE_URL" :default "sqlite://./dev.db")
(cl-s3r.config:getenv "SECRET_KEY"   :required t)

;; Integer
(cl-s3r.config:getenv-integer "PORT" :default 5000)

;; Boolean — "true" / "1" → t, anything else → nil
(cl-s3r.config:getenv-boolean "DEBUG" :default nil)
```

### `.env` File Loading Order

`s3rup` loads `.env` files from the app directory on startup:

| File | When loaded |
|---|---|
| `.env` | Always |
| `.env.<env>` | When `--env <env>` or `S3R_ENV=<env>` is set |
| `.env.local` | Always (personal overrides — add to `.gitignore`) |

Later files override earlier ones. OS environment variables always take priority over `.env` values.

Specify the environment name:

```sh
s3rup --env prod ./counter.asd
# or
S3R_ENV=prod s3rup ./counter.asd
```

## Static Files

Use `configure-static-dir` to serve app-specific assets (CSS, images, fonts). The `asset-path` helper builds the correct URL whether assets are served locally or from a CDN.

### Import

```lisp
(:import-from #:cl-s3r.server
              #:configure-static-dir
              #:asset-path)
```

### API

```lisp
;; Serve files from a directory (default: public/ relative to app)
(configure-static-dir (asdf:system-relative-pathname "my-app" "public/"))

;; Build an asset URL — returns absolute URL when S3R_ASSET_BASE_URL is set,
;; otherwise returns the path as-is
(asset-path "/styles.css")  ; => "/styles.css" or "https://cdn.example.com/styles.css"
```

### Example

```lisp
(configure-static-dir (asdf:system-relative-pathname "my-app" "public/"))

(define-layout app-layout (&key children &allow-other-keys)
  `(:html
     (:head
       (:link (@ (rel "stylesheet") (href ,(asset-path "/styles.css")))))
     (:body ,children)))
```

### Environment Variables

| Variable | Description |
|---|---|
| `S3R_ASSET_BASE_URL` | Prefix for `asset-path` — set to a CDN origin to return absolute URLs |
| `S3R_ASSET_SERVING_DISABLED=true` | Disable the static file middleware (when a CDN or reverse proxy serves assets) |

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

(let* ((r1 (cl-s3r.testing:test-render-component "counter-app"
                                                  :args '(:initial-count 0)))
       (r2 (cl-s3r.testing:test-call-action "counter-app" "increment"
                                            :state (getf r1 :state)
                                            :args  '(:initial-count 0))))
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
  |------------------------------->|  Render layout + root component to HTML
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
  |  Morph DOM (diff update)        |
```

All API endpoints are relative to the route's `apiPrefix`. For a root route the prefix is empty; for `/detail/1` the prefix is `/detail/1`, so the endpoints become `/detail/1/api/render` and `/detail/1/action`.

### Key Macros

| Macro | Purpose |
|---|---|
| `define-layout` | Define a named layout (HTML document shell, no state) |
| `define-component` | Define a named component with keyword props |
| `let-component-state` | Declare state variables serialized to the client |
| `let-function` | Register action functions callable from the client |
| `define-metadata` | Register a metadata function for a route component (e.g. page title) |
| `define-error-page` | Register a component as the error page for an HTTP status code |
| `signal-http-error` | Raise an HTTP error from within a component |

### Server API

| Function | Purpose |
|---|---|
| `configure-default-layout` | Set the default layout applied to all routes |
| `configure-route` | Map a URL path to a page component; supports `:path-param`, `:guard`, `:layout` |
| `configure-mount` | Shorthand for `configure-route :path "/"` |
| `configure-static-dir` | Set the directory to serve static assets from |
| `asset-path` | Build an asset URL (local path or CDN-prefixed absolute URL) |
| `run-server` | Start the server, block until interrupted, then stop cleanly. Port defaults to `PORT` env var or 5000. Called by `s3rup`. |
| `start-server` | Start the HTTP server on a given port (low-level) |
| `stop-server` | Stop the running server (low-level) |

### Server Endpoints (per route prefix)

| Endpoint | Method | Description |
|---|---|---|
| `<prefix>/` | GET | Render layout + root component and return full HTML document |
| `<prefix>/app.js` | GET | Dynamically generated mount entry point |
| `<prefix>/api/render` | POST | Initial page component render |
| `<prefix>/action` | POST | Execute action and return updated HTML |
| `/cl-s3r.js` | GET | Client runtime module (shared, prefix-independent) |
| `/cl-morph.js` | GET | DOM morphing utility (shared, prefix-independent) |

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

Demonstrates session-based authentication: a login form at `/`, a session-protected `/detail` page, and last-login tracking stored in the session.

```sh
cd sample/04-login
make image && make up
```

Open `http://localhost:5004`. Test credentials: `taro/password1`, `jiro/password2`, `saburo/password3`.

### Carousel (`sample/05-carousel`)

Demonstrates CSS transition animations powered by DOM morphing. Five colored slides are navigated with previous/next buttons. The server updates only the `transform: translateX(...)` style attribute; because the DOM morph preserves the element in place rather than replacing it, the browser's `transition` smoothly animates the slide change.

```sh
cd sample/05-carousel
make image && make up
```

Open `http://localhost:5005`.

### Error Handling (`sample/06-error-handling`)

Demonstrates `define-error-page` and `signal-http-error`. Includes a list page, a detail page that raises a 404 for unknown items, and a route that triggers a 500 error.

```sh
cd sample/06-error-handling
make image && make up
```

Open `http://localhost:5006`.

To stop any sample:

```sh
make down
```

### Component Spec-Sheet (`spec/`)

An interactive [spec-sheet](https://github.com/tamurashingo/spec-sheet) browser for the components included in this repository. Similar to Storybook — browse named parameter variations (sheets) and tweak props live in a Playground.

A live demo is available at:

https://cl-s3r-ui-component-323245676568.asia-northeast1.run.app/spec-sheet/

To run locally:

```sh
cd spec
make spec-sheet
```

Open `http://localhost:5100/spec-sheet`.

To stop:

```sh
make down
```

### External: clails + cl-s3r Sample ([tamurashingo/clails-s3r-sample](https://github.com/tamurashingo/clails-s3r-sample))

A multi-user TODO application that demonstrates using cl-s3r as a BFF/SSR frontend alongside [clails](https://github.com/tamurashingo/clails) (a REST API server), backed by PostgreSQL.

```
Browser → cl-s3r (:3000) → clails REST API (:5000) → PostgreSQL (:5432)
```

cl-s3r handles server-side rendering and proxies form submissions to the clails API. See the repository for setup instructions.

### Running Sample Tests (Rove unit tests)

Each sample has a `make test` target. It uses the pre-built Docker image but mounts the current source tree, so tests always run against the latest code without rebuilding the image.

```sh
cd sample/01-counter && make test
cd sample/02-todo    && make test
cd sample/03-books   && make test
cd sample/04-login   && make test
cd sample/06-error-handling && make test
```

`make image` must have been run at least once before running tests.

### E2E Tests (Playwright)

The `e2e/` directory contains Playwright tests that start all sample apps and run browser-level interaction tests against them inside Docker.

```sh
cd e2e
make image   # build all sample images + the Playwright runner image
make test    # start samples, wait for health checks, then run all tests
make clean   # stop containers and remove images
```

The `make test` command uses `docker compose run --rm playwright`, which automatically starts the sample containers as dependencies and waits for their health checks to pass before launching the tests.

**Test coverage:**

| File | Sample | What is tested |
|---|---|---|
| `tests/01-counter.spec.js` | Counter (5001) | Initial count, increment, decrement, multiple clicks, CSS served |
| `tests/02-todo.spec.js` | Todo (5002) | Add, toggle done/undone, delete, multiple items |
| `tests/03-books.spec.js` | Books (5003) | Full list, search filter, empty result, detail page, back navigation |
| `tests/04-login.spec.js` | Login (5004) | Login form, invalid credentials, valid login, logout, unauthenticated redirect |
| `tests/06-error-handling.spec.js` | Error Handling (5006) | Item list, detail page, 404 on missing item, 500 on crash, navigation from error page |

The tests can also be run against locally running sample apps without Docker by setting environment variables:

```sh
COUNTER_URL=http://localhost:5001 \
TODO_URL=http://localhost:5002 \
BOOKS_URL=http://localhost:5003 \
LOGIN_URL=http://localhost:5004 \
ERROR_HANDLING_URL=http://localhost:5006 \
npx playwright test
```

## UI Components

The `cl-s3r.components` namespace provides pre-built UI components as separate ASDF systems. Components are located under `src/components/`, each in its own subdirectory with a corresponding `.asd` file.

You can browse live examples and tweak props interactively via the spec-sheet:

https://cl-s3r-ui-component-323245676568.asia-northeast1.run.app/spec-sheet/

To run the spec-sheet locally:

```sh
cd spec
make spec-sheet
```

Open `http://localhost:5100/spec-sheet`.

## Project Structure

```
cl-s3r/
  cl-s3r.asd                       -- Core system definition
  cl-s3r.components.accordion.asd  -- Accordion component system
  cl-s3r.components.icon.asd       -- Icon component system
  roswell/
    s3rup.ros        -- CLI entry point (s3rup <app.asd>)
  src/
    renderer.lisp    -- S-expression → HTML converter
    component.lisp   -- define-component, define-layout, action dispatch, error types
    testing.lisp     -- Test utilities (cl-s3r.testing)
    cookie.lisp      -- Per-request cookie access (cl-s3r.cookie)
    session.lisp     -- HMAC-signed session management (cl-s3r.session)
    config.lisp      -- .env loading and typed env helpers (cl-s3r.config)
    server.lisp      -- HTTP server, prefix routing, layouts, error pages, static files
    client/          -- ES6 modules served to the browser
    components/
      accordion/     -- Accordion component (cl-s3r.components.accordion)
      icon/          -- Font Awesome SVG icon component (cl-s3r.components.icon)
  sample/
    01-counter/      -- Basic stateful counter (port 5001)
    02-todo/         -- Nested components and form submission (port 5002)
    03-books/        -- Multi-route app with path parameters (port 5003)
    04-login/        -- Session-based authentication (port 5004)
    05-carousel/     -- CSS transition animations via DOM morphing (port 5005)
    06-error-handling/ -- define-error-page and signal-http-error (port 5006)
  spec/
    src/             -- Component spec definitions for the spec-sheet browser
    Makefile         -- make spec-sheet: start on port 5100
  e2e/               -- Playwright browser tests for all sample apps
```

## Dependencies

- [Alexandria](https://alexandria.common-lisp.dev/) -- Common Lisp utilities
- [Jonathan](https://github.com/Rudolph-Miller/jonathan) -- JSON encoder/decoder
- [Clack](https://github.com/fukamachi/clack) -- Web application environment
- [Hunchentoot](https://edicl.github.io/hunchentoot/) -- HTTP server (via clack-handler-hunchentoot)
- [Ironclad](https://github.com/sharplispers/ironclad) -- Cryptographic operations (session HMAC)
- [Babel](https://github.com/cl-babel/babel) -- Character encoding
- [Bordeaux-Threads](https://github.com/sionescu/bordeaux-threads) -- Thread-safe session store

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
- [x] Server renders full HTML document from Lisp S-expressions on every initial request
- [x] `<script>` tag injected automatically; no static files required

### Phase 6: Page Metadata
- [x] `define-metadata` — generate page-level metadata (title etc.) from route props
- [x] Server injects metadata into the HTML document on initial render

### Phase 7: Cookie Support
- [x] `cl-s3r.cookie` package — per-request `*current-cookies*` and `*pending-cookie-changes*` dynamic variables
- [x] `get-cookie`, `set-response-cookie`, `delete-response-cookie` for component-level cookie access
- [x] `inject-set-cookie-headers` appends `Set-Cookie` headers to the Clack response automatically

### Phase 8: UX Optimization
- [x] DOM morphing (`cl-morph.js`) to replace full `innerHTML` swap — preserves element references, enables CSS transitions
- [x] Carousel sample app (`sample/05-carousel`) demonstrating CSS transition animations via DOM morphing
- [ ] State encryption and HMAC signing for tamper protection

### Phase 9: Keyword Arguments for Components
- [x] All `define-component` / `define-layout` / `define-metadata` props use `&key ... &allow-other-keys`
- [x] Uniform prop passing via keyword plists throughout the framework

### Phase 10: Route Guards
- [x] `:guard` keyword for `configure-route` — function receives Clack `env`, returns redirect path or `nil`
- [x] HTTP 302 redirect when guard returns non-`nil`
- [x] `get-cookie-from-env` utility for reading cookies inside guard functions

### Phase 11: Session Management
- [x] `cl-s3r.session` package — `get-session`, `set-session`, `destroy-session`
- [x] HMAC-SHA256 signed session cookies (constant-time comparison)
- [x] In-memory session store with mutex; pluggable via `set-session-store-handler`
- [x] `SESSION_SECRET` env var; random fallback with warning
- [x] Login sample updated to session API (`sample/04-login`)

### Phase 12: Configuration Management
- [x] `cl-s3r.config` package — `getenv`, `getenv-integer`, `getenv-boolean`
- [x] `.env` / `.env.<env>` / `.env.local` cascade loaded by `s3rup`
- [x] `--env` / `S3R_ENV` for selecting the environment

### Phase 13: Layout System
- [x] `define-layout` — stateless HTML document shell, no `data-state` attribute
- [x] `configure-default-layout` — global default layout
- [x] `:layout` option on `configure-route` — per-route override (`nil` for no layout)
- [x] Layout nesting (a layout can embed another layout)

### Phase 14: Error Handling
- [x] `define-error-page` — register a component for an HTTP status code
- [x] `signal-http-error` — raise an HTTP error from a component
- [x] `http-error` condition type with `status-code` and `params` slots
- [x] Error pages respect the same `:layout` options as routes
- [x] Error handling sample app (`sample/06-error-handling`)

### Phase 15: Static File Serving
- [x] `configure-static-dir` — serve assets via `lack/middleware/static`
- [x] `asset-path` — root-relative or CDN-prefixed URL helper
- [x] `S3R_ASSET_BASE_URL` / `S3R_ASSET_SERVING_DISABLED` environment variables

## License

MIT

## Third-party Licenses

### Font Awesome Free

The icon component (`cl-s3r.components.icon`) includes SVG icon data from [Font Awesome Free](https://fontawesome.com/).

- **Icons:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **Fonts:** [SIL OFL 1.1](https://openfontlicense.org/open-font-license-official-text/)
- **Code:** [MIT License](https://opensource.org/licenses/MIT)

https://fontawesome.com/license/free
