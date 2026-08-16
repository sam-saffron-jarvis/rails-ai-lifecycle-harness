# Neutral graph-closure `as-purge` follow-up

Date: 2026-08-16 (Australia/Sydney)

## Result

Three fresh `chatgpt:gpt-5.6-sol-max` samples of **only** `as-purge-embedded-images` under the neutral graph/transitive-closure prompt at commit `9acc1cac98f45f19950e697369162449aa4aafc2` produced **2/3 full solves**.

| Replicate | Jobs V2 run / job | Session | Published verifier | Full solve | Solver wall time | Session status | Turns / tools | Tokens (input / cached / output) |
|---|---|---|---:|---:|---:|---|---:|---:|
| 1 | `run_E1q7q7leZBoq` / `job_EzfkNBUJ69GA` | `20260816-204415-1c330dfb1229480d` | 5 runs / 25 assertions / 1 failure / 0 errors | no | 464.974s | complete | 22 / 78 | 81,206 / 893,952 / 22,125 |
| 2 | `run_hDG0TMtCvQBA` / `job_aU6yjt7VI0X_` | `20260816-204415-29b4967ccaad8349` | 5 runs / 28 assertions / 0 failures / 0 errors | **yes** | 451.785s | interrupted at the 30-call budget | 29 / 80 | 135,257 / 1,157,632 / 17,402 |
| 3 | `run_Pi36Z02CkpML` / `job_19QfdgDpjTtE` | `20260816-204415-12559d5f96c1f889` | 5 runs / 28 assertions / 0 failures / 0 errors | **yes** | 518.026s | interrupted at the 30-call budget | 29 / 95 | 97,283 / 1,465,856 / 22,976 |

All three `term-llm ask` processes exited zero and all three full visible suites passed with 179 runs, 549 assertions, 0 failures, 0 errors, and 4 skips. The two interrupted session exports ended naturally when the configured 30 LLM-call budget was exhausted; the runner then preserved the diffs, restored grading-protected paths, and ran the visible suite and published verifier. Every `grading-protected-status.txt` proof was empty. A non-green verifier remained a scored sample rather than being rerun.

## Correction and scope

The immediately preceding prompt at commit `a0268d5` explicitly enumerated task-adjacent examples such as historical copies, attachments, blobs, files, tracking records, and callback-bypassing APIs. Sam correctly rejected that as answer-shaped guidance: those examples risked leaking the structure of the solution rather than testing a general completion method.

Its three runs—`run_KeomVtE4D222`, `run_s3HCw7Zn_ig8`, and `run_AbaMUV1NgrmR`—were aborted and are **unscored**. No partial artifact, patch, verifier result, metric, or inference from those cancelled runs is used in this report.

Commit `9acc1ca` removes those examples. The tested prompt uses generic graph and transitive-closure gates: start from entities implied by observable requirements, record every relevant reachable edge and state transition, require evidence-backed dispositions, block production edits while relevant rows remain unresolved, and reconcile the graph against a final audit. It does **not** name task-specific Rails constructs such as pages, revisions, attachments, blobs, Active Storage, purge modes, or callback-bypassing association options.

This is still **adaptive prompt tuning** on a known failure. The prompt was revised after observing earlier task outcomes, and `n=3` is tiny. The result is evidence about this harness configuration, not an uncontaminated held-out benchmark, a leaderboard correction, or causal attribution.

## Audit and closure-gate behavior

The first tool call was `rails_lifecycle_audit` in every replicate. Every replicate created `.term-llm/lifecycle-closure.md` before its first production edit.

| Replicate | First audit | Closure artifact written | First production edit | Final audit | Observed behavior |
|---|---|---|---|---|---|
| 1 | 20:44:18 AEST | 20:48:03 | 20:49:09 | 20:51:11, same focus | Completed both audits, but classified the `Leaf -> Edit` historical path as irrelevant; the final reconciliation preserved that wrong disposition. |
| 2 | 20:44:19 AEST | 20:50:02 | 20:50:28 | not reached | Closure found the historical path and the production diff fixed it; the session exhausted its 30-call budget before final audit/closure reconciliation. |
| 3 | 20:44:18 AEST | 20:47:39 | 20:50:36 | not reached | Closure found the historical path and focused tests covered it; the session exhausted its 30-call budget before the final audit and its own full-suite step. |

The external runner—not model self-report—ran the full visible suite and published verifier for all three samples. This distinction matters: two verifier-green solutions did not complete the prompt's mandatory final-audit gate. The prompt improved observed graph coverage in two samples, but compliance remained imperfect.

