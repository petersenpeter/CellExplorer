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

Current coverage: opt-in `spike_import` for Neurosuite/Klustakwik and Phy,
`waveform_extraction`, `waveform_shape`,
`waveform_localization`, `acg_metrics`, `monosynaptic_detection` and
`monosynaptic_metrics`, plus `event_metrics`, `manipulation_metrics` and
`state_metrics`, `spatial_metrics`, `psth_metrics`, `theta_signal` and
`theta_metrics`, the `deepSuperficial` projection, `other_metrics` and
`cell_class_import` satisfy these stage/cache contracts.
The unchecked items above also cover the remaining stages and sorting formats,
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

Current coverage includes guarded save/restore routes, partial-save dirty tracking,
annotation and pending-review disk journals, startup recovery and undo after
recovery. Live same-sorting annotation conflicts now have editing-session guards
and explicit three-way reconciliation. Broader state separation, reconciliation
of stale recovery journals, and remaining interface/navigation work are open.

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


### Neurosuite/Klustakwik import boundary (2026-10-26)

- Extracted `.clu/.res` and optional `.spk` reading into
  `ce.io.importNeurosuiteSpikes`, with explicit session/path/group/scaling inputs
  and no dialogs, metadata callbacks, database access, cwd/RNG changes or writes.
  The legacy loader delegates this format branch; its other format routing,
  private metadata helpers and output filters remain in place. No caller-sensitive,
  MEX or resource lookup moved with this branch.
- Preserved timestamp conversion, cluster/UID ordering, noise exclusions,
  0.5 ms timestamp deduplication, waveform means/stds and channel indexing.
  Waveforms continue to use all assigned source spikes, as in the legacy code.
- Added explicit checks for missing/malformed sorting files, mismatched lengths,
  waveform framing, channel groups and sample/scaling metadata. Binary handles
  are closed reliably. OriginalClus discovery now inspects its own directory;
  undeclared OriginalClus/source-waveform alignment is rejected before reading.
- Spike cache reads now load only the named variable. Final cache saves use
  verified replacement and propagate errors. Output filtering still follows saving,
  preserving the established full-cache behavior. A failed import retains an
  existing cache; this does not make all legacy preparation effects transactional.
- **199/199 regression tests passed** in MATLAB R2024b Update 9; Code Analyzer
  found no parse diagnostics in 146 package/test/viewer/pipeline/loader files.
  Frozen legacy comparisons matched every imported field, including source
  waveform statistics, singleton units, scaling and group order. Tests also
  exercised malformed inputs, cache preservation/save failures, filters and a
  headless core-metrics run using the imported spikes without writes or figures.
- Tutorial verification loaded a temporary copy of the **151-cell spike cache**;
  every field matched and the copy remained unchanged. All original tutorial
  session/spikes/metrics hashes remained unchanged. Original sorting files are
  absent from that session, so raw import was verified on controlled fixtures,
  not on the tutorial's original sorting output.
- Updated the migration inventory to mark loadSpikes as partially extracted rather
  than fully migrated. The package API can be used explicitly before headless
  processing; automatic raw import during pipeline preflight remains unsupported.
- Next: declare import-stage dependencies and sorting revision identity before
  enabling managed raw import/cache reuse in the pipeline. Migrate the next
  format (Phy) with the same explicit input and reference-comparison discipline.
  Broader source datasets, recovery journaling and the remaining UI/migration
  work packages are still outstanding.

### Managed Neurosuite import and sorting revisions (2026-10-26)

- Added opt-in `spikeImport` options to headless processing. Preflight prepares or
  reuses imported spikes in memory with no writes or interactive fallback. The
  shared source plan resolves the same files/options used by the importer;
  timestamp conversion, deduplication and waveform formulas are unchanged.
- Declared `spike_import` ownership and dependencies. Reuse checks full source
  content, effective metadata/options, implementation, environment and cached
  outputs, retaining generation provenance. The separate
  `basename.spikeImport.cache.mat` is deferred until pipeline persistence;
  the conventional spike cache remains untouched. Source rediscovery/hashes and
  expected cache revision are checked again before writing.
- Managed imports now carry a sorting revision bound to original cell IDs,
  groups, sample rate and timestamps. Processing validates it before interval
  filtering and stores it in metric metadata. Assignment/timestamp source edits
  change the revision; waveform-only/scaling changes invalidate the import cache
  without changing sorting membership identity. This is conservative content
  identity, not proof that biological cells have been matched across sortings.
- Cached metric reuse and annotation application reject differing or one-sided
  missing sorting revisions, including when UIDs/cluIDs happen to match. Batch
  annotation checks use the selected session's revision, and annotation backups
  retain it. Unversioned legacy pairs keep their previous identity checks.
- **215/215 regression tests passed** in MATLAB R2024b Update 9. New coverage
  includes source edits with restored mtimes, waveform/scaling changes, modified
  cache outputs/implementation provenance, new groups, concurrent cache edits,
  dry-run and failed-save preservation, revised/legacy metric conflicts and
  single/batch annotation protection. A fresh synthetic recording successfully
  bootstraps import, raw waveform extraction, waveform/ACG/core metrics and reuse
  without an existing spike or metric cache.
- Code Analyzer found no parse diagnostics in 155 package/test/viewer/pipeline/
  loader files. The temporary tutorial spike-cache smoke check matched every
  field for 151 cells; original session/spikes/metrics hashes remained unchanged.
  The tutorial lacks original sorting files, so managed raw import was tested on
  synthetic recordings rather than that recording's original sorting output.
- Limits: managed import supports Neurosuite/Klustakwik only and remains opt-in.
  Existing unversioned metrics need a separate `saveAs` or explicit full required
  recomputation, with curation reconciled separately. Legacy import paths do not
  acquire managed revisions, and not every viewer whole-file save path checks
  them. Full source hashing has an I/O cost; checks provide neither file locks nor
  a multi-output transaction. Broader raw sorting datasets remain unverified.
