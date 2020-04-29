# Running an Automated Experiment (Last Updated 4/29/2020)

## A Note on Hardware

The code for this project currently works for the following setup:

- **Microscope** - Nikon Eclipse TE2000-E
- **Microscope stage controller** - Ludl MAC6000
- **Camera** - Point Grey Grasshopper3
- **Well Plate** - 15 circular wells, 4 circular fiducial marks
	- _Well Diameter_ - 8.8 mm
	- _Plate Dimension_ - 3 rows (11.79 mm between well centers), 5 columns (16.2 mm between well centers)
	- _Fiducial Marking Spacing (as measured from their centers)_ - 69.6 mm x 44.476 mm 
	- _Fiducial Marking Diameter_ - 0.381 mm
	
If a different type of hardware is used, the code may need to be modified accordingly.

## Importing Necessary Directories

To access the functions needed to run the experiment, you need to import both the `AdhesionAssay` and `3dfmAnalysis` directories into the Matlab console 
using the following code:

`addpath(genpath([directory_location]))`

## Working with the Stage

### Connecting to the Stage

To open connection to the stage, run the command

`ludl = stage_open_Ludl`

If you have not connected to the stage before, you will prompted to enter which COM port the stage is connected to, which is something you will have
to figure out manually. Once you have made your selection, your choice will be stored in a file named `PortNames.mat` inside the 
`\AdhesionAssay\hw\ludl`directory, so you won't be queried in the future. If you change which COM port the stage is connected to, you will have to 
delete `PortNames.mat` and rerun `stage_open_Ludl`.

### Running the Calibration Sequence

To initiate the calibration sequence, enter the following command into the Matlab console:

`centers = calibrate(ludl)`

A viewing window should open up on the screen showing the camera's field of view. Use the joystick connected to the stage to move the field of view so 
that the fiducial mark in the upper left corner is entirely inside of it. The image of the fiducial mark does not need to be perfectly centered in the 
image, but you want to minimize the number of "dark spots" that aren't part of the fiducial mark to be a part of the image, since that would skew the
calibration. 

Once you have done this, press the ENTER button on the keyboard. The stage should then move to the next point in the clockwise direction. If this 
second fiducial mark is not entirely inside the frame in a good field of view, use the joystick to adjust the stage's position accordingly. Press the 
ENTER button again, and the stage should move to the next point.

This process repeats itself until all four points have been imaged. `calibrate` will then return the location of the centers of each of the fiducial 
marks as `centers`.

### Moving Within the Plate

#### Querying and Changing Position in Ludl Coordinates

Commands involving the stage's location coordinates are written in units of Ludl tick marks. Each Ludl tick mark is 50 nm.

To get the stage's position in Ludl coordinates, use the command

`[x_cor,y_cor] = stage_get_pos_Ludl(ludl).Pos`

`[x_cor,y_cor]` gives the values of the x and y coordinates respectively of the stage in units of Ludl
tick marks.

To move to a specific Ludl coordinate, use the command

`stage_move_Ludl(ludl, [target_x_pos target_y_pos])`

`target_x_pos` and `target_y_pos` are both in units of Ludl tickmarks. It should be noted that `stage_move_Ludl` moves to an absolute position as
opposed to a position relative to where the stage last was.

#### Moving Between Wells

As a shortcut for moving between wells quickly, the following command can be used to move directly to the center of a target well:

`plate_space_move(ludl, centers, [row_num column_num])`

The `centers` parameter is what the `calibrate` sequence returns. `row_num` and `column_num` refer to the row and column numbers respectively of the
target well. 

For example, if the target well was in the third row and the fourth column, the command would be called as

`plate_space_move(ludl, centers, [3 4])`

### Closing Connection to the Stage

For good practice, close the connection to the stage after use with the following:

`stage_close(ludl)`

### Additional Notes

`calibrate` can also be called as follows to view additional properties of the calibration:

`[centers, theta, errormatrix] = calibrate(ludl)`

These additional properties are defined as follows:
- `theta` - the angle at which the plate is tilted in radians
- `errormatrix` - an error matrix of size [4, 2] comparing the difference between the calculated distance between each of the fiducial marks and 
the distance between each of the fiducial marks in the actual design. The results of `errormatrix` are given in units of ludl tick marks. 

If, for any reason, the stage is suspected to "drift" over time such that stage does not return to the same place for a given Ludl coordinate 
(within an acceptable tolerance), the calibration can be checked by running

`fiderror = calibrate_check(ludl, centers)`

