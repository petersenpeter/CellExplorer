# Developing CellExplorer 2.0

This directory holds internal development plans and contributor guidance.
The `docs/` directory contains the public documentation website.

See the [modernization plan](cellexplorer-2.0-plan.md) and
[migration inventory](migration-inventory.csv) for scope, ownership and progress.

## Running tests

From the repository root in MATLAB:

```matlab
run('tests/run_tests.m')
```

Or from a shell with MATLAB on the path:

```sh
matlab -batch "run('tests/run_tests.m')"
```

The runner adds the root and legacy compatibility directory temporarily, restores
the MATLAB path afterward, and fails if a test fails. Tests use temporary synthetic
data; no database, personal recordings, GUI interaction or MatNWB installation is
required. CI runs the same command on R2024b. This is the tested development
baseline, not a new minimum MATLAB version for the entire application.

## Current component APIs

- `ce.io.saveCellMetrics(metrics, file)` supports MAT, JSON and the existing NWB
  adapter. Unsupported formats throw errors instead of appearing successful.
- `ce.io.saveStruct(data, datatype, 'dataName', name, ...)` uses an explicit data
  name. The legacy `saveStruct` preserves caller-variable inference, including
  `saveStruct(session)` and interval-specific metric filenames.
- `ce.io.writeMat(file, variables)` stages named MAT variables, verifies their
  directory metadata and replaces the destination. `ce.io.writeJson` writes
  literal UTF-8 JSON and verifies decoding. Temporary files share the destination
  directory and are cleaned up on failure.
- `ce.curation.applyAnnotations(target, source, indices)` matches session-local
  UIDs, checks cluster IDs when available, and remaps annotations and group indices
  into the on-disk order. It leaves computed metrics untouched.
- `ce.curation.saveSessionAnnotations(file, source, indices)` validates, backs up
  existing annotations in that session, and saves. Failed backups abort the write.
- `ce.curation.remainingChanges` clears dirty cells only for confirmed saves.
- `ce.data.validateCellMetricsStruct` owns the existing validator. An empty nested
  plot-data struct now passes without an indexing error; metric formulas are unchanged.
- `ce.metrics` owns the migrated Gini, spatial splitter, log ISI and waveform
  calculations. Their implementations are unchanged, including plotting defaults.

Legacy functions remain in `calc_CellMetrics` and forward to these APIs. Keep the
repository root on the MATLAB path so package functions resolve. Existing
`addpath(genpath(...))` installations continue to work. Package callers can use
the migrated core with just the repository root, except NWB export, which still
uses the legacy MatNWB adapter and its existing installation requirements.

## Limits of this milestone

Verified replacement is not a multi-file transaction, a concurrent-edit lock or a
guarantee against power loss. Filesystem rename semantics vary on network shares.
MAT verification checks names/classes/sizes, not a second full read of the payload.
NWB verification checks the HDF5 container; full MatNWB compatibility still needs
format-specific integration tests.

UID/cluster checks detect changed counts, reordered units and changed identifiers.
They cannot detect a new sorting that reuses both identifiers. Pipeline saving now
checks metric/session file revisions; this is not a general curation lock. Sorting
revision IDs remain planned. Disk recovery, cache invalidation for the remaining pipeline
stages and UI performance changes are subsequent work packages.

## Session validation and headless processing

Validate metadata without displaying a window or writing files:

```matlab
report = ce.data.validateSession(session);
report = ce.data.validateSession(session, 'checkFiles', false); % Metadata only
```

`report.valid`, `report.errors`, `report.warnings` and `report.checks` are usable
from scripts. Checks contain `code`, `path`, `severity` and `message`. Required
metadata, channel/group indices and counts, epochs and paths are checked without
changing the session. Missing raw data and sorting directories are warnings here,
because cached analyses may not need them. The legacy `validateSessionStruct`
still displays a window; `ce.ui.showValidationReport` renders the structured report.

Run a read-only pipeline preflight with the same name/value options used by
`ProcessCellMetrics`:

```matlab
report = ce.pipeline.preflight('basepath', basepath, ...
    'metrics', {'waveform_metrics'}, 'getWaveformsFromDat', false, ...
    'excludeManipulationIntervals', false);
disp(report.errors)
```

Preflight defaults to headless mode. It reads local metadata and cached/supplied
spikes, checks selected-stage prerequisites and dependencies, validates intervals,
and rejects mismatched cell identities/order in a reused metric cache. It returns
resolved options in `report.parameters`; it does not call processing or preference
callbacks. Missing inputs produce actionable checks rather than dialogs.

To process after reviewing preflight, pass `'headless', true` to
`ProcessCellMetrics`; it repeats preflight before computing. Headless mode overrides
all figure/GUI flags, debug plotting, manual monosynaptic adjustment and automatic
file transfers to false, and avoids database setup. Ordinary interactive defaults
are preserved. A headless run is **not read-only**: it can save metrics and ancillary
stage outputs. `saveMat=false` alone does not disable every legacy stage's writes.
Use a separate working copy when testing a recording.

The initial headless boundary has explicit limits:

- Supply `spikes` or an existing `basename.spikes.cellinfo.mat`. Import or refresh
  original sorting output separately; `forceReloadSpikes` is rejected.
- MAT is the pipeline cache format; export JSON/NWB separately afterward.
- Custom calculation/preference callbacks and database submission are rejected
  until their noninteractive behavior has a defined contract.
- Deep/superficial import uses an existing channel-classification file. Ripple
  detection and classification preparation are separate operations.