- Next: migrate Phy with explicit inputs and frozen reference comparisons, then
  extend managed import support using these contracts. Expand revision checks to
  remaining curation/save routes and address recovery journaling. Work packages
  2–4 remain incomplete; this closes the first format's managed import/revision
  slice, not the full pipeline or persistence modernization.

### Phy import boundary and managed reuse (2026-10-26)

- Extracted the Phy branch from `loadSpikes` into `ce.io.importPhySpikes`, with
  explicit session/path/label options, shared file discovery and no UI, cwd/RNG
  changes or writes. The public loader retains cache/save/filter behavior and
  delegates parsing. No private/MEX/caller-sensitive lookup moved; the existing
  NPY reader and optional `tdfread` remain dependencies, with vendor code intact.
- Preserved label-file precedence and table-order UIDs, case-insensitive labels,
  sample conversion, 0.5 ms deduplication, original spike-row IDs and amplitude
  selection. Frozen comparisons also preserve plugin channel remapping and
  cluster-info precedence, including the legacy `phy_amp = amp + 1` convention
  and plugin shanks surviving a later cluster-info channel override.
- Added explicit errors for malformed/truncated NPY data, invalid/duplicate
  labels, incomplete plugin metadata, missing selected-cell mappings and invalid
  peak channels. Numeric NPY v1.0 is validated before the bundled reader runs;
  other versions/object arrays are outside this boundary. `rez.mat` loads only
  the named `rez` variable, and file handles are closed on failure.
- Extended managed import fingerprints, revision identity and deferred cache
  persistence to Phy. Optional file discovery is rechecked, and amplitude-only
  changes invalidate cache reuse without changing sorting membership. Shank ID
  is bound when supplied; timestamp-only Phy imports retain its absence until
  managed raw waveform extraction supplies channels/groups. A fresh recording
  can now run import, waveform/ACG/core metrics and reuse without old caches.
- Compatibility tightening: Phy `raw_clusters=true` now fails explicitly because
  the old path referenced an undefined timestamp tolerance. Source template
  waveforms are also rejected because Python IDs were used directly as MATLAB
  template indices and scaling/indexing are unvalidated. Use `.dat` waveform
  extraction. Correcting those scientific conventions requires separate work.
- Validation uses controlled synthetic files and frozen legacy results, including
  both cluster-info ID headers, label fallback, channel remapping, malformed
  inputs, public-loader save/filter/failure behavior, managed cache invalidation
  and fresh pipeline reuse. No independent real Phy sorting export is available
  in the supplied tutorial; source-template validation remains outstanding.
- **228/228 regression tests passed** in MATLAB R2024b Update 9, including
  Python-style one-dimensional/big-endian NPY input and cluster ID zero. Code
  Analyzer found no parse diagnostics in 160 files. Every cached tutorial spike
  field matched for 151 cells; original session/spikes/metrics hashes were
  unchanged.
- Next: extend sorting-revision checks to the remaining viewer/curation save
  routes, then implement recovery journaling. Continue other format migrations
  as distinct, reference-tested increments. Work packages 2–4 remain incomplete.

### Viewer save and restore identity checks (2026-10-26)

- Routed ordinary single-session Save, Save As and batch annotation persistence
  through `ce.curation.saveMetricSnapshot`. Existing MAT files require compatible
  cell identities/sorting revisions; batch snapshots also verify session keys and
  order. New exports remain available; existing non-MAT exports require a new
  filename because this boundary cannot verify their identity.
- Replacements now archive the complete previous MAT file with hash verification.
  A backup failure aborts the save, replacing the single-session viewer's former
  best-effort backup behavior. Destination hashes are checked again after staging;
  annotation saves preserve the expected revision from before their file read.
  This is not a lock or conflict detection over the entire editing session.
- Save follows an explicitly loaded filename, clears dirty state only after
  success and persists an empty dirty-cell list. Save As keeps source edits dirty.
  Partial batch saves clear only confirmed sessions. Full-file backups require
  more disk space than the previous annotation-only archives.
- Extracted annotation identity ordering, complete-session snapshots and pure
  restore preparation. Restore checks UID/cluster/revision identity before
  creating a backup or changing viewer state, and maps groups through actual
  batch indices. Count-only legacy backups are rejected rather than guessed.
  Alternate saveAs backups are discoverable in the picker.
- Restore applies through the existing viewer snapshot/rollback boundary. Fixed
  multi-cell history capture so undo restores each cell's own label/region/
  deep-superficial value, instead of repeating the first selected cell's value.
- **240/240 component tests passed** in MATLAB R2024b Update 9; no Code Analyzer
  parse diagnostics in 169 files. Live viewer checks passed on temporary
  151-cell/302-cell copies: Save/Save As conflicts, backup failure, exact backup,
  rejected/successful restore, multi-cell undo, partial batch saves and dirty-color
  preservation. The existing load/reinitialize/comparison rollback smoke also
  passed in table mode 1. Tutorial cached-spike fields and all three original
  session/spikes/metrics file hashes were unchanged.
- Next: harden the two specialized legacy writers (ground-truth subset export and
  manual monosynaptic curation), then implement recovery journaling. Same-sorting
  concurrent editing and the remaining format/UI work are still open; work
  packages 2–4 are not complete.

### Ground-truth and manual monosynaptic save boundaries (2026-10-26)

- Extracted ground-truth subset preparation/export from the viewer. Overlapping
  tags deduplicate cells; source arrays/groups and session-local metadata retain
  identity. Catalog subsets may change only while old cells still belong to the
  same complete source session and declared sorting revision. Existing exports
  get exact backups and checked replacement; cancel/partial failure no longer
  appears to be a successful all-session export.
- Manual connection review now captures both source-file revisions before the
  GUI and checks UID/cluster/shank/positional identities. Managed detections carry
  explicit cell/sorting identity. Versioned metrics reject unversioned detection;
  legacy pairs retain explicit structural identity checks. Nonsequential UIDs are
  mapped to the GUI's positional IDs.
