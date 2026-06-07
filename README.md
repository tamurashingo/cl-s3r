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

To stop:

```sh
make down
```

## Defining Components

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

### Phase 2: Nested Components and Forms
- [ ] Parent-child component nesting with S-expression callback props
- [ ] Automatic `FormData` mapping to server-side action arguments
- [ ] Full state tree collection from root component

### Phase 3: UX Optimization
- [ ] DOM diffing (virtual DOM or morphdom) to replace full `innerHTML` swap
- [ ] State encryption and HMAC signing for tamper protection

## License

MIT