- Dependency checks are conservative for requested stages, including cached stages.
  Complete stage extraction and cache freshness outside the stages below remain
  future work; matching UIDs/cluster IDs does not prove unchanged input data.

An opt-in integration check copies only metadata, spikes and metrics to a temporary
directory, forces waveform-metric recalculation, checks firing rates and cell IDs,
verifies saved output, checks for figures/cwd changes, and deletes the copy:

```matlab
addpath('tests/integration')
summary = runTutorialSessionSmoke('/path/to/tutorial/session');
acgSummary = runTutorialAcgSmoke('/path/to/tutorial/session');
monoSummary = runTutorialMonoSynSmoke('/path/to/tutorial/session');
intervalSummary = runTutorialIntervalSmoke('/path/to/tutorial/session');
importSummary = runTutorialImportSmoke('/path/to/tutorial/session');
thetaSummary = runTutorialThetaSmoke('/path/to/tutorial/session');
deepSummary = runTutorialDeepSuperficialSmoke('/path/to/tutorial/session');
coreSummary = runTutorialCoreSmoke('/path/to/tutorial/session');
classSummary = runTutorialCellClassSmoke('/path/to/tutorial/session');
loaderSummary = runTutorialLoaderSmoke('/path/to/tutorial/session');
viewerSummary = runTutorialViewerLoadSmoke('/path/to/tutorial/session');
displaySummary = runTutorialDisplaySmoke('/path/to/tutorial/session', 10);
profileSummary = profileTutorialViewer('/path/to/tutorial/session', 10);
```

This integration check needs the recording and the relevant MATLAB toolboxes. It
is not part of CI and does not exercise raw waveform extraction or every metric
stage. Keep the current checkout's root and `calc_CellMetrics` ahead of older
CellExplorer installations on the MATLAB path when running interactive checks.

## Stage execution and cache provenance

`ProcessCellMetrics` now uses `ce.pipeline.runStage` for `waveform_extraction`,
`waveform_shape`, `waveform_localization`, `acg_metrics` (wide/narrow and log
ACGs, fits, log ISIs and optional population modulation), `monosynaptic_detection`
`monosynaptic_metrics`, `event_metrics`, `manipulation_metrics`, `state_metrics`,
`spatial_metrics`, `psth_metrics`, `theta_signal`, `theta_metrics` and
`deepSuperficial`, `other_metrics` and `cell_class_import`. Definitions declare
owned/required outputs and implementation dependencies. Legacy public metric
functions remain available; their scientific formulas are unchanged.

Reuse requires matching SHA-256 fingerprints of consumed input arrays and cell
identities, effective intervals/preferences/seed, implementation files (including
the resolved CCG MEX), MATLAB/platform/toolbox versions, and current stage outputs.
Missing provenance triggers one recalculation. Edited or missing outputs also
invalidate the cache. Hashing uses the JVM and reads the actual in-memory inputs;
it does not prove that an upstream spike-sorting cache matches the recording.
When raw waveform extraction is selected, its additional recording hash establishes
the content identity used to generate those waveforms.

Inspect results and generation provenance separately:

```matlab
runInfo = cell_metrics.general.processinginfo.latestRun;
disp({runInfo.stages.name; runInfo.stages.status; runInfo.stages.reason})
acgOrigin = cell_metrics.general.processinginfo.stages.acg_metrics;
```

Each result is `completed`, `reused`, `skipped` or `failed`. A reused or skipped
stage keeps its original generation date, settings, input/output hashes and code
revision. Legacy top-level `processinginfo.params` and `date` describe the latest
invocation, not every cached field. A stage operation returns a patch; failure
leaves the input metrics unchanged, and the pipeline throws before saving its
metrics file. Optional outputs owned by a rerun stage are removed when it no
longer produces them. This is not a transaction over every legacy stage's files.

`randomSeed` defaults to `0`. Migrated stages and waveform sampling isolate and
restore the caller's RNG. Headless ACG fitting/log-ACG calculation use serial
execution and do not start a parallel pool. Interactive calls keep their existing
parallel default. The serial fitter now honors its plotting flag.

Other metric stages and sorting import remain legacy steps. Filtering that
removes cells rejects an incompatible existing metrics cache before importing
fields; use a separate `saveAs` or a complete recomputation with curation preserved
separately.

The waveform integration check verifies reuse and seed invalidation on all cells.
The ACG check uses two actual units over the first 120 seconds, verifies results
against standalone calculations, changes the interval to 60 seconds, checks reuse
and skipped provenance, and injects a failure to verify saved metrics survive.

## Raw waveform and localization stages

When `waveform_metrics` and `getWaveformsFromDat=true` are selected, extraction
uses a separate `basename.<saveAs>.waveformExtraction.cache.mat` sidecar. It stores
the named `waveformCache` variable, extracted waveform fields, and generation
provenance. The cache key includes raw-file SHA-256, selected spike times/sample
indices and identities, acquisition metadata, channel groups/tags, sampling seed,
window settings and implementation dependencies. A restricted analysis cannot
replace the canonical `basename.spikes.cellinfo.mat`.

**Raw verification reads the entire `.dat` file on each invocation**, in bounded
chunks. This favors exact content identity over timestamp-only reuse, but can be
expensive for large recordings and network storage. Size/modification-time guards
reject ordinary changes during hashing or extraction; there is no filesystem lock
or guarantee against concurrent edits that preserve both attributes. Full-size raw
recording performance has not yet been benchmarked. The managed extractor currently
accepts `int16` only because the legacy algorithm assumes two bytes per sample.

