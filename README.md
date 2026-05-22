# ScanImage Local Notes

This repository contains a local ScanImage tree with custom additions for SLM calibration and utility workflows.

## Diffraction Efficiency Calibration

### Overview

There are now two TIFF-based diffraction-efficiency calibration paths in the SLM alignment GUI:

- `SLM uniform`
- `SLM scattered`

Both are available from:

1. Open the SLM alignment GUI.
2. Click `SLM Diffraction efficiency`.
3. Choose the desired calibration mode.

The calibration updates the live ScanImage diffraction-efficiency lookup stored on the SLM object:

- `hSI.hSlmScan.hSlm.hCSDiffractionEfficiency.fromParentInterpolant{1}`

This lookup is used in SLM objective-space coordinates.

### `SLM uniform`

Entry point:

- [+scanimage/+guis/SlmAlignmentOverview.m](/mnt/c/Program%20Files/Vidrio/SI-Premium_2023.1.1_(2025-06-27)_d280f351/+scanimage/+guis/SlmAlignmentOverview.m:124)

What it does:

- Uses the older rectilinear-grid TIFF calibration path.
- Builds a `griddedInterpolant`.
- Assumes the TIFF-derived points lie on one shared XY grid reused across all Z planes.

When to use it:

- Use this only when the calibration data truly behaves like a rectangular grid across depth.

Important limitation:

- This path can fail or misrepresent the data when XY shifts with Z.
- The failure mode is that the TIFF-derived points are not a clean rectilinear 3D lattice.

### `SLM scattered`

Entry points:

- [+scanimage/+guis/SlmAlignmentOverview.m](/mnt/c/Program%20Files/Vidrio/SI-Premium_2023.1.1_(2025-06-27)_d280f351/+scanimage/+guis/SlmAlignmentOverview.m:301)
- [+scanimage/+guis/SlmAlignmentOverviewScattered.m](/mnt/c/Program%20Files/Vidrio/SI-Premium_2023.1.1_(2025-06-27)_d280f351/+scanimage/+guis/SlmAlignmentOverviewScattered.m:7)

What it does:

- Goes directly into the scattered TIFF calibration workflow.
- Prompts for a folder containing ScanImage TIFF files.
- Loads all `*.tif` and `*.tiff` files in that folder.
- Reads the SLM depth for each TIFF from:
  - `header.SI.hScan2D.parkPosition_um(1,3)`
- Groups files by depth.
- Averages all files belonging to the same depth.
- If a TIFF contains multiple pages, averages those pages into one 2D image first.
- Optionally applies median filtering.
- Uses the 5th percentile of the image stack as a baseline floor.
- Converts fluorescence to efficiency using the square-root relationship for 2-photon excitation.
- Builds a `scatteredInterpolant(...,'natural','nearest')`.
- Writes that interpolant into the live SLM diffraction-efficiency lookup.
- Saves coordinate systems after updating the LUT.

Why this path was added:

- The measured TIFF-derived points can shift in XY as a function of Z.
- In that case the old rectilinear-grid assumption is not valid.
- The scattered path uses the actual 3D point cloud directly instead of forcing it onto a shared XY grid.

### GUI usage for `SLM scattered`

1. Open the SLM alignment GUI.
2. Click `SLM Diffraction efficiency`.
3. Click `SLM scattered`.
4. Choose the TIFF folder.
5. Enter median filter width and height.
   Default is `1 x 1`, which means no smoothing.
6. Let the calibration run.

Progress feedback:

- A waitbar is shown while TIFFs load.
- Command-window output reports major stages:
  - loading TIFFs
  - grouping TIFFs by SLM Z
  - averaging within depth
  - normalization and 2-photon conversion
  - building the scattered interpolant
  - updating the ScanImage LUT

### Input TIFF expectations

The TIFF-based calibration assumes:

- ScanImage TIFFs
- acquired with the SLM scanner
- one ROI, no MROI
- no rotation
- square XY images
- small calibration images, typically under `65 x 65`

For the scattered workflow, interleaved acquisitions are supported as long as:

- each file carries the correct `parkPosition_um(1,3)` in the header
- all files share the same scan geometry

### Recommended acquisition helper

Entry point:

- [+scanimage/+util/acquireSlmVolume.m](/mnt/c/Program%20Files/Vidrio/SI-Premium_2023.1.1_(2025-06-27)_d280f351/+scanimage/+util/acquireSlmVolume.m:1)

Purpose:

- Acquire an SLM calibration volume suitable for the scattered calibration path.

What it does:

- switches imaging to the SLM scanner
- prompts for zoom
- prompts for pixels per line
- prompts for frames per depth
- prompts for SLM Z positions
- prompts for output folder
- acquires one frame per grab
- interleaves depths in randomized order to reduce order effects
- builds live running averages per depth during acquisition
- provides a non-modal abort/status window
- restores prior ScanImage settings after completion or abort

This acquisition style is intended to pair with the scattered calibration workflow, which regroups TIFFs by header depth and averages within each depth.

### Visualizing the current correction

Entry point:

- [+scanimage/+util/plotCurrentSlmPowerCorrection.m](/mnt/c/Program%20Files/Vidrio/SI-Premium_2023.1.1_(2025-06-27)_d280f351/+scanimage/+util/plotCurrentSlmPowerCorrection.m:1)

Purpose:

- Sample the current live diffraction-efficiency interpolant and plot the implied power correction over XY for a set of Z planes.

Run in MATLAB:

```matlab
scanimage.util.plotCurrentSlmPowerCorrection
```

It prompts for:

- XY frame size in microns, symmetric about `0`
- Z positions in microns

### How to validate a calibration

Good checks include:

1. Confirm the live interpolant type:

```matlab
class(hSI.hSlmScan.hSlm.hCSDiffractionEfficiency.fromParentInterpolant{1})
```

For the scattered path, this should report:

- `scatteredInterpolant`

2. Plot the current correction:

```matlab
scanimage.util.plotCurrentSlmPowerCorrection
```

3. Acquire a fresh uniform-sample dataset and check whether the corrected field is flatter than the uncorrected one.

### Offline analysis script

There is also an external helper script outside the repo:

- [/mnt/f/test_code/test_scattered_slm_diffraction_efficiency.m](/mnt/f/test_code/test_scattered_slm_diffraction_efficiency.m)

Purpose:

- analyze a TIFF folder offline
- group files by depth
- average within depth
- build and inspect the scattered interpolant
- write logs and figures to an `analysis` subfolder

Important note:

- This script does not update live ScanImage state.
- It is for analysis and validation only.
