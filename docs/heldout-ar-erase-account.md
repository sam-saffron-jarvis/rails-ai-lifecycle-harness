# Held-out Rails lifecycle-resource validation: `ar-erase-account`

Date: 2026-08-16 (Australia/Sydney)

## Result

**Partial verifier result: 4/5 tests passed; the held-out sample was not a full solve.**

The sole scored `chatgpt:gpt-5.6-sol-xhigh` run completed naturally in **235.956 seconds**, made a substantial six-file erasure patch, passed the focused visible tests and the complete visible suite, then failed one published-verifier case:

```text
Failure:
VerifierTest#test_the_book_they_shared_with_everyone_keeps_working,_bylined_as_nobody
Expected: "Deleted author"
  Actual: "Ada Sample"

5 runs, 47 assertions, 1 failures, 0 errors, 0 skips
```

It correctly erased the user and indirectly owned data in the other four verifier cases, but did not update the retained public book's existing `author` byline. It added an unused `Book#creator_name` fallback instead; the application renders the scalar `Book#author` field.

This is one held-out sample, not a retry or tuning series. It does **not** establish that the frozen lifecycle harness generalizes to the next-hardest task, and it does not add a binary full solve for Sol.

## Exact run conditions

- Task: `ar-erase-account`
- Fresh application source: Writebook commit `e5563e260434c98425f3de80d45fddf0fdb76012`
- Exact `environment.patch` applied before graph generation: SHA-256 `09e6babe5b02140a55496b0b561dfa491bab9de850dd015eee1b3b8e9e982759`
- Exact instruction file: SHA-256 `0b6d12d033d3e18617f3a7b6491c5041cc4c73cb10bb6aafd2414af3248154bf`
- Sole direct ask: exact Markdown task body after removing YAML front matter; SHA-256 `b323e14692013b979fad55477cd42ae1f859ecec97b30b0c78b80a415e47c2b1`
- Agent: unchanged `rails-bench-sol-xhigh-lifecycle-resource`
- Explicit provider/model override: `chatgpt:gpt-5.6-sol-xhigh`, matching the frozen agent
- Session-confirmed provider: `ChatGPT (gpt-5.6-sol, effort=xhigh)`
- Session-confirmed model: `gpt-5.6-sol-xhigh`
- Skills: `none`
- Tools: the unchanged agent's single unrestricted auto-approved shell
- Maximum turns: 30
- Maximum output per model call: 4,096 tokens
- Hard solver cap: 600 seconds
- User turns: 1
- LLM turns: 8
- Shell calls: 7
- Tokens: 30,531 input; 126,464 cached input; 9,243 output across the eight model calls
- Session: `20260816-170657-24365ff4e7289110`
- Solver start/end: 17:06:57–17:10:53 AEST
- Full harness end: 17:11:00 AEST

The solver received only the direct task body and `.term-llm/rails-lifecycle-audit.md`. No task front matter, benchmark metadata, verifier, solution patch, previous sessions, prior artifacts, or parent workspace was present in or exposed to its application cwd. The verifier was invoked only after solver exit, from the exact application cwd, with `/app` temporarily linked to that same workspace.

## Frozen-resource integrity

All frozen files in the lifecycle resource bundle were hashed before and after. The complete manifests are byte-identical; `frozen-resource-before-after.diff` was empty in the source experiment.

Core files used by the 3/3 prototype remained:

| Frozen file | SHA-256 before | SHA-256 after |
|---|---|---|
| `rails_lifecycle_graph.py` | `eefcccab8bde4c2ff92337cd3abd825cb067c95f7f57e20b9e6921026985efba` | identical |
| `rails-lifecycle-reference.md` | `46e883bf68af001662bcb513b00013fbde05f13c5254a0cfbd6f791717ac55f0` | identical |
| `rails-lifecycle-process.md` | `3f82ab12d7036c4f15eba21efb2fd1a1e5ead1c8dc7f17f6c0741e0aa5d7267a` | identical |

The unchanged agent was also hashed before and after:

| Frozen agent file | SHA-256 before | SHA-256 after |
|---|---|---|
| `agent.yaml` | `504f3cbe90f65b478476f92b1d2c089d5f5ec521d837d7c65d8423cafa465da9` | identical |
| `system.md` | `92ae445f093066152dd76aa631cad60693ad1e46557155c235fe263074bd2190` | identical |

`frozen-agent-before-after.diff` is empty. No frozen resource or agent file was modified.

## Deterministic held-out packet

The unchanged graph script ran only in the fresh, environment-patched repository. Its packet contains:

- schema: `rails_lifecycle_graph/v1`
- source files scanned: 71
- fact rows: 43
- source-manifest SHA-256: `5e85d5df4bf447e522b2caaf837a5ab8eb0af2329ae0a24f37bcd3b7808be51e`
- graph JSON SHA-256: `3d31c78b8f710e2d3a8e31f8b42b367f0f67e99975972cda1ae53f2827f2996a`
- combined unchanged reference + process + graph audit SHA-256: `6bfb6f44c71ec197f705d244e184f9e18994c3a923e7af40d8bc96d2107cec1c`

No pre-generated graph from another task was reused. The graph was generated after the exact task environment was applied and before the solver ran.

## Does the graph encode the patch?

**No. The graph contains generic current-repository facts, not patch instructions or hidden-answer text.** It makes several highly relevant lifecycle facts conspicuous:

- `User has_many :sessions, dependent: :destroy`
- `User has_many :accesses, dependent: :destroy`
- `User has_many :created_books, dependent: :destroy`
- `User has_many :reading_marks` with no dependency
- `Book belongs_to :creator`, optional
- `ReadingMark belongs_to :user`
- `Session after_destroy :record_signed_out`
- legacy `sessions.delete_all`, which bypasses callbacks
- `Leaf has_many :edits, dependent: :delete_all`
- markdown uploads with `dependent: :destroy`
- search-index create/update/destroy callbacks

Combined with the generic reference's destroy/delete and attachment semantics, those facts strongly expose risky ownership edges. That is the intended augmentation. But the packet does **not** say to call `User#destroy!`, select inactive users, reconstruct pre-deactivation email addresses, preserve everyone-access books, null `creator_id`, set `author` to `"Deleted author"`, or name any expected changed line.

The failure is especially informative: the scanner inventories lifecycle declarations and selected call sites, but not scalar presentation fields or ERB rendering. It surfaced `Book#creator`; it did not surface the existing `books.author` column or views rendering `book.author`. The solver inferred a `creator_name` API that the application never uses, and the verifier caught the missing scalar-author update. So the graph is strong and task-relevant, but it demonstrably did not encode the complete patch.

No forbidden strings (`verification_test.rb`, `solution.patch`, task IDs) appeared in any graph row. The graph generation policy excluded tests, evaluator data, metadata, solutions, dependencies, and parent directories.

## Solver patch and behavior

The solver changed six production files:

1. `app/controllers/users_controller.rb`
   - replaced legacy `deactivate` with `destroy!`
   - allowed lookup of already-deactivated users by removing the `.active` scope
2. `app/models/user.rb`
   - added a prepended destroy callback
   - deleted sessions without creating fresh sign-out audit rows
   - removed sign-in events for current and reconstructed original addresses
   - detached everyone-access created books before dependent destruction
3. `app/models/user/authoring.rb`
   - added `dependent: :destroy` to reading marks
4. `app/models/leaf/editable.rb`
   - changed historical edits from `delete_all` to `destroy`
5. `lib/rails_ext/action_text_markdown.rb`
   - changed uploads from attachment-only `destroy` to `purge_later`
6. `app/models/book/authorship.rb`
   - added `creator_name`, returning `"Deleted author"` when creatorless

The first edit shell call failed because its exact text replacement did not match `user.rb`; no partial changes survived that call. The solver corrected the edit in its next shell call and continued naturally. This was an in-session edit correction, not a sample retry, harness tuning, or verifier-driven retry.

The decisive miss was narrow: public books were detached from the erased creator, but their existing `author` field remained `"Ada Sample"`. The new `creator_name` method was not wired into rendering and was the wrong data surface for the published requirement.

## Tests and scoring

Solver-visible tests:

- focused controller suite: **9 runs, 26 assertions, 0 failures, 0 errors**
- full visible suite: **179 runs, 549 assertions, 0 failures, 0 errors, 4 skips**
- `git diff --check`: passed

Published verifier, run once after solver completion:

- **5 runs, 47 assertions, 1 failure, 0 errors, 0 skips**
- per-test score: **4/5**
- binary full solve: **no**

No tuning, patching, rerun, or second solver sample occurred after seeing the verifier.

## Comparison with public results

Correct published context:

- `as-purge-embedded-images` was **1/24**, with Muse **1/3**. It was not a truly universal failure.
- `ar-erase-account` is the next-hardest published task at **8/24**:
  - Opus: 3
  - Kimi: 1
  - Fable: 3
  - Sol: 1
  - Muse: 0
  - Luna: 0
  - GLM: 0
  - DeepSeek: 0

This held-out Sol xhigh lifecycle-resource sample reached 4/5 verifier cases but did not fully solve the task. The fair interpretation is:

1. The frozen resource helped Sol construct most of a difficult, multi-edge erasure patch in one sample.
2. It did not close the complete task; therefore the earlier post-hoc 3/3 prototype has not yet demonstrated reliable held-out generality.
3. The miss aligns with the graph's actual boundary: lifecycle ownership was represented; the retained book's scalar byline/presentation invariant was not.
4. With `n=1`, no causal claim about uplift over the published Sol condition is justified. Effective context and harness differ, and partial verifier counts are not the published binary task score.

## Isolation, retries, and cleanup

One initial `nohup` launch terminated before artifact creation, workspace preparation, or any solver invocation. Its log is empty and preserved with an explicit note. It was an invalid launch, not a scored sample; the foreground run above is the sole scored sample.

After scoring:

- `/app` removed
- disposable task workspace removed
- no solver process remains
- no temporary Jobs V2 definition or run was created
- canonical Writebook source remains detached and clean at `e5563e260434c98425f3de80d45fddf0fdb76012`
- frozen resource and agent hashes remain identical
- no canonical/default configuration changed
- no commit outside the disposable workspace
- no push, PR, publication, or public upload

The source experiment preserved exact prompt and hashes, task input hashes, before/after resource and agent manifests, graph and combined packet, preparation logs and baseline SHAs, raw JSONL, isolated session DB/export, tool calls, solver diff/status, visible-test evidence, verifier output, metrics, timestamps, invalid-launch evidence, and artifact hashes. Those bulky runtime artifacts are not committed here; `bin/run-eval ar-erase-account` regenerates the public-facing experiment structure.
