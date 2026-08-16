# Rails lifecycle audit semantics

- `destroy` / `destroy_all` instantiate records and run callbacks plus dependent handling.
- `delete` / `delete_all` issue direct deletion and bypass record callbacks and downstream dependent handling.
- Trace ownership as a graph: direct children, concerns, joins, delegated/polymorphic records, and historical revisions may own distinct resources.
- `dependent: :destroy` destroys children with callbacks; `:delete_all` deletes directly; `:nullify` updates foreign keys directly.
- Active Storage attachment rows, blob rows, and stored files are separate lifecycle objects.
- `purge` removes attachment/blob/file synchronously; `purge_later` removes the attachment and enqueues blob/file purge after commit.
- An upstream `delete_all` makes downstream callback cleanup unreachable.
- `after_commit` runs only after successful outer commit; `after_rollback` only on rollback.
- Transaction-aware jobs should enqueue after commit and disappear on rollback; rollback reporting needs a separate path.
- Validate applicable invariants: current and historical owners, direct and batch destruction, unrelated resources preserved, empty owner harmless, upload/fetch unchanged, commit and rollback behavior.

Before editing, account for direct, indirect, and historical ownership edges, callback reachability, transaction boundaries, the actual persisted/rendered requirement path, and one focused test command.
