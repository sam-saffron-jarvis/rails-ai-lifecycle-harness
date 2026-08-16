# Rails AI lifecycle harness

A Rails developer agent with normal term-llm file/search/edit/shell tools plus one first-class custom tool:

```text
rails_lifecycle_audit()
```

The audit deterministically scans the current Rails repository and returns a structured ownership, callback, deletion, and state-transition graph. The agent pairs it with a neutral transitive-closure ledger: every observable requirement and relevant reachable edge must have repository evidence, patch evidence, and focused test evidence before completion.

This is **harness augmentation**, not a model-only benchmark. Its effective context and tooling differ from the public Rails benchmark.

## Latest runway-aware result

The latest focused experiment is **6/6 full solves** with `chatgpt:gpt-5.6-sol-max`: three fresh samples each of the two tasks that the prior neutral 30-call batch scored 0/3.

| Task | Latest runway-aware harness | Prior neutral 30-call batch |
|---|---:|---:|
| `ar-erase-account` | **3/3** | 0/3 |
| `av-toc-cache-per-role` | **3/3** | 0/3 |
| **Total** | **6/6** | **0/6** |

The [detailed report](docs/runway-two-tasks-max.md) preserves all six verifier rows, session and Jobs V2 identities, prompts and hashes, timing, turn/tool/token counts, first-production-edit timing, protected restore proof, diffs, and audit selection. All six visible suites and published verifiers passed after protected test restoration.

This result changed **the prompt and runway together**. Compared with the prior neutral batch, the agent prompt was rewritten around early production delivery and task-appropriate audit selection, the LLM-call limit rose from 30 to 100, and the model timeout rose from 600 to 1,800 seconds. The task bodies, published verifiers, source pins, model resolution, max effort, 4,096-token per-call output limit, and grading protocol remained fixed.

The extra runway was operationally necessary: every sample used 41–50 turns, and all three account asks ran for 617–744 seconds. It therefore prevented the old call cap in all six and the old wall timeout in all three account runs. It does **not** follow that runway alone caused 0/6 → 6/6, because the prompt changed at the same time and was adaptively tuned after observing these known-task failures. With `n=3` per task and no ablation, this is neither a causal claim nor a general reliability estimate.

### Prior neutral five-task view

The previous frozen neutral max-effort result remains **3/15 full solves**: [`as-purge-embedded-images` 2/3](docs/as-purge-max-neutral-closure.md) plus [the other four tasks 1/12](docs/other-four-max-neutral-matrix.md). That evidence is not erased or silently combined with the runway-aware batch.

| Task | Published Sol rows | Neutral harness |
|---|---:|---:|
| `as-purge-embedded-images` | 0/3 | **2/3** |
| `sup-log-to-terminal` | 0/3 | **0/3** |
| `ar-erase-account` | 1/3 | **0/3** |
| `as-variant-processed-once` | 2/3 | **1/3** |
| `av-toc-cache-per-role` | 2/3 | **0/3** |
| **Total** | **5/15** | **3/15** |

Those two neutral batches used harness commit `fffb3c88ab4032a3a5c42eb1d3b1347d593b01ae`, neutral system hash `f31f0592…`, `gpt-5.6-sol` at `effort=max`, 30 LLM calls, a 600-second timeout, the same source pins, and the same protected-surface grading protocol. The single other-four full solve was the variant canonicalization fix (`format: :webp` → `format: "webp"`). All three logger samples missed dynamic severity propagation; all three account and all three TOC samples left no production change after protected test restoration.

## How the agent works

For lifecycle-sensitive work, the agent:

1. calls `rails_lifecycle_audit` before editing;
2. verifies the audit against focused repository reads;
3. writes `.term-llm/lifecycle-closure.md`, starting from every entity implied by an observable requirement and following relevant edges to transitive closure;
4. blocks production edits while relevant rows are missing or unresolved;
5. maps every requirement to persisted/rendered code and focused evidence;
6. runs a final audit, inspects the diff and status, and runs the visible suite.

The scanner reads application source under `app/models`, `app/jobs`, `app/controllers`, `lib/rails_ext`, and database migrations/schema. It deliberately excludes tests, gems, evaluator files, task metadata, and solution artifacts. It emits repository facts and Rails lifecycle semantics, not an exact patch.

Example fact:

```json
{
  "source_symbol": "Leaf::Editable",
  "kind": "declaration",
  "owns_or_association": "has_many edits",
  "dependent_mode": "delete_all",
  "deletion_mechanism": "direct SQL deletion of associated records",
  "callbacks_expected": "no",
  "file": "app/models/leaf/editable.rb",
  "line": 8
}
```