Closure artifact SHA-256 values:

| Replicate | Closure SHA-256 |
|---|---|
| 1 | `f1f9d82b1430e10f9f9d6ce735c06456c1b723ced35f8f75b11637d0e55d7f2a` |
| 2 | `d41e81aa042f8fe92107419b81f3149fd4fe18d2508bdd2bd4be85f3b5a2c9e9` |
| 3 | `86d344b77a21f24190287dbf9ee616e4f47714768780186c13db9ee65da011fa` |

## Patches and verifier outcomes

Replicate 1 changed only the upload dependency in production:

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

It passed 4/5 tests. The remaining failure was the historical-revision case:

```text
VerifierTest#test_a_page_revised_after_its_image_went_in_frees_the_revision's_image_too
Expected true to be nil or false
```

Replicates 2 and 3 made both required production changes:

```diff
-has_many :edits, dependent: :delete_all
+has_many :edits, dependent: :destroy
```

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

Both passed all five verifier tests, including upload-then-fetch, direct page destruction, completed background cleanup of blob/file state, and revised-page history.

Solver diff evidence:

| Replicate | Solver diff stat | Solver diff SHA-256 |
|---|---|---|
| 1 | 2 files, 58 insertions, 1 deletion; one production file and one test file | `d057640a0644f0e71336f036bb2bbe3f4ff3714d59ff572eea9ba0f392f2207a` |
| 2 | 4 files, 54 insertions, 2 deletions; two production files and two test files | `b12bea9b9db006daaba5e2e0964960d31b7526e050d78a69d6f0eb8d61ee11f5` |
| 3 | 6 files, 157 insertions, 6 deletions; two production files and four test files | `93db50c1091162313d75c93c7700970b213a0c7124ac6fa62abef03b7e65051d` |

Solver-authored tests did not influence the published score. Before grading, the runner restored `test/`, `bin/`, and `config/environments/test.rb` from the pre-agent snapshot.

## Protocol, timing, and hashes

- Frozen neutral prompt commit: `9acc1cac98f45f19950e697369162449aa4aafc2`
- Aborted answer-shaped prompt commit: `a0268d5` (unscored; cancelled artifacts excluded)
- `rails/ai-evals`: `8b4cab9165fc7878e4a2203f0966e45a1608cd09`
- Basecamp Writebook: `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`)
- term-llm: `v0.0.393` (`cc5d7939`)
- Requested provider: `chatgpt:gpt-5.6-sol-max`
- Actual resolution in every session: `gpt-5.6-sol`, `effort=max`, model label `gpt-5.6-sol-max`
- Exact task matrix: `TASKS=as-purge-embedded-images`; one sample and isolated workspace per job
- One user turn containing only the exact benchmark task body; 30 LLM calls, 4,096 output tokens per call, 600-second model cap
- Skills and dedicated search disabled; normal developer tools plus first-class `rails_lifecycle_audit`
- Verifier, solution, metadata, prior runs, and cancelled-run artifacts remained outside each application workspace during inference
- Prompt artifact SHA-256, identical in all three samples: `28d9deeb24ad0ac96ef154ff473fd2de9ece11705ddf56b97f4a4f1e82f0fe10`

Frozen file hashes:

| Input | SHA-256 |
|---|---|
| `agent.yaml` | `5462f43d1c9439e878b7cbbebb1716c4247a29b48fd702a18464405382faa3b6` |
| neutral `system.md` | `f31f0592db61b393cab1da1090b24794cd17679550b8db4dc5d4f392dc6ad2a6` |
| custom-tool wrapper | `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a` |
| bundled lifecycle graph | `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7` |
| bundled tool reference | `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06` |
| `bin/run-eval` | `0b443c40ba37bb1b91b551b357ccf6002def494f78f84e548c3b364cd0c07636` |
| matrix worker | `360adbbbccc585c6d34c6c198f78cc61f5367c258542f80584b200ced4f00b66` |

The three manual Jobs V2 runs began concurrently at 20:44:10 AEST. Authoritative Jobs V2 state recorded all three program jobs as succeeded at the job layer: replicate 2 at 20:51:57, replicate 1 at 20:52:10, and replicate 3 at 20:53:02 AEST. Job-layer durations were 466.491s, 479.680s, and 531.984s respectively. No sample was rerun, excluded, or replaced.

Raw sessions, caches, workspaces, and verifier artifacts remain in ignored local `.matrix/` storage and are not published because they contain large reconstructed source trees. This report preserves the protocol, identities, timing, hashes, metrics, production diffs, verifier outcomes, cancellation accounting, and limitations.
