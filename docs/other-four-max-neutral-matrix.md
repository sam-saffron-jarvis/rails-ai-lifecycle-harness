# Neutral max-effort matrix: the other four Sol failure tasks

> **Historical experiment.** This report uses the earlier neutral 30-call/600-second protocol. It is provenance, not part of the current [corrected runway-aware five-task matrix](corrected-runway-five-task-matrix.md). See [history](history.md).

Date: 2026-08-16 (Australia/Sydney)

## Result

Three fresh `chatgpt:gpt-5.6-sol-max` samples of each of the four remaining original Sol failure tasks produced **1/12 full solves** under the frozen neutral lifecycle harness at `fffb3c88ab4032a3a5c42eb1d3b1347d593b01ae`.

| Task | Full solves | Verifier scores by replicate |
|---|---:|---|
| `sup-log-to-terminal` | **0/3** | 2/3, 2/3, 2/3 tests |
| `ar-erase-account` | **0/3** | 1/5, 1/5, 1/5 tests |
| `as-variant-processed-once` | **1/3** | 0/5, 5/5, 3/5 tests |
| `av-toc-cache-per-role` | **0/3** | 3/6, 3/6, 3/6 tests |
| **Total** | **1/12** | **26/57 verifier tests** |

These are the **other-four batch**, launched after the separately published `as-purge-embedded-images` neutral batch. Combining the batches gives the latest neutral max-effort five-task view: `as-purge` 2/3 plus these four tasks 1/12, or **3/15 full solves**. Both batches used the same frozen harness files, neutral system hash, model resolution, task source pins, and grading protocol, but they began at different times and are not one concurrent 15-run launch.

This is a small stochastic harness study, not a corrected public benchmark score, a leaderboard claim, or causal evidence. The neutral prompt was adaptively developed after observing failures on a known task, and this harness differs materially from the public benchmark.

## Twelve authoritative samples

Verifier cells are `runs/assertions/failures/errors`. Ask cells are `session status / process exit / solver wall seconds`; exit 1 is the 30-call cap and exit 124 is the 600-second model timeout. Tokens are `input/cache-read/output`.

| Task | Rep | Session | Verifier | Full | Ask | Turns/tools | Tokens | Preserved production diff |
|---|---:|---|---:|---:|---|---:|---:|---|
| `sup-log-to-terminal` | 1 | `20260816-205822-16c9ad55217131f6` | 3/3/1/0 | no | `interrupted` / 0 / 478.976s | 29/51 | 64,682/687,104/20,070 | `script/library_report.rb` |
| `sup-log-to-terminal` | 2 | `20260816-205822-0ce01b5172b03d3d` | 3/3/1/0 | no | `active` / 1 / 462.574s | 29/48 | 79,113/736,768/20,161 | `script/library_report.rb` |
| `sup-log-to-terminal` | 3 | `20260816-205822-46a0490b83e8cef4` | 3/3/1/0 | no | `complete` / 0 / 408.949s | 29/49 | 68,182/584,192/17,485 | `script/library_report.rb` |
| `ar-erase-account` | 1 | `20260816-210633-7fbd28c0d800147f` | 5/27/4/0 | no | `active` / 1 / 599.009s | 29/87 | 91,886/1,444,864/24,484 | none; tests only |
| `ar-erase-account` | 2 | `20260816-210617-52861ad25e42b9e0` | 5/27/4/0 | no | `interrupted` / 124 / 602.009s | 15/92 | 101,630/483,840/21,236 | none; tests only |
| `ar-erase-account` | 3 | `20260816-210523-50464f31bfb0b157` | 5/27/4/0 | no | `interrupted` / 124 / 602.001s | 20/100 | 87,284/822,272/23,165 | none; tests only |
| `as-variant-processed-once` | 1 | `20260816-211647-d28eefd33cbf6385` | 5/0/0/5 | no | `interrupted` / 0 / 511.610s | 29/68 | 84,906/1,275,904/19,851 | `app/models/picture.rb` |
| `as-variant-processed-once` | 2 | `20260816-211633-5e47971c6e0cb7f5` | 5/21/0/0 | **yes** | `interrupted` / 0 / 547.839s | 29/70 | 107,484/1,426,944/20,203 | `app/models/picture.rb` |
| `as-variant-processed-once` | 3 | `20260816-211540-34d46a136f027e7f` | 5/20/2/0 | no | `interrupted` / 0 / 302.731s | 29/69 | 91,689/1,089,024/11,340 | none |
| `av-toc-cache-per-role` | 1 | `20260816-212531-317e236ffadc7419` | 6/33/3/0 | no | `active` / 1 / 543.606s | 29/67 | 90,142/1,474,560/20,642 | none; tests only |
| `av-toc-cache-per-role` | 2 | `20260816-212553-2edf768e4faf9d2d` | 6/33/3/0 | no | `active` / 1 / 508.375s | 29/81 | 83,260/1,195,008/20,220 | none; tests only |
| `av-toc-cache-per-role` | 3 | `20260816-212056-cf900c98a5294c72` | 6/33/3/0 | no | `interrupted` / 0 / 565.608s | 29/79 | 92,502/1,479,680/21,633 | none; tests only |

