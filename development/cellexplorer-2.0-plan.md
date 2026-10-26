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
`monosynaptic_metrics`, plus `event_metrics`, `manipulation_metrics` and
`state_metrics`, `spatial_metrics`, `psth_metrics`, `theta_signal` and
`theta_metrics`, the `deepSuperficial` projection, `other_metrics` and
`cell_class_import` satisfy these stage/cache contracts.
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

### Event, manipulation and state stages (2026-10-26)

- Replaced their inline orchestration with three independently cached stages.
  Named MAT-variable loading prevents unrelated saved variables from becoming
  configuration. Complete file hashes, consumed data, preferences and selected
  spike identities/times participate in cache decisions.
- Added dynamic output ownership and retirement. Removed, renamed and ignored
  inputs clear their old scalar metrics and plot metadata only after successful
  computation. Legacy metadata supplies initial ownership; unattributable orphan
  fields are not guessed. Skipped stages retain their results and provenance.
- Added early schema/collision checks, including manipulation files used only for
  exclusion. Duplicate state names and cross-family scalar-name collisions now
  fail explicitly. Empty inputs retire undefined outputs rather than invoking
  calculations with zero events or zero duration.
- Preserved numerical expressions and effective preference differences between
  event and manipulation PSTHs. The new native integration test compared all
  event/manipulation/state outputs exactly with a captured pre-extraction pipeline
  using two tutorial units and synthetic intervals. Reuse, changed files,
  ignored/renamed/deleted inputs and failure preservation passed without figures.
- **86/86 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer found
  no parse diagnostics in 70 package/test/pipeline files; `git diff --check` passed.
  All three original tutorial input files retained their recorded SHA-256 hashes.
- Scientific follow-up remains separate: audit the legacy state-mask/ISI indexing,
  state-duration convention and PSTH center alignment before changing formulas.
- Next: migrate spatial/theta and imported-PSTH orchestration, followed by remaining
  loaders and processing implementations. Full-population validation and hosted CI
  remain outstanding.

### Spatial maps and imported PSTHs (2026-10-26)

- Replaced the inline spatial/PSTH imports with two independently cached stages.
  Named MAT-variable loads and complete-file hashes cover their dependencies.
  Cell columns are aligned using explicit UID or cluster identity; matching counts
  alone are rejected. Conflicting/duplicate identities, invalid dimensions and
  the reserved spatial alias collision fail before headless processing.
- Preserved spatial formulas and the conventional map filenames/variable names.
  The special `ratemap` input produces the original scalar metrics and map alias;
  state-dependent maps keep their per-cell matrices. Missing files retire both
  maps and their metadata, and removal of `ratemap` clears its scalar metrics.
- Fixed imported PSTH variable lookup, per-cell storage and axis-label copying.
  Curves now populate the viewer's existing `psth` container. Validation and batch
  loading recognize that container, including missing-session padding and retained
  per-session axes. Unrelated custom PSTHs remain outside imported-field cleanup.
- **98/98 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer found
  no parse diagnostics in 77 package/test/pipeline/loader files; `git diff --check`
  passed. Tests cover identity alignment/rejection, malformed data, independent
  reuse/invalidation, output edits, renamed/deleted files and batch alignment.
- Tutorial integration passed using **all 151 cell identities**, their cached
  metrics/spikes and synthetic map/PSTH inputs in a temporary directory. Spatial
  calculations and fresh plot metadata matched the pre-extraction pipeline exactly.
  Historical metadata for absent maps was excluded from the numerical baseline;
  its intentional removal was tested separately. Reuse, no-write mode, malformed
  input failure preservation and deleted outputs passed without figures. Original
  session/spikes/metrics hashes remained unchanged. This is import validation,
  not validation of upstream spatial-map estimation.
- Compatibility change: existing imported files require producer-verified `UID`
  or `cluID` metadata. Imports retain their upstream time selection; changing
  pipeline spike intervals does not recompute imported curves. NWB PSTH export,
  interactive viewer checks and hosted CI remain outside this milestone.
- Next: split theta signal preparation from theta metrics. The current helper can
  create an LFP and save a cache regardless of the pipeline's `saveMat` setting;
  migrate its raw/cache dependencies and persistence before claiming a fully
  controlled headless theta stage. Then continue remaining loaders, processing
  functions and UI work.

