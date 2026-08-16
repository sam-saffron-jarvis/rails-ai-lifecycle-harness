# Post-hoc Rails lifecycle-resource prototype

> **Historical prototype.** These post-hoc and resource-assisted experiments are provenance, not part of the current [corrected runway-aware five-task matrix](corrected-runway-five-task-matrix.md). See [history](history.md).

Date: 2026-08-16 (Australia/Sydney)

## Answer

**Yes, in this bounded post-hoc sample the augmented harness solved `as-purge-embedded-images` completely.** The one fresh `chatgpt:gpt-5.6-sol-xhigh` run made both required lifecycle changes and passed the published verifier at **5/5**. Both controls also passed completely: `ar-archive-book-access` at **6/6** and `aj-enqueue-after-commit` at **8/8**.

This is **harness augmentation with an effective-context difference**, not a model-only benchmark result. It is post-hoc and `n=1/task`. It shows that a generic, repository-derived lifecycle graph plus concise Rails semantics and an evidence-first process *can* bridge the exact gap seen in the prior strict Sol samples. It does not establish reliability.

The controls did not regress, so this sample does **not** trigger the requested overfitting/poor-generality warning. They also did not improve in binary score over the earlier broad Sol xhigh controls, which had already solved both. Their role here is evidence that the same frozen resources/process remained useful rather than breaking unrelated lifecycle tasks.

## Scored outcomes

All three runs used a fresh prepared Writebook v1.2.1 workspace, exact task environment, exact Markdown task body as the sole question, skills disabled, one unrestricted auto-approved shell, 30 turns, 4,096 output tokens, and a 600-second cap. The frozen resource file was attached with `-f .term-llm/rails-lifecycle-audit.md`.

| Task | Completion / wall | Session | LLM turns / tools | Input / cached / output | First edit attempt / successful edit | Solver-visible tests | Published verifier | Full solve |
|---|---|---|---:|---:|---|---|---|---:|
| `as-purge-embedded-images` | natural / 116.603s | `20260816-163421-c35c6eeece592e47` | 7 / 6 | 17,940 / 65,536 / 3,257 | call 3 at 67.884s / call 4 at 74.698s | focused **2/9 green**; full **179/549 green**, 4 skips | **5 runs, 28 assertions, 0 failures, 0 errors** | **yes** |
| `ar-archive-book-access` | natural / 93.653s | `20260816-163622-3344d2174520da70` | 8 / 7 | 19,649 / 90,624 / 2,896 | call 3 at 49.668s / call 4 at 55.108s | focused **6/15 green**; full **179/549 green**, 4 skips | **6 runs, 20 assertions, 0 failures, 0 errors** | **yes** |
| `aj-enqueue-after-commit` | natural / 186.028s | `20260816-163800-6bdfb1b8523a0f96` | 9 / 8 | 58,310 / 126,464 / 6,790 | call 3 at 87.515s / call 4 at 95.430s | no narrow matching test; broad book selection hit an environmental Chrome startup error; full **179/549 green**, 4 skips | **8 runs, 30 assertions, 0 failures, 0 errors** | **yes** |

Totals: **396.284 solver-seconds**, 24 LLM turns, 21 shell calls, 95,899 input tokens, 282,624 cached-input tokens, and 12,943 output tokens.

The call-3 edits used `apply_patch`, which is not installed in these workspaces and returned 127. Each solver immediately performed the same production edit with `sed`/Ruby on call 4. That is an environment/tool-affordance blemish, not a model retry or score-driven rerun.

The Active Job run's selected book tests accidentally included `test/system/publish_book_test.rb`; Chrome failed to create a Selenium session. The solver then ran the canonical visible suite, which excludes system tests and passed. The published transaction verifier subsequently passed 8/8. No test was rerun to manufacture a score.

## Exact production patches

### `as-purge-embedded-images`

