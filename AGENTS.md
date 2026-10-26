# Working on CellExplorer

## Architecture and compatibility

- Follow `development/cellexplorer-2.0-plan.md` and the migration inventory.
- `docs/` is the public documentation website. Keep internal plans, migration
  inventories and contributor guidance in `development/`.
- Put new implementation in the appropriate `+ce` component. Do not add unrelated
  helpers to `calc_CellMetrics` or create another catch-all utilities directory.
- Preserve public functions, MAT variable/filename conventions and custom extension
  packages. Keep legacy forwarding functions for migrated public APIs.
- Moving numerical code must not change its formulas. Separate scientific changes
  from structural changes and validate them against reference results.
- Audit private functions, bundled resources, dynamic lookup, MEX dependencies and
  caller-sensitive functions such as `inputname` before relocating code.
- Treat channel indexing (zero/one based), sample/time units, and session-local cell
  identity as explicit contracts. Never use matching counts as proof of identity.

## Verification

- Run `run('tests/run_tests.m')` in MATLAB, or use `matlab -batch` with that command.
- Test file changes using temporary synthetic data; never overwrite research data
  as part of a test. Failure paths must preserve existing files and unsaved edits.
- Use package-qualified calls inside migrated components. Keep UI and base-workspace
  access out of data, curation and persistence operations.
- Report checks actually run and limitations. GUI smoke checks and full scientific
  pipeline validation are separate from component tests.