### Theta preparation, metrics and persistence (2026-10-26)

- Extracted signal preparation and cell metrics into independent cached stages.
  Full LFP content, channel/calibration/rate metadata, selected spike identities
  and samples, behavior contents and preferences now participate in provenance.
  Behavior or interval changes reuse signal preparation while refreshing metrics.
- Moved the public theta helper behind a compatibility wrapper in `ce.processing`.
  Both paths share the original numerical kernel. Direct-call defaults remain;
  the managed pipeline requires an existing int16 LFP and never resamples one
  implicitly. Named MAT-variable loading prevents saved variables from overriding
  options. Interactive diagnostics are isolated in `ce.ui`.
- Retained the conventional cache filename/variable with an embedded signal
  provenance record. Cache preparation is read-only; verified persistence occurs
  after successful pipeline calculation/validation and respects `saveMat`.
  Intervening cache edits abort replacement; unchanged caches are not rewritten.
  These writes remain independent of other pipeline outputs, not a transaction.
- Added behavior/acquisition/frame checks and explicit seconds/sample-index
  validation. Requested theta processing retires old metrics if its behavior file
  or channel tag disappears; excluded theta stages retain their outputs.
- **110/110 regression tests passed** in MATLAB R2024b Update 9. Signal outputs
  matched a frozen pre-migration helper exactly. Tests cover channel reading,
  raw-file edits, independent invalidation, cache edits/conflicts, failure
  preservation, removed inputs and legacy option isolation. Code Analyzer reported
  no parse diagnostics in 91 package/test/pipeline/loader/wrapper files.
- Tutorial integration used units **80 and 135**, first 120 seconds, with synthetic
  LFP and behavior in a temporary directory. Theta outputs matched the captured
  pre-extraction pipeline exactly. Reuse, changed intervals/behavior, no-write
  execution, malformed-input preservation and stale-output retirement passed
  without figures. All three original tutorial input hashes remained unchanged.
- CI now includes Image Processing Toolbox. Hosted CI, actual tutorial LFP/behavior,
  full-recording resource use and interactive plots remain untested. Legacy speed
  gating, phase-index and histogram conventions are preserved for a separate
  scientific audit.
- Next: migrate deep/superficial inputs and remaining core/finalization logic,
  then continue loader separation and UI improvements.

### Deep/superficial import and cell annotation preservation (2026-10-26)

- Replaced inline detection/classification orchestration with an import stage for
  the reviewed channel file. Full file contents, cell identities and peak channels
  participate in cache decisions. Channel IDs are explicit and one-based; source
  electrode-group order is validated when present. The assignment formulas are
  unchanged; reordered channel rows are resolved by identity instead of position.
- Separated the automatic projection from editable cell labels/distances. Edits
  are compared with a verified previous projection and tracked independently of
  the calculation cache. Known overrides, including empty/NaN values, survive
  source changes, missing/restored files and forced computation. Unknown legacy
  annotations are retained and reported rather than overwritten. A damaged
  automatic baseline cannot be used to erase cell edits.
- Forced pipeline rebuilds recover deep/superficial annotation context from the
  previous MAT cache when identities match. This protection does not change the
  legacy force-reload treatment of unrelated annotations. Classification source
  files remain read-only; only normal metric persistence writes imported results.
- Compatibility boundary: the pipeline now requires classification preparation
  explicitly when ripple inputs/tags indicate it is needed, in both interactive
  and headless modes. Existing reviewed classification files can be imported
  without LFP/ripple files. The original classifier/review APIs retain their legacy
  behavior and still await migration; import provenance does not certify their
  freshness against upstream LFP, geometry or ripple changes.
- **123/123 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer found
  no parse diagnostics in 98 package/test/pipeline/loader/wrapper files. Tests cover
  channel/group identity, source/peak-channel edits, manual overrides, damaged
  provenance, forced annotation recovery, missing inputs and headless preflight.
- Tutorial integration used **all 151 cells and the actual 128-channel reviewed
  classification**, with copies of five input files. Fresh assignment and metadata
  matched the pre-extraction pipeline exactly. Legacy annotation preservation,
  reuse, changed source files, manual cell edits, no-write execution and failure
  preservation passed without figures. All original input hashes were unchanged.
- GUI review, classifier numerical generation and hosted CI remain untested by
  this milestone. Next: separate core metric calculation from pipeline
  finalization/persistence, then continue upstream preparation and loader/UI work.

