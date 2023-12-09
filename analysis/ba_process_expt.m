function Data = ba_process_expt(filepath, modeltype, aggregating_variables)
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

if nargin < 3 || isempty('modeltype')
    modeltype = 'erf';
end

if nargin < 2 || isempty('PlateID')
    logentry('No PlateID defined. Creating one at random.');
    PlateID = ['PL-' num2str(randi(2^32,1,1))];
end

if nargin < 1 || isempty('filepath')
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
    otherwise
        error('The input datatype is incorrect. Need a struct or filepath on the input.');
end

ForceTable = ba_make_ForceTable(Data);
Data.ForceTable = ForceTable;
      
[Data.FileTable, Data.ForceTable] = ba_calc_BeadsLeft(Data, aggregating_variables);

% filter out any forces less than 10 femtoNewtons
TmpTable = Data.ForceTable(Data.ForceTable.Force > 10e-15,:);

if height(TmpTable) ~= height(Data.ForceTable)
    logentry(['Removed ' num2str(height(TmpTable) - height(ForceTable)) ' force measurement(s). Below 10 fN threshold.']);
end

Data.ForceTable = TmpTable;

[Data.DetachForceTable, fits] = ba_plate_detachmentforces(Data, aggregating_variables, modeltype, true, false);

cd(rootdir);

end


function outs = sa_fracleft(fid, spotid, force, startCount)

    force = force(:);
    Nforce = length(force);   
    
    % I do not really understand how this determines "rank" of force, but
    % it does and outputs the fraction left attached
    [~,Fidx] = sort(force, 'ascend');
    [~,Frank] = sort(Fidx, 'ascend');    
    
    fracleft = 1-(Frank ./ startCount);

    outs = [fid(:), spotid(:), force(:), fracleft(:)];
end




