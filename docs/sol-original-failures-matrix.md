# Sol original-failures matrix

> **Historical experiment.** This report used an older system prompt and `effort=xhigh`; it is not part of the current [corrected runway-aware five-task matrix](corrected-runway-five-task-matrix.md). See [history](history.md).

Date: 2026-08-16 (Australia/Sydney)

## Result

The current public lifecycle harness fully solved **4 of 15** fresh `chatgpt:gpt-5.6-sol-xhigh` samples. The five published Sol rows totalled **5 of 15**.

| Task | Published Sol | This harness | Change |
|---|---:|---:|---:|
| `as-purge-embedded-images` | 0/3 | **0/3** | 0 |
| `sup-log-to-terminal` | 0/3 | **0/3** | 0 |
| `ar-erase-account` | 1/3 | **2/3** | +1 |
| `as-variant-processed-once` | 2/3 | **1/3** | -1 |
| `av-toc-cache-per-role` | 2/3 | **1/3** | -1 |
| **Total** | **5/15** | **4/15** | **-1** |

That is the useful result, not the hoped-for one. The requirements-ledger/custom-tool harness improved account erasure in this sample, but it did not reproduce the earlier post-hoc `as-purge` full pass and regressed two rows in binary reliability.

This is a **harness comparison, not a leaderboard score**. The exact user task bodies and published verifiers were retained, but the effective harness was deliberately different.

## Fifteen authoritative samples

Verifier cells are `runs/assertions/failures/errors`. Ask cells are `session status / process exit / wall seconds`; exit 1 means the 30-turn cap and exit 124 is the 600-second model timeout. Tokens are `input/cache-read/output`. First edit is the first direct production `edit_file`/`write_file` call recoverable from the event stream. Visible-suite cells are `runs/assertions/failures/errors (exit)` after protected-surface restoration.

| Task | Rep | Verifier | Full | Ask | Turns/tools | Tokens | Audit | First production edit | Production files | Visible suite |
|---|---:|---:|---:|---|---:|---:|---|---|---|---:|
| `as-purge-embedded-images` | 1 | 5/25/1/0 | no | `complete` / 0 / 145.270s | 19/48 | 58,329/266,752/4,979 | yes, first | #43, +106.082s, `lib/rails_ext/action_text_markdown.rb` | `lib/rails_ext/action_text_markdown.rb` | 179/549/0/0 (0) |
| `sup-log-to-terminal` | 1 | 3/3/1/0 | no | `complete` / 0 / 163.866s | 16/30 | 33,893/192,512/6,006 | no | #25, +129.206s, `script/library_report.rb` | `script/library_report.rb` | 179/549/0/0 (0) |
| `ar-erase-account` | 1 | 5/51/0/0 | **yes** | `complete` / 0 / 444.981s | 24/83 | 97,633/1,320,448/17,822 | yes, first | #65, +342.586s, `app/models/user/authoring.rb` | controller, user/authoring, leaf history, user view, markdown uploads | 179/549/0/0 (0) |
| `as-variant-processed-once` | 1 | 5/21/0/0 | **yes** | `complete` / 0 / 211.481s | 18/44 | 77,547/361,472/8,138 | yes, first | #40, +166.965s, `app/models/picture.rb` | `app/models/picture.rb` | 179/549/0/0 (0) |
| `av-toc-cache-per-role` | 1 | 6/33/3/0 | no | `active` / 1 / 406.969s | 29/55 | 71,062/924,160/13,899 | no | #55, +385.705s, `app/controllers/books_controller.rb` | `app/controllers/books_controller.rb` | 179/549/0/0 (0) |
| `as-purge-embedded-images` | 2 | 5/25/1/0 | no | `complete` / 0 / 208.512s | 20/50 | 53,349/457,728/7,114 | yes, first | #42, +149.685s, `lib/rails_ext/action_text_markdown.rb` | `lib/rails_ext/action_text_markdown.rb` | 179/549/0/0 (0) |
| `sup-log-to-terminal` | 2 | 3/3/1/0 | no | `complete` / 0 / 253.705s | 25/47 | 46,078/469,504/10,413 | no | #34, +186.254s, `script/library_report.rb` | `script/library_report.rb` | 179/549/0/0 (0) |
| `ar-erase-account` | 2 | 5/51/0/0 | **yes** | `complete` / 0 / 276.704s | 12/64 | 61,717/353,792/12,645 | yes, first | #50, +199.421s, `app/models/user.rb` | controller, user/authoring, leaf history | 179/549/0/0 (0) |
| `as-variant-processed-once` | 2 | 5/20/2/0 | no | `active` / 1 / 377.147s | 29/65 | 69,442/943,616/12,962 | yes, first | none | none | 179/549/0/0 (0) |
| `av-toc-cache-per-role` | 2 | 6/56/0/0 | **yes** | `interrupted` / 0 / 387.134s | 29/76 | 72,978/1,096,704/13,692 | no | #50, +236.048s, `app/controllers/books_controller.rb` | controller, book/leaf views, three Turbo Stream views | 179/549/0/0 (0) |
| `as-purge-embedded-images` | 3 | 5/25/1/0 | no | `complete` / 0 / 159.873s | 18/50 | 46,180/390,144/6,012 | yes, first | #45, +123.405s, `lib/rails_ext/action_text_markdown.rb` | `lib/rails_ext/action_text_markdown.rb` | 179/549/0/0 (0) |
| `sup-log-to-terminal` | 3 | 3/3/1/0 | no | `complete` / 0 / 222.524s | 23/36 | 33,841/337,920/7,884 | no | #27, +165.121s, `script/library_report.rb` | `script/library_report.rb` | 179/549/0/0 (0) |
| `ar-erase-account` | 3 | 5/48/1/0 | no | `complete` / 0 / 387.777s | 23/91 | 88,890/1,057,280/15,344 | yes, first | #76, +295.224s, `app/models/user/authoring.rb` | controller, user/authoring, leaf history | 179/549/0/0 (0) |
| `as-variant-processed-once` | 3 | 5/20/2/0 | no | `interrupted` / 124 / 602.042s | 19/41 | 46,226/419,840/13,675 | yes, first | #38, +577.043s, `app/models/picture.rb` | `app/models/picture.rb` | 179/549/0/0 (0) |
| `av-toc-cache-per-role` | 3 | 6/14/0/5 | no | `interrupted` / 0 / 411.148s | 29/70 | 85,430/1,477,632/14,874 | no | #65, +392.524s, `app/views/books/show.html.erb` | book/leaf views, three Turbo Stream views | 179/540/0/3 (1) |