- Separated selection projection, persistence and viewer application. Detection
  arrays cannot change during review. Preserved inhibitory precedence and legacy
  excitatory-only count/histogram rules; retained transmission probabilities are
  subset by pair identity, and unsupported stale probability fields are removed
  for recalculation. Viewer inhibition now clears when the saved selection clears,
  and unrelated annotation edits stay in memory.
- Both MAT replacements are staged and both originals archived before committing.
  A caught second-write failure rolls back the first file only if its new hash is
  still ours. Concurrent edits prevent destructive rollback and report backup
  locations. These checks do not provide crash recovery or a multi-file atomic
  transaction. Exact backup creation is shared with ordinary viewer saves.
- Failed reviews remain in the live viewer for retry. Changed inputs require an
  explicit discard decision before starting a new review; choices are never
  silently rebased. The connection model changes only after persistence succeeds.
  Drafts are not yet persisted across closing/crashing the viewer.
- **253/253 component tests passed** in MATLAB R2024b Update 9; no Code Analyzer
  parse diagnostics in 178 files. Frozen ground-truth projection comparisons,
  revision conflicts, exact backups, injected second-write rollback and refusal
  to overwrite a concurrent edit passed. Live save callbacks passed on a temporary
  151-cell tutorial copy with synthetic connection candidates and stubbed review
  choices. The separate two-unit tutorial pipeline check matched legacy numerics,
  verified invalidation/manual-selection retention and archived previous files.
  All three original tutorial session/spikes/metrics hashes remained unchanged.
- Next: recovery journaling for annotations and pending reviews, including startup
  recovery and identity checks before replay. Same-sorting concurrent annotation
  conflict handling and remaining importer/UI work remain open; work packages
  2–4 are still incomplete.

### Durable annotation and pending-review recovery (2026-10-26)

- Added `ce.curation.recovery` with read-only baseline capture, per-viewer/per-source
  journals, discovery, checked in-memory recovery, retirement and save refresh.
  Drafts live in `<basepath>/.cellexplorer/recovery/`, outside source metric files.
  They contain annotations/identity/dirty UIDs and compact connection selections;
  scientific metrics and CCG arrays are not duplicated.
- Wired checkpoints after completed main-loop callbacks, before Save/session
  replacement, immediately after connection review and at normal exit. The old
  workspace autosave remains, but its pre-edit timing is not used for recovery.
  Unchanged drafts skip rewriting; partial batch errors retain successful state.
- Startup and a File-menu action offer Recover/Later/Discard draft. Recovery checks
  exact source hashes, UID/cluster/sorting identity and loaded baseline annotations
  before transactional application with undo. Pending reviews additionally check
  detection bytes and automatic results. Multiple drafts require choosing one;
  malformed or stale drafts remain on disk for explicit reconciliation.
- Successful saves retire only corresponding owned/accepted drafts. Save As keeps
  source drafts, failed batch sessions retain theirs, and selection discard cleans
  up only after replacement succeeds. Journal replacement/removal checks hashes.
  Review discard does not rebase source hashes. A failed new checkpoint after a
  source save preserves accepted older drafts.
- Added exact previous/staged-file hashes to successful save results. A pending
  review can follow this viewer's own confirmed annotation save only when that
  save replaced its reviewed revision and detection remains unchanged. The review
  can then survive another close/reopen before it is saved. External changes before
  or after the save still reject this transition.
- Recovery covers the last completed checkpoint, not edits inside an unfinished
  callback/review. Read-only/full disks report failures while keeping live edits.
  These are optimistic checks, not a live-instance lock, conflict merge, multi-file
  crash transaction or power-loss guarantee. No original research files were used
  as test write destinations.
- **267/267 component tests passed** in MATLAB R2024b Update 9; no Code Analyzer
  parse diagnostics in 188 files. Live recovery passed across five viewer launches,
  including annotation-only checkpoints, Later, undo, saving annotations before
  a pending review, another recovery and final journal cleanup. Ordinary save/
  restore/partial-batch and specialized-save smoke checks passed. Cached spike
  fields matched for 151 cells; original tutorial session/spikes/metrics hashes
  remained unchanged. Process-kill, power-loss and network-share failures were
  not simulated.
- Next: detect same-sorting annotation conflicts across the whole editing session
  and provide an explicit reconciliation flow. Continue remaining importer and UI
  state-separation work as independent increments; work packages 2–4 remain open.

### Editing-session conflict detection and annotation reconciliation (2026-10-26)

- Ordinary viewer Save, partial batch saves and Save As to a loaded source now
  retain the source revision captured at session opening. A same-sorting change
  blocks the write instead of silently overwriting another user's annotations.
  New connection reviews require that same baseline. Direct scripted annotation
  saves accept an optional expected hash without breaking three-argument callers.
- Capture original disk annotation snapshots alongside normalized viewer recovery
  baselines. Confirmed save receipts advance the expected revision; changes after
  the save are not accidentally adopted. This remains an optimistic check, not a
  filesystem lock or protection against the final check/rename race.
- Added pure three-way merging by session-local UID. Independent scalar edits and
  group memberships combine; differing values and deletion versus editing require
  explicit decisions. Sorting/cluster changes remain nonmergeable identity errors.
- Added File > Reconcile changes from disk, with per-conflict Mine/Disk/Cancel
  choices. It reloads current scientific data, applies combined annotations through
  the viewer rollback boundary, and leaves persistence to a later Save. Checks
  before/after reading, decisions and application reject intervening changes.
  Cancellation preserves old edits/history. Successful reconciliation starts a
  fresh history with undo for the applied annotations; selection/filter state can
  reset, and affected sessions are conservatively marked dirty in full.
- Added explicit pending-review discard so users can reconcile without entering
  another review. Annotation edits survive discard. Prior recovery drafts remain
  until the reconciled state is successfully saved. Merging stale recovery files
  against changed sources is still separate work; this flow handles live edits.
- Fixed an existing theta test's comparison of the shared temporary parent folder
  timestamp. It still verifies the fixture's own directory and contents, while
  ignoring unrelated creation/removal of files in its parent.
