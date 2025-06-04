# Superfine Lab Adhesion Assay

## Overview

The Superfine lab adhesion assay measures the detachment force experienced by magnetic beads subjected to an upward magnetic force. Surface chemistries for  the bead and substrate are modified to measure interaction strengths for the desired mechanical/chemical attachments (e.g., Wheat Germ Agglutinnin bound to mucins/mucus produced by human broncial epithelial cells). This README describes the matlab code used to both run the experiment by controlling the hardware and managing the data collection. This repository also contains the analysis stack for compiling the results.

## Installation / Dependencies

Matlab R2021b or later is required.  Two additional to the Superfine repositories are required: `3dfmAnalysis` and `VidCollect`.

Code in these repositories makes use of several MATLAB-specific toolboxes, including:

- Computer Vision Toolbox
- Curve Fitting Toolbox
- Global Optimization Toolbox
- Image Acquisition Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox
- Statistics and Machine Learning Toolbox
- Symbolic Math Toolbox
- System Identificaiton Toolbox
- Wavelet Toolbox

### Importing Necessary Directories

To access the functions needed to run the experiment, you need to import both the `AdhesionAssay` and `3dfmAnalysis` directories into the Matlab console
using the following code:

`addpath(genpath([directory_location]))`

Example: `addpath(genpath('D:\jcribb\src\AdhesionAssay'))`

> Note: A lot of the dependency code in 3dfmAnalysis is old and clunky but should work. If you have issues, ask for help. Don't spend time trying to fix it yourself.

## Code Structure

The AdhesionAssay codebase is categorized into subdirectories as follows:

- **analysis**: used for calculating detachment forces and summarizing experimental results.
- **automation**: handles assay-level automation of hardware, defining plate geomtries, etc
- **calib**: contains the point-spread functions and collection code for z-tracking and defines transit media properties (e.g., viscosity)
- **config**: configuring hardware (magnet, microscope, camera, etc.) for assay use
- **control**: assay "low-level" hardware control (i.e., coordinate systems, autofocus, image and/or bead distribution quality assessment, etc.)
- **doc**: various documentation elements, hardware documentation, datatypes
- **external**: code pulled from external sources
- **hw**: hardware-specific modules for the scope, stage, zmotor, etc.
- **legacy**: old code architecture to use for early project reference. Move along. Nothing to see here.
- **modeling**: see analysis/fitting
- **mosaics**: handling mosaic image collection for bead distributions across wells
- **protocols**: project lab-bench protocols (may need moving to stand-alone proj)
- **studies**: scripts that analyze specific studies/experiments (may need moving)
- **ui**: potential GUI for running an experiment. Still in development.
- **util**: utility functions for low-level computation & info handling.

## Typical MATLAB Workflow

- Prepare microscope for data collection: `ba_config`, `ba_calibrate_plate`
- Preview video: `ba_impreview`
- Collect video data: `ba_pulloff`
- Video meta-analysis: `ba_workflow`, which converts binary videofile into image stack, generates a mini-video for later reference, tracks bead displacments in XYZ, and compresses video
- Force calculation and results aggregation: `ba_process_expt`

## Cloning, committing, and pulling updates

The AdhesionAssay project uses submodules for the assay's hardware, which includes the Thorlabs Zmotor, Nikon Scope, Ludl Stage, and eventually the camera. This requires cloning and pulling updates in a slightly different way.

To clone the full repository: `git clone --recursive git@github.com:cribb/AdhesionAssay.git`

To update all submodules to their latest states: `git submodule foreach git pull origin main`

Note: Don't forget you have to commit the updated positions of the submodules to the super-repository, i.e. `git commit -m "Updated to newer commits for submodules." *`

Changes to any submodule should be made in the submodule's base repository and then pulled into AdhesionAssay using the above command. --Jeremy

### A Note on Hardware

The code for this project currently works for the following hardware setup:

- **Microscope** - Nikon Eclipse TE2000-E
- **Microscope stage controller** - Ludl MAC6000
- **Camera** - Point Grey Grasshopper3
- **Well Plate** - 15 circular wells, 4 circular fiducial marks located at corners
  - _Well Diameter_ - 8.8 mm
  - _Plate Dimension_ - 3 rows (11.79 mm between well centers), 5 columns (16.2 mm between well centers)
  - _Fiducial Marking Spacing (as measured from their centers)_ - 69.6 mm x 44.476 mm
  - _Fiducial Marking Diameter_ - 0.381 mm

If a different type of hardware is used, the code may need to be modified accordingly.

