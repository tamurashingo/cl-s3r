# 11-nested — nested component behaviour

A diagnostic sample. Each route isolates one nesting pattern so that the
behaviour of nested components can be observed without one case disturbing
another. It doubles as the reproduction case for the nested-component issues
#31, #32 and #33.

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

## Cases

Verified in Chromium against a locally running server.

| # | Route | Pattern | Result |
|---|---|---|---|
| 1 | `/case1` | stateless child invokes a parent action | works |
| 2 | `/case2` | stateful child invokes its own action | works |
| 3 | `/case3` | stateful child, then the parent re-renders | works — child keeps its state (#31) |
| 4 | `/case4` | parent action rendered inside a stateful child | **action silently dropped — open (#32)** |
| 5 | `/case5` | two instances of the same stateful child | works — each keeps its own state (#31, #33) |
| 6 | `/case6` | the same patterns three levels deep | depth changes nothing |
| 7 | `/case7` | all state lifted to the root, children stateless | works |
| 8 | `/case8` | stateful child inside a stateful child | works — ids stay unique (#33) |
| 9 | `/case9` | stateful children in a list, with and without `key` | `key` follows the item; without it, state follows the position |

### Case 3 — a parent re-render keeps the nested child's state

Click `child +1` twice (child = 2), then `parent +1` once:

```
before parent click : case3-app-0 {"PARENT-COUNT":0}   counter-child-0.0 {"COUNT":2}
after  parent click : case3-app-0 {"PARENT-COUNT":1}   counter-child-0.0 {"COUNT":2}
```

The browser collects the whole state tree and POSTs it; the server now indexes
every node of that tree by `component-id` and hands it to the render pass, so a
nested component picks its own state back up instead of re-initialising from its
props. A component that was not in the tree — a list item that has just been
added, a branch that has just been expanded — still starts from its props.

### Case 4 — a parent action inside a stateful child never runs (open)

The button carries `data-on-click='["PARENT-BUMP"]'`, but nothing happens and no
error appears in the browser console. The POST body shows why:

```json
{"action":["PARENT-BUMP"],
 "component-id":"stateful-wrapper-0.0",
 "state":{"component":"case4-app", ...}}
```

`findActionTarget` (`src/client/cl-runtime.js`) walks up to the *nearest ancestor
with a non-empty `data-state`*, which is the wrapper, not the root that defines
`parent-bump`. The server then looks for `parent-bump` in `stateful-wrapper` and
only logs to stdout:

```
Warning: Action PARENT-BUMP not found in component stateful-wrapper (Available: ("wrapper-hit"))
```

Tracked in #32. Until it is fixed: do not render a parent callback inside a
stateful child. If a UI component offers a controlled mode (for example
`checkbox` with `checked` + `onclick`), use it so the component stays stateless
and the action reaches the root.

### Case 5 and 8 — ids are stable and unique

`component-id` is `<name>-<path>`, where the path is the component's position in
the tree: the root is `0` and each child appends its own segment. Numbering is
relative to the parent and does not depend on the render pass, so a partial
re-render of one subtree produces exactly the ids the full page produced.

```
/case5 initial         : case5-app-0  counter-child-0.0  counter-child-0.1
/case5 after parent +1 : case5-app-0  counter-child-0.0  counter-child-0.1

/case8 initial         : counter-child-0.0 "outer A"   counter-child-0.1.0 "inner B"
/case8 after wrapper+1 : counter-child-0.0 "outer A"   counter-child-0.1.0 "inner B"
```

In `/case8`, re-rendering only the wrapper subtree used to renumber its inner
child from 1 and collide with outer A's id, which corrupted the server-side
init-args registry and made outer A render with inner B's props. With
path-based ids the inner child keeps `counter-child-0.1.0` in every pass.

### Case 9 — `key` for list children

Children in a list are numbered by position, so deleting or re-ordering items
moves state from one item to another. Pass `key` to give a child an identity
that survives the change — the key replaces the positional segment of the id
(`counter-child-0.0.kalpha`).

```lisp
(counter-child (@ (key ,name) (label ,name)))
```

Giving three children counts, then clicking `rotate` (first item to the end):

```
with key    : bravo=0   charlie=0  alpha=3    <- alpha's count moved with alpha
without key : bravo=5   charlie=0  alpha=0    <- position 0 kept the count
```

`key` only matters for children that own state (or that wrap something which
does). A purely presentational list needs no key.

## What to keep in mind

* State lives wherever you declare it, but a component that is *not* in the DOM
  the browser reported — a newly rendered one — starts from its props.
* Use `key` for stateful children inside a list.
* Do not render a parent callback inside a stateful child until #32 is fixed.
* A component whose root element carries an explicit `id` attribute is addressed
  by that id instead of by its path. Its own state is then not restored on a
  parent re-render, because the state lookup happens before the element is
  rendered and can only use the path.

## Testing nested behaviour

`cl-s3r.testing:test-render-html` renders a component tree to HTML and can stand
in for the state the browser would have reported, which is what `test.lisp`
asserts against:

```lisp
(test-render-html "case3-app"
                  :state '(:parent-count 7)
                  :client-state '(("counter-child-0.0" . (:count 2))))
```

Pass `:path` and `:forced-id` to reproduce the render pass the server performs
for a single subtree.
