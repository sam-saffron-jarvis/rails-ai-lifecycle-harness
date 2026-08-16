# Rails AI lifecycle harness

A Rails developer-agent harness that adds a deterministic lifecycle audit to normal file, search, edit, and shell tools.

## Current result: 8/15

The corrected runway-aware harness produced **8/15 full solves** with three fresh `chatgpt:gpt-5.6-sol-max` samples on each of five Rails tasks:

| Task | Full solves | Verifier outcomes by replicate |
|---|---:|---|
| `as-purge-embedded-images` | **0/3** | 4/5, 4/5, 4/5 tests |
| `sup-log-to-terminal` | **0/3** | 2/3, 2/3, 2/3 tests |
| `ar-erase-account` | **3/3** | 5/5, 5/5, 5/5 tests |
| `as-variant-processed-once` | **2/3** | 5/5, 5/5, 0/5 tests |
| `av-toc-cache-per-role` | **3/3** | 6/6, 6/6, 6/6 tests |
| **Total** | **8/15** | **61/72 verifier tests** |

Every visible suite passed after protected test restoration: 179 runs, 549 assertions, 0 failures, 0 errors, and 4 skips in each workspace. Every solver session completed naturally; no sample reached the 100-turn or 1,800-second limit.

The [full current report](docs/corrected-runway-five-task-matrix.md) preserves all 15 session rows, exact prompts and hashes, model resolution, limits, timings, turn/tool/token metrics, production diffs, verifier failures, protected-restore proof, Jobs V2 provenance, and the host-interruption resume record.

This is **harness augmentation**, not a model-only benchmark. Relative to the earlier neutral runs, the prompt and runway changed together, and the prompt was adaptively tuned after observing these known-task failures. There is no ablation. The result is descriptive—not a causal claim, general reliability estimate, corrected public benchmark score, or leaderboard claim.

## Current prompt architecture

The agent's objective is the smallest complete production fix. Its process is deliberately runway-aware:

1. turn the request into observable outcomes, including behavior that must remain unchanged;
2. classify the task before selecting tools;
3. call `rails_lifecycle_audit` first for deletion, cleanup, ownership, attachment, callback, transaction, or enqueue-timing work;
4. for other work, trace the actual execution path without calling the audit merely because it exists;
5. inspect the production entry point, downstream consumers, and nearest existing tests narrowly;
6. spend no more than roughly one third of available calls before the first production edit;
7. patch production before writing a regression test, then use focused failures to repair the implementation;
8. preserve a coherent production diff rather than spending the end of the run on more process.

Investigation, notes, and self-authored tests are evidence for a fix; they are not substitutes for one. The prompt also reserves the final third of the call budget for implementation, verification, and repair.

The custom tool is:

```text
rails_lifecycle_audit(focus: "task-derived lifecycle focus")
```

It scans the current Rails repository and returns a structured ownership, callback, attachment, deletion, transaction, and job-lifecycle report plus concise Rails semantics. It reads application source—not tests, evaluator files, task metadata, solutions, or prior runs—and emits repository facts rather than an exact patch.

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

## Reproduce the current protocol

Requirements:

- [`term-llm`](https://github.com/SamSaffron/term-llm) configured with ChatGPT access;
- `git`, `mise`, and Ruby 3.4.7;
- `sudo` permission to create the temporary `/app` verifier symlink;
- Linux or a compatible shell environment.

```bash
git clone https://github.com/sam-saffron-jarvis/rails-ai-lifecycle-harness.git
cd rails-ai-lifecycle-harness

PROVIDER='chatgpt:gpt-5.6-sol-max' \
MAX_TURNS=100 \
ASK_TIMEOUT_SECONDS=1800 \
MAX_OUTPUT_TOKENS=4096 \
  bin/run-eval as-purge-embedded-images
```

Replace the final task with any current matrix task:

```text
as-purge-embedded-images
sup-log-to-terminal
ar-erase-account
as-variant-processed-once
av-toc-cache-per-role
```

The runner pins:

- `rails/ai-evals` at `8b4cab9165fc7878e4a2203f0966e45a1608cd09`;
- Basecamp Writebook at `e5563e260434c98425f3de80d45fddf0fdb76012` (`v1.2.1`);
- 100 LLM calls, 4,096 output tokens per call, and a 1,800-second model timeout when invoked as above.

It creates a fresh ignored workspace, freezes agent/tool hashes before inference, sends the exact post-front-matter benchmark body as the sole user question, and exposes neither verifier nor solution to the model. After preserving `solver.diff`, it restores `test/`, `bin/`, and `config/environments/test.rb` from baseline before running the visible suite and published verifier.

The script's defaults remain a smaller general-purpose budget and `chatgpt:gpt-5.6-sol-xhigh`; specify all four environment variables above to reproduce the current matrix. A non-green verifier is a valid sample and makes `bin/run-eval` exit nonzero. Do not retry it merely to improve the score.

## Use it on your Rails application

```bash
cd /path/to/rails-app
term-llm ask \
  --agent /path/to/rails-ai-lifecycle-harness/agents/rails-lifecycle-developer \
  "Fix the lifecycle bug described here..."
```

Add `--yolo` only in a disposable workspace when you deliberately want unattended execution.

Generate the standalone audit artifacts with:

```bash
bin/build-audit /path/to/rails-app
```

This writes:

```text
/path/to/rails-app/.term-llm/rails-lifecycle-audit.md
/path/to/rails-app/.term-llm/rails-lifecycle-audit.json
```

## Current caveats

- Five known tasks and three stochastic samples per task are too small for a general reliability estimate.
- Prompt design was adaptive. Prompt and runway changed together relative to the old neutral matrix.
- The public benchmark and this harness differ in system context, tools, effort, step semantics, time budget, orchestration, and environment reconstruction.
- The 15 samples were collected in two separately launched batches with identical frozen agent/runner inputs but term-llm patch versions `v0.0.393` and `v0.0.394`.
- One variant verifier encountered fixture foreign-key errors despite the same canonical production fix as two passing samples; it remains scored 0/5.
- The static Ruby scanner is intentionally simple and can miss metaprogrammed or dynamically declared associations.
- Rails semantics in the bundled reference are pinned to the benchmark's Rails `8.2.0.alpha` source.
- The verifier expects `/app`; the runner refuses to replace an existing path.
- `bin/run-eval` uses unattended execution in a disposable workspace. Do not point it at work you cannot discard.

## History

Earlier prompts, budgets, controls, and reports remain available as provenance in [docs/history.md](docs/history.md). They are historical experiments, not rows silently mixed into the current **8/15** result.

## Repository layout

```text
agents/     developer agent and bundled Ruby lifecycle audit tool
bin/        audit builder and reproducible evaluation runners
resources/  Ruby scanner, Rails reference, and process schema
docs/       current report and historical provenance
```

## License

MIT
