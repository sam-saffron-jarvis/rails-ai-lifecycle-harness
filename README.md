# Rails AI lifecycle harness

A Rails developer agent with normal term-llm file/search/edit/shell tools plus one first-class custom tool:

```text
rails_lifecycle_audit()
```

The audit deterministically scans the current Rails repository and returns a structured ownership, callback, deletion, and state-transition graph. The agent pairs it with a neutral transitive-closure ledger: every observable requirement and relevant reachable edge must have repository evidence, patch evidence, and focused test evidence before completion.

This is **harness augmentation**, not a model-only benchmark. Its effective context and tooling differ from the public Rails benchmark.

## Latest neutral max-effort result

The latest five-task view is **3/15 full solves** with `chatgpt:gpt-5.6-sol-max`—three fresh samples for each of Sol's five original published failure-task rows:

| Task | Published Sol rows | Latest neutral harness |
|---|---:|---:|
| `as-purge-embedded-images` | 0/3 | **2/3** |
| `sup-log-to-terminal` | 0/3 | **0/3** |
| `ar-erase-account` | 1/3 | **0/3** |
| `as-variant-processed-once` | 2/3 | **1/3** |
| `av-toc-cache-per-role` | 2/3 | **0/3** |
| **Total** | **5/15** | **3/15** |

The arithmetic combines two batches under the same frozen neutral harness and model resolution:

- [`as-purge-embedded-images`: 2/3](docs/as-purge-max-neutral-closure.md), launched first as a dedicated three-run batch;
- [the other four tasks: 1/12](docs/other-four-max-neutral-matrix.md), launched later as three workers that each ran those four tasks sequentially.

Both batches used harness commit `fffb3c88ab4032a3a5c42eb1d3b1347d593b01ae`, neutral system hash `f31f0592…`, `gpt-5.6-sol` at `effort=max`, the same source pins, and the same protected-surface grading protocol. They had different launch times and are not one concurrent 15-run launch.

The single other-four full solve was the variant canonicalization fix (`format: :webp` → `format: "webp"`). All three logger samples missed dynamic severity propagation; all three account and all three TOC samples left no production change after protected test restoration. The detailed reports preserve every verifier row, session and Jobs V2 identity, timing, token count, diff, prompt hash, restore proof, and failure mode.

This is not a victory lap. The prompt was adaptively developed after observing known failures, `n=3` per task is tiny and stochastic, and the harness differs materially from the public benchmark. The result is neither a causal claim nor a leaderboard correction.

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
- 30 LLM calls and 4,096 output tokens per call

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

Earlier work is retained as provenance, not as the current headline:

- [Original five-task xhigh matrix](docs/sol-original-failures-matrix.md): **4/15** full solves. It used an older system prompt and `effort=xhigh`; it is not directly interchangeable with the latest neutral max result.
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
