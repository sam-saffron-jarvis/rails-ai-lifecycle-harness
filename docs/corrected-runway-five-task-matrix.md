# Corrected runway-aware five-task matrix

Date: 2026-08-17 (Australia/Sydney)

## Result

The current corrected runway-aware harness produced **8/15 full solves** with three fresh `chatgpt:gpt-5.6-sol-max` samples on each of the five tasks:

| Task | Full solves | Verifier outcomes by replicate |
|---|---:|---|
| `as-purge-embedded-images` | **0/3** | 4/5, 4/5, 4/5 tests |
| `sup-log-to-terminal` | **0/3** | 2/3, 2/3, 2/3 tests |
| `ar-erase-account` | **3/3** | 5/5, 5/5, 5/5 tests |
| `as-variant-processed-once` | **2/3** | 5/5, 5/5, 0/5 tests |
| `av-toc-cache-per-role` | **3/3** | 6/6, 6/6, 6/6 tests |
| **Total** | **8/15** | **61/72 verifier tests** |

All 15 visible suites passed: 179 runs, 549 assertions, 0 failures, 0 errors, and 4 skips in every workspace. All solver sessions completed naturally, all ask processes exited zero, and no sample reached the 100-turn or 1,800-second limit.

This is a coherent current five-task view, but it was collected as **two separately launched batches**:

- account erasure and per-role TOC caching: 6 samples launched at 07:50 AEST under harness commit `e0761fda28958b395886a12adb335f0695ad309f`;
- purge, logger, and variant processing: 9 intended samples launched at 08:20 AEST under commit `2ec2776ef7be2cc2faf6428e36c3a76239071003`, whose only change from the first batch was the already-published account/TOC report and README documentation.

The effective agent, runner, model, limits, source pins, prompts, and grading protocol were identical. This was not one concurrent 15-sample launch.

## What “corrected runway-aware” means

The current prompt prioritizes a small complete production patch, requires task classification before tool selection, and reserves implementation/repair runway instead of treating investigation or self-authored tests as completion. It calls `rails_lifecycle_audit` first for deletion, ownership, attachment, callback, transaction, and enqueue-timing work; other tasks trace their actual execution path without calling the audit merely because it exists.

The run configuration was:

```text
provider:          chatgpt:gpt-5.6-sol-max
LLM-call limit:    100
model timeout:     1,800 seconds
output per call:   4,096 tokens
skills/search:     disabled
```

Relative to the earlier neutral 30-call/600-second runs, **prompt and runway changed together**, and the prompt was adaptively tuned after observing these known-task failures. The matrix has no prompt-only or runway-only ablation. It therefore supports no causal attribution, general reliability estimate, public-benchmark correction, or leaderboard claim.

## Fifteen authoritative samples

Verifier cells are `runs/assertions/failures/errors`. Ask cells are `session status / process exit / solver wall seconds`. Tokens are `input/cache-read/output`.

### Batch A: account erasure and TOC caching

| Task | Rep | Session | Verifier | Full | Ask | Turns/tools | Tokens | First production edit |
|---|---:|---|---:|---:|---|---:|---:|---|
| `ar-erase-account` | 1 | `20260817-075025-07de3d8e634986db` | 5/51/0/0 | **yes** | `complete` / 0 / 616.643s | 50/116 | 125,067/2,690,560/25,652 | turn 8, +141.224s, `app/models/user.rb` |
| `ar-erase-account` | 2 | `20260817-075026-dc5a11f757669225` | 5/51/0/0 | **yes** | `complete` / 0 / 743.678s | 42/104 | 119,242/2,587,136/32,498 | turn 7, +156.535s, `app/models/user/authoring.rb` |
| `ar-erase-account` | 3 | `20260817-075025-05105e1c555a8c5b` | 5/51/0/0 | **yes** | `complete` / 0 / 642.434s | 41/115 | 112,674/2,203,136/26,773 | turn 10, +189.135s, `app/models/user.rb` |
| `av-toc-cache-per-role` | 1 | `20260817-080056-12c0d926b38743a9` | 6/56/0/0 | **yes** | `complete` / 0 / 559.465s | 44/77 | 95,314/1,838,592/20,537 | turn 8, +116.171s, `app/controllers/books_controller.rb` |
| `av-toc-cache-per-role` | 2 | `20260817-080304-94f1fd212d2cbf3d` | 6/56/0/0 | **yes** | `complete` / 0 / 599.052s | 45/76 | 116,475/1,495,552/22,554 | turn 5, +61.192s, `app/views/books/show.html.erb` |
| `av-toc-cache-per-role` | 3 | `20260817-080122-07c37911d0e2ca8f` | 6/56/0/0 | **yes** | `complete` / 0 / 579.029s | 43/81 | 97,995/2,143,232/22,813 | turn 4, +76.927s, `app/controllers/books_controller.rb` |

