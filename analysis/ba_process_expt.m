function Data = ba_process_expt(filepath, modeltype, aggregating_variables, savefileTF)
% BA_PROCESS_EXPT analyzes the output of a bead adhesion experiment.
%
% This function begins the process of analyzing the output of the bead
% adhesion experiment where the bead detaches from the surface and moves
% through z while being tracked by vst. The z-velocity is then used to back
% out the detachment force.
% 
% Inputs:
%  filepath   path location of the tracking results for an "experiment"/plate.
%  PlateID    string indentifier for the plate used in the experiment
%  modeltype  model used for fitting forces. Can be "linear", "erf", or "exponential"
%  aggregating_variables   The list of index variables for the experiment,
%                          e.g, "pH", "BeadChemistry", "SubstrateChemistry", etc.
%
% Output:
%  Data   structure containing tables of File, Bead/Tracking, and Force Data
%

if nargin < 4 || isempty(savefileTF)
    savefileTF = false;
end

if nargin < 3 || isempty(aggregating_variables)
    error('Need aggregating variables for compiling results.');
end

if nargin < 2 || isempty(modeltype)
    modeltype = 'erf';
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

    Data.ForceTable = ba_make_ForceTable(Data);
          
    % Update FileTable with remaining bead count once pulls are completed
    Data.FileTable = ba_calc_BeadsLeft(Data);
    
    % filter out any forces less than 10 femtoNewtons
    TmpTable = Data.ForceTable(Data.ForceTable.Force > 10e-15,:);
    
    if height(TmpTable) ~= height(Data.ForceTable)
        logentry(['Removed ' num2str(height(TmpTable) - height(Data.ForceTable)) ' force measurement(s). Below 10 fN threshold.']);
    end
    
    Data.ForceTable = TmpTable;
end

Data.DetachForceTable = ba_plate_detachmentforces(Data, aggregating_variables, modeltype, true, true);

if savefileTF
    PlateName = string(unique(Data.FileTable.PlateID));
    if numel(PlateName) == 1
        save([char(PlateName), '.platedata.mat'], '-STRUCT', 'Data');
    end
end

cd(rootdir);

end