```diff
diff --git a/app/models/leaf/editable.rb b/app/models/leaf/editable.rb
@@
-    has_many :edits, dependent: :delete_all
+    has_many :edits, dependent: :destroy

diff --git a/lib/rails_ext/action_text_markdown.rb b/lib/rails_ext/action_text_markdown.rb
@@
-    has_many_attached :uploads, dependent: :destroy
+    has_many_attached :uploads, dependent: :purge_later
```

This is the complete two-edge repair the prior matched strict Sol runs missed: current markdown attachment destruction now schedules blob/file purge, and historical edits are destroyed with callbacks rather than deleted directly. The verifier confirmed current and revised-page cleanup, sibling/cover preservation, trash preservation, and upload/fetch behavior.

### `ar-archive-book-access`

```diff
diff --git a/app/models/book.rb b/app/models/book.rb
@@
-  before_destroy :archive_access_list
+  before_destroy :archive_access_list, prepend: true
```

The prepended callback snapshots access rows before the dependent association's destroy callback removes them. App deletion, console deletion, revocation, empty access, levels, and final removal all passed.

### `aj-enqueue-after-commit`

```diff
diff --git a/app/jobs/application_job.rb b/app/jobs/application_job.rb
@@
 class ApplicationJob < ActiveJob::Base
+  self.enqueue_after_transaction_commit = true

diff --git a/app/jobs/books/import_failure_job.rb b/app/jobs/books/import_failure_job.rb
@@
 class Books::ImportFailureJob < ApplicationJob
+  self.enqueue_after_transaction_commit = false
```

Commit-dependent follow-up jobs defer to the outermost commit and disappear on rollback. The failure notification explicitly remains immediate, so enqueueing from the import rescue survives the rollback path. All eight transaction/job verifier cases passed.

## Frozen resource design

### 1. Rails lifecycle reference

`rails-lifecycle-resource/rails-lifecycle-reference.md` is task-name-free and solution-free. It covers:

- `destroy`/`destroy_all` versus `delete`/`delete_all` callback behavior;
- association dependency modes, scoped and through behavior;
- direct, batch, delegated, polymorphic, and historical ownership;
- Active Storage attachment/blob/service-file separation;
- `purge` and `purge_later`;
- transaction, nested transaction, `after_commit`, `after_rollback`, and Active Job deferral;
- a generic ten-cell lifecycle test matrix.

It was verified against the exact Rails bundled by the frozen app: Rails `8.2.0.alpha`, git `3a4961048ad251b50991ae83135d760a8a9e8ae3`. Provenance in the reference points to local Rails source and the corresponding Rails API/guides:

- `activerecord/lib/active_record/persistence.rb` and `relation.rb`;
- `guides/source/association_basics.md`;
- `activestorage/lib/active_storage/attached/model.rb` and `app/models/active_storage/attachment.rb`;
- `activerecord/lib/active_record/transaction.rb`;
- `activejob/lib/active_job/enqueue_after_transaction_commit.rb` and Rails 7.2/8.2 release notes.

### 2. Deterministic graph tool

The historical experiment used `rails_lifecycle_graph.py`; the published harness now ships an equivalent Ruby implementation at `resources/rails_lifecycle_graph.rb`. It scans only the current repository's:

- `app/models/**/*.rb`;
- `app/jobs/**/*.rb`;
- `app/controllers/**/*.rb`;
- `lib/rails_ext/**/*.rb`;
- `db/schema.rb` and `db/migrate/**/*.rb` where present.

It never boots Rails and never reads tests, task files, verifier, solution, dependency source, parent directories, or prior benchmark artifacts. Stable JSON rows contain:

- source symbol, file, and line;
- association/ownership declaration;
- dependency mode;
- deletion mechanism;
- whether callbacks are expected;
- attachment lifecycle;
- normalized source declaration.

The same unchanged script produced all three packets:

| Task | Source files | Rows | Graph SHA-256 | Supplied audit SHA-256 |
|---|---:|---:|---|---|
| `as-purge-embedded-images` | 64 | 36 | `521f561d7072d890d51816377411a13f2b4b84744a89a6e9ab3d5f7b981458fa` | `5c859672365b39ab03d121c21af6f7968911939a719d99b59c2dca255e66b52f` |
| `ar-archive-book-access` | 66 | 37 | `5a239a7e6e86f2e352bfb339bea804680b9b1ffb68c717db49f3d6980e2c62f6` | `be58aef1b98cfe288760385c8ee06511005fca98f4bfe75a326dc0bab912aa15` |
| `aj-enqueue-after-commit` | 69 | 41 | `1684f0215b5909193b18b2531ec28d1f902f895ad27465f07d0bdf6688d305de` | `1328b5b34f5862e01e02aeb17100bdfcb4647efc944b00d630d44c19ce07876b` |

### 3. Process and schema

`rails-lifecycle-resource/rails-lifecycle-process.md` requires an internal evidence packet with direct, indirect, historical, and transaction edges; callback behavior; one focused existing test; and a minimal fact-to-file patch plan. The graph packet carries `required_solver_evidence_schema`, and preparation rejected packets missing fields/sections.

Because the requested table was internal, there is no separate serialized solver-authored table to validate after the fact. Observable compliance is therefore bounded: all three solvers explicitly read the attached resource on call 1, narrowed repository inspection to the surfaced lifecycle edges, attempted the production edit on call 3, and produced patches matching those inspected facts. Do not claim stronger evidence-packet compliance than that.

## Graph quality and leakage audit

### Relevant edges exposed

For the target, the graph surfaced the complete factual path:

- `Page has_markdown body`;
- generated `has_one markdown_#{name}`, polymorphic `as: :record`, `dependent: :destroy`;
- `ActionText::Markdown belongs_to record, polymorphic: true`;
- `has_many_attached uploads, dependent: :destroy`, with attachment-only deletion semantics;
- `Leaf has_many edits, dependent: :delete_all`, callbacks not expected;
- `Edit delegated_type leafable, dependent: :destroy`;
- `Leaf` and `Edit` delegated current/historical leafables.

For archive, it surfaced `Book`'s `before_destroy`, `has_many :accesses, dependent: :destroy`, and the controller's record destroy. It did **not** prescribe `prepend: true`; the solver inferred callback order from application code.

For Active Job, it surfaced the importer and editing transaction blocks, all three `perform_later` sites, and generic outer commit/rollback semantics. It did **not** prescribe the two job configuration lines; the solver inspected `ApplicationJob` and the failure job to choose them.

### Leakage decision

**Valid; no verifier/solution leakage found.** The graph contains repository facts plus generic Rails semantics, not task IDs, expected patch text, verifier assertions, solution artifacts, or score feedback. Preparation scanned every row for forbidden task/verifier/solution strings, and exact packets were frozen before the first solver started.

The target packet makes the two suspicious modes highly visible (`uploads dependent: :destroy`; historical `edits dependent: :delete_all`) and the generic reference explains what those modes do. That is deliberately strong harness assistance. It makes the solution inferable, but it does not encode “change file X from A to B,” and the unchanged tool also supported two controls whose exact fixes were not present in graph output. Calling this model-only parity would be bullshit; calling it leakage would also be inaccurate.

Minor scanner noise: the generic direct-delete regex misclassified `File.extname(...).delete(".")` as a lifecycle deletion call. It did not affect any patch. A production version should type-filter or suppress known scalar/container receivers.

## Did the solver use the resource and edit earlier?

- **Used it:** yes, explicitly on call 1 in all three sessions. The sessions preserve the attached file and resource-read command.
- **Edited earlier by call count:** partly. Every run attempted an edit on call 3 after two inspection calls, exactly as the strict process required. The successful edit was call 4 only because `apply_patch` was unavailable.
- **Earlier than prior controls:** no clean speed win. Prior strict as-purge Sol samples successfully edited on call 3 at 26.333s, 42.267s, and 40.130s; this augmented sample attempted call 3 at 67.884s and succeeded at 74.698s. Prior broad Sol controls first edited archive and Active Job on call 4 at 57.858s and 42.528s; augmented runs succeeded on call 4 at 55.108s and 95.430s. The resource improved target completeness, not edit latency.