## Running an Experiment

### Working with the Stage

For details on how to use commands within the LudlStage submodule, see the submodule README.md on GitHub.

#### Running the Calibration Sequence

To initiate the calibration sequence, enter the following command into the Matlab console:

`plate = ba_calibrate_plate(ludl)`

A viewing window should open up on the screen showing the camera's field of view. Use the joystick connected to the stage to move the field of view so
that the fiducial mark in the upper left corner is entirely inside of it. The image of the fiducial mark does not need to be perfectly centered in the
image, but you want to minimize the number of "dark spots" that aren't part of the fiducial mark to be a part of the image, since that would skew the
calibration.

Once you have done this, press the ENTER button on the keyboard. The stage should then move to the next point in the clockwise direction. If this
second fiducial mark is not entirely inside the frame in a good field of view, use the joystick to adjust the stage's position accordingly. Press the
ENTER button again, and the stage should move to the next point.

This process repeats itself until all four points have been imaged. `plate` has the following properties:

- `centers` - an array containing the location of the center
- `theta` - the angle at which the plate is tilted in radians
- `errormatrix` - an error matrix of size [4, 2] comparing the difference between the calculated distance between each of the fiducial marks and
the distance between each of the fiducial marks in the actual design. The results of `errormatrix` are given in units of ludl tick marks.

#### Moving Between Wells

As a shortcut for moving between wells quickly, the following command can be used to move directly to the center of a target well:

`plate_space_move(ludl, plate, [row_num column_num], movegrid_plate, platelayout)`

The following is a breakdown of some of the inputs:

- `plate` is the output of the ba_calibrate_plate function
- `row_num` and `column_num` refer to the row and column numbers respectively of the target well
- `movegrid_plate` refers to how far the specified location in the well is from its center in units of millimeters. It takes the form of `[xcor ycor]`
and can be set to [0 0] if you want to move to the center of the well
- `platelayout` refers to whether the plate layout is that of phase 1 (`platelayout = 1`) or phase 2 (`platelayout = 2`) of the experiment

#### Additional Notes

If, for any reason, the stage is suspected to "drift" over time such that stage does not return to the same place for a given Ludl coordinate
(within an acceptable tolerance), the calibration can be checked by running

`fiderror = calibrate_check(ludl, plate)`

In this sequence, the stage will move to the center of each fiducial mark, image it, and calculate how far the center of the fiducial mark is
from where its center ought to be as indicated by the calibration. The results returned in `fiderror` are in units of ludl tick marks.

### Working with the Microscope

For details in working with the microscope controls, please reference README.md in the NikonScope submodule.

### Using the `ba_pulloff_auto` Routine and Metadata

#### Creating Metadata File

The metadata file should be created using the CISMM Well Layout program for a 3 x 5 structure. The following parameters can be set as independent variables.
Keep in mind that these category names should be input into the program exactly or the Matlab script will not be able to read it properly.

- SampleName
- SampleInstance
- BinFile
- IncubationStartTime
- SubstrateChemistry
- BeadChemistry

Once you are done, save the file as a .csv file. Don't worry if your resulting Excel file contains more cells than needed - the Matlab program that extracts
the metadata will delete these automatically.

#### Editing `well_metadata_script`

`well_metadata_script` is the Matlab script that parses the metadata from the .csv file for a given well, adds additional constant metadata, and then saves
all of it as a .m file. `ba_pulloff_auto` will require the output .m file to run.

To run this script, use the command

`metafile = well_metadata_script(row,col)`

where `row` refers to the row value of the well and takes an input value in the set [1, 2, 3], and `col` refers to the column value of the well, takes an input
value in the set [1, 2, 3, 4, 5].

If you want to change the properties of the independent variables (ie. Name, etc.), you should do so inside here. The current iteration does not have the file name of the .csv file
as an input, so you will also have to change this inside the file.

#### Running `ba_pulloff_auto`

`ba_pulloff_auto` is the script that performs the following for a given location:

- Lowers/raises the magnet
- Takes/saves a video of the beads as a .bin file
- Populates the remainder of the metadata skeleton created by `well_metadata_script`

`ba_pulloff_auto` can be called as follows:

`ba_pulloff_auto(h, filename, exptime, metafile)`

where `h` is the handle of the z-motor, `filename` is the filename for the new, completely populated metadata file, and `exptime` is the exposure time in milliseconds.

### Running an automated experiment

A skeleton of the workflow has been created in a script called `master_control`. It currently is verified to have the capability to run an experiment, but has not been tested on actual samples yet.