- **277/277 component tests passed** in MATLAB R2024b Update 9; no Code Analyzer
  parse diagnostics in 194 files. Live 151-cell and 302-cell checks covered stale
  Save/Save As, conflict cancellation, changes during choices, reconciliation,
  undo and preservation of updated scientific fields. Existing recovery,
  save/restore/partial-batch and specialized-save checks passed. All cached spike
  fields matched; the three original tutorial file hashes remained unchanged.
  Choices were stubbed and races injected deterministically; no filesystem locks,
  physical multi-process race tests or network-share guarantees are claimed.
- Next: extract curation history and edit state from the large viewer into a
  component with explicit operations. Continue remaining importer migration and
  broader recording validation; work packages 2–4 remain incomplete.

### UI-focused review: CellExplorer, NeuroScope2 and session editor (2026-10-26)

The current priority is functionality, performance, robustness and scientific plot
clarity across all three interfaces. This review changes the next-work ordering;
Phy1/Phy2/raw_clusters compatibility remains open in the importer backlog. No
production UI implementation was changed during the review.

Evidence: current source inspection, current rendered screenshots, existing paired
CellExplorer profiles, and isolated MATLAB R2024b checks on temporary copies.
See [observations](benchmarks/ui-review-2026-10-26/observations.json),
[CellExplorer](benchmarks/ui-review-2026-10-26/cellexplorer.png),
[NeuroScope2](benchmarks/ui-review-2026-10-26/neuroscope.png),
[session General](benchmarks/ui-review-2026-10-26/session-general.png), and
[session Extracellular](benchmarks/ui-review-2026-10-26/session-extracellular.png).
The tutorial metadata/metrics supplied the first two views; NeuroScope2 used a
synthetic 16-channel recording. All original session/spikes/metrics hashes remained
unchanged. The full 277-test suite was not rerun for this review. Capture-run
startup observations are not performance benchmarks: they are single trials with
Java code-cache/rendering warnings. Use the earlier balanced profiles only within
their documented limits, and establish fresh baselines before optimization.

#### Findings requiring correction before broader redesign

| Priority | Finding and evidence | Required outcome |
| --- | --- | --- |
| P0 | NeuroScope2 reads with configurable precision but uses two bytes per sample for seeks and duration (`NeuroScope2.m`, `load_ephys_data`, lines 952–981; precision at 5207; duration at 5258). Reproduced: a six-second int32 recording reports twelve seconds; after moving to 0.25 s, the final ramp sample is 1500 instead of 2500. | A typed reader owns bytes/sample, sample indexing, complete reads, EOF and growing-file behavior. Regression fixtures cover int16/int32/single and reject unsupported encodings explicitly. Preserve all scientific unit conversions. |
| P0 | `gui_session` Save calls `readBackFields` and direct `save` without validation (1386, 1441). Typing `not-a-number` into sampling rate saved `NaN` in the temporary session file. Validation is a separate menu action. | Parse and validate a candidate draft before replacing the accepted model or disk file; actionable field errors, checked replacement, backup/revision handling, and preserved edits on failure. |
| P0 | NeuroScope2 closes unrelated file readers with `fclose('all')` (179), reproduced with a sentinel opened before launch. Session switches reset data before successful initialization (7519 onward) and replace file handles without scoped ownership. | Close only owned handles, clean up on errors/switch/exit, and prepare a new session before committing it. A failed load retains the previous data, view, edits and handles. |
| P0 | CellExplorer's recent curation guards are not applied uniformly across the other UIs. NeuroScope2 saves session metadata on normal exit by default (190, 224), and its metric/event save callbacks use generic `saveStruct` (6413, 6421). Session-editor Save uses direct `save`. Generic verified writes do not supply an editing-session revision or curation reconciliation. | Shared persistence contracts appropriate to each file type. Separate viewer preferences from scientific metadata; explicit dirty state; unchanged browsing should not rewrite session metadata. Protect concurrent session, event and cell-metric edits. |
| P1 | Both large viewers delete/recreate plot children during normal updates (`CellExplorer.m` 1530; `NeuroScope2.m` 746). CellExplorer also resets stored zoom state (454) and resamples some >2000-cell overlays on redraw (1648 and similar branches). | Update affected graphics/data only; retain zoom and selection deliberately; keep population sampling stable for the same view. Profile individual paths before claiming gains. |
| P1 | Session-editor numeric arrays use `eval`, including channel coordinates (1243), channel groups (3128) and epochs (3093). Most scalar fields accept `str2double` without finite/range checks. | Explicit parsers supporting documented scalar/list/range syntax, field-level messages, and cross-field validation. Preserve custom metadata fields and legitimate channel-list workflows. |

Additional source-inspection concerns to include in the test matrix:

- `NeuroScope2('session', session)` reads the supplied name/path (84–86), but
  initialization subsequently loads metadata from disk (5146 onward). Verify and
  formalize whether the caller's unsaved struct or the disk session is authoritative.
- The low-frequency display filter downsamples before filtering (1014 onward).
  Review aliasing and edge handling with numerical fixtures as separate scientific
  work; do not hide a formula change in a renderer extraction.
- Slider normalization divides by recording duration minus window duration (155).
  Cover empty/short recordings, equal-duration windows, truncated final samples and
  live acquisition growth. Distinguish load failures from valid empty windows.
- Session-editor OK returns changes without saving, while Save persists and keeps
  the window open; Cancel returns the input struct but cannot undo earlier explicit
  saves/import side effects. Window-close behavior lacks an explicit common contract.
  Button names, dirty state and close decisions should make these distinctions clear.

#### CellExplorer: retain the scientific workflows, simplify review

Functionality:

- Introduce named review layouts for cell classification, recording quality and
  connection review. Keep existing custom plots and shortcuts available.
- Pin a reference cell/session for comparison; show which cells are selected versus
  merely visible, and preview the count/sessions affected by bulk annotation actions.
- Add action/metric search and saved filter presets; expose active filters as a
  compact summary with an obvious reset. Provide explicit missing-data explanations.
- Open NeuroScope2 at the selected cell's session/channel/time interval, with an
  explicit channel-index and time-unit contract.

