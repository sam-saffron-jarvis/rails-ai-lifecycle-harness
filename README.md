# Rails AI lifecycle harness

A Rails developer agent with normal term-llm file/search/edit/shell tools plus one first-class custom tool:

```text
rails_lifecycle_audit()
```

The tool deterministically scans the current Rails repository and returns a structured ownership/callback/deletion graph together with concise Rails lifecycle semantics. It produced a **5/5 verifier pass** for `as-purge-embedded-images` in the original post-hoc sample, but a later preregistered three-sample matrix scored **0/3** on that task. One good sample was not reliability.

The agent:

1. calls the lifecycle audit tool when the task involves deletion, cleanup, ownership, attachments, callbacks, transactions, or enqueue timing;
2. uses normal `read_file`, `write_file`, `edit_file`, `glob`, `grep`, and `shell` tools to inspect, implement, and test;
3. keeps a requirements ledger so every explicit observable outcome is mapped to its real persisted/rendered path and focused evidence.

This is **harness augmentation**, not a corrected model-only benchmark score. The effective context differs from the published Rails benchmark.

## Full original-failures matrix

Fifteen fresh `chatgpt:gpt-5.6-sol-xhigh` samples—three for each of Sol's five original published failure-task rows—produced **4/15 full solves**, versus **5/15** in the published rows:

| Task | Published Sol | Lifecycle harness |
|---|---:|---:|
| `as-purge-embedded-images` | 0/3 | **0/3** |
| `sup-log-to-terminal` | 0/3 | **0/3** |
| `ar-erase-account` | 1/3 | **2/3** |
| `as-variant-processed-once` | 2/3 | **1/3** |
| `av-toc-cache-per-role` | 2/3 | **1/3** |

The full [matrix report](docs/sol-original-failures-matrix.md) includes all 15 verifier outcomes, latency/session/tool/token metrics, audit and first-edit timing, production diffs, protected-restore evidence, failure modes, frozen hashes, and comparison confounders. Same task bodies and published verifiers; materially different effective harness. It is a harness study, not a leaderboard result.

## Reproduce the result

Requirements:

- [`term-llm`](https://github.com/SamSaffron/term-llm) configured with ChatGPT access
- `git`, `mise`, and Ruby 3.4.7
- `sudo` permission to create the temporary `/app` verifier symlink
- Linux or a compatible shell environment

```bash
git clone https://github.com/sam-saffron-jarvis/rails-ai-lifecycle-harness.git
cd rails-ai-lifecycle-harness
bin/run-eval as-purge-embedded-images
```

The runner defaults to `chatgpt:gpt-5.6-sol-xhigh`. Override it to compare another configured provider/model:

```bash
PROVIDER='ollama:qwen38-27b-fixed-v22-t10:latest' bin/run-eval as-purge-embedded-images
```

It pins the source inputs to:

- `rails/ai-evals` at `8b4cab9165fc7878e4a2203f0966e45a1608cd09`
- Basecamp Writebook at `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`)
- `chatgpt:gpt-5.6-sol-xhigh`
- 30 turns and 4,096 output tokens per call

It clones into ignored `.cache/`, creates a fresh workspace under `.runs/`, freezes agent/tool hashes before inference, invokes the benchmark body as the sole question, and exposes neither the verifier nor solution to the model. After preserving the solver diff, it restores `test/`, `bin/`, and `config/environments/test.rb` from the pre-agent snapshot before running the visible suite and published verifier, matching the benchmark's protected-surface grading protocol.

The full-solve sample produced this production patch:

```diff
-has_many :edits, dependent: :delete_all
+has_many :edits, dependent: :destroy
```

```diff
-has_many_attached :uploads, dependent: :destroy
+has_many_attached :uploads, dependent: :purge_later
```

The full-solve sample's verifier result was:

```text
5 runs, 28 assertions, 0 failures, 0 errors, 0 skips
```