### Core metrics and pipeline finalization (2026-10-26)

- Extracted mandatory `other_metrics` calculations into a managed stage with
  explicit spike/identity, interval, preference, implementation and output hashes.
  Preserved existing formulas and the unconditional calculation contract; matching
  inputs now reuse results. Stale spike totals and undefined duration inputs fail
  explicitly. Legacy duration, histogram, CV2 and burst conventions remain unchanged
  pending a separate scientific audit.
- Separated metadata refresh, legacy output cleanup and invocation provenance from
  numerical calculations. Optional owned metadata is retired when absent, and
  database IDs use scalar numeric parsing rather than expression evaluation.
  Generated Unknown/NaN deep/superficial defaults no longer become accidental manual
  overrides when classification inputs become available.
- Deferred metric backups until computation/validation succeeds. Saving verifies
  metric/session revisions before writes, preserves the entire previous metrics
  file in a hash-verified backup, and writes session MAT files through verified
  replacement. Backup failures abort; session-save errors are no longer swallowed.
  `saveMat=false` suppresses managed saving and metric backups.
- **138/138 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer
  found no parse diagnostics in 108 package/test/pipeline/loader/wrapper files.
  New tests cover numerical fixtures, cache repair/reuse, interval/preference
  changes, metadata updates, stale totals, exact backups, concurrent destination
  edits, invalid destinations and backup failures.
- Tutorial integration used **all 151 cells** from temporary copies of the three
  original input files. Every core-stage output matched the frozen pre-extraction
  implementation exactly, including exclusion-duration behavior. Cache reuse,
  metadata-only refresh, no-save runs, byte-identical backups and stale-input
  failure preservation passed without figures. Original input hashes were unchanged.
- Limits: individual verified saves are not a multi-file transaction or a lock;
  later failures may leave earlier sidecars/metrics saved. Waveform sidecars still
  lack concurrent-revision checks. Legacy preparation/custom callbacks, database
  submission and summary figures retain their own side effects. GUI, NWB/JSON
  pipeline round trips and hosted CI were not validated by this milestone.
- Next: isolate the remaining custom/classification import boundary, replacing
  count-only CellClass correspondence with explicit identity validation; then
  continue upstream preparation, loader separation and UI work. Multi-file recovery
  and waveform-sidecar revision checks remain persistence follow-ups.

### Identity-safe CellClass import and custom callback dispatch (2026-10-26)

- Replaced the inline Buzcode count-only import with `cell_class_import`, using
  named-variable loading, complete source fingerprints and explicit cell identity.
  UID or cluster IDs determine label order; both must agree when present. Source
  supersets support filtered target cells. Empty labels retain the legacy Unknown
  default, and classification formulas were not changed.
- Extracted shared identity matching into `ce.data.cellIdentityOrder`; spatial and
  PSTH imports retain their existing exact-cell-set contract. Managed CellClass
  labels are cached independently of editable putative cell types/manual labels.
  Missing sources retire managed outputs; absent sources preserve legacy values
  without managed provenance. Source files are never rewritten by the importer.
- Compatibility boundary: CellClass files without verified identities now fail,
  even when counts match. Headless preflight detects invalid files before
  calculation/saving. The unconditional import selection behavior is unchanged.
  Producers must supply verified mappings; current spike order is not sufficient
  evidence to annotate an unidentified historical file.
- Extracted custom calculation discovery/dispatch while preserving package names,
  callback arguments, discovery order and selection/exclusion behavior. Callbacks
  must preserve cell count and declared identity/order. They remain uncached and
  disallowed in headless runs; their own external side effects cannot be rolled
  back. Putative-cell-type callback formulas remain unchanged.
- **150/150 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer
  found no parse diagnostics in 117 package/test/pipeline/loader/wrapper files.
  Tests cover missing/duplicate/conflicting identities, reordered sources, subsets,
  malformed labels, source/output changes, deletion/restoration, preserved manual
  fields, preflight failure preservation and callback selection/identity/failures.
- Tutorial integration used **all 151 real cell identities with synthetic labels**
  in temporary copies. Ordered imports matched the frozen previous implementation
  exactly; reversed source order preserved correspondence. Reuse, edited sources,
  removal, no-save behavior and missing-identity failures passed without figures.
  All three original input hashes were unchanged. This validates import mechanics,
  not biological labels or an upstream classifier implementation.
