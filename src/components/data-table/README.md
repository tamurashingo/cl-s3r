# data-table

Paginated data table component for the cl-s3r framework.  
Renders a `<table>` with optional column headers and pager controls.  
All pagination state (`current-page`) is managed client-side via `data-state`.

## Installation

Add `cl-s3r.components.data-table` to your system's `:depends-on`:

```lisp
(defsystem "my-app"
  :depends-on ("cl-s3r" "cl-s3r.components.data-table")
  ...)
```

Load at runtime:

```lisp
(ql:quickload "cl-s3r.components.data-table")
```

Import the component into your package:

```lisp
(defpackage #:my-app
  (:use #:cl)
  (:import-from #:cl-s3r.components.data-table #:data-table))
```

## Usage

### Minimal — rows only (no column headers)

```lisp
(data-table (@ (rows ,rows)))
```

All field values in each row plist are rendered left-to-right without a header row.

### With column headers

```lisp
(data-table (@ (rows    ,rows)
               (columns '(:name "Name" :status "Status" :age "Age"))))
```

`columns` is a plist of keyword → label pairs.  
The keywords must match the keys used in each row plist.

### With pagination

```lisp
(data-table (@ (rows      ,rows)
               (columns   '(:name "Name" :status "Status"))
               (page-size 10)
               (pager     t)))
```

The pager (Prev / page-info / Next) is shown automatically when more than one page exists.

### With fetch-fn (server-side paging)

```lisp
(data-table (@ (fetch-fn  ,#'my-fetch-fn)
               (columns   '(:name "Name" :status "Status"))
               (page-size 20)
               (pager     t)))
```

`fetch-fn` is called on every render with the current `:page` and `:page-size`.  
When `fetch-fn` is provided it takes priority over `rows`.

### Custom pager labels

```lisp
(data-table (@ (rows        ,rows)
               (next-label  "More →")
               (prev-label  "← Back")
               (empty-label "Nothing to show")))
```

## Parameters

| Parameter     | Type     | Default      | Description |
|---------------|----------|--------------|-------------|
| `rows`        | list     | `nil`        | Row data as a list of plists. Used when `fetch-fn` is not provided. |
| `columns`     | plist    | `nil`        | Column definitions `(:key "Label" ...)`. Omit to hide the header row. |
| `page-size`   | integer  | `10`         | Number of rows per page. |
| `page`        | integer  | `1`          | Initial page number (1-based). |
| `pager`       | boolean  | `t`          | Show pager controls. Hidden when there is only one page. |
| `fetch-fn`    | function | `nil`        | Data-fetch function. Called at render time with `:page` and `:page-size`. Takes priority over `rows`. |
| `next-label`  | string   | `"Next"`     | Label for the Next button. |
| `prev-label`  | string   | `"Previous"` | Label for the Previous button. |
| `empty-label` | string   | `"No data"`  | Message shown when there are no rows to display. |
| `id`          | string   | `nil`        | HTML `id` attribute on the root element. Required when embedding multiple instances on the same page so each gets a unique `data-component-id`. |

## Data formats

### `rows`

A list of keyword-keyed plists:

```lisp
'((:name "Alice" :status "active"   :age 30)
  (:name "Bob"   :status "inactive" :age 25))
```

### `columns`

A plist alternating between a keyword key and its display label:

```lisp
'(:name "Name" :status "Status" :age "Age")
```

Keys must correspond to the keys used in `rows`.

### `fetch-fn` return value

```lisp
'(:rows     ((:name "Alice" :status "active") ...)
  :total    300
  :page     1
  :has-prev nil
  :has-next t)
```

| Key        | Type    | Description |
|------------|---------|-------------|
| `:rows`    | list    | Row plists for the current page. |
| `:total`   | integer | Total record count (used to compute total pages). |
| `:page`    | integer | Current page number. |
| `:has-prev`| boolean | Whether a previous page exists. |
| `:has-next`| boolean | Whether a next page exists. |

Returning `nil` from `fetch-fn` is treated as empty data.

## Multiple instances on the same page

Each `data-table` instance must have a unique `id` so the framework can
distinguish their states:

```lisp
(data-table (@ (id "users-table")   (rows ,users)   (page-size 10)))
(data-table (@ (id "orders-table")  (rows ,orders)  (page-size 5)))
```

Without an explicit `id`, the framework auto-assigns one, but the selector
used in `data-component-id` attributes will not be predictable.

## Pagination behaviour

**rows mode**

- `total-pages = (ceiling (length rows) page-size)`
- The displayed slice is `rows[(page-1)*page-size .. min(page*page-size, length(rows))]`
- `has-prev` is true when `current-page > 1`
- `has-next` is true when `current-page < total-pages`

**fetch-fn mode**

- `:has-prev`, `:has-next`, and `:total` come from the function's return value
- `total-pages = (ceiling total page-size)`

**Pager visibility**

The pager row is rendered only when `pager` is `t` **and** at least one of
`has-prev` or `has-next` is true (i.e. it is hidden on single-page data).

## HTML structure

```html
<div class="data-table" data-component="data-table" data-component-id="..." data-state="...">
  <style>/* embedded CSS */</style>
  <table class="data-table__table">
    <thead><!-- only when columns is provided -->
      <tr>
        <th class="data-table__th">Name</th>
        <th class="data-table__th">Status</th>
      </tr>
    </thead>
    <tbody>
      <!-- normal rows -->
      <tr class="data-table__tr">
        <td class="data-table__td">Alice</td>
        <td class="data-table__td">active</td>
      </tr>
      <!-- empty state (no rows) -->
      <tr>
        <td class="data-table__empty" colspan="2">No data</td>
      </tr>
    </tbody>
  </table>
  <!-- pager: shown only when has-prev or has-next -->
  <div class="data-table__pager">
    <button class="data-table__pager-btn" disabled>Previous</button>
    <span  class="data-table__pager-info">1 / 6</span>
    <button class="data-table__pager-btn" data-on-click='["next-page"]'>Next</button>
  </div>
</div>
```

## CSS classes

| Class                    | Element | Notes |
|--------------------------|---------|-------|
| `data-table`             | root `<div>` | |
| `data-table__table`      | `<table>` | `width: 100%; border-collapse: collapse` |
| `data-table__th`         | `<th>` | Column header cell |
| `data-table__td`         | `<td>` | Data cell |
| `data-table__tr`         | `<tr>` | Data row; even rows get a subtle background |
| `data-table__pager`      | `<div>` | Flex row containing pager controls |
| `data-table__pager-btn`  | `<button>` | Prev / Next button; `:disabled` when no more pages |
| `data-table__pager-info` | `<span>` | "current / total" page display |
| `data-table__empty`      | `<td>` | Shown in place of rows when the data set is empty |