Totals checked from the twelve rows: **6,133.287 solver-seconds**, 325 LLM turns, 861 tool calls, 1,042,760 input tokens, 12,700,160 cached-input tokens, and 240,490 output tokens. Every visible suite passed with 179 runs, 549 assertions, 0 failures, 0 errors, and 4 skips.

All twelve called `rails_lifecycle_audit` as their first tool and created `.term-llm/lifecycle-closure.md`. Only the three logger samples reached a final audit. The single full solve exhausted the configured call budget before the mandatory final audit; the external runner, not model self-report, preserved and graded its patch.

## Diffs and failure modes

### Logger broadcast: 0/3

Replicates 1 and 3 attached a new stdout logger to `Rails.logger`:

```diff
+Rails.logger.broadcast_to ActiveSupport::Logger.new($stdout, level: :info)
```

Replicate 2 constructed a separate `ActiveSupport::BroadcastLogger` around `Rails.logger` and a stdout logger, then sent report messages through it. All three made normal output appear in both destinations, but the stdout logger retained its own permissive level. When the verifier raised `Rails.logger.level`, all four progress lines still reached stdout instead of only the warning. Each passed 2/3 tests and failed the same dynamic-severity case.

### Account erasure: 0/3

No replicate left a production change. All spent their edit budget on protected test files; the runner removed those changes before grading. Replicate 1 hit the 30-call cap just as it attempted its first production edit, while replicates 2 and 3 timed out before one.

The three restored workspaces therefore had the same 1/5 outcome: normal removal did not erase all owned rows, private-book history/search state remained, the public book retained `Ada Sample` rather than `Deleted author`, and attempting to erase an already deactivated account returned 404 instead of the normal redirect.

### Variant processing: 1/3

Replicate 2 found the canonicalization bug:

```diff
-format: :webp
+format: "webp"
```

That made the upload-time and read-time Active Storage transformation identities match and passed all five tests with 21 assertions.

Replicate 1 only reordered transformation keys. That created a noncanonical variation identity and the verifier stopped at fixture setup with five foreign-key errors involving `active_storage_variant_records`. Replicate 3 made no production edit; reading processed the image once more and left two derived files, failing 2/5 tests.

### Per-role TOC cache: 0/3

No replicate left a production change. Each wrote extensive tests, but those were on the protected surface and were restored away before grading. Each baseline production workspace passed the three invariant/layout cases and failed the same three role-isolation cases: a reader could receive editor controls, an editor could miss controls after a reader primed the cache, and edit rights not derived from an access-level row could miss controls.

## Isolation and validation

- Exact matrix root: `.matrix/other-four-max-neutral-20260816T105817Z` (ignored local storage).
- Exact Jobs V2 identities:
  - `job_jC1WNsWZqGgM` / `run_7MoidTUFhB_E`
  - `job_1t9obJPsnw7N` / `run__gVYWEMVa16B`
  - `job_U7jdbqqImd8_` / `run_flayqRE7lu-v`
