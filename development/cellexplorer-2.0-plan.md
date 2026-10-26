# CellExplorer 2.0 restructuring and modernization

Working branch: `CellExplorer-2.0`. Started 2026-10-26.

## Objectives and compatibility

Replace `calc_CellMetrics` as an implementation bucket with components that have
clear responsibilities. Protect scientific results and manual curation, make
noninteractive operation dependable, and make changes independently testable.

Keep the public entry points, existing MAT filenames and variable names, and
custom calculation/plot packages compatible. Introduce MATLAB package functions
incrementally; retain forwarding functions at established public paths. Do not
change scientific formulas as part of a relocation. Do not remove an apparently
unused function without investigating external use.

## Target organization

| Location | Responsibility |
| --- | --- |
| Top-level entry points | Compatible launch/load/process APIs |
| `+ce/+data` | Data contracts, validation, identity and migrations |
| `+ce/+io` | File loading, verified replacement, format adapters |
| `+ce/+metrics` | Numerical metric calculations |
| `+ce/+processing` | Waveforms, features and signal preprocessing |
| `+ce/+pipeline` | Preflight, stage dependencies, execution, caching, provenance |
| `+ce/+curation` | Annotation updates, history, recovery and conflict checks |
| `+ce/+plotting` | Reusable plotting operations |
| `+ce/+ui` | CellExplorer, NeuroScope2 and metadata interfaces |
| `+ce/+integrations` | External services and optional integrations |
| `tests` | Synthetic fixtures and regression tests |
| `toolboxes` / native directories | Attributed vendor code and native dependencies |

Component-private helpers belong next to their owner, not in a new global utility
bucket. Package code should not depend on GUI callbacks or the base workspace.
During migration, dependencies on unmigrated functions must be explicit and
documented. Resolve resources relative to their owner, not the working directory.

## Migration inventory

The companion `migration-inventory.csv` records the files in `calc_CellMetrics`
and `util`, proposed ownership, compatibility requirements, and migration status.
Proposed ownership is a review map, not permission to move vendor/private/native
files independently of their callers or bundled assets. Public-use status is
conservative because repository searches cannot prove external callers absent.

## Ordered work packages

### 1. Establish and exercise the component boundaries

- [x] Record the inventory and developer rules; provide a repeatable test command.
- [x] Introduce `ce.io` for verified MAT/JSON writes and compatible save wrappers.
- [x] Reject unsupported exports explicitly; repair the existing format routing.
- [x] Extract curation application/saving from the batch-save callback.
- [x] Check identity before applying annotations; reject changed identities/counts.
- [x] Keep unsaved changes when a write fails or batch saving is canceled.
- [x] Extract metric validation into `ce.data`, preserving the legacy entry point.
- [x] Move a small set of independent metric functions without changing formulas;
      verify legacy/package agreement and numerical reference cases.
- [x] Add regression tests and CI; run available checks and document limitations.

This is the first executable milestone. It establishes working boundaries used
by the existing application, rather than empty directories or a wholesale rename.

### 2. Make pipeline execution reproducible

- [x] Separate machine-readable session validation from its report window.
- [x] Establish an initial headless contract for local metadata and cached/supplied
  spikes: no dialogs or workspace/cwd changes; errors identify missing inputs
  before computation. Interactive importers and undeclared callbacks are rejected.
- [ ] Expand headless preparation to additional importers and optional stages.
- [ ] Resolve and record configuration, preferences, code revision, MATLAB/toolbox
  versions, input identity and random sampling state.
- [ ] Extract stages with declared inputs/outputs/dependencies and structured results.
- [ ] Invalidate caches when relevant inputs, parameters or implementations change.
- [ ] Keep each stage's provenance when it is reused; distinguish skipped from failed.
- [ ] Add deterministic numerical fixtures and reference-dataset comparisons before
  modifying any calculation behavior.

Acceptance: a changed interval cannot reuse an incompatible ACG; repeated runs
with the same inputs/configuration reproduce results; failures are attributable
to stages; noninteractive runs never require a dialog.

Current coverage: `waveform_extraction`, `waveform_shape`,
`waveform_localization`, `acg_metrics`, `monosynaptic_detection` and
`monosynaptic_metrics` satisfy these stage/cache contracts.
The unchecked items above also cover the remaining stages and sorting import,
and remain open until that migration is complete.