Performance:

- Separate scientific data, annotation/history state, selection/filter state and
  graphics handles. Extract view-data preparation before changing the renderer.
- Cache population backgrounds by source revision, filters, plotted variables and
  representation; move only the selected-cell overlay during ordinary navigation.
- Reuse scatter/line/image objects and update XData/YData/CData where appropriate.
  Cache invalidation must cover annotation-dependent colors and grouping as well.
- Use deterministic UID-based population sampling and display the sampled/total
  count. Keep full-resolution analysis separate from display simplification.
- Preserve the existing deferred-table improvements. Previous paired measurements
  reduced initialization work (357 to 281 ms); navigation was polling-limited and
  did not demonstrate a meaningful improvement. Do not extrapolate a broad speedup.

Plots and illustrations:

- Label embedding axes specifically (PC1/PC2 and explained variance for PCA), show
  units consistently, and make selected cells identifiable by outline/shape as well
  as color. Respect saved user cell-type palettes.
- Replace crowded vertical epoch text and stacked annotations in firing-rate plots
  with aligned, labeled timeline lanes and hover details. Keep gaps/unknown states
  visibly distinct; expose the displayed time interval.
- Offer density/aggregate views for large populations with explicit counts and
  binning, alongside raw points. Retain spike/waveform detail for the selected cell.
- Share a probe/channel illustration with the other UIs, highlighting the selected
  cell's channel/shank and distinguishing physical coordinates from channel index.

#### NeuroScope2: make time navigation accurate, responsive and legible

Functionality and robustness:

- A recording overview should show the visible window, current epoch, bookmarks and
  edited events. Extend the existing epoch overview rather than adding a competing
  timeline. Provide exact-time jumps and predictable keyboard pan/zoom commands.
- Make event edits undoable and recoverable, with dirty state and checked save
  results. Preserve the active time/channel selection on recoverable failures.
- Show raw/LFP source, precision, sampling rate, filter/reference settings and
  display representation. Clarify which transformations affect analysis versus view.
- Own the binary readers and session replacement boundary independently of figures;
  release only resources belonging to this viewer.

Performance:

- Preserve the existing overlap-reuse and Range/min-max display modes. These are
  already present; the opportunity is better cache boundaries and graphics reuse.
- Cache raw windows, transformed traces and display envelopes separately. Keys
  include file revision/size, channel selection, time range, sampling rate,
  reference/filter parameters and plot representation. Live files need growth-aware
  invalidation. Bound cache memory and cancel superseded work during navigation.
- Update existing trace and overlay handles. Coalesce repeated drag/scroll requests
  so stale windows are not rendered after the user has moved on.
- Extend display reduction according to actual plot pixel width, retaining extrema
  and time alignment. Rendering reduction must never change event detection inputs.
- Profile channel count, window duration, overlays, spectral calculations, filtering
  and file reads separately. Existing built-in benchmark functions are useful
  starting points but need assertions, reproducible fixtures and resource isolation.

Plots and illustrations:

- Make amplitude/time scales and channel identifiers readily visible. The captured
  default view has group colors but lacks on-trace channel numbers and an amplitude
  scale bar; both already exist as options, so improve discoverability/defaults.
- Link trace selection to the probe layout. Use restrained group colors, a consistent
  highlight style and accessible ordered color scales for continuous quantities.
- Give events, spikes, states and behavior separate aligned lanes when needed;
  provide a compact overlay legend and avoid hiding traces under dense annotations.
- Make spectrogram color scale/quantity, frequency axis and processing settings
  explicit. Validate scaling separately before changing existing calculations.

#### Session editor: a validated draft with visual context

Functionality and robustness:

- Edit a draft that preserves unknown/custom fields. Distinguish Apply to caller,
  Save to file and Discard local changes, while retaining the public return-value
  contract for pipeline and viewer callers.
- Reuse `ce.data.validateSession` for required metadata and cross-field checks;
  augment it with precise field locations and editor-friendly messages. Validation
  should identify sample/channel counts, finite rates, group membership, coordinate
  lengths, epoch bounds and missing paths without silently coercing values.
- Show a summary of changes before imports/templates replace existing metadata,
  including source and affected fields. No incidental save merely from inspection.
- Provide a file/path status and explicit target filename, rather than inferring
  save destination from substring comparisons with the current working directory.

Performance and plots:

- The captured editor eagerly creates 14 tables and 158 controls, including hidden
  tabs. Measure tab initialization and large channel-group updates before introducing
  lazy creation; validate the whole model even when controls have not been built.
- Embed a probe preview beside electrode/spike groups: linked row/site selection,
  groups, regions, bad channels, channel IDs and coordinate units. Avoid requiring
  inspection of long coordinate strings or labeling every site at every zoom level.
- Embed an epoch timeline alongside the table, showing ordering, gaps, overlaps and
  recording bounds. Changes should update both views from the same draft model.
- Add compact acquisition summaries (duration, samples, channels, dtype, byte-size
  consistency) and a prioritized validation list that navigates to the relevant field.

#### Shared implementation and acceptance sequence

1. **Correctness and editing contracts.** Fix NeuroScope2 byte indexing, scoped
   readers and failed-load preservation; add session-editor candidate validation and
   guarded saves; close the remaining cross-UI curation save bypasses. Add temporary
   fixtures covering invalid input, canceled dialogs, read-only destinations,
   concurrent changes, EOF/short files and cleanup. Keep original recordings read-only.
2. **Measurable responsiveness.** Establish comparable first-ready, input-to-painted
   response, p50/p95 navigation, handle counts and peak-memory measurements. Use
   151/302 tutorial cells, larger independent recordings when available, and synthetic
   16/128/384-channel traces at multiple rates/durations. Warm runs and startup runs
   are separate; measure actual painting rather than a coarse timer polling interval.
   Candidate target: cached selection updates below 100 ms and ordinary cached pan
   below 150 ms on the documented reference fixture. These are targets, not claims.