Cache persistence uses verified replacement after the requested calculations and
validation succeed. The sidecar and metrics are separate writes, not a multi-file
transaction. A valid sidecar may remain if the subsequent metrics write fails.
`saveMat=false` writes neither sidecar nor metrics through these stages. Managed
extraction suppresses noise/figure-file exports and propagates bad-channel detector
failures; direct legacy calls retain their existing defaults. With raw extraction
disabled, supplied/cached waveforms remain the authoritative input.

Localization owns trilaterated positions, waveform length constants, effective
channel coordinates and optional CCF positions. It fingerprints these dependencies
independently, so coordinate-only changes do not invalidate waveform shape or ACGs.
Removing a CCF file removes its old stage-owned outputs. Coordinate precedence is:
explicit session x/y, `basename.chanCoords.channelInfo.mat`, `chanMap.mat`, a tagged
`analysisTags.chanMapFile`, then generated coordinates. File-derived coordinates
are stored in metrics, not silently promoted to authoritative session coordinates
that would hide later file edits. Existing explicit session coordinates still win.

Synthetic tests exercise actual binary extraction, legacy numerical agreement,
same-size raw-file edits, restricted inputs, deterministic reuse, failure paths,
and complete pipeline sidecar persistence. CI requires Statistics, Curve Fitting
and Signal Processing toolboxes; theta tests also require Image Processing.
Tutorial checks additionally compare 151-cell
localization to a captured pre-extraction baseline and test a coordinate shift
on two units; no full tutorial raw extraction has been run.

## Monosynaptic detection and review

Automatic detection and metrics derived from accepted connections have separate
stage records. The existing `basename.mono_res<suffix>.cellinfo.mat` filename and
`mono_res` variable remain compatible with `gui_MonoSyn`. The scientific detector,
convolution and transmission-probability formulas are unchanged.

`mono_res.processinginfo.detection` records spike times, UID/cluster/shank identity,
intervals, detection settings (including inhibitory detection), code/native
dependencies, environment and output fingerprints. The optional probability table
is fingerprinted at the path actually used by the legacy detector. The bundled
file is named `ProbSynMat.mat`, while that detector looks for `ce_ProbSynMat.mat`;
this existing optional-resource behavior has not been changed by the migration.

The automatic output hash excludes editable pair selections. Changes made by the
legacy GUI therefore preserve detection reuse and only invalidate the derived
connection metrics. Reviewed pairs must be a unique subset of the detected
candidates, and `sig_con` must agree with `sig_con_excitatory`. Matching provenance
preserves reviews even during an otherwise identical forced recomputation.

When provenance differs or is absent, prior selections are not applied to the new
detection. The pipeline reports that decision, and every changed on-disk file is
archived byte-for-byte under `revisions_mono_res/` before replacement. Archive
names include the original file hash. Failed backups or an intervening file edit
abort the save. `processinginfo.review` records whether selections are automatic,
preserved external edits, or returned from interactive review; `review_returned`
does not assert that a user approved every pair. The latest review status is also
available in `cell_metrics.general.processinginfo.monosynapticReview`.

Manual review stays in `ce.ui.reviewMonoSyn` and is never invoked headlessly.
Detection and review do not write files; successful pipeline finalization handles
the verified save. `saveMat=false` also suppresses monosynaptic-file/backup writes.
File revision checks are not a lock, and saving connections and cell metrics is
not a multi-file transaction. Direct calls to the legacy GUI with a filename still
use its legacy save behavior.

Two projection bugs are explicitly fixed: inhibitory-only detections now reach
the metrics, and an empty selection resets stale synaptic-effect labels to
`Unknown`. In/out connection counts retain their established excitatory-only
meaning. Units with no spikes after exclusion are rejected with an actionable
error rather than passed into the legacy detector's positional indexing.

The opt-in native smoke test compares two tutorial units with the legacy detector,
tests interval/option invalidation and no-write execution, then uses coupled
synthetic spike trains to verify manual rejection survives reruns and force reload.
These native tests are separate from hosted CI. Interactive GUI review and
full-population detection have not yet been validated in this milestone.

## Event, manipulation and state inputs

The three interval stages read only the named struct from each matching MAT file,
hash the complete file, and record consumed data, effective preferences, selected
spikes and output ownership. Changes to one input family invalidate that stage
independently. Preflight validates the named structs, finite Nx2 intervals and
output-name collisions without calling preference callbacks. Manipulation files
used for spike exclusion are checked even when manipulation metrics are skipped.
State processing requires `ints`; event/manipulation processing requires
`timestamps`. Peak-aligned PSTHs additionally require one finite peak per event.

Stages declare dynamic scalar fields alongside `events`, `manipulations` and their
`general` metadata. Removing, renaming or ignoring inputs clears their old fields
after successful calculation. Empty event files/empty state intervals do not
produce undefined metrics. A skipped stage retains its outputs and provenance.
Duplicate state names or event/manipulation names that would overwrite the same
scalar metrics fail with an explicit collision error.

Output ownership is stored in each stage's provenance. Existing legacy plot/state
metadata also identifies fields to retire on the first managed run. Flat orphaned
fields with neither ownership nor supporting metadata cannot be attributed safely
and are not guessed from their suffix alone. Known retired fields are cleared only
after the new calculation succeeds; unrelated fields remain outside stage cleanup.

PSTH settings preserve existing behavior: events may have per-name preferences,
while manipulations use the common settings and the legacy default `intervals`.
Sampling rate comes from session metadata. This extraction preserves the legacy
PSTH and state formulas, including state-mask/ISI indexing, denominator conventions
and PSTH center alignment. Those numerical conventions need a separate scientific
audit; agreement with the old implementation does not establish their correctness.