### 3. Complete the implementation migration

- Migrate loaders and format adapters, then processing functions and remaining
  metrics, in dependency-aware batches with compatibility tests.
- Audit `private` resolution, MEX lookup, NWB specifications, embedded assets,
  `inputname`/`nargout` behavior, and dynamic plugin discovery before relocation.
- Preserve vendor attribution; distinguish original code from adapted vendor code.
- Update internal callers to package-qualified names while retaining public wrappers.
- Retire the legacy directory only under an explicitly documented compatibility
  policy after downstream users have a migration path.

Acceptance: implementation ownership is unambiguous, old entry points work, and
each moved component has coverage appropriate to its numerical or I/O behavior.

### 4. Separate curation state and improve interfaces

- Separate scientific data, annotation state, selection/filter state and handles.
- Persist recovery snapshots or a journal; workspace autosave alone is insufficient.
- Check file revisions before overwriting concurrent edits. Existing UID/cluster
  checks cannot detect every re-sorting that reuses identifiers; introduce a sorting
  revision identity before claiming complete conflict detection.
- Standardize undo/redo and show per-session save outcomes and dirty state.
- Profile representative data, then retain graphics objects and refresh only the
  affected panels; measure cell-selection latency and memory.
- Add searchable actions, saved filters and workflow-oriented layouts.
- Evaluate any UI framework change with a representative plotting prototype.

Acceptance: interrupted sessions recover edits, partial saves remain visible,
and measured navigation improves without losing existing analysis workflows.

## Verification and rollout

Use synthetic temporary data for persistence/failure tests, explicit expected
values for simple calculations, and representative reference data for scientific
regressions. Test both legacy functions and package APIs. Run MATLAB Code Analyzer
on changed implementation files and the automated suite through `tests/run_tests`.
CI should run the same suite on a pinned MATLAB release. GUI behavior requires a
separate interactive smoke check; automated component tests do not replace it.

Commit/review each coherent work package independently. Record completed work,
test evidence and outstanding limitations below. Do not mark a later phase done
merely because its directories exist.

## Execution record

- Initial state: clean working tree on `CellExplorer-2.0`.
- Work package 1 completed in the working tree on `CellExplorer-2.0`.
- Inventoried all 200 files in `calc_CellMetrics` and `util`, including private,
  vendor, native and resource files. Proposed ownership is recorded for each.
- Migrated nine public entry points into `ce.io`, `ce.data` and `ce.metrics` with
  compatibility wrappers. Preserved legacy function signatures and caller-name
  inference. The four numerical implementations and validator are byte-for-byte
  identical to their pre-migration implementations.
- Added staged/verified persistence and extracted batch curation into `ce.curation`.
  Batch saves align UIDs, compare available cluster IDs, back up on-disk annotations
  in the correct session, and retain dirty cells after partial or canceled saves.
- Repaired JSON literal writing, generic export routing, unsupported-format errors,
  the invalid-datatype loader error, and the UI's missing-path save fallback.
- Added developer instructions, an executable regression suite and a pinned R2024b
  GitHub Actions workflow. The hosted workflow has not yet been executed.
- Local validation: **31/31 tests passed** using MATLAB R2024b Update 9. Coverage
  includes MAT/JSON round trips, failed staging/verification preserving existing
  bytes, backup failures, reordered/mismatched units, partial/canceled save tracking,
  legacy signatures and package use without the legacy directory on the path.
- The NWB routing test uses a temporary synthetic HDF5 adapter, not MatNWB. Its
  source is stored as `.m.txt` so recursive installation paths cannot shadow the
  production adapter. Full NWB schema validation remains outstanding.
- MATLAB Code Analyzer: no new diagnostic kinds in the modified application entry
  points (CellExplorer: 382 to 380 diagnostics; ProcessCellMetrics: 44 unchanged).
  No PARSE diagnostics in package/test files. Existing legacy analyzer findings
  were not treated as a reason to change scientific code during migration.
- Inventory completeness, unchanged numerical/validation bodies, and
  `git diff --check` verified. Interactive GUI and full recording-pipeline smoke
  tests remain outstanding; component tests do not establish those results.
- Work package 2 is in progress; work packages 3–4 remain planned.

### Session validation and headless boundary (2026-10-26)

