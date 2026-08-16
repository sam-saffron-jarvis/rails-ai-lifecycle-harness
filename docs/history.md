# Experiment history

The primary current result is the [corrected runway-aware five-task matrix](corrected-runway-five-task-matrix.md): **8/15 full solves** across five tasks, three samples each, with 100 calls and a 1,800-second model timeout.

This page keeps the chronology concise. Older detailed reports remain intact as provenance; their results use different prompts, budgets, effort settings, controls, or experimental status and must not be silently pooled with the current matrix.

## Chronology

1. [Initial lifecycle-harness experiments](experiment-results.md) — early post-hoc work, including a one-off `as-purge` pass and resource-assisted controls. Useful for design history, not reliability.
2. [First held-out account-erasure run](heldout-ar-erase-account.md) — 4/5 before a deliberately post-hoc process correction yielded a later 5/5; the corrected run was not a clean held-out score.
3. [Original five-task xhigh matrix](sol-original-failures-matrix.md) — **4/15** with an older system prompt and `effort=xhigh`.
4. [Prompt-tuned max-effort purge follow-up](as-purge-max-prompt-tuned.md) — **2/3**, with prompt and effort changed together.
5. [Neutral max-effort purge correction](as-purge-max-neutral-closure.md) — **2/3** after answer-shaped examples were removed; aborted answer-shaped runs were explicitly unscored.
6. [Neutral max-effort other-four matrix](other-four-max-neutral-matrix.md) — **1/12**. Combined with the separately launched neutral purge batch, the historical neutral five-task view was **3/15**.
7. [Runway-aware account/TOC batch](runway-two-tasks-max.md) — **6/6** after prompt and runway changed together; this report remains the detailed source for the first six rows of the current matrix.
8. [Corrected runway-aware five-task matrix](corrected-runway-five-task-matrix.md) — **8/15**, combining that 6/6 batch with nine fresh purge/logger/variant outcomes under the same effective harness and disclosing the separate launch, host interruption, and exact missing-sample resume.

There was no literally universal failure in the August 2026 public table. `as-purge-embedded-images` was the hardest at 1/24 successful public runs: seven models scored 0/3 and Muse scored 1/3.