In this sequence, the stage will move to the center of each fiducial mark, image it, and calculate how far the center of the fiducial mark is 
from where its center ought to be as indicated by the calibration. The results returned in `fiderror` are in units of ludl tick marks.

## Working with the Microscope

### Connecting to the Microscope

To open connection to the microscope, run the command

`scope = scope_open`

The Nikon Eclipse TE2000-E microscope is currently connected to the COM2 port. If the scope is to be connected to a different serial port,
make sure to change it in the `scope_open` source code.

### Controlling the Lamp

In order to automate microscope control, make sure that the light above the "REMOTE" button in the "DIA LAMP" section of the remote interface
is green. Otherwise, the microscope will assume you intend to use manual control and your commands will not go through.

To determine if the lamp is on or off, run 

`state = scope_get_lamp_state(scope)`

To turn the lamp on or off, run 

`scope_set_lamp_state(scope, state)`

In both `scope_get_lamp_state` and `scope_set_lamp_state`, `state = 0` corresponds to the lamp being off and `state = 1` corresponds to the lamp being on.

The brightness of the lamp can be adjusted through adjusting the lamp voltage. The lamp voltage, when on, takes on values in the range [3, 12].

To check the lamp voltage, run

`voltage = scope_get_lamp_voltage(scope)`

To change the lamp voltage, run

`scope_set_lamp_voltage(scope, voltage)`

It should be noted that the above command should ONLY be run when the lamp is on. Additionally, if the input parameter `voltage` is not in the range [3, 12]
an error will result.

### Controlling the Focus

The values that the focus position can take range from 0 to somewhere in the 10000s range. Since this range is very large, it is not practical to manually 
key in the values to find the optimal focus manually. It is better to run the following autofocus routine below:

`focus_scores = ba_testautofocus(scope, [min_focus_val max_focus_val], stepsize, exptime)`

The outputted graph will indicate which focus position has the best focus, which you will have to manually move to. Note that the above function is made 
to handle images of flourescent beads when viewed using the LED driver, NOT for imaging fiducial markings under the scope lamp. 

To check the current position of the focus, run

`focus = scope_get_focus(scope)`

To change the focus position, run

`scope_set_focus(scope, focus_value)`

You can also change the step size of the focus if you would like. Changing the stepsize has a negligible effect on speed, so it is recommended that you 
use the finest setting. Note that the step size can either be coarse (step_size = 0), medium (step_size = 1), or fine (step_size = 2).

To check the step size of the focus, run

`step_size = scope_get_focus_res(obj1)`

To change the step size of the focus, run

`res = scope_get_focus_res(obj1)`

### Changing the Optical Path

More than one camera can be attached to the microscope at a time. To switch between them is to switch the optical path. 

You can check which optical path you are on by running the following:

`path = scope_get_op_path(scope)`

where `path` is the path number of the optical path. 

To change the optical path you are on, run

`scope_set_op_path(scope, path)`

### Closing Connection to the Microscope

For good practice, close the connection to the microscope after use with the following:

`scope_close(scope)`

In some cases, if connection to the scope is not closed properly, `scope_open` will return an error the next time it is run. If such an error
is encountered, turn on and off the microscope and try again. 

## Using the `ba_pulloff_auto` Routine and Metadata

### Creating Metadata File

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

### Editing `well_metadata_script`

`well_metadata_script` is the Matlab script that parses the metadata from the .csv file for a given well, adds additional constant metadata, and then saves 
all of it as a .m file. `ba_pulloff_auto` will require the output .m file to run.

To run this script, use the command

`metafile = well_metadata_script(row,col)`

where `row` refers to the row value of the well and takes an input value in the set [1, 2, 3], and `col` refers to the column value of the well, takes an input 
value in the set [1, 2, 3, 4, 5].

If you want to change the properties of the independent variables (ie. Name, etc.), you should do so inside here. The current iteration does not have the file name of the .csv file 
as an input, so you will also have to change this inside the file.

### Running `ba_pulloff_auto`

`ba_pulloff_auto` is the script that performs the following for a given location:

- Lowers/raises the magnet
- Takes/saves a video of the beads as a .bin file
- Populates the remainder of the metadata skeleton created by `well_metadata_script`

`ba_pulloff_auto` can be called as follows:moto

`ba_pulloff_auto(h, filename,exptime, metafile)`

where `h` is the handle of the z-motor, `filename` is the file name for the new, completely populated metadata file, and `exptime` is the exposure time in milliseconds.

## Running an experiment (WORK IN PROGRESS)

A skeleton of the workflow has been created in a script called `master_control.` It has not been tested to see if it compiles and is missing the algorithm for searching for an 
ideal field of view, but the process is the same.