## Comparison and interpretation

| Evidence | `as-purge` | Archive control | Active Job control |
|---|---:|---:|---:|
| Prior matched strict Sol xhigh | 0/3 full: 4/5, 4/5, 2/5 | not run under that three-sample hard harness | not run under that three-sample hard harness |
| Prior broad Sol xhigh, different system/context | not part of matrix | 6/6 full | 8/8 full |
| Lifecycle-resource prototype | **5/5 full** | **6/6 full** | **8/8 full** |

The strongest supported conclusion is narrow but useful:

1. The prior as-purge failure was not simply “Sol cannot reason about Rails lifecycle cleanup.” With a generic semantic reference and deterministic graph facts, it connected current and historical ownership and made both edits.
2. The controls stayed solved using the same resource/process. This argues against an as-purge-only handcrafted packet.
3. The target uplift is confounded by effective context and a two-line system addition; that is the experiment's point. It is not a fair model leaderboard comparison.
4. `n=1/task`, post-hoc task selection, and known target failure history mean the result is hypothesis-generating. Reliability needs fresh tasks or preregistered repeats, neither of which this bounded request authorized.

No overfitting warning is triggered because controls did not regress. No “resources always solve lifecycle tasks” claim is justified.

## Freeze, isolation, and artifacts

Frozen before scoring:

- graph script SHA-256: `eefcccab8bde4c2ff92337cd3abd825cb067c95f7f57e20b9e6921026985efba`;
- Rails reference: `46e883bf68af001662bcb513b00013fbde05f13c5254a0cfbd6f791717ac55f0`;
- process: `3f82ab12d7036c4f15eba21efb2fd1a1e5ead1c8dc7f17f6c0741e0aa5d7267a`;
- agent YAML: `504f3cbe90f65b478476f92b1d2c089d5f5ec521d837d7c65d8423cafa465da9`;
- system prompt: `92ae445f093066152dd76aa631cad60693ad1e46557155c235fe263074bd2190`.

The agent differs from `rails-bench-sol-xhigh-hard-control` only by name and one system paragraph telling it to read the supplied lifecycle resource, build the compact internal evidence table, then implement/test. Provider/model/tools/search/turn budget remained unchanged.

Prompt hashes:

- as-purge: `28d9deeb24ad0ac96ef154ff473fd2de9ece11705ddf56b97f4a4f1e82f0fe10`;
- archive: `dbe977e7e28f371b81a8bc7b7586ea9d86ddaecc42c4d9d31d3591948bc9f551`;
- Active Job: `82597b9d3f482a60b7ffb398a5f0d13e97a80335130619ac167cb5933a5cd6ba`.

`rails-lifecycle-resource-20260816/` preserves exact supplied packets, graph JSON, prompt bytes/hashes, source/environment/verifier hashes, preparation logs, baseline SHAs, raw JSONL, stderr, isolated session DBs, session exports, tool calls, timestamps, diffs/status, test commands/results, verifier outputs, metrics, all-before-scoring hash manifest, job record/events, and cleanup proof.

Two preparation-only harness failures occurred before any solver was invoked: the first tried to execute the frozen read-only Python script directly; the second tried to overwrite a prior 0444 artifact. They are preserved under `rails-lifecycle-resource-invalid-prep-permission/` and `rails-lifecycle-resource-invalid-prep-readonly-copy/`. Both were fixed before packet freeze/scoring. There were no scored retries, no tuning after a result, and no model exposure to either failure.

Jobs V2 run `run_Q8qfmdnDNxhv` executed the three valid samples sequentially from **16:34:17 to 16:41:12 AEST** and exited 0. The temporary job was deleted. `/app`, disposable workspaces, and solver processes are gone.

No term-llm source, canonical agent/default, application source, task corpus, verifier, or solution was modified. No commits were made outside disposable benchmark workspaces; nothing was pushed or published.
