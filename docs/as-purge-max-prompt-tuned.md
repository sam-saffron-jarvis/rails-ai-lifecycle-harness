# Prompt-tuned max-effort `as-purge` follow-up

> **Historical experiment.** Prompt and effort changed together here; these rows are not part of the current [corrected runway-aware five-task matrix](corrected-runway-five-task-matrix.md). See [history](history.md).

Date: 2026-08-16 (Australia/Sydney)

## Result

Three fresh `chatgpt:gpt-5.6-sol-max` samples of **only** `as-purge-embedded-images` produced **2/3 full solves**.

| Replicate | Jobs V2 run | Session | Published verifier | Full solve | Solver wall time | Turns / tools | Tokens (input / cached / output) |
|---|---|---|---:|---:|---:|---:|---:|
| 1 | `run_Lr2zlWByW_yX` | `20260816-201806-7417ee5477ab3093` | 5 runs / 28 assertions / 0 failures / 0 errors | **yes** | 339.943s | 22 / 62 | 62,894 / 629,760 / 14,148 |
| 2 | `run_ryaE8Lm0zVmn` | `20260816-201806-5772520963112a90` | 5 runs / 25 assertions / 1 failure / 0 errors | no | 225.096s | 16 / 63 | 57,323 / 461,824 / 8,239 |
| 3 | `run_46aUnGoIaX94` | `20260816-201809-0ab10b0b23bc2d32` | 5 runs / 28 assertions / 0 failures / 0 errors | **yes** | 354.741s | 22 / 65 | 73,051 / 717,824 / 14,447 |

All three solver sessions completed normally. All three full visible suites passed with 179 runs, 549 assertions, 0 failures, and 0 errors (4 skips). The published verifier supplied the binary score.

## What changed from the prior xhigh matrix

The earlier [15-sample original-failures matrix](sol-original-failures-matrix.md) scored this task **0/3**. This follow-up changed **two variables at once**:

1. The agent system prompt added an explicit lifecycle destruction/retention-closure step and a final reconciliation of every relevant direct, indirect, historical, attachment, and asynchronous ownership edge.
2. Provider effort changed from `chatgpt:gpt-5.6-sol-xhigh` to `chatgpt:gpt-5.6-sol-max`.

The task body, published verifier, source pins, tools, turn/output limits, and grading protocol were retained. Because prompt and effort changed together—and because each condition has only three stochastic samples—the difference between 0/3 and 2/3 does **not** establish which change helped, or establish causality at all. It is a prompt-tuned max-effort follow-up, not a controlled attribution experiment or leaderboard correction.

## Patches and failure mode

Replicates 1 and 3 made both production changes needed to cover current pages and historical revisions:

```diff
-has_many :edits, dependent: :delete_all
+has_many :edits, dependent: :destroy
```

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

They passed all five verifier tests, including the revised-page case, and preserved upload-then-fetch behavior.

Replicate 2 changed only the upload purge mode:

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

It passed 4/5 but omitted `Leaf::Editable`'s historical `edits` edge. The verifier failure was:

```text
VerifierTest#test_a_page_revised_after_its_image_went_in_frees_the_revision's_image_too
Expected true to be nil or false
```

The audit surfaced the historical edge in every sample and was the first tool call in every sample. Replicate 2 still failed to carry that finding into its final production diff. More explicit instructions reduced the observed miss rate in this tiny follow-up; they did not eliminate the failure mode.

Solver-authored regression tests shown in raw diffs were not allowed to influence grading. The runner restored and cleaned `test/`, `bin/`, and `config/environments/test.rb` before the visible suite and published verifier; every `grading-protected-status.txt` proof was empty.

## Protocol and provenance

- Frozen harness/prompt commit: `2bf3b07fbc8d28ff5e15be56f2b714069f9df4c1`
- Prior xhigh matrix harness commit: `38cb205fb91a3b6b19371fe65b44aa7705bc22c1`
- `rails/ai-evals`: `8b4cab9165fc7878e4a2203f0966e45a1608cd09`
- Basecamp Writebook: `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`)
- term-llm: `v0.0.393` (`cc5d7939`)
- Provider requested: `chatgpt:gpt-5.6-sol-max`
- Actual session resolution in all three sessions: `gpt-5.6-sol`, `effort=max`, model label `gpt-5.6-sol-max`
- One user turn per session; the exact `as-purge-embedded-images` task body was the sole question
- 30 turns, 4,096 output tokens per call, 600-second model cap
- Skills and dedicated search disabled; normal developer tools plus first-class `rails_lifecycle_audit`
- Verifier, solution, metadata, and prior runs remained outside the application workspace until grading
- Prompt SHA-256, identical in all three samples: `28d9deeb24ad0ac96ef154ff473fd2de9ece11705ddf56b97f4a4f1e82f0fe10`

Frozen file hashes:

| Input | SHA-256 |
|---|---|
| `agent.yaml` | `5462f43d1c9439e878b7cbbebb1716c4247a29b48fd702a18464405382faa3b6` |
| prompt-tuned `system.md` | `f7beb455b3b1056c180bfe00fbac2a681a9a4f4f139c883d40cd26e1333a1e61` |
| prior xhigh matrix `system.md` | `67353524d9f8903b8fc4e515c1760af697dac7970cc6cb6239d89e6aae9ec6b4` |
| custom-tool wrapper | `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a` |
| bundled lifecycle graph | `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7` |
| bundled tool reference | `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06` |
| `bin/run-eval` | `0b443c40ba37bb1b91b551b357ccf6002def494f78f84e548c3b364cd0c07636` |
| matrix worker | `360adbbbccc585c6d34c6c198f78cc61f5367c258542f80584b200ced4f00b66` |

Three manual Jobs V2 program jobs began concurrently at 20:18:00 AEST. Their definitions explicitly set `TASKS=as-purge-embedded-images` and `PROVIDER=chatgpt:gpt-5.6-sol-max`, with one sample and an isolated cache/workspace per job. The exact authoritative runs all finished successfully at the job layer between 20:22:01 and 20:24:12 AEST. A non-green verifier was captured as a valid sample by the worker rather than rerun. There were no invalid samples, exclusions, or reruns.

Raw sessions, caches, workspaces, and verifier artifacts remain in ignored local `.matrix/` storage and are not published because they include large reconstructed source trees. This report preserves the protocol, hashes, identifiers, aggregate outcomes, representative production diffs, and failure mode.