The native interval smoke test uses two tutorial spike trains and synthetic event,
manipulation and state files in a temporary directory. An optional function handle
can compare results with a pre-extraction pipeline snapshot. Tests cover reuse,
file changes, ignored/renamed/deleted inputs, malformed files and preservation of
saved metrics on failure. Ripple detection and channel-classification generation
remain separate legacy preparation operations.

## Spatial maps and imported PSTHs

`spatial_metrics` reads `basename.<name>.firingRateMap.mat` and its named struct;
`psth_metrics` reads `basename.<name>.psth.mat` and its named struct. Source files
are never rewritten. Each file needs a finite `x_bins` vector and either `UID` or
`cluID` describing its cell-column order. Identities must be unique and match the
selected spike population exactly. The importer reorders columns to that
population; when both identity fields are supplied, their mappings must agree.
Files without identity fail preflight, even when their cell counts match. Add
identity metadata using the producer's verified mapping, never by assuming that
the current spikes happen to have the same ordering. Existing filenames remain
unchanged; this is a deliberate tightening of the legacy input contract.

Maps use the established 1-by-cell-count `map` cell array, with a bins-by-states
matrix in each cell. Every cell's dimensions are checked. The special `ratemap`
input requires one state per cell and at least two bins for its scalar spatial
metrics. Other names can hold multiple states. Its legacy `firingRateMap` alias
is retained; a second input named `firingRateMap` would collide and is rejected.
Place-field, coherence, coverage and Gini formulas remain unchanged, with explicit
dependencies on the legacy spatial helpers pending their relocation.

PSTHs use a bins-by-cell-count numeric `unit` matrix. They are imported as one
column per cell under `cell_metrics.psth.<name>`, with metadata under
`general.psth.<name>`, matching the existing viewer. This fixes the old importer's
full-filename variable lookup, single-cell storage and incorrect `x_label` copy.
The validator accepts this container; batch loading pads missing-session curves
and retains each session's axis metadata. Interactive viewer behavior has not
been smoke-tested in this milestone. NWB export of PSTHs remains unsupported by
the legacy NWB adapter; use MAT for these outputs.

Both stages fingerprint complete source files, aligned data, target identities,
implementation and outputs. Removed/renamed files retire stage-owned outputs;
spatial scalar metrics disappear when `ratemap` is removed. Imported PSTH cleanup
preserves unrelated custom PSTHs. Skipped stages preserve their outputs and
provenance. Unknown legacy fields named after full filenames are not guessed or
deleted automatically.

These are imports of precomputed curves. Restricting spike times cannot regenerate
the source curves, and the import provenance does not claim to do so. Regenerate
the source files upstream if maps or PSTHs should represent a different time
selection. `saveMat=false` suppresses pipeline metric persistence for these stages.

The tutorial import smoke test uses every tutorial cell and synthetic map/PSTH
files in a temporary copy. An optional pre-extraction function handle compares
all spatial outputs exactly. It also checks identity alignment, independent cache
invalidation, removed files, no-write mode and preservation of saved metrics after
an invalid input. This validates import behavior, not upstream map estimation.

## Theta signal preparation and metrics

Theta has separate `theta_signal` and `theta_metrics` stages. Signal preparation
requires an existing `basename.lfp`, interpreted as interleaved, native-endian
int16 samples. It fingerprints the complete file, selected one-based Theta
channel, LFP sampling rate, channel count and calibration. A channel reader loads
only the selected channel into memory. Preflight checks complete frames, at least
one second of data and sampling-rate compatibility with the legacy spectrogram
window. The full LFP is hashed on each preparation call; performance and memory
use for full recordings have not been benchmarked.

The conventional `basename.InstantaneousTheta.lfp.mat` and `InstantaneousTheta`
variable are retained. `processinginfo.thetaSignal` stores generation provenance.
Legacy caches without provenance are recomputed once; edited cached signal outputs
also invalidate reuse. Managed computation produces only the selected channel,
so old values for other channels are not carried forward as if they were verified.
Signal preparation writes nothing and never generates an LFP. Create/resample
LFP data separately before calling the pipeline.

Theta metrics fingerprint the prepared phase, signal provenance, selected spike
times/sample indices/identities, behavior-file contents and effective intervals
and preferences. Changing behavior, spike intervals or histogram preferences can
reuse the LFP-derived signal. Behavior is loaded only from the named `animal`
struct and requires strictly increasing finite `time` plus matching `speed`
samples; NaN speeds retain the legacy exclusion behavior. Spike `times` are
seconds and `ts` are acquisition sample indices, aligned within one sample.
Invalid zero/out-of-range phase indices fail with guidance rather than silently
shifting timestamps. Spikes beyond the LFP duration remain excluded as before.

When theta is requested but its behavior file or channel tag is absent, old theta
metrics/curves are retired after a successful empty-stage update. The signal file
is retained and the latest signal stage is marked skipped. An explicitly excluded
theta stage retains all results and provenance. Malformed present inputs fail;
they do not silently become empty results.

Pipeline finalization saves the theta cache only after computation and metric
validation succeed, and only when `saveMat=true`. Replacement uses verified MAT
writing, rejects intervening cache edits and avoids rewriting unchanged data.
This is revision checking, not a lock or a transaction across theta, metrics and
other pipeline files. Other legacy operations can still write ancillary files;
`saveMat=false` is not a global read-only guarantee for the whole pipeline.