- Next: separate local metric loading and batch assembly from database/UI progress
  handling, retaining public loader APIs and per-session identity. This prepares
  a testable foundation for UI improvements. Upstream sorting/classification
  preparation, declared callback contracts and multi-file recovery remain open.

### Local loaders, batch assembly and progress boundary (2026-10-26)

- Replaced the mixed database/UI/file/assembly implementation of
  `loadCellMetricsBatch` with a compatible public adapter over `ce.io.loadMetricBatch`
  and pure `ce.data.assembleMetricBatch`. Local reads load only `cell_metrics`,
  validate session identity and never access database settings. Public loaders
  remain at their original paths; MAT loading requires only the repository root.
- Preserved cell/session order, duplicate session requests, per-session metadata,
  group and connection offsets, and UID/cellID/cluster values. Batch IDs scope
  identities across sessions. Fixed implicit zero padding in missing nested
  metrics; all gaps now receive NaN/empty padding. Logical fields survive assembly,
  and incompatible dimensions/types fail instead of silently dropping arrays.
- Separated progress-window ownership and cancellation into `ce.ui`. Local batches
  accept `headless=true` or `showProgress=false`; component loading accepts a
  progress callback. Owned windows close on failures, supplied windows remain
  caller-owned, and cancellation cannot return a partially assembled batch.
- Database resolution is explicit and separate, retains requested order and
  duplicates, and disables resolver writes/cwd changes. Live database/network and
  legacy configuration UI behavior were not exercised; stub tests cover dispatch.
- Fixed single-loader routing for supplied metrics and batch inputs. Extracted
  filtering into `ce.data.filterMetricCells`; multiple exact-match values now work
  as alternatives, and ground-truth filters inspect the correct group container.
- **161/161 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer
  found no parse diagnostics in 128 package/test/pipeline/public-loader/wrapper
  files. Tests cover headless local loads with a rejecting database stub, session
  identity, offsets, missing-data padding, type/shape conflicts, large integer
  precision, filters, failures, cancellation and progress-window ownership.
- Tutorial integration built a **302-cell batch from two temporary copies of the
  151-cell metrics file**. Every field matched the frozen old loader exactly,
  excluding benchmark timings. Single-session filtering, no headless figures,
  unchanged cwd and unchanged source/copy hashes also passed.
- Compatibility limits: missing/invalid files and conflicting shapes now throw
  errors; nested batches are rejected. Batch loading remains eager/in-memory and
  MAT-only. JSON/NWB adapters remain legacy and were not validated here. Progress
  cancellation is checked between operations, not during individual MAT reads or
  concatenation. Full CellExplorer GUI behavior remains to be exercised.
- Next: wire structured loading failures and cancellation into CellExplorer's
  session-switch/reload UI, preserving the current metrics and unsaved edits when
  loading fails. Then profile large-batch opening and rendering before selecting
  UI performance changes. Upstream preparation and persistence recovery stay open.

### Guarded viewer reload and session switching (2026-10-26)

- Routed primary reload, file-picker and database-session selection callbacks
  through a shared load/confirm/capture/apply/restore boundary. Reads and identity
  checks happen before active-state replacement; closed progress windows and
  invalid files leave the current metrics and edits intact. File selection now
  loads only the named variable and does not change cwd.
- Added explicit discard confirmation for unsaved edits, defaulting to Cancel.
  State capture follows loading/confirmation, covering edits made while progress
  callbacks yield. Reentrant load requests are guarded. Success/cancellation are
  logged without an extra modal dialog; errors retain their actual cause.
- Initialization failures restore the data model, dirty tracking, undo history,
  selection, cell-type assignments, preferences, plot/reference state, paths and
  RNG state. Existing control properties and dynamic tags are restored as well.
  Tag-button destruction is deferred until initialization finishes. A secondary
  graphics-restoration failure is reported separately after model restoration.
- Reload resolves the actual selected filename or `saveAs`, including dotted
  basenames and mixed per-session batch names. Fixed batch assembly of legitimate
  single-session viewer saves carrying all-one `batchIDs`; true nested batches
  remain rejected.
