# Rails AI lifecycle harness

A reproducible Rails-aware context augmentation that turned `as-purge-embedded-images` from **0/3 with Sol xhigh** into a **5/5 verifier pass**.

The harness does three things before asking the model to edit:

1. scans the current Rails application for associations, attachments, callbacks, deletion calls, transactions, and job enqueue points;
2. combines those repository facts with a compact, versioned Rails lifecycle reference;
3. asks the agent to account for direct, indirect, and historical ownership edges before making a minimal patch.

This is **harness augmentation**, not a corrected model-only benchmark score. The effective context differs from the published Rails benchmark.

## Reproduce the result

Requirements:

- [`term-llm`](https://github.com/SamSaffron/term-llm) configured with ChatGPT access
- `git`, Python 3, `mise`, and Ruby 3.4.7
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

It clones into ignored `.cache/`, creates a fresh workspace under `.runs/`, freezes hashes before inference, invokes the benchmark body as the sole question, and exposes neither the verifier nor solution to the model. The published verifier runs only after the solver exits.

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

Generate the resource without running a benchmark:

```bash
bin/build-audit /path/to/rails-app
```

This writes:

```text
/path/to/rails-app/.term-llm/rails-lifecycle-audit.md
/path/to/rails-app/.term-llm/rails-lifecycle-audit.json
```

Attach the Markdown file to an agent request or adapt the included agent:

```bash
cd /path/to/rails-app
term-llm ask \
  --agent /path/to/rails-ai-lifecycle-harness/agents/sol-xhigh-lifecycle-resource \
  -f .term-llm/rails-lifecycle-audit.md \
  "Fix the lifecycle bug described here..."
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

The first genuinely held-out task was the next-hardest public eval, `ar-erase-account`. With the same frozen resource unchanged it reached **4/5 tests and 47 assertions with one failure**, not a full solve. The lifecycle graph captured indirect ownership and callback hazards but deliberately omitted scalar presentation fields; Sol preserved a public book yet failed to replace its displayed author byline. See [the held-out report](docs/heldout-ar-erase-account.md).

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
agents/     term-llm agent used by the experiment
bin/        audit builder and reproducible eval runner
resources/  deterministic scanner, Rails reference, process schema
docs/       full experiment report
```

## License

MIT
