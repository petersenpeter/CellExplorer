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
They cannot detect a new sorting that reuses both identifiers, or concurrent edits
with unchanged identities. Sorting revision IDs and file-revision conflict checks
remain planned. Disk recovery, cache invalidation for the remaining pipeline
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
- Deep/superficial processing requires existing ripple and channel-classification
  files; its interactive preparation is not launched automatically.
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
```

This integration check needs the recording and the relevant MATLAB toolboxes. It
is not part of CI and does not exercise raw waveform extraction or every metric
stage. Keep the current checkout's root and `calc_CellMetrics` ahead of older
CellExplorer installations on the MATLAB path when running interactive checks.

## Stage execution and cache provenance

`ProcessCellMetrics` now uses `ce.pipeline.runStage` for `waveform_extraction`,
`waveform_shape`, `waveform_localization`, `acg_metrics` (wide/narrow and log
ACGs, fits, log ISIs and optional population modulation), `monosynaptic_detection`
and `monosynaptic_metrics`. Definitions declare
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
and Signal Processing toolboxes. Tutorial checks additionally compare 151-cell
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