Batch A totals: **3,740.301 solver-seconds**, 265 turns, 569 tool calls, 666,767 input tokens, 12,958,208 cached-input tokens, and 150,827 output tokens.

### Batch B: purge, logger, and variant processing

| Task | Rep | Session | Verifier | Full | Ask | Turns/tools | Tokens | First production edit |
|---|---:|---|---:|---:|---|---:|---:|---|
| `as-purge-embedded-images` | 1 | `20260817-082040-cb086635a3d30d75` | 5/25/1/0 | no | `complete` / 0 / 140.486s | 16/39 | 31,937/217,600/5,226 | turn 4, +25.926s, `lib/rails_ext/action_text_markdown.rb` |
| `as-purge-embedded-images` | 2 | `20260817-082040-cc67f56a2dd36ab5` | 5/25/1/0 | no | `complete` / 0 / 162.285s | 16/46 | 39,462/297,472/6,276 | turn 3, +23.449s, `lib/rails_ext/action_text_markdown.rb` |
| `as-purge-embedded-images` | 3 | `20260817-082040-9978c4deef890c23` | 5/25/1/0 | no | `complete` / 0 / 170.295s | 18/53 | 55,326/417,792/6,962 | turn 5, +46.958s, `lib/rails_ext/action_text_markdown.rb` |
| `sup-log-to-terminal` | 1 | `20260817-082314-513e747c5174a829` | 3/3/1/0 | no | `complete` / 0 / 249.527s | 25/40 | 66,685/394,752/10,208 | turn 6, +79.327s, `script/library_report.rb` |
| `sup-log-to-terminal` | 2 | `20260817-082334-0f856ac5fd0bbbd2` | 3/3/1/0 | no | `complete` / 0 / 201.318s | 18/31 | 30,176/214,528/8,613 | turn 5, +44.504s, `script/library_report.rb` |
| `sup-log-to-terminal` | 3 | `20260817-082341-0e58eec71602f38c` | 3/3/1/0 | no | `complete` / 0 / 178.286s | 10/23 | 25,135/89,600/8,387 | turn 4, +56.214s, `script/library_report.rb` |
| `as-variant-processed-once` | 1 | `20260817-082736-a7e6d73e3826576d` | 5/21/0/0 | **yes** | `complete` / 0 / 336.370s | 25/54 | 68,341/890,880/14,787 | turn 11, +155.158s, `app/models/picture.rb` |
| `as-variant-processed-once` | 2 | `20260817-084009-28d0c02e6aaff137` | 5/21/0/0 | **yes** | `complete` / 0 / 233.939s | 20/42 | 61,295/646,656/9,902 | turn 10, +101.906s, `app/models/picture.rb` |
| `as-variant-processed-once` | 3 | `20260817-082651-67be172153233cf0` | 5/0/0/5 | no | `complete` / 0 / 425.207s | 37/67 | 85,879/1,590,272/17,030 | turn 9, +123.890s, `app/models/picture.rb` |

Batch B totals: **2,097.713 solver-seconds**, 185 turns, 395 tool calls, 464,236 input tokens, 4,759,552 cached-input tokens, and 87,391 output tokens.

Combined totals checked from all 15 rows: **5,838.014 solver-seconds**, 450 turns, 964 tool calls, 1,131,003 input tokens, 17,717,760 cached-input tokens, and 238,218 output tokens. Published verifiers ran 72 tests with 447 assertions, 6 failures, and 5 errors; 61 tests passed.