The public `calcInstantaneousTheta2` entry point now forwards to `ce.processing`.
Its direct-call cache/LFP-creation defaults remain available. It uses scoped
MAT loading so saved workspace variables cannot override its options. Numerical
work is shared with `ce.processing.instantaneousTheta`; optional diagnostic plots
live in `ce.ui.plotThetaMetrics` and are never invoked headlessly.

Scientific conventions are preserved for separate review: the eligibility gate
uses speed > 10, while histogram selection uses `speed_threshold`; spike samples
map through `ceil(ts*srLfp/sr)`; smoothing, bin centers and peak/trough ratios are
unchanged. Component tests compare all signal outputs to a frozen legacy helper.
The tutorial smoke test compares theta metrics on two real spike trains with
synthetic LFP/behavior, checks independent reuse and verifies no-write/failure
preservation. Actual tutorial LFP/behavior, interactive plots and hosted CI have
not been validated by this milestone.

## Reviewed deep/superficial classifications

The `deepSuperficial` stage reads only `deepSuperficialfromRipple` from the
conventional `basename.deepSuperficialfromRipple.channelinfo.mat`. This is an
import of reviewed channel assignments, not a rerun of the classifier. An existing
classification does not require the LFP or ripple-event file. The pipeline never
generates or overwrites those source files, including on `forceReload`.

Channel identity must be explicit: `channel` lists every recording channel once
using one-based IDs. `channelClass` and `channelDistance` must align with it.
The importer normalizes these three fields to recording-channel order; distances
remain in micrometers and NaN distances/empty labels are supported. If the source
includes `ripple_channels`, each electrode group's channel order must match the
session. Cells are mapped through the selected spikes' `maxWaveformCh1` values,
with UID/cluster identity retained in the projection. Equal channel counts alone
are not evidence of correspondence.

Complete source contents, cell identities and peak channels determine cache reuse.
The automatic projection is recorded under
`general.processinginfo.deepSuperficialProjection`, separately from editable
`deepSuperficial` and `deepSuperficialDistance` fields. The source metadata remains
in `general.SWR` and `general.processinginfo.deepSuperficialfromRipple`.
`general.processinginfo.deepSuperficialReview` records override masks, preserved
values and the number of affected cells. Console output reports preservation.

Cell edits are inferred from differences against a previous projection whose
stored output hash still verifies. Known overrides survive reuse, source/peak
channel changes, and later source removal/restoration, including empty labels and
NaN distances. Existing annotations without a trustworthy baseline are retained
conservatively and reported as `legacy_annotations_preserved`; the pipeline does
not silently relabel them as newly computed results. For a forced pipeline rebuild,
the previous MAT cache supplies this annotation context, subject to matching cell
identities/order. This recovery applies to deep/superficial fields, not to every
other legacy field discarded by `forceReload`.

If no classification file, ripple file or Ripple tag exists, the requested stage
retires its automatic assignment and source metadata. Curated cells retain their
values; other cells become empty/NaN, or the fields disappear when no overrides
remain. If ripples or a Ripple tag are present but classification is missing,
preflight requires preparation instead of starting detection. Excluded stages
retain their outputs and do not inspect the source. Malformed classification data
fails before headless computation. `saveMat=false` leaves metric persistence to
the existing pipeline controls and never writes the reviewed channel source.

This import does not establish that a classification is current with respect to
raw LFP, ripple detection, geometry or channel tags. Reconcile/regenerate the source
separately when those upstream inputs change. The existing classifier and review
GUI remain available with their legacy file/figure behavior; classifier numerical
generation and GUI modernization are still outstanding.

The tutorial check uses all 151 cells and the actual reviewed 128-channel file in
a temporary copy. It compares fresh projections exactly with the old pipeline,
preserves existing legacy annotations, checks source edits/manual cell overrides,
and verifies no-write/failure behavior. All five original inputs remain unchanged.

## Core metrics, finalization and saving

`ce.pipeline.runCoreMetrics` manages the `other_metrics` stage. It owns spike counts,
rates, rate variability and instability, CV2, the Mizuseki burst index, refractory
violations and firing-rate response curves. As in the original pipeline, these
metrics are mandatory on every invocation, regardless of `metrics`/`excludeMetrics`.
Matching spike times, identities, totals, interval settings, bin-size preference,
code and output hashes allow reuse. Preflight rejects stale cached spike totals.

The numerical conventions are unchanged: first-to-last-spike duration, subtraction
of exclusion intervals even when using the full spike subset, adaptive histogram
bins with an omitted trailing partial bin, the CV2 cutoff, the burst-index loop and
per-mille refractory violations. These require a separate scientific audit before
changing formulas. An entirely zero-duration population, or an empty unit with
duration exclusions, now fails explicitly instead of failing during indexing/binning.

`updateMetadata`, `cleanMetrics` and `recordRun` separate session metadata, legacy
output normalization and invocation provenance from numerical calculation.
Metadata updates do not invalidate core calculations. Missing optional owned
metadata is removed; database IDs accept finite numeric scalars instead of MATLAB
expressions. Generated deep/superficial Unknown/NaN defaults are distinguished from
manual annotations when a reviewed classification becomes available later.

`beginPersistence` captures destination revisions before calculation.
`saveOutputs` validates outputs and checks both metric/session revisions before
writing. With `saveBackup=true`, it archives the exact previous metrics file,
including extra MAT variables, under `revisions_cell_metrics` using the existing
`cell_metrics_*` convention plus a content hash. Backup failure aborts saving.
Backups occur after successful calculation/validation; `saveMat=false` creates
neither managed outputs nor metric backups. Session files now use verified MAT
replacement and report failures instead of silently swallowing them.