## Reproduce a sample

Requirements:

- [`term-llm`](https://github.com/SamSaffron/term-llm) configured with ChatGPT access
- `git`, `mise`, and Ruby 3.4.7
- `sudo` permission to create the temporary `/app` verifier symlink
- Linux or a compatible shell environment

```bash
git clone https://github.com/sam-saffron-jarvis/rails-ai-lifecycle-harness.git
cd rails-ai-lifecycle-harness
PROVIDER='chatgpt:gpt-5.6-sol-max' bin/run-eval as-purge-embedded-images
```

The runner pins:

- `rails/ai-evals` at `8b4cab9165fc7878e4a2203f0966e45a1608cd09`
- Basecamp Writebook at `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`)
- 30 LLM calls, 4,096 output tokens per call, and a 600-second model timeout by default

To reproduce the latest runway-aware configuration rather than the default neutral budget:

```bash
PROVIDER='chatgpt:gpt-5.6-sol-max' MAX_TURNS=100 ASK_TIMEOUT_SECONDS=1800 \
  bin/run-eval ar-erase-account
```

`MAX_OUTPUT_TOKENS` remained at its 4,096 default.

It creates a fresh ignored workspace, freezes agent/tool hashes before inference, invokes the exact post-front-matter benchmark body as the sole user question, and exposes neither verifier nor solution to the model. After preserving the solver diff, it restores `test/`, `bin/`, and `config/environments/test.rb` from the baseline before running the visible suite and published verifier.

The runner's default provider remains `chatgpt:gpt-5.6-sol-xhigh`; specify `PROVIDER` explicitly when reproducing the latest max-effort configuration. A non-green published verifier is a valid sample and makes `bin/run-eval` exit nonzero.

## Use it on your Rails application

```bash
cd /path/to/rails-app
term-llm ask \
  --agent /path/to/rails-ai-lifecycle-harness/agents/rails-lifecycle-developer \
  "Fix the lifecycle bug described here..."
```

Add `--yolo` only in a disposable workspace when you deliberately want unattended execution.

Generate the standalone audit artifact with:

```bash
bin/build-audit /path/to/rails-app
```

It writes:

```text
/path/to/rails-app/.term-llm/rails-lifecycle-audit.md
/path/to/rails-app/.term-llm/rails-lifecycle-audit.json
```

## Historical experiments

Earlier work is retained as provenance, not silently folded into the current headline:

- [Runway-aware account/TOC experiment](docs/runway-two-tasks-max.md): **6/6**, with both prompt and runway changed together after observing the known-task failures; not a controlled attribution experiment.
- [Original five-task xhigh matrix](docs/sol-original-failures-matrix.md): **4/15** full solves. It used an older system prompt and `effort=xhigh`; it is not directly interchangeable with the latest runway-aware result.
- [Prompt-tuned max-effort `as-purge` follow-up](docs/as-purge-max-prompt-tuned.md): **2/3**, but effort and prompt changed together.
- [Neutral `as-purge` correction](docs/as-purge-max-neutral-closure.md): **2/3** after answer-shaped examples were removed; the aborted answer-shaped runs are explicitly unscored.
- [Initial post-hoc experiments](docs/experiment-results.md): included a one-off `as-purge` full pass and resource-assisted controls. One good sample was not reliability.
- [First held-out account-erasure run](docs/heldout-ar-erase-account.md): 4/5 tests before a deliberately post-hoc process correction produced a later 5/5. The corrected run is not a clean held-out score.

There was no literally universal failure in the August 2026 public table. `as-purge-embedded-images` was the hardest at 1/24 successful runs: seven models scored 0/3 and Muse scored 1/3.

## Caveats

- The lifecycle resource and closure process were designed after examining this failure class and then adaptively revised. Broader held-out validation is still needed.
- Three samples per task are too few for a reliability estimate; model runs are stochastic.
- The public benchmark and this harness differ in system context, tools, effort, step semantics, time budget, orchestration, and environment reconstruction. Matching task bodies and verifiers do not erase those confounders.
- The static Ruby scanner is intentionally simple; metaprogrammed or dynamically declared associations may be missed.
- Rails semantics in the bundled reference are pinned to the benchmark's Rails `8.2.0.alpha` source.
- `bin/run-eval` uses unattended execution in a disposable workspace. Do not point it at work you cannot discard.
- The verifier expects `/app`; the runner refuses to replace an existing path.

## Repository layout

```text
agents/     developer agent and bundled Ruby custom lifecycle tool
bin/        audit builder and reproducible eval/matrix runners
resources/  Ruby scanner, Rails reference, and process schema
docs/       experiment reports and provenance
```

## License

MIT
