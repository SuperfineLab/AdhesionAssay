function Data = ba_process_expt(filepath, aggregating_variables, weightmethod, improveBadFitsTF, savefileTF)
% BA_PROCESS_EXPT analyzes a bead adhesion experiment for detachment forces
%
% This function begins the process of analyzing the output of the bead
% adhesion experiment where the bead detaches from the surface and moves
% through z while being tracked by vst. The z-velocity is then used to back
% out the detachment force.
% 
% Output:
%  Data   structure containing tables of File, Bead/Tracking, and Force Data
%
% Inputs:
%   filepath*   path location of the tracking results for an "experiment"/plate.
%   aggregating_variables*   The list of index variables for the experiment,
%     e.g, "pH", "BeadChemistry", "SubstrateChemistry", etc.
%   weightmethod - one from the below list of weighting computation options
%     [ unweighted, inverseconf, scaled-inversebin, {quantile} ]
%   improveBadFitsTF - [{true} false] switch for using distribution of the 
%       sum-square-error (SSE) to re-fit datasets with abnormally high SSE
%   savefileTF - [true {false}] switch for saving results to the data
%       directory
%
% Notes: (*) denotes required parameters (i.e., no default values)
%


if nargin < 5 || isempty(savefileTF)
    savefileTF = false;
end

if nargin < 4 || isempty(improveBadFitsTF)
    improveBadFitsTF = true;
end

if nargin < 3 || isempty(weightmethod)
    weightmethod = 'quantile';
end

if nargin < 2 || isempty(aggregating_variables)
    error('Need aggregating variables for compiling results.');
end

if nargin < 1 || isempty(filepath)
    error('No input data. Needs a B-style struct or a filepath on the input.');
end

rootdir = pwd;

switch class(filepath)
    case 'char'
        if ~isempty(dir(filepath))
            cd(filepath);
            logentry(['Moved to: ' filepath]);

            Data = ba_load_raw_data(filepath);
        else
            error('Filepath is either empty or does not exist.');
        end
    case 'struct'
        % check for presence of raw datatypes (not derived/computed)
        if isfield(filepath, 'FileTable') && ...
           isfield(filepath, 'TimeHeightVidStatsTable') && ...
           isfield(filepath, 'TrackingTable') && ...
           isfield(filepath, 'BeadInfoTable')  
            Data = filepath;
        else
            error('Input Data structure is malformed.');            
        end

        savefileTF = false;
    otherwise
        error('The input datatype is incorrect. Need a struct or filepath on the input.');
end


if ~isfield(Data, 'ForceTable')

%     Data.ForceTable = ba_make_ForceTable(Data, 'unweighted');
    WeightMethod = 'quantile';
    Data.ForceTable = ba_make_ForceTable(Data, WeightMethod);
          
    % Update FileTable with remaining bead count once pulls are completed
    Data.FileTable = ba_calc_BeadsLeft(Data);
    
    % filter out any forces less than 10 femtoNewtons
    TmpTable = Data.ForceTable(Data.ForceTable.Force > 10e-15,:);
    
    if height(TmpTable) ~= height(Data.ForceTable)
        logentry(['Removed ' num2str(height(TmpTable) - height(Data.ForceTable)) ' force measurement(s). Below 10 fN threshold.']);
    end
    
    Data.ForceTable = TmpTable;
end

% weightmethod = 'quartile';
% weightmethod = 'unweighted';
[tmpDetachForceTable, optstartT] = ba_plate_detachmentforces(Data, aggregating_variables, fitmethod, weightmethod);

if ~improveBadFitsTF
    Data.DetachForceTable = tmpDetachForceTable;
else
    logentry('Improving bad fits...');
    Data.DetachForceTable = ba_improve_bad_fits(tmpDetachForceTable, aggregating_variables, optstartT);
end

Data.aggregating_variables = aggregating_variables;

if savefileTF
    PlateName = string(unique(Data.FileTable.PlateID));
    if numel(PlateName) == 1
        save([char(PlateName), '.platedata.mat'], '-STRUCT', 'Data');
    end
end

cd(rootdir);

end