An independent end-to-end packaging smoke with the same frozen files scored **4/5**, making the stochasticity rather less theoretical. To collect three fresh samples:

```bash
for run in 1 2 3; do
  bin/run-eval as-purge-embedded-images || true
done
```

Each invocation creates a fresh application workspace and preserves its artifacts under `.runs/`. A non-green published verifier makes `bin/run-eval` exit nonzero.

## Use it on your own Rails application

The benchmark runner is convenient, but the agent itself needs no preflight wrapper or attached file:

```bash
cd /path/to/rails-app
term-llm ask \
  --agent /path/to/rails-ai-lifecycle-harness/agents/rails-lifecycle-developer \
  "Fix the lifecycle bug described here..."
```

The model calls `rails_lifecycle_audit` as a normal tool, then uses the built-in developer tools. Add `--yolo` only in a disposable workspace when you deliberately want unattended execution.

Generate the same audit as a standalone Markdown artifact when useful:

```bash
bin/build-audit /path/to/rails-app
```

This writes:

```text
/path/to/rails-app/.term-llm/rails-lifecycle-audit.md
/path/to/rails-app/.term-llm/rails-lifecycle-audit.json
```

The scanner is deterministic and uses only application source under:

- `app/models`
- `app/jobs`
- `app/controllers`
- `lib/rails_ext`
- `db/migrate` and `db/schema.rb` when present

It deliberately excludes tests, gems, evaluator files, task metadata, and solution artifacts.

## Experiment results

The frozen generic resource was used unchanged for three post-hoc tasks:

| Task | Without lifecycle resource | With lifecycle resource |
|---|---:|---:|
| `as-purge-embedded-images` | Sol xhigh 0/3 full; best 4/5 | **5/5** |
| `ar-archive-book-access` | Not part of the matched Sol hard control | **6/6** |
| `aj-enqueue-after-commit` | Not part of the matched Sol hard control | **8/8** |

The first genuinely held-out task was the next-hardest public eval, `ar-erase-account`. With the same frozen resource unchanged it reached **4/5 tests and 47 assertions with one failure**, not a full solve. The lifecycle graph captured indirect ownership and callback hazards, but Sol invented an unused `creator_name` method instead of updating the rendered `Book#author` byline. See [the held-out report](docs/heldout-ar-erase-account.md).

A deliberately post-hoc process correction added a requirements ledger, call-site validation for every new API, and permission to add focused tests for uncovered explicit requirements. With resource facts unchanged, the next run passed **5/5 tests and 51 assertions**. That demonstrates the harness mistake was fixable; it is not a clean held-out score. The recommended custom-tool agent includes this requirements-ledger process.

The three original resource-assisted samples fully passed their published verifier; the held-out sample did not. See [the full experiment report](docs/experiment-results.md) for hashes, isolation details, diffs, limitations, and provenance.

There was no literally universal failure in the August 2026 public table. `as-purge-embedded-images` was the hardest at **1/24** successful runs: seven models scored 0/3 and Muse scored 1/3.

## What the scanner adds

The JSON packet records facts such as:

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

It does not emit an exact patch. The model still has to connect repository facts to Rails semantics and implement the repair.

## Caveats

- This resource was designed after examining a lifecycle failure class. It is post-hoc and needs broader held-out validation.
- The static Ruby scanner is intentionally simple. Metaprogrammed or dynamically declared associations may be missed.
- Rails semantics in the reference are pinned to the benchmark's Rails `8.2.0.alpha` source. Review them before applying the resource to another Rails version.
- `bin/run-eval` uses `--yolo` inside a disposable benchmark workspace. Do not point it at a repository containing work you cannot discard.
- The verifier expects `/app`; the runner refuses to replace an existing path.

## Repository layout

```text
agents/     normal developer agent and bundled Ruby custom lifecycle tool
bin/        Ruby audit builder and reproducible eval runner
resources/  Ruby scanner, Rails reference, process schema
docs/       full experiment reports
```

## License

MIT