- Added `ce.data.validateSession` with structured checks/errors/warnings and
  optional filesystem checks. Missing parents, invalid channel indices/counts,
  malformed epochs and missing paths produce reports rather than indexing errors.
- Kept `validateSessionStruct(session)` as the window-opening compatibility API;
  the separate `ce.ui.showValidationReport` renders the same report.
- Extracted pipeline parameter parsing and added `ce.pipeline.preflight`.
  `ProcessCellMetrics(..., 'headless', true)` validates before computation,
  disables presentation/manual steps and file transfers, and avoids DB setup.
- The initial boundary requires local metadata and supplied/cached spikes. It
  rejects source reimport, unsupported export modes, undeclared custom callbacks,
  missing native/toolbox dependencies and interactive optional preparation.
- Reused metric caches must match the spike UID order and available cluster IDs.
  This is an identity guard, not full parameter/input cache invalidation.
- Scoped metrics loading to its named MAT variable so unrelated saved variables
  cannot replace the run configuration. Made nested waveform-cache metadata checks
  safe when fields are absent. Fixed an existing empty nested-struct indexing error
  in metric validation; numerical formulas remain unchanged.
- **54/54 regression tests passed** in MATLAB R2024b Update 9, including an actual
  headless synthetic pipeline run, read-only preflight, invalid inputs, dependency
  detection, cache identity mismatch, and preservation of cwd/figures/input files.
- Opt-in tutorial smoke: `Peter_MS22_180629_110319_concat`, **151 cells**. Copied
  only session/spikes/metrics to temporary storage, removed one cached waveform
  metric to force recalculation, processed and saved the copy, and verified saved
  output, cell IDs, firing rates and waveform results against the standalone
  calculation. Processing took about **6.35 seconds**; no figures or cwd changes.
- Original tutorial session/spikes/metrics SHA-256 hashes were unchanged afterward.
  No raw recording data were copied or modified. This did not validate every
  metric stage or raw waveform extraction.
- Code Analyzer found no parse diagnostics in the new components, tests or pipeline.
  The extracted parser retains legacy string-validator advisories. The current
  branch's legacy validation window also passed an open/table/close smoke check;
  MATLAB's original path contains another installation, so the check explicitly
  selected this checkout.
- Next at that checkpoint: extract stage execution and record stage-specific
  provenance, then replace field-presence cache reuse with parameter/input-aware
  invalidation (initial coverage implemented below).

### Initial stage execution and cache invalidation (2026-10-26)

- Extracted waveform descriptors and ACG orchestration into `ce.pipeline.stages`.
  Added explicit input/output/dependency definitions and a stage runner that
  records completed/reused/skipped/failed results. Failed operations preserve the
  previous metrics; the pipeline stops before saving the metrics file.
- Added typed SHA-256 fingerprints for inputs, effective configuration, resolved
  implementation files/native binaries, environment and outputs. Old caches
  without provenance are recomputed once. Reuse and skipped selections retain
  original provenance instead of relabeling old results with new parameters.
- Added an isolated random seed (default 0), deterministic serial headless ACG
  execution, and plotting-flag handling in the legacy serial fitter. Numerical
  formulas and public function call compatibility are preserved.
- Restricted waveform extraction cannot overwrite the canonical spike file.
  A post-filter identity guard prevents attaching old annotations/metrics to a
  reduced set of cells. Optional outputs are removed when a rerun no longer
  produces them.
- Tutorial waveform check: all **151 cells**, matching standalone waveform
  metrics, saved/returned output equality, successful reuse, and seed-change
  invalidation. No figures. The first processing call took about **17 seconds**,
  including spatial localization; reuse took about **8 seconds** including I/O.
- Tutorial ACG check: **two units (80 and 135), first 120 seconds**. ACGs and fits
  matched standalone calculations. Changing to 60 seconds recomputed both stages;
  repeating that selection reused both. Skipping ACG retained its provenance.
  An injected calculation failure left the saved metrics file byte-for-byte
  unchanged. No figures were created.
- **60/60 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer
  reported no parse diagnostics in 46 package/test/modified pipeline files;
  `git diff --check` passed. The three original tutorial input files retained
  their recorded SHA-256 hashes after integration testing.
- Remaining scope: raw-source cache freshness, spatial localization provenance,
  other metric stages and a full-recording/full-pipeline validation. No UI
  performance changes or hosted-CI execution are claimed by this milestone.