- All three authoritative program runs started concurrently at 20:58:17 AEST and succeeded at the job layer without replacement: replicate 3 at 21:30:32, replicate 2 at 21:34:33, and replicate 1 at 21:34:45 AEST.
- Each worker ran exactly `sup-log-to-terminal`, `ar-erase-account`, `as-variant-processed-once`, and `av-toc-cache-per-role`, sequentially, once. No non-green result was rerun, excluded, or replaced.
- All twelve session records resolve the requested `chatgpt:gpt-5.6-sol-max` to `gpt-5.6-sol`, `effort=max`, model label `gpt-5.6-sol-max`.
- Every session contains one user turn with the exact post-front-matter benchmark body as the sole question. Prompt SHA-256 values match across all three replicates and the previously validated published bodies:
  - `sup-log-to-terminal`: `4b2087a587f2f35fa4eafdb4fb19d9b913a3fa3c1f9012c3a4bcbfb1de5fef49`
  - `ar-erase-account`: `b323e14692013b979fad55477cd42ae1f859ecec97b30b0c78b80a415e47c2b1`
  - `as-variant-processed-once`: `0cdbafd089661a70618e94fab3ceae627a542d6ce593830c26a1bea0138f12c0`
  - `av-toc-cache-per-role`: `cea0c07d009682348a8130b7cb5356ba43772090ced69dd7b49006ae7b838b97`
- The verifier, solution, task metadata, prior runs, and other workspaces remained outside each application workspace during inference.
- Before grading, the runner preserved `solver.diff`, then restored `test/`, `bin/`, and `config/environments/test.rb` from the baseline. All twelve `grading-protected-status.txt` proofs were empty. Logger-created test directories were explicitly removed by the restore.
- All twelve solver diffs were inspected. The production-file summary above is based on the preserved patches after separating protected test changes; solver-authored tests never affected a score.
- Ask exits were six zero exits, four 30-call-cap exits, and two valid 600-second timeouts. Every sample still produced complete, parseable grading artifacts.

## Frozen inputs

- Harness commit: `fffb3c88ab4032a3a5c42eb1d3b1347d593b01ae`
- Neutral `system.md`: `f31f0592db61b393cab1da1090b24794cd17679550b8db4dc5d4f392dc6ad2a6`
- `agent.yaml`: `5462f43d1c9439e878b7cbbebb1716c4247a29b48fd702a18464405382faa3b6`
- Custom-tool wrapper: `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a`
- Bundled lifecycle graph: `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7`
- Bundled tool reference: `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06`
- `bin/run-eval`: `0b443c40ba37bb1b91b551b357ccf6002def494f78f84e548c3b364cd0c07636`
- Matrix worker: `360adbbbccc585c6d34c6c198f78cc61f5367c258542f80584b200ced4f00b66`
- `rails/ai-evals`: `8b4cab9165fc7878e4a2203f0966e45a1608cd09`
- Basecamp Writebook: `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`)
- term-llm: `v0.0.393` (`cc5d7939`)
- 30 LLM calls, 4,096 output tokens per call, 600-second model cap, skills and dedicated search disabled

## Comparison caveats

The public benchmark used miniswen with one bash tool, provider-default effort, 100 steps, a 30-minute cap, and no network. This run used term-llm's custom Rails agent, normal developer tools, the first-class lifecycle audit, a neutral graph-closure ledger, explicit max effort, 30 LLM calls, and a 10-minute cap in a locally reconstructed environment.

The exact task bodies and published verifiers are the matching axis. System context, tool affordances, effort, step semantics, time budget, orchestration, and environment reconstruction are confounders. With only three stochastic samples per task—and adaptive prompt development on known failures—the result supports no causal, reliability, or leaderboard claim beyond this exact effective harness.

Raw sessions, caches, workspaces, and verifier artifacts remain in ignored local `.matrix/` storage and are not committed.
