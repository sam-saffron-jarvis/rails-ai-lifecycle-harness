# Generic Rails lifecycle reference (Rails 8.2.0.alpha)

Scope: application-level ownership, destruction, storage cleanup, and transaction/job timing. This is generic reference material: derive the repository's actual graph before changing code.

## Record and collection deletion

- `record.destroy` / `destroy!` run destroy callbacks and honor dependent associations. `record.delete` issues a direct SQL delete and runs neither callbacks nor dependent handling.
- `relation.destroy_all` instantiates records and calls `destroy` on each. `relation.delete_all` emits direct SQL without instantiation, callbacks, or association dependency handling.
- Association collection operations have their own semantics. Owner destruction follows the association's `dependent:` mode. `dependent: :destroy` calls child `destroy`; `:delete`/`:delete_all` delete directly; `:nullify` updates foreign keys directly; `:destroy_async` enqueues destruction after owner commit. Scoped dependencies cover only the scope. `:through` dependencies affect join rows, not target rows.
- Therefore trace every path that can remove an owner: ordinary UI destroy, console/direct destroy, relation/batch destroy, direct delete/delete_all, database cascades, and historical/revision cleanup. A callback-based resource cleanup is unreachable when an upstream edge uses direct deletion.

## Ownership and historical/polymorphic edges

- Treat ownership as a graph, not a model-file list. Include direct child associations, join/delegated records, concern-defined associations, and records retained as revisions/history. The current record and an old revision may own distinct resource-bearing records.
- Polymorphic associations store both id and class/type. Renames require data migration. A polymorphic child does not establish lifecycle ownership by itself; the owner-side association and its deletion mode decide reachability.
- `delegated_type` is a polymorphic `belongs_to` plus helpers; its `dependent:` mode applies when the delegator is destroyed. Still inspect the edge that destroys the delegator.

## Active Storage

- An attachment joins an application record to a blob; the blob identifies the stored service object/file. Deleting only the attachment does not itself mean the blob row and stored file are gone.
- `purge` removes the attachment and synchronously purges the blob/file. `purge_later` removes the attachment and enqueues blob purge.
- Rails 8.2's `has_one_attached` / `has_many_attached` default is `dependent: :purge_later`. The generated attachment association itself uses `dependent: :destroy`; after the attachment's destroy commits, `ActiveStorage::Attachment#purge_dependent_blob_later` schedules blob purge only when the owning attachment reflection's dependency is `:purge_later`.
- Consequently distinguish: attachment-row destruction; blob-row destruction; service-file deletion; and eventual completion of queued purge. Shared blobs may not be purgeable while other attachments still reference them.
- Upload/fetch behavior is a separate invariant from cleanup. Keep attachment creation, blob persistence, URL generation, and service download working.

## Transactions, callbacks, and jobs

- `after_commit` runs only after successful commit; `after_rollback` runs on rollback. Nested transaction callbacks transfer to the parent and run only at the outermost outcome. Outside an open transaction, transaction `after_commit` work runs immediately.
- Work that depends on committed rows/files belongs after commit. Work that must report rollback belongs on rollback (or outside the failed transaction), not in commit-only handling.
- In this frozen Rails 8.2.0.alpha source, Active Job can defer jobs with `enqueue_after_transaction_commit`; deferred jobs enqueue after all enclosing transactions commit and are dropped on rollback. Adapter/config policy matters, so inspect application/job configuration rather than assuming every `perform_later` call is deferred.
- `after_commit` cannot roll back an already committed transaction. Design idempotent jobs and account for enqueue/service failures separately.

## Generic lifecycle test matrix

For the resource-bearing operation, cover only applicable cells:

1. creation/upload then fetch/read remains successful;
2. normal owner `destroy` removes direct resources after queued work drains;
3. historical/revision owners are cleaned, not only the current owner;
4. sibling/shared/unrelated resources remain;
5. empty/no-resource owner is harmless;
6. relation/batch destroy follows callbacks; direct `delete`/`delete_all` is either intentionally unsupported, guarded, or tested as bypassing callbacks;
7. successful outer transaction enqueues only after commit;
8. rolled-back inner/outer transaction does not enqueue commit-dependent work;
9. rollback notification/compensation still occurs where required;
10. focused existing tests first, then the full visible suite once.

## Provenance

Verified against the exact Rails source bundled by the frozen app: Rails `8.2.0.alpha`, git `3a4961048ad251b50991ae83135d760a8a9e8ae3`.

- Active Record persistence: `activerecord/lib/active_record/persistence.rb` (`delete`, `destroy`) and `activerecord/lib/active_record/relation.rb` (`destroy_all`, `delete_all`). Online API: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html and https://api.rubyonrails.org/classes/ActiveRecord/Relation.html
- Associations/polymorphism/delegated types: `guides/source/association_basics.md`. Online guide: https://guides.rubyonrails.org/association_basics.html
- Active Storage: `activestorage/lib/active_storage/attached/model.rb`, `activestorage/app/models/active_storage/attachment.rb`, and `guides/source/active_storage_overview.md`. Online guide: https://guides.rubyonrails.org/active_storage_overview.html
- Transactions: `activerecord/lib/active_record/transaction.rb` and `guides/source/active_record_callbacks.md`. Online guide: https://guides.rubyonrails.org/active_record_callbacks.html#transaction-callbacks
- Active Job commit deferral: `activejob/lib/active_job/enqueue_after_transaction_commit.rb`, `activejob/lib/active_job/enqueuing.rb`, `guides/source/7_2_release_notes.md`, and `guides/source/8_2_release_notes.md`. Online API: https://api.rubyonrails.org/classes/ActiveJob/Enqueuing.html