3. **Visible workflow/plot improvements.** Deliver shared scale/legend/selection
   conventions, session probe/epoch previews, CellExplorer pinned comparisons and
   clear timeline lanes, and NeuroScope2 visible-window/channel context. Review
   resized/HiDPI views and light/dark/export variants; check for clipped text and
   distinguishable categories without relying only on color.
4. **Reproducible figures and connected workflows.** Extend existing PNG/PDF export
   with consistent sizing/fonts/backgrounds, axis limits, units and an optional
   metadata sidecar containing source revision, selected UIDs/channels, time window,
   filters and display sampling. Export from a view snapshot so export styling does
   not mutate the live axes. Validate selected-cell/session/time handoff between UIs.

Continue within MATLAB's current interfaces while extracting components under
`+ce/+ui`, `+ce/+plotting`, `+ce/+io` and `+ce/+curation`. Do not commit to a framework
rewrite before a representative plotting prototype demonstrates compatibility and
measured benefit. Keep scientific changes separate from UI changes, preserve custom
plot/plugin entry points, and retain explicit file/identity/unit contracts.

### UI implementation: binary readers and validated metadata edits (2026-10-26)

First delivery within UI step 1 (correctness and editing contracts):

- NeuroScope2 now routes raw, LFP, analog and packed-digital windows through
  `ce.io.binaryPrecision`, `binarySampleCount` and `readBinaryWindow`. Offsets are
  zero-based samples multiplied by the declared scalar width and channel count;
  incomplete trailing frames are excluded. Raw precision comes from
  `extracellular.precision`; LFP uses `extracellular.precisionLfp` when supplied,
  otherwise `int16`, independently of raw precision.
- The raw-window cache retains overlap in both navigation directions and avoids
  reads when the window is unchanged. It is bounded to one window and keyed by
  reader/file, precision, channel count, file size and modification time. Growth
  invalidates it. This is display caching, not content-hash provenance; a same-size
  rewrite with an unchanged filesystem timestamp cannot be detected by this key.
- Reader ownership is scoped to the viewer, including exceptional exit. Reloads
  close the previous readers; closing NeuroScope2 no longer calls `fclose('all')`.
  Short recordings bound the window to complete samples, the slider avoids zero
  division, and read failures clear traces and suppress dependent plots.
- `gui_session` parses numeric literals/lists/ranges without `eval`. Missing
  coordinates may use `NaN`; rates, counts and indices may not. Apply and Save
  validate a candidate and preserve the prior draft/typed controls on failure.
  The editor profile reuses `ce.data.validateSession`, permits unsorted recordings,
  and adds precision, optional scalar, coordinate-length and time-series checks.
  Custom fields survive edits. Digital-stream gain metadata may be zero.
- The buttons now distinguish **Apply & Close** (validated return to caller),
  **Save** (disk write), and **Cancel** (restore input values; already saved files
  remain saved). Title-bar close follows Cancel and also restores input parameters.
  Upgrading old metadata through the template no longer immediately saves it.
- Saves retain the explicitly opened filename, use canonical paths, handle picker
  cancellation, and check the revision captured when editing began. Existing
  destinations get an exact-byte backup under `revisions_session/`; replacement is
  staged and its full session value verified before the last revision check.
  These are optimistic checks, not an interprocess filesystem lock.

Verification:

- MATLAB R2024b Update 9: **289 component tests passed**; **204 files** checked
  without parse errors. Binary tests cover all ten scalar precisions, overlap in
  both directions, cache hits/growth, EOF/partial frames and reader ownership.
  Metadata tests cover parsing, unsorted sessions, invalid values/groups/epochs,
  unknown fields, literal matrix/column shapes, relative paths, exact backups,
  revision conflicts and backup failure.
- Opt-in `tests/integration/runUIRobustnessSmoke.m` exercises live callbacks on
  copied tutorial metadata and synthetic recordings. A `uiwait` shim invokes
  callbacks after construction/plotting, avoiding timer/graphics races. All eight
  scenarios passed across isolated runs, including a relative, nonstandard session
  filename. Repeated GUI launches showed Java code-cache warnings and intermittent
  stalls in this installation; run `1:3`, `4:6`, `7` and `8` in separate MATLAB
  processes. These are correctness checks, not UI timing measurements.
- Original tutorial session, spikes and cell-metrics hashes remain unchanged.

Still open within UI step 1: transactional NeuroScope2 session replacement after a
failed reload; explicit dirty/save decisions and revision checks for its metadata,
metrics and event writers; broader import/template draft handling. Its current
save-on-exit preference is unchanged. Filtering/scientific calculations are also
unchanged. Steps 2–4 (response profiling/graphics reuse, probe/epoch previews and
plot styling/export) remain pending; this delivery does not claim speed targets or
a completed visual redesign. CellExplorer's rendering changes have not begun.

### NeuroScope2 layout and feature research (2026-10-26)

Requested focus: make sidebar elements easier for contributors to add and resize,
and identify useful plots/functions beyond the current viewer.

#### Finding: layout sizes have several independent sources

`NeuroScope2.m` uses `uix.GridFlex`, `VBox`, `HBox` and `ScrollingPanel` for its
outer layout, but most section contents still use normalized `Position` vectors.
The General tab sets section `Heights`/`MinimumHeights` and separately assigns a
975-pixel scroll minimum. Data initialization repeats the section-size logic with
another total (`605 + ...`). The analysis tab separately specifies five section
heights and a 510-pixel scrolling minimum. Contributors therefore have to keep
control positions, section dimensions, and tab totals synchronized.

There are also conflicting sidebar minimum widths: the 220-pixel minimum is
immediately replaced with 5 pixels. The lower status/navigation strip has many
fixed-width columns. These need explicit narrow-window behavior, not just changes
to sidebar panel totals.

#### Recommended architecture: sections measured from their rows

Keep the current figure/axes and bundled layout toolbox for the first migration.
Add a small shared layout layer under `+ce/+ui/+layout`, with NeuroScope2 section
builders under `+ce/+ui/+neuroscope`. This is a proposed API, not implemented code.