Saving is still a sequence of individual replacements, not a multi-file transaction
or a lock. A later failure can leave earlier sidecars/metrics saved; waveform
sidecars do not yet have concurrent-revision checks. Legacy preparation, callbacks,
database submission and summary figures retain their own side effects, so this
does not make every `saveMat=false` pipeline configuration globally read-only.

`tests/integration/runTutorialCoreSmoke` uses temporary copies of the tutorial
session, spikes and metrics. An optional pre-extraction function handle enables
exact numerical comparison. It checks all 151 cells, reuse, metadata-only updates,
legacy exclusion denominators, exact backups, no-save execution and rejection of
stale totals without changing the original files.

## CellClass imports and custom calculation callbacks

`cell_class_import` reads only the `CellClass` variable from the conventional
`basename.CellClass.cellinfo.mat`. As before, an existing file is imported on every
pipeline invocation, including partial metric runs; it is not controlled by metric
selection or `keepCellClassification`. It writes only the derived
`CellClassBuzcode` field, leaving `putativeCellType` and manual labels untouched.

The source must declare unique finite `UID` or `cluID` values in label order.
When both are supplied, both must agree on the mapping. Reordered sources are
aligned by identity; a source can cover more cells than the selected spike subset.
Every label must be a character row or empty, with empty labels becoming `Unknown`.
Row and column cell arrays are normalized to the output row convention.
`ce.data.cellIdentityOrder` also owns identity matching for spatial/PSTH imports,
which retain their stricter requirement to cover exactly the selected cells.

Compatibility change: count-only CellClass files now fail with an actionable error
in both execution modes; headless preflight catches this before calculation.
Have the producer attach identities using its verified source mapping. Copying the
current spike IDs into an old file solely because the counts match is not a valid
migration. The importer never writes or repairs the source file itself.

The stage fingerprints the whole source file, aligned labels, target identities,
implementation and outputs. Reuse retains generation provenance. Changes to spike
intervals alone do not relabel the precomputed source as newly calculated.
Editing `CellClassBuzcode` invalidates the derived cache and restores source labels
on the next import; use the independent curation fields for manual classifications.
Removing the source retires previously managed imported labels. Without managed
provenance, existing legacy values are retained when no source exists. A forced
rebuild retains the broader pipeline's legacy handling of unrelated old fields.

`ce.pipeline.customCalculationNames` and `runCustomCalculations` separate extension
discovery and dispatch from orchestration. They preserve the `+customCalculations`
package, first-package discovery order, selection/exclusion behavior and callback
signature `(cell_metrics, session, spikes, parameters)`, including both spike
subsets. Callbacks remain uncached. Their output must preserve the metrics struct,
cell count and any existing UID/cluster identity; returned identities must match
the input spike order. Errors propagate before managed saving. This checks the
declared identity, not whether a callback silently reordered unidentified arrays.

Undeclared callbacks remain disallowed in headless runs. Interactive callbacks may
perform their own file/GUI/network operations; dispatch cannot roll those effects
back. The putative-cell-type classification callback and its formulas are unchanged.
Plugin manifests, dependency declarations and callback cache ownership remain
future work.

The tutorial import check uses synthetic pE/pI/empty labels on all 151 real cell
identities in a temporary copy. It checks legacy-compatible assignment, reversed
source order, reuse, source edits, source removal and no-write/failure preservation.
It does not validate biological classification accuracy or an upstream producer.

## Local metric loading and batch assembly

The public `loadCellMetrics` and `loadCellMetricsBatch` entry points remain in the
repository root. Local MAT loading needs only that root on the MATLAB path; it
does not look up database credentials, rewrite session files or change directory.

```matlab
metrics = ce.io.readCellMetrics('/path/session.cell_metrics.cellinfo.mat');
batch = loadCellMetricsBatch('basepaths', {'/path/one','/path/two'}, ...
    'basenames', {'one','two'}, 'headless', true);
[metrics, indices] = loadCellMetrics('cell_metrics', metrics, ...
    'brainRegion', {'CA1','CA3'}, 'putativeCellType', {'Pyramidal'});
```

`ce.io.readCellMetrics` loads only the named `cell_metrics` variable and validates
cell count and identity. `ce.io.loadMetricBatch` loads local MAT files and accepts
an optional `(fraction, message)` progress callback. `ce.data.assembleMetricBatch`
combines already loaded structs without I/O or UI. It preserves requested session
order, duplicates and local UID/cellID/cluster values. `batchIDs` supplies the
session scope; UID values may repeat across sessions but must be unique within one.
Local source paths are made absolute. Source metadata is retained in
`general.batch`, alongside `general.basepaths`, `basenames` and `saveAs` mappings.

Numeric metrics missing from any session receive NaN padding at every position,
including gaps before the first occurrence. Missing nested cell-valued data receive
empty cells; missing top-level labels receive empty strings. Complete numeric
arrays retain their class; padding promotes values to double and rejects large
integers that cannot be represented exactly. Per-cell logical fields now survive
assembly. Nested numeric matrices must have compatible row counts and one column
per cell. Incompatible shapes/types and unsupported metadata outside `general`
fail explicitly instead of silently dropping data. No resampling or numerical
metric calculation occurs in the loader.

Group indices and connection pairs are validated as local one-based positions
before adding session offsets. Legacy per-cell tag/group lists are normalized by
`ce.data.metricGroups`. Session and animal metadata still produce repeated
`session_*`/`animal_*` fields. Nested batches are rejected; load their individual
sessions instead. Single-session files saved by the viewer may contain all-one
`batchIDs`; those remain valid single-session inputs. `truePositive` and
`falsePositive` remain excluded from assembly,
and the existing excitatory/inhibitory connection representation is retained.