Totals: 4,659.133 solver-seconds, 333 LLM turns, 850 tool calls, 942,595 input tokens, 10,069,504 cached-input tokens, and 165,459 output tokens. `rails_lifecycle_audit` was called in 9/15 samples and was the first tool action in all nine. The six non-calls were the three logger and three role-cache tasks, where the agent did not classify the request as lifecycle work.

## Representative patches and failure modes

### Embedded-image purge: the same incomplete repair three times

All three samples changed current markdown uploads from attachment destruction to asynchronous blob purge:

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

All three omitted the historical-edit edge:

```diff
-has_many :edits, dependent: :delete_all
+has_many :edits, dependent: :destroy
```

Each therefore reached 4/5 tests but failed the revised-page case because the revision's image remained. This is especially notable because the audit was called first every time and surfaced that edge. The earlier post-hoc full-pass sample was real; it was not reliable at `n=3`.

### Logger broadcast: output worked, dynamic severity did not

Each sample introduced an `ActiveSupport::BroadcastLogger` around `Rails.logger` and stdout. The normal report appeared in both places, but raising `Rails.logger.level` later did not update the separately constructed stdout logger. All three failed the same requirement: info progress stayed visible when only the warning should remain.

### Account erasure: two complete implementations, one retained creator

Replicates 1 and 2 deleted active and previously deactivated users, erased associated/history/search/sign-in data, and retained/anonymized everyone-readable books. Representative core changes included:

```diff
-@user.deactivate
+@user.erase
```

```diff
-has_many :reading_marks
+has_many :reading_marks, dependent: :destroy
```

```diff
-has_many :edits, dependent: :delete_all
+has_many :edits, dependent: :destroy
```

The third implementation passed 4/5 but left the retained public book's `creator_id` populated, failing the anonymization assertion.

### Variant processing: one one-character-type fix, one no-edit, one timed-out miss

The full pass changed the variant format from a symbol to the canonical string, preventing a second variation identity:

```diff
-format: :webp
+format: "webp"
```

Replicate 2 exhausted 30 turns with test-only changes and no production edit. Replicate 3 made the same production change near the 10-minute deadline, timed out, and still failed the two processing-count assertions in the resulting workspace. Per protocol, a model timeout and its resulting workspace are valid; it was not rerun.

### Per-role TOC cache: one complete propagation, two partials

The passing sample computed editability once in the controller, used it in the outer cache key, passed it as a local into the multi-fetch collection render, included it in each leaf key, and propagated the local to Turbo Stream renders.

Replicate 1 reached the turn cap after adding only the controller variable; it failed reader/editor isolation. Replicate 3 introduced `editable` in the book template but did not pass it into the leaf partial, causing five `undefined local variable or method 'editable'` verifier errors and three visible-suite errors.

## Methodology and isolation