- A section defines an ID, title and ordered rows. Row types cover labeled fields,
  checkbox/field pairs, button groups, bounded tables, plots and custom content.
  Each exposes its preferred/minimum size, visibility and resize policy.
- Centralize control height, font, label width, padding and spacing policies.
  Measure label text where necessary; account for native widget minimums. Text
  controls retain usable heights while value columns stretch horizontally.
- Derive section height from visible rows, spacing, padding and title/border size;
  derive the scrolling extent from the visible sections. Calculate this in one
  place when rows are added, hidden, expanded or resized. Callers never maintain a
  second total. Uix supplies allocation; the new layer supplies measurement.
- Support collapsible sections and an Advanced group. `uix.BoxPanel` already has
  collapse hooks; the parent must also reclaim the collapsed section's height.
  Preserve state by stable section IDs, not child order. Do not assume `Visible`
  alone removes a layout slot.
- Give tables a bounded viewport and internal scrolling, rather than expanding
  every table to the entire recording's channel/event count. Avoid conflicting
  mouse-wheel behavior between table and sidebar scroll containers.
- Reflow label/field pairs vertically when narrow; define a usable minimum sidebar
  width and a separate collapsed-sidebar mode. Reflow the bottom strip or move
  low-priority status text into a secondary row.
- Separate layout updates from trace recomputation. Resize/reflow should update
  existing handles; adding many rows should trigger one layout pass. Guard against
  resize feedback loops. Lazy construction of optional sections is a later,
  measured optimization, not a prerequisite for this layout change.

A contributor should be able to add a numeric field with its label, units, default,
validation and callback in one section builder. No normalized coordinates or tab
height edits should be required. Start with regular MATLAB functions/structs and a
small set of row builders; avoid inventing a general UI configuration language.

For optional panels, add a registration contract: stable ID/title/order, a
`create(parent, context)` function, preferred-size notification, update hooks and
cleanup. Pass explicit state access/commands to new panels instead of exposing all
nested variables. Keep existing `+analysis_tools` entry points working through an
adapter; those already offer user extensions, but their current inputs expose
`UI`, `ephys` and `data`, and category dispatch is hard-coded.

#### Alternatives and local compatibility checks

