# Runway-aware two-task max-effort experiment

Date: 2026-08-17 (Australia/Sydney)

## Result

Three fresh `chatgpt:gpt-5.6-sol-max` samples of each selected task produced **6/6 full solves** under harness commit `e0761fda28958b395886a12adb335f0695ad309f`:

| Task | Full solves | Published verifier by replicate | Latest neutral 30-call batch |
|---|---:|---|---:|
| `ar-erase-account` | **3/3** | 5/5, 5/5, 5/5 | 0/3 |
| `av-toc-cache-per-role` | **3/3** | 6/6, 6/6, 6/6 | 0/3 |
| **Total** | **6/6** | **33/33 verifier tests** | **0/6** |

Every visible suite also passed: 179 runs, 549 assertions, 0 failures, 0 errors, and 4 skips in each workspace. Every published verifier exited zero. This is the first batch in this repository where all three samples solved either selected task.

The comparison is intentionally descriptive, not causal. The earlier [neutral max-effort matrix](other-four-max-neutral-matrix.md) used the prior neutral graph-closure prompt, 30 LLM calls, and a 600-second model timeout; it scored both tasks 0/3. This experiment changed **the prompt and runway together**: the prompt was rewritten around early production delivery and task-appropriate audit selection, while the limits rose to 100 LLM calls and 1,800 seconds. The prompt was adaptively tuned after seeing these known-task failures. With `n=3`, no ablation, and two coupled changes, 0/6 → 6/6 cannot identify which change mattered or establish general reliability.

## Six authoritative samples

Verifier cells are `runs/assertions/failures/errors`. Ask cells are `session status / process exit / solver wall seconds`. Tokens are `input/cache-read/output`.

| Task | Rep | Session | Verifier | Full | Ask | Turns/tools | Tokens | First production edit |
|---|---:|---|---:|---:|---|---:|---:|---|
| `ar-erase-account` | 1 | `20260817-075025-07de3d8e634986db` | 5/51/0/0 | **yes** | `complete` / 0 / 616.643s | 50/116 | 125,067/2,690,560/25,652 | turn 8, +141.224s, `app/models/user.rb` |
| `ar-erase-account` | 2 | `20260817-075026-dc5a11f757669225` | 5/51/0/0 | **yes** | `complete` / 0 / 743.678s | 42/104 | 119,242/2,587,136/32,498 | turn 7, +156.535s, `app/models/user/authoring.rb` |
| `ar-erase-account` | 3 | `20260817-075025-05105e1c555a8c5b` | 5/51/0/0 | **yes** | `complete` / 0 / 642.434s | 41/115 | 112,674/2,203,136/26,773 | turn 10, +189.135s, `app/models/user.rb` |
| `av-toc-cache-per-role` | 1 | `20260817-080056-12c0d926b38743a9` | 6/56/0/0 | **yes** | `complete` / 0 / 559.465s | 44/77 | 95,314/1,838,592/20,537 | turn 8, +116.171s, `app/controllers/books_controller.rb` |
| `av-toc-cache-per-role` | 2 | `20260817-080304-94f1fd212d2cbf3d` | 6/56/0/0 | **yes** | `complete` / 0 / 599.052s | 45/76 | 116,475/1,495,552/22,554 | turn 5, +61.192s, `app/views/books/show.html.erb` |
| `av-toc-cache-per-role` | 3 | `20260817-080122-07c37911d0e2ca8f` | 6/56/0/0 | **yes** | `complete` / 0 / 579.029s | 43/81 | 97,995/2,143,232/22,813 | turn 4, +76.927s, `app/controllers/books_controller.rb` |

Totals checked from the six rows: **3,740.301 solver-seconds**, 265 LLM turns, 569 tool calls, 666,767 input tokens, 12,958,208 cached-input tokens, and 150,827 output tokens.

“First production edit” is the first `edit_file` or `write_file` call targeting `app/` or `lib/`, measured from session creation. All six edited production before tests. The account runs made 12/8, 17/5, and 13/6 production/test edit-tool calls; the TOC runs made 7/7, 3/3, and 13/4. These are activity counts, not final diff size: several TOC edits were later reverted.