## Batch B host interruption and exact resume

Three Jobs V2 workers were launched concurrently at 08:20:35 AEST:

- `job_c3jGkV0VfL41` / `run_XF8vHhB5jpfy`: attempt 1, succeeded at 08:33:22 after all three replicate-1 samples;
- `job_OZNXK6fbunp-` / `run_IPyWLHLdJPQK`: attempt 1, worker lost at 08:37:28 after completing valid replicate-2 purge and logger samples;
- `job_VL9WHKHpCQqb` / `run_6XIEPEMLJNaX`: attempt 1, succeeded at 08:34:06 after all three replicate-3 samples.

The host killed the worker/aggregator for the second program run. Its completed purge and logger artifacts were retained and were **not rerun**. The interrupted worker had created a directory for the third task, but no session, ask exit, protected-restore proof, visible-suite result, or verifier result existed; it was not a valid started sample.

Only that genuinely missing sample was run directly against the same replicate-2 cache and runs root:

- `job_X19J6zH6UONv` / `run_vGlaNiRDan5G`: replicate-2 `as-variant-processed-once`, attempt 1, started 08:40:06 and succeeded 08:44:12 AEST.

There were no score-driven retries, replacements, exclusions, or reruns of completed samples.

## Production diffs and failure modes

### Embedded-image purge: 0/3

All three samples made the same production change:

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

Each also added a protected test later removed before grading. Solver diff stats were 2 files +19/-1, 2 files +27/-1, and 2 files +19/-1. The change fixed current-page image cleanup and preserved upload/fetch behavior, but all three missed images owned by historical revisions: `test_a_page_revised_after_its_image_went_in_frees_the_revision's_image_too` failed. Each scored 4/5 tests and 25 assertions with one failure.

### Logger broadcast: 0/3

Replicates 1 and 2 replaced report calls with a local `ActiveSupport::BroadcastLogger` combining `Rails.logger` and a stdout logger (1 file, +9/-4 each). Replicate 3 called `Rails.logger.broadcast_to ActiveSupport::Logger.new($stdout)` (1 file, +2).

All three duplicated normal output correctly but left the stdout logger at its own permissive level. Raising `Rails.logger.level` therefore failed to suppress informational progress on stdout; each scored 2/3.

### Account erasure: 3/3

All three patches implemented hard erasure, administrator reachability for previously deactivated accounts, owned-row and upload cleanup, historical edit cleanup, search removal, private-book deletion, public-book retention with `creator_id: nil`, and `Deleted author` rendering. Production/test solver diff stats were:

| Rep | Production files | Test files | Solver diff stat |
|---:|---:|---:|---|
| 1 | 6 | 2 | 8 files, +135/-19 |
| 2 | 7 | 1 | 8 files, +112/-25 |
| 3 | 7 | 1 | 8 files, +109/-19 |

All three passed 5/5 published tests and all 51 assertions. See the [original Batch A report](runway-two-tasks-max.md) for the file-by-file orchestration differences.

### Variant processing: 2/3

All three samples found the same canonicalization fix:

```diff
-format: :webp
+format: "webp"
```

Replicates 1 and 2 passed 5/5 with 21 assertions. Their solver diffs were 2 files +32/-1 and 2 files +8/-1; the protected tests were restored before grading.

Replicate 3 had the same one-line production fix and a 2-file +20/-1 solver diff, but its verifier stopped during fixture setup with five foreign-key errors in `active_storage_variant_records`, so it is conservatively scored 0/5 and not replaced. This is an observed grading-state failure, not a failed behavior assertion; the matrix is too small to separate patch reliability from order-dependent environment behavior.

### Per-role TOC cache: 3/3

All three computed editability once, included role/editability and versioned records in cache identity, and threaded the computed value into rendering. Production/test solver diff stats were 3 files +85/-10, 3 files +76/-10, and 4 files +77/-10. All three passed 6/6 and all 56 assertions. The [Batch A report](runway-two-tasks-max.md) preserves the implementation-shape differences.

## Audit selection and runway

Audit selection matched the current prompt:

- all purge, account, and variant samples called `rails_lifecycle_audit` exactly once as their first tool;
- no logger or TOC sample called it;
- all 15 reached a production edit before completion;
- solver-authored tests were preserved in `solver.diff` but restored away before grading.

The 100-turn/1,800-second runway was operationally necessary for Batch A: all six account/TOC samples used 41–50 turns, and all three account asks exceeded the old 600-second timeout. Batch B completed in 10–37 turns and 140–425 seconds, so those nine samples did not need the added cap. This still does not isolate runway as the cause of any score change because the prompt changed with it.

## Exact inputs, isolation, and validation

- Matrix roots (ignored local storage):
  - `.matrix/runway-two-tasks-max-20260816T215020Z`
  - `.matrix/runway-remaining-three-max-20260816T222035Z`
- Harness commits: `e0761fda28958b395886a12adb335f0695ad309f` and documentation-only successor `2ec2776ef7be2cc2faf6428e36c3a76239071003`.
- Model request: `chatgpt:gpt-5.6-sol-max`; every session resolves to `gpt-5.6-sol`, `effort=max`, model label `gpt-5.6-sol-max`.
- Limits: `MAX_TURNS=100`, `ASK_TIMEOUT_SECONDS=1800`, `MAX_OUTPUT_TOKENS=4096`.
- Prompt SHA-256 values, identical across each task's three replicates and byte-identical to each session's sole user question:
  - `as-purge-embedded-images`: `28d9deeb24ad0ac96ef154ff473fd2de9ece11705ddf56b97f4a4f1e82f0fe10`
  - `sup-log-to-terminal`: `4b2087a587f2f35fa4eafdb4fb19d9b913a3fa3c1f9012c3a4bcbfb1de5fef49`
  - `ar-erase-account`: `b323e14692013b979fad55477cd42ae1f859ecec97b30b0c78b80a415e47c2b1`
  - `as-variant-processed-once`: `0cdbafd089661a70618e94fab3ceae627a542d6ce593830c26a1bea0138f12c0`
  - `av-toc-cache-per-role`: `cea0c07d009682348a8130b7cb5356ba43772090ced69dd7b49006ae7b838b97`
- Frozen system prompt: `64f380437e336fa9fc12fe39151a8b8482aaa8cc967805ca7b0630962c9ce114`.
- `agent.yaml`: `5462f43d1c9439e878b7cbbebb1716c4247a29b48fd702a18464405382faa3b6`.
- Custom-tool wrapper: `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a`.
- Bundled lifecycle graph: `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7`.
- Bundled tool reference: `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06`.
- `bin/run-eval`: `8f272d54d67f629fd088fdd997a032b2ce06d7198958eb96b0463c7c2623bab4`.
- Matrix worker: `360adbbbccc585c6d34c6c198f78cc61f5367c258542f80584b200ced4f00b66`.
- `rails/ai-evals`: `8b4cab9165fc7878e4a2203f0966e45a1608cd09`.
- Basecamp Writebook: `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`).
- term-llm: Batch A used `v0.0.393` (`cc5d7939`); Batch B used `v0.0.394` (`6f85c93e`). This harness update did not change the frozen agent files or recorded task/model configuration, but it is a disclosed cross-batch runtime difference.
- Skills and dedicated search were disabled. Verifiers, solutions, task metadata, prior runs, and other workspaces remained outside each application workspace during inference.
- Before grading, every runner preserved `solver.diff`, restored `test/`, `bin/`, and `config/environments/test.rb`, and produced an empty `grading-protected-status.txt`. All visible-suite exits were zero.

## Interpretation and caveats

The current harness solved account erasure and TOC caching consistently in this small sample, found the variant identity fix in all three production diffs, and still systematically missed historical-revision image ownership and dynamic logger severity propagation. The failures are useful precisely because they were retained rather than retried into a prettier number.

The scientific claim remains narrow. These are known tasks; prompt design was adaptive; `n=3` is small; two launch batches and a term-llm patch-version difference are disclosed; one variant verifier encountered order-dependent fixture-state errors; and prompt plus runway changed together relative to the historical neutral matrix. Treat **8/15** as the observed result of this exact effective harness and protocol, not as a model score or evidence that one design choice caused the improvement.