- Next: migrate waveform extraction and spatial localization with explicit raw
  data/channel-coordinate dependencies, then extend the stage contract to the
  remaining metrics.

### Raw waveform extraction and spatial localization (2026-10-26)

- Added a managed extraction stage with a separate, verified waveform sidecar.
  Cache reuse requires raw-content SHA-256, spike/sample arrays, cell identities,
  acquisition metadata, channel selections, preferences, seed and implementation
  fingerprints. Restricted extraction never overwrites the canonical spike file.
- Raw hashing streams the entire recording on every run. This is deliberately
  stricter than timestamp-only reuse, but full-recording performance remains
  unmeasured. Managed extraction rejects non-int16/truncated data rather than
  applying the legacy two-byte duration assumption to other sample formats.
- Extracted spatial localization from `ProcessCellMetrics` without changing its
  fitting formulas. Coordinate and CCF dependencies now invalidate localization
  independently. Removed CCF files remove stale outputs. File-derived coordinates
  are not persisted as session overrides that could hide later edits.
- Managed extraction propagates bad-channel detector failures and suppresses
  ancillary noise/figure writes; legacy direct-call defaults remain available.
  Sidecar persistence occurs after successful computation/validation, but sidecar
  and metrics replacement are not a multi-file transaction.
- **68/68 regression tests passed** in MATLAB R2024b Update 9. Tests include actual
  extraction from an eight-channel synthetic binary file, equality with the legacy
  extractor, same-size file edits, restricted inputs, reuse, failure preservation,
  canonical-spike protection and pipeline `saveMat=false` behavior.
- Tutorial localization on **151 cells matched the pre-extraction baseline exactly**
  for `trilat_x`, `trilat_y`, `peakVoltage_expFit` and channel coordinates. A 100 µm
  coordinate shift on two tutorial units reran localization and reused waveform
  shape/ACG stages. Both tutorial integration checks passed without figures.
- CI configuration now includes Curve Fitting and Signal Processing toolboxes in
  addition to Statistics. Hosted CI and full tutorial raw extraction remain unrun.
- Code Analyzer found no parse diagnostics in 53 package/test/modified pipeline
  files; `git diff --check` passed. All three original tutorial input files retained
  their recorded SHA-256 hashes.
- Next: extend stage execution and dependency-aware caching to monosynaptic
  connections and the remaining optional metric stages, then continue the loader
  and processing-function migration.

### Monosynaptic detection, curation and persistence (2026-10-26)

- Extracted automatic detection and accepted-connection metrics into separate
  stages, preserving the legacy detector, convolution and transmission formulas.
  Input fingerprints include spike identities/times, shank IDs, intervals, explicit
  detection settings, resolved native/code dependencies and the actual optional
  probability-table resource. Preflight checks the interval MEX even without an
  explicit user interval, because the detector always calls it.
- Kept the conventional `mono_res` filename/variable and GUI-compatible pair
  fields. Automatic output hashes exclude manual selections. Matching detection
  provenance retains curated choices, including across forced recomputation.
  Changed/unverified provenance starts a new automatic selection and reports that
  prior selections were not applied; no legacy review is silently relabeled.
- Added exact-file revision archives and verified replacement. Failed backups or
  intervening edits abort saving. Unchanged files are not rewritten, and
  `saveMat=false` now suppresses monosynaptic writes. These are independent writes,
  not a transaction across all pipeline outputs.
- Isolated interactive review in `ce.ui.reviewMonoSyn`. Fixed the projection's
  inhibitory-only omission and stale synaptic-effect labels after all connections
  are removed. Excitatory-only in/out count semantics are retained.
- **76/76 regression tests passed** on MATLAB R2024b Update 9. Native integration
  on two tutorial units matched legacy automatic detection; changed options and
  intervals invalidated results. Coupled synthetic trains verified that manual
  rejection survives reuse and force reload, while prior and legacy files are
  archived. No figures appeared; no-write execution preserved the mono file.
- Code Analyzer reported no parse diagnostics in 62 package/test/pipeline files.
  GUI review, hosted CI and full-population native detection remain unrun.
- Next: migrate optional event/manipulation/state metric stages and their input-file
  dependencies, followed by the remaining loaders and processing implementations.