## Did the runway prevent caps and timeouts?

Yes, for this exact batch:

- Every sample used **41–50 LLM turns**, so all six would have crossed the earlier 30-call ceiling before natural completion. The 100-call runway prevented that cap from ending every run.
- All three account asks used **616.643–743.678 seconds**, beyond the earlier 600-second timeout. The 1,800-second runway allowed all three to finish naturally.
- TOC asks used **559.465–599.052 seconds**. They completed just inside the old wall timeout, but still exceeded the old 30-call budget.
- No sample approached the new cap: the maximum was 50/100 turns and 743.678/1,800 seconds. All six sessions report `complete`, and all ask processes exited zero.

That establishes that more runway was operationally necessary for these completions. It does not establish that runway alone caused the score change because the prompt changed at the same time.

## Audit selection and production/test behavior

The revised prompt says to use the lifecycle audit for deletion/ownership/callback work, but not merely because the tool exists.

- **Account erasure:** all three runs called `rails_lifecycle_audit` exactly once, as their first tool, with a task-specific erasure focus. They then traced the controller, user associations, books, sessions/sign-in events, reading marks, search indexing, historical edits, markdown uploads, and rendering paths. This was the appropriate selection.
- **TOC caching:** none of the three runs called `rails_lifecycle_audit`. They began with repository search and followed the book show view, leaf partial, editability checks, fragment cache identity, and nearest controller tests. This was also appropriate: cache/render identity is not lifecycle ownership just because a lifecycle tool is available.
- No run created the old `.term-llm/lifecycle-closure.md` process artifact. The production patch preceded self-authored regression-test work in every run.
- Solver-authored tests were preserved in `solver.diff` for analysis but then removed from the grading workspace. They did not contribute to either visible-suite or published-verifier scores.

## Production patches

### Account erasure: 3/3

All three patches implemented the complete observed behavior through slightly different shapes:

- the admin Remove action hard-deletes rather than merely deactivating;
- previously deactivated users remain reachable by administrators and can be erased;
- sessions, access grants, reading marks, private authored books, leaves, historical edits/leafables, markdown uploads, Active Storage rows/files, and search-index state are cleaned up through reachable destroy/callback paths;
- globally shared books survive with `creator_id: nil` and rendered author `Deleted author`;
- sign-in events keyed by both the scrambled deactivated address and recovered original address are removed.

Common lifecycle fixes changed `Leaf::Editable#edits` from `dependent: :delete_all` to `:destroy`, changed markdown uploads from attachment-row-only destruction to `purge_later`, and added dependent destruction for reading marks. Replicates 2 and 3 also made search removal unconditional on post-destroy `searchable?`, while replicate 1 reached a passing path without that exact change. The controller/model split varied: replicate 1 used destroy callbacks, replicate 2 concentrated orchestration in `User::Authoring`, and replicate 3 introduced `User#erase` with an explicit transaction.

Final preserved solver diffs were:

| Rep | Production files | Test files | Solver diff stat |
|---:|---:|---:|---|
| 1 | 6 | 2 | 8 files, +135/-19 |
| 2 | 7 | 1 | 8 files, +112/-25 |
| 3 | 7 | 1 | 8 files, +109/-19 |

There was no verifier failure mode in this batch. The material residual difference is patch breadth and orchestration style, not observed behavior: all three passed all 51 verifier assertions after protected restore.

### Per-role TOC cache: 3/3

All three final patches computed editability once, threaded it into the leaf partial, and included role/editability plus versioned records in fragment identity. That prevented a reader from receiving an editor fragment, allowed an editor to receive controls after a reader primed the cache, handled edit rights not derived from an access-level row, expired renamed leaves, and avoided one access check per TOC entry.

Replicates 1 and 2 kept the computed value local to `show.html.erb`; replicate 3 set `@book_editable` in `BooksController#show`. The final preserved production diffs were compact:

| Rep | Production files | Test files | Solver diff stat |
|---:|---:|---:|---|
| 1 | 2 | 1 | 3 files, +85/-10 |
| 2 | 2 | 1 | 3 files, +76/-10 |
| 3 | 3 | 1 | 4 files, +77/-10 |