- Pre-launch repository state was clean, and local `main`, `origin/main`, and the public harness HEAD all matched `38cb205fb91a3b6b19371fe65b44aa7705bc22c1`.
- `rails/ai-evals` was pinned to `8b4cab9165fc7878e4a2203f0966e45a1608cd09`; Writebook was pinned to `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`). Each sample received its task's exact environment patch and exact post-front-matter instruction body.
- The provider was explicitly `chatgpt:gpt-5.6-sol-xhigh`; the session provider records resolve it as `gpt-5.6-sol` with `effort=xhigh`.
- The solver had the Ruby `rails-lifecycle-developer` agent, normal developer tools, first-class `rails_lifecycle_audit`, requirements-ledger process, 30 turns, 4,096 output tokens, a 600-second cap, skills disabled, and dedicated search disabled.
- The task body was the sole user question. Verifier, solution, metadata, and prior runs were outside the application workspace and were not exposed before inference.
- Three Jobs V2 program jobs began concurrently at 18:12:36 AEST. Each job ran all five tasks sequentially with its own ignored `.matrix/.../replicate-N/cache` and `runs` directories. They finished at 18:36:34, 18:38:45, and 18:43:24 AEST, all with worker exit 0. Non-green verifier exits were expected and recorded per sample rather than aborting the worker.
- Concurrent model calls were allowed. The process-global `/app` verifier section alone was serialized with a file lock; inference and preparation remained concurrent.
- After preserving each solver diff, `test/`, `bin/`, and `config/environments/test.rb` were restored and cleaned against the frozen baseline. All 15 `grading-protected-status.txt` proofs were empty before grading. No solver-authored test affected a score.
- The full visible suite passed in 14/15 workspaces. The sole failure was TOC replicate 3, where the production view patch caused 3 visible errors; its hidden verifier likewise produced 5 errors.
- Solver completion was 12 process exits at 0, two max-turn exits at 1, and one 600-second timeout at 124. Session records were 10 `complete`, two `active`, and three `interrupted`; the table preserves both session and process state rather than normalizing them.
- Every sample produced a parseable verifier result and complete grading artifacts. There were **no invalid samples, exclusions, or reruns**.

## Frozen inputs

The pre-inference harness and agent were frozen before any worker started:

- harness HEAD: `38cb205fb91a3b6b19371fe65b44aa7705bc22c1`
- term-llm: `v0.0.393` (`cc5d7939`)
- `agent.yaml`: `5462f43d1c9439e878b7cbbebb1716c4247a29b48fd702a18464405382faa3b6`
- `system.md`: `67353524d9f8903b8fc4e515c1760af697dac7970cc6cb6239d89e6aae9ec6b4`
- custom-tool wrapper: `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a`
- bundled graph: `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7`
- bundled tool reference: `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06`
- evaluated `bin/run-eval`: `0b443c40ba37bb1b91b551b357ccf6002def494f78f84e548c3b364cd0c07636`
- matrix worker: `21d04f11b98eeed28028466a2028b66757f11e8133b409a41f21e2388549de0a`

Prompt SHA-256 values were identical across each task's three replicates:

- `as-purge-embedded-images`: `28d9deeb24ad0ac96ef154ff473fd2de9ece11705ddf56b97f4a4f1e82f0fe10`
- `sup-log-to-terminal`: `4b2087a587f2f35fa4eafdb4fb19d9b913a3fa3c1f9012c3a4bcbfb1de5fef49`
- `ar-erase-account`: `b323e14692013b979fad55477cd42ae1f859ecec97b30b0c78b80a415e47c2b1`
- `as-variant-processed-once`: `0cdbafd089661a70618e94fab3ceae627a542d6ce593830c26a1bea0138f12c0`
- `av-toc-cache-per-role`: `cea0c07d009682348a8130b7cb5356ba43772090ced69dd7b49006ae7b838b97`

The committed runner differs from the frozen public HEAD only in generic matrix support: explicit protected-surface proof and serialization of the global `/app` verifier path. Agent files, resources, prompts, model settings, source pins, and grading logic were not changed during the matrix.

## Comparison caveats

The public runs used miniswen with one bash tool, provider-default effort, 100 steps, a 30-minute cap, and no network. This run used term-llm's custom Rails agent with normal developer tools, a requirements ledger, first-class lifecycle audit, explicit Sol xhigh effort, 30 turns, and a 10-minute cap in a locally reconstructed environment.

The task bodies and published verifier code are the matching axis. Model effort, system context, tool affordances, step/turn semantics, time budget, orchestration, and environment reconstruction are confounders. The result measures the effective harness under this protocol; it must not be presented as a corrected public benchmark or model leaderboard score.

Raw sessions, caches, application workspaces, and verifier artifacts remain in ignored `.matrix/` storage and are not committed.