- **170/170 regression tests passed** in MATLAB R2024b Update 9. Code Analyzer
  found no parse diagnostics in 136 package/test/pipeline/viewer/loader/wrapper
  files. New tests cover failed reads/initialization, cancellation, confirmation,
  edits during loading, rollback failures, control restoration and reload source
  resolution.
- Actual viewer smoke checks used **151 tutorial cells and a 302-cell batch**
  from temporary copies. Missing files, a late initialization failure after
  history/control updates, declined discard and a closed batch progress window
  preserved edits/history/selection. Successful reload, file selection and batch
  selection passed. Save indicator/title restoration and unchanged cwd/source
  hashes were checked. Dialogs, database and analytics/preferences were isolated
  with test stubs; PCA was used for visualization.
- Limits: the legacy rendering loop after commit, reference/ground-truth loaders,
  explicit reinitialization and other startup paths are not made transactional by
  this change. Arbitrary callback side effects cannot be rolled back. Replacement
  retains both datasets in memory. Live database services and all plot types were
  not tested.
- Next: profile opening/rendering on larger batches, then extract the expensive
  viewer preparation work from graphics updates. Extend guarded loading to
  reference/ground-truth inputs and preserve edits during explicit reinitialization.
  Upstream preparation and multi-file persistence recovery remain open.

### Viewer profiling and display-preparation extraction (2026-10-26)

- Added a reproducible viewer profiler for first display and three redraws, and a
  paired numerical/timing check against frozen legacy display preparation. The
  scaling fixture repeats the tutorial recording 10 times (1,510 cells); it is not
  a collection of independent recordings. GUI profiling uses PCA and isolates
  database, analytics and preference persistence.
- The measurements identify UI/table construction as a larger opening cost than
  file reading or display-array preparation. Profiled first-ready observations
  were approximately 9–10 seconds. Timer polling, profiler overhead and separate
  MATLAB process startup prevent interpreting these as a before/after speedup.
  Raw summaries are recorded in `development/benchmarks/viewer-2026-10-26.json`.
- Extracted waveform interpolation/z-scores, ACG/ISI normalization and theta
  display curves into `ce.ui.prepareDisplayData`, independent of graphics and
  mutable UI state. It runs before control/history updates, preallocates waveform
  matrices and reports invalid waveform/time dimensions explicitly. A partially
  present waveform display cache is now regenerated instead of skipped.
- Preserved per-cell spline evaluation and all existing zero/NaN/range conventions.
  Matrix-valued spline evaluation was rejected after exact tests detected tiny
  floating-point differences. No scientific formulas or embedding defaults changed.
- **179/179 regression tests passed** in MATLAB R2024b Update 9. The new tests
  compare frozen outputs for common/different axes, missing/NaN/constant waveforms,
  per-session theta axes, single cells, optional fields and cache handling.
  Code Analyzer found no parse diagnostics in 140 package/test/viewer/pipeline/
  loader/wrapper files.
- Every prepared field matched exactly on **1,510 tutorial-derived cells**. Five
  alternating warmed measurements gave medians of **53.9 ms legacy / 44.5 ms
  extracted preparation**. This is a small component-level improvement, not an
  application startup claim. Actual viewer load/rollback/cancellation checks also
  passed with 151 cells and a 302-cell batch. Original source hashes were unchanged.
- Limits: display reuse still follows the legacy initialized flag rather than
  dependency fingerprints. Reference preparation and dimensionality reduction
  remain inline; the main rendering loop is unchanged. Default t-SNE/UMAP, distinct
  large recordings and peak-memory limits were not benchmarked.
- Next: investigate deferring construction/population of costly tables until they
  are visible, with measured startup/redraw comparisons. Continue separating viewer
  preparation from graphics, and extend guarded loading/reinitialization coverage.


### Deferred tables and selected-cell formatting (2026-10-26)

- Removed the full-batch metric string cache. `ce.ui.metricTableData` formats only
  the selected cell when its table is visible, preserving numeric/text display
  conventions. Visible values now reflect the current metrics. Scientific arrays
  and calculation formulas are unchanged.
- Deferred the Tags widget until first opening its tab. Starting with Table data
  set to None also defers the main widget; a placeholder retains its layout slot.
  Existing widgets are reused, and tag checkboxes are restored from filter state.
- Fixed custom cell-list headings reverting on mode switches. Live testing also
  exposed missing-field errors when highlighting preference tags absent from the
  session; the affected rendering paths now check whether the tag exists.