Replicates 1 and 3 briefly explored controller/Turbo Stream changes and then reverted unnecessary pieces before completion. Again there was no published-verifier failure mode: all three passed all 56 assertions after protected restore.

## Isolation, exact inputs, and grading

- Matrix root: `.matrix/runway-two-tasks-max-20260816T215020Z` (ignored local storage).
- Harness commit: `e0761fda28958b395886a12adb335f0695ad309f`.
- Model request: `chatgpt:gpt-5.6-sol-max`; all six session records resolve to `gpt-5.6-sol`, `effort=max`, model label `gpt-5.6-sol-max`.
- Limits: `MAX_TURNS=100`, `ASK_TIMEOUT_SECONDS=1800`, and `MAX_OUTPUT_TOKENS=4096` (the runner default, passed explicitly to `term-llm ask`).
- Prompt hashes match across replicates and match the previously validated exact post-front-matter benchmark bodies:
  - `ar-erase-account`: `b323e14692013b979fad55477cd42ae1f859ecec97b30b0c78b80a415e47c2b1`
  - `av-toc-cache-per-role`: `cea0c07d009682348a8130b7cb5356ba43772090ced69dd7b49006ae7b838b97`
- Frozen revised system prompt: `64f380437e336fa9fc12fe39151a8b8482aaa8cc967805ca7b0630962c9ce114`.
- `agent.yaml`: `5462f43d1c9439e878b7cbbebb1716c4247a29b48fd702a18464405382faa3b6`.
- Custom-tool wrapper: `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a`.
- Bundled lifecycle graph: `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7`.
- Bundled tool reference: `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06`.
- `bin/run-eval`: `8f272d54d67f629fd088fdd997a032b2ce06d7198958eb96b0463c7c2623bab4`.
- Matrix worker: `360adbbbccc585c6d34c6c198f78cc61f5367c258542f80584b200ced4f00b66`.
- `rails/ai-evals`: `8b4cab9165fc7878e4a2203f0966e45a1608cd09`.
- Basecamp Writebook: `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`).
- term-llm: `v0.0.393` (`cc5d7939`).
- Skills and dedicated search were disabled. The verifier, solution, task metadata, prior runs, and other workspaces remained outside each application workspace during inference.
- Before grading, every runner preserved `solver.diff`, restored `test/`, `bin/`, and `config/environments/test.rb`, and produced an empty `grading-protected-status.txt`. All visible-suite and verifier exit files contain zero.

## Jobs V2 provenance and cleanup

The three authoritative program jobs started concurrently at 07:50:20 AEST. Each ran exactly `ar-erase-account` and then `av-toc-cache-per-role`, sequentially, once:

- `job_XOQCIytfVoqp` / `run_UdJZvGZW4YQ9`: attempt 1, succeeded at 08:10:27 AEST;
- `job_W-YdXcnvKwfQ` / `run_n5cDOrdFeONS`: attempt 1, succeeded at 08:13:13 AEST;
- `job_EJTSkexVZq7t` / `run_sWW2iTZzfcHo`: attempt 1, succeeded at 08:11:11 AEST.

Each job's authoritative run history contained exactly that one run. There were no reruns, replacements, excluded samples, or other tasks. After publication the three temporary job definitions were deleted and `/app` was confirmed absent.

## Interpretation

The practical result is strong but narrow: the runway-aware harness stopped spending the entire budget on process and tests, selected the lifecycle audit only where relevant, reached production edits within 61–189 seconds, and completed all six known-task samples. More runway clearly prevented old caps from terminating these exact sessions.

The scientific claim is smaller. Prompt and runway moved together, the prompt was developed adaptively against known failures, and both tasks had already informed harness design. This batch is evidence about the behavior of this exact effective harness, not a clean held-out validation, an attribution experiment, a general reliability estimate, or a leaderboard correction. A useful next experiment would freeze this prompt and ablate 30 vs 100 calls and 600 vs 1,800 seconds on fresh tasks—but that is a different experiment, not evidence retroactively supplied here.
