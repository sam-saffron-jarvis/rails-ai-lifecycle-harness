# Single-ask subagent `as-purge` experiment

## Result: invalid orchestration; 0/3 observed verifier passes

Three exact Jobs V2 samples were launched from harness commit [`2204d06e0f2b3d530d63f0bac0572ffe1c0d22bc`](https://github.com/sam-saffron-jarvis/rails-ai-lifecycle-harness/commit/2204d06e0f2b3d530d63f0bac0572ffe1c0d22bc). Each runner made one top-level `term-llm ask` with `rails-lifecycle-developer`; the parent was supposed to synchronously call `rails-state-analyst` once, then `rails-red-test-author` once, before implementing and verifying.

The runner did make exactly one parent ask per sample, but a generic subagent model-resolution bug invalidated the experiment. `spawn_agent` exposed a required `model` argument instead of transparently applying the parent agent's `spawn.agent_models` mapping. Each parent guessed model names repeatedly until one happened to work. The successful children therefore ran on `gpt-5.4` in replicates 1–2 and `mistral-large-latest` in replicate 3—not the frozen `chatgpt:gpt-5.6-sol-max` child configuration—and the parents made 17, 34, and 35 child calls rather than exactly two.

No run was retried or replaced. These three samples are **invalid and unscored** as a test of the intended architecture. For completeness, their observed production patches also scored **0/3 full solves**: all visible suites passed after protected restoration, while each published verifier failed one of five tests.

The earlier external staged pipeline at commit [`244428f`](https://github.com/sam-saffron-jarvis/rails-ai-lifecycle-harness/commit/244428f) was rejected, cancelled, and is also unscored. It has not been substituted into this result.

## Frozen protocol and exact Jobs V2 runs

- Matrix root: `.matrix/single-ask-subagents-as-purge-20260816T231523Z`
- Task: `as-purge-embedded-images` only
- Parent request: `chatgpt:gpt-5.6-sol-max`
- Parent limits: 100 turns, 3,600-second ask timeout, 4,096 output tokens per call
- Task prompt SHA-256: `28d9deeb24ad0ac96ef154ff473fd2de9ece11705ddf56b97f4a4f1e82f0fe10` in all three samples
- `rails/ai-evals`: `8b4cab9165fc7878e4a2203f0966e45a1608cd09`
- Basecamp Writebook: `e5563e260434c98425f3de80d45fddf0fdb76012`
- No retries, replacements, or score-driven exclusions

| Rep | Job / exact run | Jobs status | AEST interval | Job wall | Runner result |
|---:|---|---|---|---:|---|
| 1 | `job_kjSQHpuJdPbH` / `run_6Lsykkxgahvz` | succeeded, attempt 1, natural completion | 09:15:23–09:28:14 | 771.169s | evaluator exit 1 |
| 2 | `job_8oyMvIdDOHVH` / `run_Nv7Cy1XAhQQx` | succeeded, attempt 1, natural completion | 09:15:23–09:37:42 | 1,339.184s | evaluator exit 1 |
| 3 | `job_CZLBjEJlHB-w` / `run_WH43Rymnd7Kk` | succeeded, attempt 1, natural completion | 09:15:23–10:07:53 | 3,150.252s | evaluator exit 1 |

A Jobs V2 status of `succeeded` means the worker completed naturally. The worker deliberately exits zero after recording `bin/run-eval`'s non-green evaluator result in its JSONL and stdout.

## Parent ask validation

The runner source contains one `term-llm ask` invocation. The three isolated session databases independently confirm one root session, one root user turn, and all child sessions linked through `parent_id` to that root.

| Rep | Parent session | Resolved parent model | Ask wall | LLM turns / tools | Tokens: input / cache read / output |
|---:|---|---|---:|---:|---:|
| 1 | `20260817-091531-29001d8127649f56` | `gpt-5.6-sol-max`, effort `max` | 753.836s | 27 / 38 | 61,192 / 257,536 / 11,088 |
| 2 | `20260817-091531-0eb90d05335e314b` | `gpt-5.6-sol-max`, effort `max` | 1,321.870s | 59 / 85 | 125,678 / 1,559,040 / 33,421 |
| 3 | `20260817-091529-8d4bb5e1abda6648` | `gpt-5.6-sol-max`, effort `max` | 3,134.882s | 67 / 105 | 134,876 / 1,386,496 / 25,874 |

The parent architecture was therefore single-ask at the runner boundary. It was not compliant at the child-orchestration boundary.

## Child orchestration and compliance

All successful children shared the exact parent workspace and were linked to the parent session. In every sample, all analyst attempts preceded all test-author attempts, so role ordering was preserved. Everything else that depended on exactly one correctly configured child of each type failed.

| Rep | Analyst calls | Test-author calls | Completed children | Intended child model | Actual completed model | Exactly one each? |
|---:|---:|---:|---|---|---|---|
| 1 | 16 | 1 | 1 analyst, 1 test author | `chatgpt:gpt-5.6-sol-max` | `gpt-5.4`, effort unrecorded | no |
| 2 | 32 | 2 | 1 analyst, 2 test authors | `chatgpt:gpt-5.6-sol-max` | `gpt-5.4`, effort unrecorded | no |
| 3 | 32 | 3 | 1 analyst, 3 test authors | `chatgpt:gpt-5.6-sol-max` | `mistral-large-latest`, effort unrecorded | no |

The remaining child sessions ended in `error` with zero model turns and zero tokens: 14 in replicate 1, 30 in replicate 2, and 25 in replicate 3. Failures included unsupported aliases, missing credentials, and provider authentication errors. The raw stream marked the enclosing tool call complete because `spawn_agent` returned a structured execution error; the child session database is authoritative for success versus error.

### Completed child sessions

| Rep | Child session | Role | Seconds | LLM / tools | Tokens: input / cache / output | User prompt SHA-256 | System SHA-256 |
|---:|---|---|---:|---:|---:|---|---|
| 1 | `20260817-091928-8b01559a5924abda` | analyst | 174.280 | 21 / 76 | 53,834 / 461,824 / 7,692 | `0a5d6c17e18e45a91e907d3510094ff5e7a7910d960fdb1bab83babae40bec93` | `f6c106ba7bab40e35e5bfcb31e5642476e48bfdd78549e12b0635e9b3e1beb19` |
| 1 | `20260817-092241-5dfbefc6da025226` | test author | 223.739 | 27 / 45 | 46,079 / 642,560 / 9,321 | `d3a9f5f9a27244d157149f10799d6da75cce192ecc79bf49bb247bc43323cdb2` | `a8eb64a6642ee461c637b6665ff9683b130630bf58b34fac29ed685ea653603e` |
| 2 | `20260817-092453-2016f1124716ab78` | analyst | 140.545 | 14 / 54 | 50,648 / 303,616 / 6,600 | `478cec5d6d5f661260bb1a5a35ce5251c0677b66007ea9ad6d46e3e13046ca08` | `c45cc68bdc63e14b433796a4559041423c07960b63f79a3faea2e7c612cfe424` |
| 2 | `20260817-092737-e6ad61617ab4ef69` | test author | 117.772 | 14 / 32 | 38,574 / 270,336 / 4,969 | `c05269406d0780b7d9bcac30a43d8882627f0852128ff5e04081722436134b16` | `e457bcfc5cb335f92fee0046012563f8ca70dd99849e8704a04d107dddd1919d` |
| 2 | `20260817-093310-7afcc74c14a8ae40` | test correction | 26.923 | 6 / 6 | 15,219 / 44,032 / 644 | `08822fb921a00e5df2f7e4382c065df762584afcf28be6f5fe3c66993200ca02` | `e457bcfc5cb335f92fee0046012563f8ca70dd99849e8704a04d107dddd1919d` |
| 3 | `20260817-094146-83219a7b23dd2f83` | analyst | 47.903 | 4 / 16 | 36,275 / 0 / 1,830 | `c39311aa2db038ccd40b7b6f6c77b080edde9b880e0e39d97c2fbe9388f3d20e` | `29d902f0e4e619c0714375d4309e5bc349fb635ab2b23d919c5d491f7e3f1a58` |
| 3 | `20260817-094248-3a40759f52743b70` | test author | 782.915 | 54 / 80 | 1,000,885 / 452,752 / 14,405 | `e59aa0a12fa2f446a327ee0461045771fda23d17730343cc78d907ca86a02147` | `a3c9478b2347fa1f1daafef5723fe914fa00b9aaf754c4906bfb44a1ccade4d8` |
| 3 | `20260817-095623-ff4a3223112d60ed` | test correction | 282.904 | 17 / 17 | 275,227 / 38,816 / 11,870 | `d60fb8978a2b40057ef8309ed660800fb385ffa2d2b02a7a477e74bc579e2f0c` | `a3c9478b2347fa1f1daafef5723fe914fa00b9aaf754c4906bfb44a1ccade4d8` |
| 3 | `20260817-100147-0313354060173f38` | test correction | 166.542 | 15 / 15 | 131,354 / 49,920 / 4,430 | `43f37f78ca9034c1281cd06b4d8a175a2632b937ada9221493c5a3fc18d05f39` | `a3c9478b2347fa1f1daafef5723fe914fa00b9aaf754c4906bfb44a1ccade4d8` |

## State artifacts and revision coverage

Each completed analyst wrote `.term-llm/state-analysis.md` in the shared workspace. The artifacts were then consumed by the parent and test author, proving workspace sharing. Their coverage was uneven:

| Rep | Artifact SHA-256 | State/revision assessment |
|---:|---|---|
| 1 | `c460ce68556544e090d25b2274fda250d405b7e501f343a099d132ee0ce26a5d` | Strong repository-grounded ownership chain; explicitly covered direct destruction, UI trash semantics, historical revisions, shared blobs, upload/fetch URLs, deferred purge completion, and rollback risk. |
| 2 | `eab2704a723a35298618396d06b638d96f6f5d2cf5ac677439ed77e80087d30c` | Strong revision and trash coverage; mapped current and historical page owners, upload/fetch, job timing, transaction behavior, and shared-blob risk. |
| 3 | `a2461e0e137f0d31302b78b5c194e08f32e1add2ba370afa07d8f91d2b365026` | Partial and materially inaccurate in places: it described a `Leaf::Editable`/rich-text path rather than the actual page/markdown ownership chain, mentioned historical revisions only as an unsupported candidate, and omitted trash/shared-blob coverage. |

The frozen analyst definition hash was `923b44fbb0517922b4c3c25fc6cb7fbb46fad3af8c3dd690bf6a4fe06bde664a`; its agent YAML hash was `6f4455e0658990e8e2027096d192e9a253272843ee9f99b7c10b1e3c4221e50d`.

## Test-author boundary and baseline-red evidence

All completed test-author children stayed within `test/`; no child changed production. The parent made production edits only after at least one analyst and one test-author session had completed. However, only replicate 2 produced a baseline-red historical-revision test.

| Rep | Test-author behavior | Baseline-red evidence | Revision test? | Compliance |
|---:|---|---|---|---|
| 1 | Added one lifecycle test file; production remained untouched. | 4 runs, 21 assertions, 1 meaningful failure; parent patch then made 4/22 green. | no—covered simple deletion and shared blob, despite the analyst's revision warning | boundary pass; coverage fail |
| 2 | Added/updated controller tests only; a second child corrected a bad old-URL assertion. | Initial baseline: 15 runs, 84 assertions, 2 meaningful attachment-retention failures, including historical revisions. | yes—current and historical page owners | boundary and revision coverage pass; exactly-once fail |
| 3 | Added one model/integration test file, then used two correction children to remove invalid/skipped cases. | Initial 6/26 had 2 failures and 1 skip; corrected baseline reached 3/17 with 1 meaningful failure before production. | no—covered direct destruction, rollback, and unrelated upload/fetch | boundary pass; initial-red quality, revision, and exactly-once fail |

Before grading, the runner preserved `solver.diff`, restored `test/`, `bin/`, and `config/environments/test.rb`, and confirmed an empty `grading-protected-status.txt` in all three workspaces.

## Parent production behavior and verifier outcomes

| Rep | Production patch | Parent-visible verification before restore | Restored visible suite | Published verifier |
|---:|---|---|---|---|
| 1 | Changed markdown uploads from `dependent: :destroy` to `:purge_later`. | Focused 4/22 green; full 181/562 green with 4 skips. | 179 runs, 549 assertions, green, 4 skips | 4/5; failed historical-revision image cleanup |
| 2 | Added purge callbacks across current/history owners and changed attachment dependency to `:purge_later`. | Focused 15/92 green; full 180/574 green with 4 skips. | 179 runs, 549 assertions, green, 4 skips | 4/5; wrongly purged on trash, where the page still exists |
| 3 | Changed markdown uploads from `dependent: :destroy` to `:purge_later`. | Focused 5/28 green; full 182/568 green with 4 skips. | 179 runs, 549 assertions, green, 4 skips | 4/5; failed historical-revision image cleanup |

Observed verifier arithmetic: **12/15 tests, 0/3 full solves**. Because the child architecture was not the requested frozen architecture, these are diagnostic outcomes, not scored benchmark samples.

The verifier was visible only after inference. The task prompt was the sole root user question, and neither verifier nor solution was in the application workspace during the ask. `/app` grading was serialized, each run created and removed its temporary symlink, and all three produced a verifier result rather than `SKIPPED_APP_EXISTS`.

## Artifact integrity

Frozen architecture hashes recorded before inference:

- parent `agent.yaml`: `73f7dd573358b14b0881f14741d8456336eab72435eeee66d8ca7bbedcb7f627`
- parent `system.md`: `eff1fd1643e0d159a55479afa394af42fefef74a4f34aec3c9c84eaaec05d38f`
- red-test agent YAML: `854c1049ac5a241c143f49cc6fda7d1e8cce9bd94c8a7ae805308d11eab6a218`
- red-test system: `ec36a77511d65ea194c8675b9ef4aa3341bef5991c2eab8fe42a12a86d281c91`
- lifecycle graph: `89d26e24e2ef480c2696aac08ab737cf35f0a2d25c7f5328b08bb0aa1ac95ce7`
- lifecycle reference: `736a37c33b48c3f9efb1770dfaee4d4fdf4bd70fb8381d30bdd66309ba1d2b06`
- custom-tool wrapper: `2ef14b6def3016402f008adbffec85b37f4dbb6672494bb5817e575f2ea2504a`
- `bin/run-eval`: `5ec5316ab954ebfb7b09a7f7631dffe0fd8bf1a32a906b9cfa5b2d991bf4c9e6`

Per-replicate raw/session/database hashes:

| Rep | `raw.jsonl` | `session.json` | `sessions.db` | `solver.diff` |
|---:|---|---|---|---|
| 1 | `bb056b9277716902e8b11133735ac2c71899b8a7deeb1cd0578d53be5e09302c` | `1a3bb5684f3a543a76f7617c341847777784c987a7df2de4045a15f834b4650a` | `7b3a55b9864b9f93316a1967f4a28e344b7fef4656a8fd07cc2f7adbbdef98a1` | `086a03444ddc0babf3ee2bd74f4067a3a7731f4151accc6279a3730bd11abef7` |
| 2 | `0ffc6547c026e6f5f4c7680f90272acd8621a313c8f78c4548c02ae47cfe40a4` | `5b97d0a97691f8c504d704335690e8162bd4559b40f2ace846fd2595a3f49ed2` | `fc672cfc58effa3259fcb4e10830a967f1fc76ad7cab136d4cb0d101b0b8bde3` | `588b38ac3d322d0f34c1e88b6d9623787ffd00c0c346fabe85cf34e082e615bd` |
| 3 | `232a2b256b157e8a8e9437162d475076bdcba6e58345b7ecff17af4996039ad8` | `bef47ff13c7453cfe68f37caab8e2979b8e078186b5ffcfce60dbaac18676678` | `e07dac1ee8dbfc1293e71dfa392c5c6b9135d63839e1691f54751c7a9074c2ef` | `086a03444ddc0babf3ee2bd74f4067a3a7731f4151accc6279a3730bd11abef7` |

## Interpretation

This run validates the **single top-level ask** and shared-workspace mechanics, but not the intended two-child experiment. The generic failure is architectural rather than task-specific: configured child model selection was not enforced at the tool boundary, so the parent burned calls probing providers and changed the effective child models. Replicate 3 even inspected configured providers and environment-variable presence while trying to recover. Silently rerunning would hide that failure; these exact runs remain the record.

The corrected five-task **8/15** report remains the primary scored result. This invalid experiment neither replaces nor modifies it.