Progress windows belong to `ce.ui.metricLoadProgress`. `headless=true` or
`showProgress=false` suppresses this UI. On failure, windows created by the loader
close; caller-supplied progress handles remain the caller's responsibility.
Closing a progress window raises `ce:io:LoadCancelled`, with no partial batch
returned. Cancellation is checked between loads and around assembly, not during
a MAT read or a large concatenation. Batch loading is still eager and holds all
session data in memory; streaming and resource limits remain future work.

Database requests go through `ce.integrations.resolveMetricSessions` only when
explicit session names/IDs are supplied. It preserves request order/duplicates
and calls the existing resolver with `changeDir=false` and `saveMat=false`.
The database integration can still perform its legacy configuration UI/network
operations; only the local loading path has been verified without those effects.
Database behavior is covered with stubs, not a live service.

`loadCellMetrics` now filters supplied metrics directly and returns batch results
without attempting a second unrelated file load. Filtering is OR within a filter
and AND across filters. Brain-region/animal/label matching remains exact; cell
type/synaptic-effect/deep-superficial matching remains substring-based. Ground-truth
filters read the correct container, and absent fields/tags produce no matches.
Filters return indices without modifying or subsetting the source data.

Compatibility changes: missing/malformed files and incompatible batch dimensions
now raise errors instead of returning empty/partial results or silently skipping
data. Batch loading supports MAT only; non-MAT batch requests are rejected.
Single-session JSON/NWB loading still uses the legacy adapters and was not
validated in the loader milestone. Viewer replacement checks are described below.

The tutorial check assembles 302 cells from two temporary copies of the complete
151-cell metrics file. All fields match the frozen legacy batch loader exactly,
excluding benchmark timings. It also checks single-session filtering, no progress
figures in headless mode, unchanged cwd and unchanged source/copy file hashes.

## Guarded viewer reload and session switching

CellExplorer's reload, file-picker and database-session selection callbacks now
use `ce.ui.tryMetricLoad`. Loading and identity validation happen before replacing
the active metrics. A failed read or closed progress window retains the current
dataset, selected cell, edits and undo history. Successful file reads use only the
named `cell_metrics` variable and do not change the working directory.

After loading, the viewer asks before discarding unsaved changes, defaulting to
Cancel. The prompt does not save or discard anything itself. A clean reload also
asks for confirmation. The state snapshot is taken after loading/confirmation,
so edits made while a progress callback yields are included. Reentrant load
requests are ignored while a replacement is in progress. Success and cancellation
are logged without another modal confirmation; errors report the actual cause.

If legacy session initialization fails after starting to update state, the viewer
restores metrics, dirty-cell tracking, undo history, cell-type assignments, selected
cell, preferences, plotting data, reference/ground-truth state and source paths.
It also restores the captured random state and working directory. Surviving
control properties, the Save indicator and figure title are restored; dynamic tag
buttons are rebuilt. Destructive tag-button rebuilding is deferred until the end
of initialization. If graphics restoration itself fails, the model remains
restored and the error explicitly advises saving before reopening the viewer.

`ce.ui.readMetricSelection` records the selected filename and handles basenames
containing dots. `ce.ui.reloadMetricSelection` honors that filename or the single
session's `saveAs`; batches honor each session's own `saveAs`, including mixed
names. Reload no longer silently selects the default `cell_metrics` file when
the user opened another metrics file.

The same boundary also covers explicit reinitialization, cached and selected
reference/ground-truth loads, and exploring those comparisons as primary data.
Initial command-line loading and other legacy entry points still need review. It does not provide disk rollback or undo external work
performed by custom plotting/spike callbacks. Keeping current and candidate
datasets available during replacement increases peak memory use. Rendering after
a successful commit remains in the existing main loop.

`runTutorialViewerLoadSmoke` exercises the actual viewer and menu callbacks with
temporary copies of the 151-cell tutorial metrics, then a 302-cell batch. Dialogs,
database selection, analytics and preference persistence are stubbed; PCA is used
for test visualization. Checks cover missing files, a deliberately late
initialization error, cancelled discard, successful reload/file/batch switches,
and a real progress window closed by the test immediately after construction.
They verify retained metrics/history/selection and the Save indicator, unchanged
cwd and an unchanged original metrics file. This is a focused GUI smoke check,
not coverage of every plot or a live database service.

## Viewer display preparation and profiling

`ce.ui.prepareDisplayData(metrics, logIntervals)` prepares interpolated waveform
arrays, waveform z-scores, normalized ACG/ISI arrays and theta display curves
without graphics, file access, cwd changes or random sampling. The viewer calls it
before updating controls and edit history. It preallocates waveform matrices and
validates waveform/time dimensions and finite increasing time axes.

The formulas retain the legacy common time grid, per-cell spline calls, zero
columns for missing/NaN waveforms, NaN theta handling and division by range without
minimum subtraction. Matrix-valued spline interpolation was evaluated but rejected
because it introduced floating-point differences. The frozen legacy implementation
is kept as a test fixture. A partially present waveform display cache is now
repaired; previously the vector-valued cache check could skip it.

The existing `general.initialized` display-cache convention remains in use. It
does not establish freshness when inputs change. This component does not migrate
embedding calculations or reference-data preparation, and rendering after a
successful replacement remains in the legacy main loop.

