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

A later [single-ask subagent experiment](docs/single-ask-subagents-as-purge.md) is **invalid and unscored**. It correctly made one top-level parent ask per sample, but a generic child-model resolution bug caused repeated spawn attempts and wrong child models; the exact three runs were retained and not retried. Their diagnostic verifier outcome was 0/3 full solves. This does not alter the corrected **8/15** result above.

This is **harness augmentation**, not a model-only benchmark. Relative to the earlier neutral runs, the prompt and runway changed together, and the prompt was adaptively tuned after observing these known-task failures. There is no ablation. The result is descriptive—not a causal claim, general reliability estimate, corrected public benchmark score, or leaderboard claim.

## Current prompt architecture

Ordinary use is one parent invocation. `rails-lifecycle-developer` owns implementation and verification and synchronously orchestrates two project-bundled child roles in order:

1. `rails-state-analyst` inspects persisted states, ownership, lifecycle timing, and counterexamples, then writes `.term-llm/state-analysis.md` without changing production or tests;
2. `rails-red-test-author` reads that shared artifact, writes focused tests only under `test/`, and proves a meaningful baseline-red signal;
3. the parent validates both boundaries, implements the production fix, makes the focused tests green, runs the visible suite, and reconciles the final diff.

The parent has `spawn_agent`; the two allowed child definitions are bundled under `agents/rails-lifecycle-developer/subagents/`. They are not external runner phases. The deterministic `rails_lifecycle_audit` remains available to the analyst and parent for lifecycle-sensitive work.

The deterministic lifecycle tool remains available as:

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

It creates a fresh ignored workspace, freezes agent/tool hashes before inference, sends the exact post-front-matter benchmark body as the sole user question, and exposes neither verifier nor solution to the model. Because benchmark target apps do not run the one-time global installer, the runner copies only the two bundled child definitions into that app's temporary `term-llm-agents/` registry before the ask, then removes the registry afterward. This staging lets the parent's `spawn_agent` resolve project-local children; it does **not** call analysis, test, or implementation model phases externally. After preserving `solver.diff`, the runner restores `test/`, `bin/`, and `config/environments/test.rb` from baseline before running the visible suite and published verifier.

The script's defaults remain a smaller general-purpose budget and `chatgpt:gpt-5.6-sol-xhigh`; specify all four environment variables above to reproduce the current matrix. A non-green verifier is a valid sample and makes `bin/run-eval` exit nonzero. Do not retry it merely to improve the score.

## Use it on your Rails application

Install the parent and both bundled child definitions once:

```bash
cd /path/to/rails-ai-lifecycle-harness
bin/install-agents
```

Then ordinary use from a Rails repository is exactly one parent ask:

```bash
cd /path/to/rails-app
term-llm ask --agent rails-lifecycle-developer \
  "Fix the lifecycle bug described here..."
```

The parent invokes both child roles synchronously in the same workspace, then implements and verifies itself. There is no external three-call pipeline. Add `--yolo` only in a disposable workspace when you deliberately want unattended execution.

The August 2026 experiment found a term-llm child-model resolution defect that caused parents to probe model names rather than honor the configured mapping. See the [invalid run report](docs/single-ask-subagents-as-purge.md); do not treat those samples as evidence that the command above currently guarantees exact child-model compliance.

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