MathWorks' [grid layout manager](https://www.mathworks.com/help/matlab/ref/uigridlayout.html)
supports fixed, proportional and content-fit rows/columns. It is a strong option
for a future programmatic `uifigure` UI; App Designer files are not required.
However, the [migration workflow](https://www.mathworks.com/help/matlab/creating_guis/modern-programmatic-app-building.html)
includes controls, callbacks, containers and dialogs. Its documentation also
explains current-figure/current-axes differences. NeuroScope2's implicit graphics
targets, drag/zoom, ROI tools, streaming, keyboard handling, exports and extensions
need representative validation before selecting that migration.

A temporary isolated probe on MATLAB R2024b Update 9 found:

- `uigridlayout` rejected a classic `figure` parent.
- A `uifigure` grid with modern labels/fields and fit sizing was created.
- A legacy `uicontrol` could be parented to that grid, but it had no `Layout`
  property. Constructor success is not proof of compatible grid behavior.
- Existing `uix.VBox`/`HBox`/`ScrollingPanel` containers accepted a central row-size
  calculation: adding four 28-pixel rows changed the derived scroll minimum to
  40, 72, 104 and 136 pixels, including padding/spacing, without separate totals.

This was a feasibility check, not a full responsive-layout implementation or a
performance/HiDPI benchmark. No production UI code changed in this research pass.

The repo bundles GUI Layout Toolbox **2.3.5**. The upstream
[release history](https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox)
currently lists **2.4.2**, with intervening web-graphics, theme and panel changes.
Evaluate an upgrade independently; upgrading alone will not remove hard-coded
NeuroScope2 geometry, and it affects CellExplorer/gui_session as well.

#### Useful additions, distinguished from existing functions

The viewer already has spectrograms, CSD, RMS inset, instantaneous signal/power/
phase, population rate, waveforms, probe coordinates, an epoch strip and a summary
figure. `+analysis_tools` adds linear/log PSD, channel correlation, temporal offsets,
RMS, CCGs and rasters. These need discoverability and integration improvements;
they should not be presented as wholly missing analyses.

| Priority | Addition or extension | Concrete benefit and scope |
| --- | --- | --- |
| 1 | Recording overview and named bookmarks | Extend the existing epoch strip/summary with a visible-window rectangle, clickable event/state lanes, named bookmarks and a cached multiresolution amplitude/activity overview. Avoid scanning the full raw file on every pan. Navigation history already exists; persistent named bookmarks are the addition. |
| 1 | Channel-quality map | Extend the existing probe view with RMS, clipping fraction, flatline indicators and line-noise measures for an explicitly selected interval. Link site selection to traces and a channel table; show gaps/unknown coordinates rather than inventing physical placement. RMS already exists; integration and additional quality indicators are new. |
| 2 | Event-aligned trace browser | Select events and channels, then show a trial-by-time heatmap, individual/mean traces and event context; allow jumping back to the source event. Report included/excluded events and boundary handling. This complements existing event overlays, rasters and CCGs. |
| 2 | Raw/processed comparison | Linked views of the same samples before/after the selected filter/reference, with units, amplitude scales and processing labels. Explicit channel selection for reference calculations could extend the current median-across-channels option; changing reference math is a separate scientific change. |
| 2 | Linked spectral inspection | Promote existing PSD and spectrogram tools into discoverable panels with shared channel/time selection and consistent quantity/units. A frequency-by-channel/depth heatmap adds a useful view; label channel index when physical depth is unavailable. Audit existing display-scaling dependencies before reusing calculations. |
| Later | Coherence and band-power maps | Add only for a defined scientific workflow, with explicit windows, estimator, reference and channel-pair selection. Keep numerical validation separate from layout refactoring. |

Workflow gaps worth pairing with the layout work: searchable controls/actions,
saved view presets, persistent named bookmarks, undo/redo for event edits, dirty
state and guarded saves, and visible raw/LFP/reference/filter status. Existing
notes, event flags and navigation history should remain supported. Heavy analysis
panels should update on demand or after navigation settles, with cancellation and
stale-result rejection; layout flexibility should not cause more recomputation.

#### First implementation slice and acceptance

Convert the General tab's Extracellular/filter section to the proposed row-based
builder while preserving its handles/callback behavior. Make section measurement
and the scroll extent follow its contents. Add one optional example field through
registration to demonstrate that no parent dimensions need editing. Then migrate
Navigation, Events, Spectrogram and the remaining sections incrementally.

Check add/remove/hide/collapse, reorder by ID, saved preferences, empty/large tables,
long labels, larger fonts, narrow/wide sidebars and repeated resizing. Include
macOS/Windows and HiDPI review when those environments are available. Verify
callbacks still address the same settings, resizing does not recompute traces or
leak handles, and extension failure leaves the core viewer usable. Only then add
new plots, beginning with overview/bookmarks and the channel-quality view.

### NeuroScope2 row-layout pilot implemented (2026-10-26)

The first layout slice from the research proposal is implemented:

- Extracted the Extracellular/filter controls to
  `ce.ui.neuroscope.buildTraceSection`, preserving their existing handle names,
  defaults and callbacks. Its row definitions contain no normalized positions.
- Added `ce.ui.layout.RowSection` for labeled fields and paired controls with
  stable IDs, adding/removing/hiding rows, collapse/expand, font sizing and
  narrow-width reflow. Hiding/collapsing preserves typed values.
- The General tab derives its scrolling extent from actual section requirements;
  the separate 975-pixel initial total and `605 + ...` reload total are removed.
  Metadata-driven table minima remain in place for sections not yet migrated.
- Restored the intended 220-pixel minimum sidebar width by removing the immediately
  following assignment that replaced it with 5 pixels.
- Parent height updates are deferred/coalesced outside the current `uix` redraw.
  Visual verification caught reentrant resizing that could position siblings using
  stale dimensions; the binding now settles pending sizes and disposes its timer
  and listeners on section destruction. Layout changes do not invoke filtering or
  other analysis callbacks.

Contributor instructions and an optional-field example are in
[development/README.md](README.md#adding-neuroscope2-trace-controls-2026-10-26).
No changes to parent dimensions are needed when adding that field. This is a
reusable row API, not yet a complete external panel/plugin registry.

Verification covers extension, hide/remove, collapse, font changes, narrow/wide
layouts, repeated resizing without handle growth, parent scrolling requirements,
callback preservation and timer cleanup. Live smoke scenario 9 uses synthetic
recordings and copied metadata, including real filter and LFP-switch callbacks.
The next sections to migrate are Navigation, Events and Spectrogram. Saved
collapse/layout preferences, the remaining tabs, the lower status strip, and
Windows/HiDPI review remain open; the plots proposed in the research section are
also still pending.

Final verification for this pilot: **296 tests passed** in MATLAB R2024b Update 9;
**210 files** passed parse checks. Scenario 9 passed with original tutorial
metadata unchanged, and its settled view was visually inspected. The synthetic
[layout preview](benchmarks/neuroscope-row-layout-2026-10-26/neuroscope.png) records
the migrated section after exercising filtering and LFP switching. MATLAB emitted
its previously observed Java code-cache warning during GUI checks; no response-time
benchmark or cross-platform rendering claim is made here.

### NeuroScope2 measured sections expanded (2026-10-26)

Navigation, Event controls and Spectrogram now use dedicated row-based builders.
Navigation retains playback/time/amplitude callbacks; events retain their table,
selection, flagging, editing and save callbacks; spectrogram settings retain the
existing calculation and validation. Labeled event counts and frequency fields
make their meaning visible without relying on tooltips. Button groups reflow
vertically when needed, and all three sections support collapse/expand.

All four sidebar tabs now calculate their scrolling minima from section heights,
minimum sizes, spacing and padding. This removes the remaining duplicated tab
height totals. Legacy sections still specify their own individual dimensions;
only the four migrated sections automatically measure their contents.

Next: migrate the remaining analysis controls (CSD, instantaneous metrics,
RMS noise and audio), then spike/state/behavior controls and the lower
status strip. Saved layout preferences and an external section registry remain
follow-ups. The proposed overview/bookmark and probe-quality plots are still
pending. Event persistence and transactional session reload remain separate
robustness work; this increment does not change their behavior.

Verification: **299 component tests passed** and **213 files passed parse checks**
on MATLAB R2024b Update 9/macOS. Live scenario 10 passed with the tutorial session
SHA-256 unchanged across the run. The synthetic
[General](benchmarks/neuroscope-sections-2026-10-26/neuroscope-general.png),
[Events](benchmarks/neuroscope-sections-2026-10-26/neuroscope-events.png) and
[Spectrogram](benchmarks/neuroscope-sections-2026-10-26/neuroscope-spectrogram.png)
captures were visually inspected. Windows/HiDPI review and performance benchmarks
remain pending. MATLAB again emitted its Java code-cache warning during GUI tests.


Navigation follow-up: restored the original compact arrangement at the user's
request, including its 65-pixel panel and stacked central amplitude arrows.
Its builder and existing callbacks remain separate from the main viewer. The
sidebar still derives its total scroll height; Events, Spectrogram and trace
controls retain their measured rows. Navigation no longer collapses or reflows
into separate button rows. The earlier General preview shows the superseded
navigation arrangement. The
[restored navigation preview](benchmarks/neuroscope-sections-2026-10-26/neuroscope-navigation-restored.png)
was visually checked, and live smoke scenario 10 passed again.
The regression run also exposed a timer firing while a sidebar container's child
list and size vectors were temporarily out of sync. SectionBinding now defers
that update until the container finishes registering its children.
It also skips updates while any parent is being deleted: MATLAB can dispatch a
timer after the scrolling panel's internal controls are removed but before the
section destruction listener runs.
Final follow-up verification: 299 component tests passed, plus three consecutive
runs of the ten layout tests, with no layout timer errors in the final run.
