# Rails lifecycle repair process

Before editing, use the supplied `rails_lifecycle_graph/v1` packet and focused repository inspection to build a compact internal evidence packet matching `required_solver_evidence_schema`.

It must account for:

1. every relevant direct ownership edge;
2. every indirect edge through concerns, joins, delegated or polymorphic records;
3. current and historical/revision ownership;
4. callback behavior on every deletion path, including direct/batch deletion;
5. transaction commit and rollback behavior for jobs/external work;
6. one focused existing test command; and
7. a minimal production patch plan mapping each edit to an observed fact.

Do not infer a patch from the reference alone. Resolve facts to `file:line`, reject missing required sections, then edit promptly, run the focused existing test, run the full visible suite once, inspect diff/status, and stop. Do not create new tests or probes.