- The component suite includes exact comparisons with the former string conversion
  for numeric/text fields, NaNs, infinities and empty values. Live viewer checks
  passed for all three starting table modes with 151 cells and a 302-cell batch:
  lazy creation/reuse, custom columns, sorted navigation, checkbox selection,
  tag-filtered list rows, rollback, successful switches and progress cancellation.
  All three original tutorial input hashes remain unchanged.
- **181/181 regression tests passed** in MATLAB R2024b Update 9; Code Analyzer
  found no parse diagnostics in 140 package/test/viewer/pipeline/loader files.
- Eight balanced measurements after warming both versions used 1,510 cells.
  Median session initialization fell from **357 ms to 281 ms**. First-ready
  medians were **2.705 s before / 2.567 s after**, with overlapping ranges;
  navigation observations were approximately **264 ms in both**, constrained by
  the 250 ms polling interval. This is a reduction in initialization work, not
  evidence of a broad startup/navigation speedup. Selected profile results and
  methodology are in `development/benchmarks/viewer-tables-2026-10-26.json`.
- Limits: first opening a deferred table still pays its construction cost. The
  cell list remains eager over the filtered subset, and plots still use the legacy
  rendering loop. PCA and repeated copies of one recording are the measured scope;
  this does not complete the interface or implementation-migration work packages.
- Next: extend edit-preservation guards to explicit reinitialization and
  reference/ground-truth loading. Then return to upstream preparation/remaining
  processing migration, with recovery journaling and broader recording validation
  still outstanding.


### Guarded reinitialization and comparison datasets (2026-10-26)

- Explicit reinitialization now uses current in-memory annotations and embedding,
  preserving dirty tracking, undo history, selection and filters. It refreshes
  preparation without a discard prompt; failures restore the earlier model,
  controls and RNG state. Undo remains usable after success.
- Fixed initialization using missing animal names to blank unrelated text fields;
  the live fixture now verifies labels survive absent animal metadata.
- Routed reference/ground-truth cache reads and selected batches through staged
  loading and rollback. Only the expected named MAT variable is read. Display
  modes are enabled only after successful loading; existing comparison controls
  are reused. Rollback includes comparison axis bounds, menu checks, selected tabs
  and removal of newly created comparison tabs.
- Extracted comparison preparation into `ce.ui.prepareComparisonData` with
  explicit inputs and frozen legacy comparisons. Histogram, smoothing, waveform,
  normalization and class-mapping formulas are unchanged.
- Comparison cache writes now use verified staged replacement as the final
  fallible commit step. Preparation or write failures retain current comparison
  data and primary-session edits. Local reference paths are used directly when
  available; repository/download fallbacks stage and validate transferred files.
- Exploring either comparison as primary data now honours unsaved-change
  confirmation and initialization rollback.
- **186/186 component tests passed** in MATLAB R2024b Update 9. Code Analyzer
  found no parse diagnostics in 142 package/test/viewer/pipeline/loader files.
  New tests cover named caches, identity errors, selected-tab/menu restoration and
  exact legacy comparison preparation, including empty/NaN waveforms.
- Live checks passed in all three initial table modes, using an exact temporary
  viewer copy with 151 cells and a 302-cell batch. They exercised reinitialization
  success/failure and subsequent undo; rendered both overlays; tested comparison
  selection, preparation/write failures, closed progress windows and declined/
  accepted exploration. Missing animal metadata did not erase labels. All
  comparison caches/catalogues were temporary; all three tutorial source hashes
  were unchanged.
- Every comparison-preparation output matched the frozen legacy exactly for
  **151 and 1,510 tutorial-derived cells**, for both reference and ground-truth
  modes. The ground-truth fixture uses a synthetic all-cell classification to
  test preparation, not to validate biological ground truth.
- Limits: post-commit rendering and arbitrary custom callback side effects remain
  outside rollback. The ground-truth catalogue still selects sessions and uses
  its legacy best-effort list cache. Downloads are individually verified, not a
  multi-file transaction. Live database/network services and all custom plots
  remain untested.
- Next: return to upstream sorting/spike preparation and remaining processing
  migration, starting with explicit importer inputs and headless failure behavior.
  Recovery journaling, sorting revision identity and broader recording validation
  remain outstanding; work packages 2–4 are still incomplete.
