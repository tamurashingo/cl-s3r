# 11-nested — nested component behaviour

A diagnostic sample. Each route isolates one nesting pattern so that the
behaviour of nested components can be observed without one case disturbing
another. Unlike the other samples, this one is **not** a showcase: several
cases demonstrate behaviour that is currently broken.

## Running

```sh
cd sample/11-nested
make image && make up     # http://localhost:5011
make down
```

Unit tests (needs `make image` once):

```sh
make test
```

Without Docker:

```sh
ros run \
  --eval '(push #p"/path/to/cl-s3r/" asdf:*central-registry*)' \
  --eval '(push #p"/path/to/cl-s3r/sample/11-nested/" asdf:*central-registry*)' \
  --eval '(ql:quickload :11-nested)' \
  --eval '(cl-s3r.server:run-server :port 5011)'
```

## Vocabulary

* **stateless child** — a component with no `let-component-state`; it renders
  `data-state="{}"`.
* **stateful child** — a component with its own `let-component-state`, so it
  renders a non-empty `data-state`.
* **parent action** — an action defined in an ancestor's `let-function` and
  passed down as an S-expression prop.

## Cases and what actually happens

Verified in Chromium against a locally running server.

| # | Route | Pattern | Result |
|---|---|---|---|
| 1 | `/case1` | stateless child invokes a parent action | **works** |
| 2 | `/case2` | stateful child invokes its own action | **works** |
| 3 | `/case3` | stateful child, then the parent re-renders | **child state is lost** |
| 4 | `/case4` | parent action rendered inside a stateful child | **action silently dropped** |
| 5 | `/case5` | two instances of the same stateful child | works alone; both reset on a parent re-render |
| 6 | `/case6` | the same patterns three levels deep | depth alone changes nothing |
| 7 | `/case7` | all state lifted to the root, children stateless | **works — recommended pattern** |
| 8 | `/case8` | stateful child inside a stateful child | **props of a sibling get overwritten** |

### Case 3 — a parent re-render resets the nested child

Click `child +1` twice (child = 2), then `parent +1` once:

```
before parent click : case3-app-1 {"PARENT-COUNT":0}   counter-child-2 {"COUNT":2}
after  parent click : case3-app-1 {"PARENT-COUNT":1}   counter-child-1 {"COUNT":0}
```

The child falls back to its initial value, and its `data-component-id` changes
as well.

Cause: a nested component is expanded by `expand-child-component`, which always
renders the child with a `nil` state (`src/component.lisp:282`):

```lisp
(render-html (apply #'render-component tag nil ...))
```

The browser does collect the child's state and POSTs it (`collectStates` in
`src/client/cl-runtime.js` builds the whole tree), but the server only reads the
node belonging to the action target (`src/server.lisp:409`) and discards the
rest. So state is only preserved for the component that is directly addressed;
every other component in the re-rendered subtree restarts from its props.

### Case 4 — a parent action inside a stateful child never runs

The button carries `data-on-click='["PARENT-BUMP"]'`, but nothing happens and
no error appears in the browser console. The POST body shows why:

```json
{"action":["PARENT-BUMP"],
 "component-id":"stateful-wrapper-2",
 "state":{"component":"case4-app", ...}}
```

`findActionTarget` (`src/client/cl-runtime.js:201`) walks up to the *nearest
ancestor with a non-empty `data-state`*, which is the wrapper, not the root that
defines `parent-bump`. The server then looks for `parent-bump` in
`stateful-wrapper` and only logs to stdout (`src/component.lisp:228`):

```
Warning: Action PARENT-BUMP not found in component stateful-wrapper (Available: ("wrapper-hit"))
```

The client receives a 200 with unchanged HTML, so the failure is invisible in
the browser. This is the trap when combining a hand-written root with a stateful
UI component such as `accordion`, `data-table` or an uncontrolled `checkbox`:
any callback rendered *inside* that component stops reaching the root.

### Case 5 — instances stay separate until the parent re-renders

```
initial          : counter-child-2 {"COUNT":0}  counter-child-3 {"COUNT":100}
B+1 B+1 A+1      : counter-child-2 {"COUNT":1}  counter-child-3 {"COUNT":102}
after parent +1  : counter-child-1 {"COUNT":0}  counter-child-2 {"COUNT":100}
```

Each instance keeps its own state while only the children act, which confirms
that per-instance state works as long as nothing above them re-renders. The
parent re-render resets both (case 3) and shifts every id down by one, because
the action pass restarts `*component-render-counter*` at 0 while the target's id
is supplied by `*forced-component-id*` and no longer consumes a number
(`src/component.lisp:160`, `src/component.lisp:236`).

### Case 8 — id reuse corrupts a sibling's props

Steps: `parent +1`, then `wrapper +1`, then `child +1` on **outer A**.

```
initial        : counter-child-2 "outer A"   counter-child-4 "inner B"
after parent +1: counter-child-1 "outer A"   counter-child-3 "inner B"
after wrapper+1: counter-child-1 "outer A"   counter-child-1 "inner B"   <- duplicate id
after A   +1   : counter-child-1 "inner B"   counter-child-1 "inner B"   <- A now shows B's props
```

Only the wrapper's subtree is re-rendered for `wrapper-hit`, so its inner child
is numbered from 1 again and collides with outer A's id. The server merges the
freshly registered init-args into the render token's registry
(`src/server.lisp:435`), so `counter-child-1` now maps to *inner B's* props.
The next action on outer A replays those props and A renders as "inner B" —
props, not just state, cross between instances.

## Summary of the root causes

1. **Nested state is never restored.** `expand-child-component` hardcodes a
   `nil` state, and `handle-action` only uses the target node of the state tree
   the client sent. Any component other than the action target re-initialises.
2. **Actions are routed by DOM proximity, not by who defines them.**
   `findActionTarget` picks the nearest stateful ancestor; an action name that
   does not exist there is dropped with a stdout warning and a 200 response.
3. **`component-id`s are positional, not identity-based.** They are
   `<name>-<render counter>`, and the counter is per render pass, so ids shift
   between a full render and a partial re-render and can even be duplicated
   across two live instances — which also corrupts the server-side init-args
   registry that is keyed by them.

## Working within today's behaviour

Case 7 is the pattern that holds up: keep every piece of state in the root
component, make children purely presentational, and pass values plus callback
S-expressions down as props — the approach `sample/02-todo` uses. In particular:

* Do not rely on a nested component's own state surviving an ancestor's action.
* Do not render a parent callback inside a stateful child. If a UI component
  offers a controlled mode (for example `checkbox` with `checked` + `onclick`),
  use it so the component stays stateless and the action reaches the root.

## Directions for a fix

* Restore nested state during expansion: thread the client's collected state
  tree through `expand-child-component` instead of passing `nil`.
* Give components stable identity — an explicit `key`/`id` prop folded into the
  generated `component-id`, or a path-based id (`root.0.1`) instead of a global
  counter — so ids survive partial re-renders.
* Resolve an action by searching the ancestor chain for the component that
  actually defines it, or encode the defining component's id into the action
  payload at render time; and return an error to the client when no handler is
  found instead of a silent 200.
