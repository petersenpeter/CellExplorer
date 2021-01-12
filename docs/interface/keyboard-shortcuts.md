---
layout: default
title: Keyboard shortcuts
parent: Graphical interface
nav_order: 5
---
<style>
.main-content dd{
    margin: 0 0 0 110px !important;
    margin-left: 0.2em  !important;
}
dl {
    padding: 0.1em;
  }
  dt {
    float: left;
    clear: left;
    width: 100px;
    text-align: right;
    color: black;
  }
  dt::after {
    content: " ";
  }
  dd {
    margin: 0 0 0 110px;
    padding: 0 0 0.5em 0;
  }
</style>

# Keyboard shortcuts
{: .no_toc}
Keyboard shortcuts allow you to quickly interact with your data in CellExplorer. Pressing `H` in CellExplorer will show available shortcuts. A `+` sign indicate that the key must be combined with command/control (Mac/Windows).

### Navigation
<dl>
  <dt>< (left)</dt>
  <dd>Navigate to previous cell</dd>
  <dt>> (right)</dt>
  <dd>Navigate to next cell</dd>
  <dt>.</dt>
  <dd>Navigate to next cell with same class</dd>
  <dt>,</dt>
  <dd>Navigate to previous cell with same class</dd>
  <dt>+G</dt>
  <dd>Go to a specific cell</dd>
  <dt>Page Up</dt>
  <dd>Next session in batch (only in batch mode)</dd>
  <dt>Page Down</dt>
  <dd>Previous session in batch (only in batch mode)</dd>
  <dt>Numpad0</dt>
  <dd>Navigate to first cell</dd>
  <dt>Numpad1-9</dt>
  <dd>Navigate to next cell with that numeric class</dd>
</dl>

### Cell assignment actions
<dl>
  <dt>1-9</dt>
  <dd>Assign Cell-types</dd>
  <dt>+B</dt>
  <dd>Assign Brain region</dd>
  <dt>+L</dt>
  <dd>Assign Label</dd>
  <dt>plus</dt>
  <dd>Add Cell-type</dd>
  <dt>+Z</dt>
  <dd>Undo assignment</dd>
  <dt>+R</dt>
  <dd>Reclassify cell types</dd>
</dl>

### Display
<dl>
  <dt>M</dt>
  <dd>Show/Hide menubar</dd>
  <dt>N</dt>
  <dd>Change layout (6, 5 or 4 subplots)</dd>
  <dt>+E</dt>
  <dd>Highlight excitatory cells (triangles)</dd>
  <dt>+I</dt>
  <dd>Highlight inhibitory cells (circles)</dd>
  <dt>+F</dt>
  <dd>Display ACG fit</dd>
  <dt>K</dt>
  <dd>Calculate and display significance matrix for all metrics (KS-test)</dd>
  <dt>T</dt>
  <dd>(Re)calculate tSNE space from a selection of metrics</dd>
  <dt>W</dt>
  <dd>Show waveform metrics</dd>
  <dt>+Y</dt>
  <dd>Perform ground truth cell type classification</dd>
  <dt>+U</dt>
  <dd>Load ground truth cell types</dd>
  <dt>space</dt>
  <dd>Show action dialog for selected cells</dd>
</dl>

### Other shortcuts
<dl>
  <dt>H</dt>
  <dd>Open list of keyboard shortcuts</dd>
  <dt>+P</dt>
  <dd>Open preferences for CellExplorer</dd>
  <dt>+C</dt>
  <dd>Open file directory of the selected cell</dd>
  <dt>+D</dt>
  <dd>Open sessions in the Buzsaki lab database</dd>
  <dt>+A</dt>
  <dd>Load spike data</dd>
  <dt>+J</dt>
  <dd>Adjust mono-synaptic connections for selected session</dd>
  <dt>+V</dt>
  <dd>Visit the Github documentation</dd>
</dl>