`profileTutorialViewer` builds a scaling fixture from repeated tutorial metrics,
opens the actual viewer and profiles the first display plus three cell advances.
`runTutorialDisplaySmoke` checks every prepared field against the frozen code and
alternates five warmed preparation measurements. Both keep source files read-only;
the GUI profiler disables database/analytics and preference writes and explicitly
uses PCA. These checks need a MATLAB graphics environment and are separate from CI.

The [recorded measurements](benchmarks/viewer-2026-10-26.json) use 10 copies of 151
cells, not 10 independent recordings. Profiled first-ready observations were about
9–10 seconds, with UI/table construction a larger cost than file reading or display
preparation. Timer polling, profiling overhead and graphics startup affect these
observations; they do not establish a startup speedup. In the paired warmed run,
median preparation time was 53.9 ms for the old block and 44.5 ms for the extracted
component. All resulting fields matched exactly. Larger/different recordings,
default t-SNE/UMAP configurations and memory ceilings remain to be profiled.


## Tables created and populated on demand

`ce.ui.metricTableData(metrics, fields, cellIndex)` formats only the selected
cell, preserving the legacy numeric/text conversion and older MATLAB NaN rule.
The viewer no longer stores a string table for every cell in the batch. Visible
metrics are read from current values rather than a session-initialization cache.
The filtered/sorted cell list retains its existing behavior and preserves custom
column headings when switching table modes.

The Tags table is created on first opening its tab, then reused. Its checkboxes
are populated from the active highlight/include/exclude state, including after
failed-load restoration. Preference tags absent from the current recording no
longer cause highlight rendering to access missing fields. When the Table data
preference is None, the main table is also deferred until the user selects a
visible table mode; an empty panel preserves the layout slot.

`runTutorialViewerLoadSmoke(source, tableMode)` accepts initial table modes 1, 2
and 3. It verifies initial widget counts, opening/reusing tables, custom columns,
sorted row identity, cell selection, tag-filtered list rows, navigation, and
restoring visible table values and tag state after a failed reload. A test-only
tag is added to the temporary fixture; original tutorial files remain untouched.
The harness explicitly cleans up dialog stubs so all three modes can run in one
MATLAB process. These checks use PCA and do not cover every custom plot.

The [table measurements](benchmarks/viewer-tables-2026-10-26.json) compare four
runs per version in balanced order after warming both versions, using 1,510 cells.
Median session initialization decreased from 357 ms to 281 ms; first-ready
medians were 2.705 s and 2.567 s, with overlapping ranges. Navigation observations
were about 264 ms for both versions, limited by the 250 ms timer polling interval.
These results support reduced initialization work, not a broad navigation or
startup-speed claim. The first opening of each deferred table still incurs its
widget cost, and the filtered cell list is not virtualized.


## Reinitialization and comparison loading

Explicit reinitialization uses the current in-memory annotations and embedding.
It refreshes prepared data while retaining dirty-cell tracking, undo history,
selected cell, class selection, text/tag filters and comparison selections. It
requires no discard prompt because it preserves curation. Preparation failures
restore the previous metrics, view and RNG state; a successful reinitialization
still allows undoing earlier edits. Initialization also no longer blanks unrelated
text fields when a cell lacks animal metadata.

Reference and ground-truth loading uses the same guarded operation boundary.
`ce.io.readCellMetrics(file, variableName)` reads only `cell_metrics`,
`reference_cell_metrics` or `groundTruth_cell_metrics`, validating cell identity.
`ce.ui.prepareComparisonData` takes explicit preferences, axis bounds, log
intervals and a smoothing kernel, and returns prepared metrics, display data and
comparison limits without mutating the viewer. Its legacy histogram, smoothing,
waveform and ACG formulas are preserved and compared to a frozen reference.

A candidate is prepared before replacing an active comparison. Existing tabs and
listboxes are reused. Rollback restores comparison data, axis bounds, list values,
menu checks and selected tabs, and removes tabs created by an unsuccessful load.
A failed or cancelled first load does not enable an empty overlay. Comparison
loading does not discard primary-session annotations. Exploring a comparison as
primary data uses the ordinary unsaved-change confirmation and rollback path.

Selected comparison batches are cached through verified `ce.io.writeMat` only
after preparation and control updates succeed. Cache-write failures restore the
previous active comparison; existing files are protected by staged replacement.
The established cache filenames, named variables and raw-cache representation
remain unchanged. Reference selection can use the local paths returned by the
selector; missing inputs retain the repository/download fallback. Downloads and
copies are staged and validated before entering the per-session cache.

The viewer smoke test runs an exact temporary copy of `CellExplorer.m`, keeping
all comparison caches and catalogue files outside the repository. It exercises
successful and failed reinitialization, undo, cancelled comparison selection,
wrong-variable caches, malformed comparison preparation, cache-write failure,
ground-truth selection controls, progress cancellation and declined/accepted
exploration. It yields back to the main loop to render both comparison overlays.
The ground-truth dialog's controls are real; its wait/selection is automated.

Limits: rendering after commit remains in the legacy loop. Arbitrary custom
callback side effects are outside rollback. The ground-truth catalogue retains
its existing session-based selection and best-effort list-cache behavior.
Successful per-session downloads may remain cached after later cancellation;
this is not a multi-file transaction. Live database/network services, other MATLAB
releases and every custom plot were not exercised.

Validation on MATLAB R2024b Update 9: 186 component tests passed, and all three
initial table modes passed the live smoke. Comparison preparation matched the
frozen code exactly on 151 and 1,510 tutorial-derived cells. The ground-truth
comparison fixture assigns a synthetic class to all cells; it tests preparation
compatibility, not biological classification accuracy. Original session, spikes
and metrics file hashes were unchanged.
