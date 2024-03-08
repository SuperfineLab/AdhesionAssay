function [SimOut, SamplingCheck] = resample_study(Broot, NSims, NCurves, WithReplacementTF)
%%% SamplingN - how many beads do you want to sample from each plate?
%%% WithReplacementTF - A Boolean; true means with replacement, false means
%%% without replacement

path_for_genpath = '/Users/stevesnare/code';
addpath(genpath([path_for_genpath, filesep, '3dfmAnalysis']));

if nargin < 4 || isempty(WithReplacementTF)
    WithReplacementTF = true;
end

if nargin < 3 || isempty(NCurves)
    NCurves = 5;  % aggregating across columns
end

if nargin < 2 || isempty(NSims)
    NSims = 1;
end

if nargin < 1 || isempty(Broot)
    error("Can't function without data.");
end

FileVarsToKeep = {'PlateID', 'Fid', 'Well', 'PlateRow', 'PlateColumn', ...
                  'SubstrateChemistry', ...
                  'FirstFrameBeadCount', 'LastFrameBeadCount'};

%%% I got rid of Bead Chemistry because in all of these plates, the bead
%%% chemistry is the same as the substrate chemistry, so having both
%%% variables is redundant.
%%%I also got rid of Buffer, and PH, because for every observation they
%%%were PBS, and 7, respectively

% % % % % % % Important NOTE: Starting points in the fitting function are tuned to the 
% % % % % % % **log10(force_in_nN)**. The units on the input MUST match exactly 
% % % % % % % for the fitting function to operate in an expected fashion within the 
% % % % % % % number of MaxEvals also established in the ba_fit_erf code.

%%% Master Curve Parameter Calculations
mc_aggregating_variables = {'PlateID'};
MasterCurveDetachForceTable = ba_plate_detachmentforces(Broot, mc_aggregating_variables, 'erf', true, false);


% % % % magic numbers
% % % [nWells, nCols, nRows] = deal(15, 5, 3);
% % % NCurves = nWells;

RawForceDataT = innerjoin(Broot.FileTable(:,FileVarsToKeep), Broot.ForceTable, 'Keys', {'Fid'}); %% keeps only relevant columns

for c = 1:length(NCurves)
    for s = 1:NSims
        SimID = s;
        sim{s,1} = RunSim(RawForceDataT, NCurves(c), SimID, WithReplacementTF);
    end
    q{c,1} = vertcat(sim{:});      
end
SimOut = vertcat(q{:});

PlateSummaryT = SummarizePlateCounts(RawForceDataT);

% This checks the average number of points per curve against the average
% number of forces across all plates in the study. The two columns should
% more or less match
[g, SamplingCheck] = findgroups(SimOut(:,'CurveCount'));
SamplingCheck.SimMeanPointsPerForceCurve = splitapply(@mean, SimOut.Nforces, g);
SamplingCheck.PlateMeanPointsPerForceCurve = mean(PlateSummaryT.TotalNforces) ./ SamplingCheck.CurveCount;








end



function outs = RunSim(RawForceDataT, NCurves, SimID, WithReplacementTF)

%
% We want to assign a "CurveID" to each force, i.e., the curve to which
% each force measurement belongs. The number of Curves depends on the total
% number of forces available divided by however many curves we want to see
% on the plate (a stand-in for sampling the available data).
%
[g, gT] = findgroups(RawForceDataT.PlateID);
tmp = splitapply(@(x1,x2,x3){sa_setCurveID(x1,x2,x3,NCurves,WithReplacementTF)}, RawForceDataT.PlateID, RawForceDataT.Fid, RawForceDataT.SpotID, g);
tmp = vertcat(tmp{:});
RawForceDataNew = innerjoin(RawForceDataT, tmp, 'Keys', {'PlateID', 'Fid', 'SpotID'});
clear tmp;

% 
% Now that we have CurveIDs assigned, we split up the curves and apply fits
% to each set. The CurveIDs serve PLATE-WIDE.
%
% function myfit = ba_fit_erf(logforce, pct_left, weights, Nterms, startpoint)
Nterms = 2;
[gg, ggT] = findgroups(RawForceDataNew.PlateID, RawForceDataNew.CurveID);
tmp = splitapply(@(x1,x2,x3,x4,x5){sa_grabfits(x1, x2, x3, x4, x5, Nterms)}, ...
                             RawForceDataNew.PlateID, ...
                             RawForceDataNew.CurveID, ...
                             RawForceDataNew.Force, ...
                             RawForceDataNew.FractionLeft, ...
                             RawForceDataNew.Weights, ...
                             gg);
tmp = vertcat(tmp{:});

tmp.SimID = repmat(SimID, height(tmp), 1);
tmp.CurveCount = repmat(NCurves, height(tmp), 1);

tmp = movevars(tmp, {'PlateID', 'CurveCount', 'SimID', 'CurveID', 'Nforces'}, 'before', 'FitObject');

outs = tmp;

end


function outs = sa_setCurveID(PlateID, Fid, SpotID, NCurves, replaceTF)

    
    if replaceTF
        CurveID = randi(NCurves, numel(PlateID),1);        
    else
        error('Not implemented yet.');
        % Use randperm instead of randi if "no replacement" is desired.
    end

    outs = table(PlateID(:), Fid(:), SpotID(:), CurveID(:), 'VariableNames', ...
        {'PlateID', 'Fid', 'SpotID', 'CurveID'});

end


function outs = sa_grabfits(plateid, curveid, force, fractionleft, weights, nterms)
    
    myfit = ba_fit_erf(log10(force * 1e9), fractionleft, weights, nterms);  
    
    myfit.PlateID = plateid(1);
    myfit.CurveID = curveid(1);
    myfit.Nforces = numel(force);

    outs = struct2table(myfit, 'AsArray',true);
end


function PlateSummaryT = SummarizePlateCounts(file_force_table)
    % To find the number of force measurements per file/well, return the height
    % of the resulting sub-tables when splitting based on Fid.
    [f, fT] = findgroups(file_force_table(:, {'PlateID', 'Fid'}));
    fT.Nforces = splitapply(@height, file_force_table.Fid, f);    
    
    % Sum over the BeadCounts for all Fid's in each given Plate.
    [p, PlateSummaryT] = findgroups(fT(:, {'PlateID'}));
    PlateSummaryT.PlateCode = double(PlateSummaryT.PlateID);
    PlateSummaryT.TotalNforces= splitapply(@sum, fT.Nforces, p);
    PlateSummaryT.MinNforces = splitapply(@min, fT.Nforces, p);
    PlateSummaryT.MeanNforces = splitapply(@mean, fT.Nforces, p);
    PlateSummaryT.MaxNforces = splitapply(@max, fT.Nforces, p);

end



% % % % % for k = 1:length(NForcesPerCurve)
% % % % % 
% % % % %     for i = 1:50
% % % % %         Nsample_array{i,1} = grouped_resample(file_force_table,NForcesPerCurve(k),WithReplacementTF);
% % % % %     end
% % % % % 
% % % % %     result_array{k,1} = vertcat(Nsample_array{:});
% % % % % 
% % % % % end
% % % % % 
% % % % % result_array = vertcat(result_array{:});
% % % % % 
% % % % % 
% % % % % 
% % % % % % summary = groupsummary(result_array,{'PlateID','Nbeads'},{'mean','std'},'am');
% % % % % %[a,aT] = findgroups(Nsample_array(:,"PlateID"));
% % % % % 
% % % % % confidence_widths = grouped_confwidth(result_array);
% % % % % 
% % % % % uniquePlateID = unique(confidence_widths.PlateID);
% % % % % 
% % % % % % Plot data for each unique PlateID separately
% % % % % figure;
% % % % % hold on; 
% % % % % for i = 1:length(uniquePlateID)
% % % % %     % Filter data for the current PlateID
% % % % %     plateData = confidence_widths(confidence_widths.PlateID == uniquePlateID(i), :);
% % % % %     
% % % % %     % Plot the data as a line plot
% % % % %     plot(plateData.Nbeads, plateData.amconfwidth, '-o', 'DisplayName', char(uniquePlateID(i)));
% % % % % end
% % % % % 
% % % % % % Add labels and title
% % % % % xlabel('Nbeads');
% % % % % ylabel('Confidence Interval Width of am');
% % % % % title('Line Graph for Each PlateID');
% % % % % legend('show'); % Show legend with PlateID labels
% % % % % 
% % % % % pause(0.1)
% % % % % 
% % % % % outs = result_array;
% % % % % 
% % % % % end
% % % % % 
% % % % % 
% % % % % function outs = grouped_resample(measurements, SamplingN, WithReplacementTF)
% % % % % 
% % % % %     % Take the logarithm of measurements
% % % % %     measurements.log_forces = log10(measurements.Force*1e9);
% % % % %     
% % % % %     
% % % % %     % Preallocate cell array to store sampled points
% % % % %     sampledbeads = cell(4,1);
% % % % % 
% % % % %     groups = unique(measurements.PlateID);
% % % % % 
% % % % %           
% % % % %     for i = 1:length(groups)
% % % % %         % Extract data corresponding to the current group
% % % % %         groupData = measurements(measurements.PlateID == groups(i), :);
% % % % %     
% % % % %         % Sample 'SamplingN' random points from the current group
% % % % %         sampledbeads{i} = datasample(groupData, SamplingN, 'Replace', WithReplacementTF);
% % % % %     end
% % % % % 
% % % % %  
% % % % %   result_array = cell(4,1);
% % % % %     for i = 1:length(sampledbeads)
% % % % %         % Extract data for the current plate group
% % % % %         currentGroupData = sampledbeads{i};
% % % % %         
% % % % %      
% % % % %         % calculate fit parameters for each group
% % % % %         result = struct2table(ba_fit_erf(currentGroupData.log_forces, ...
% % % % %             currentGroupData.FractionLeft, ...
% % % % %             currentGroupData.Weights));
% % % % %         
% % % % %         
% % % % %         
% % % % %         result_array{i}.PlateID = unique(currentGroupData.PlateID);
% % % % %         result_array{i}.Nbeads = SamplingN;
% % % % %         result_array{i}.am = result.am;
% % % % %         result_array{i}.as = result.as;
% % % % %         result_array{i}.bm = result.bm;
% % % % %         result_array{i}.bs = result.bs;
% % % % %         result_array{i}.amconf = result.amconf;
% % % % %         result_array{i}.asconf = result.asconf;
% % % % %         result_array{i}.bmconf = result.bmconf;
% % % % %         result_array{i}.bsconf = result.bsconf;
% % % % %      %   result_array{i} = RMSE COLUMN
% % % % %         result_array{i} = struct2table(result_array{i});
% % % % %         
% % % % %     
% % % % %         %why dont these work??
% % % % %         
% % % % %      
% % % % %     end
% % % % %    
% % % % % 
% % % % %     outs = vertcat(result_array{:});
% % % % % end
% % % % % 
% % % % % 
% % % % % 
% % % % % function outs = grouped_confwidth(table)
% % % % % 
% % % % %     plategroups = unique(table.PlateID);
% % % % %     Nbeadgroups = unique(table.Nbeads);
% % % % %     ci_widths = cell(length(Nbeadgroups)*length(plategroups),1);
% % % % %     
% % % % % 
% % % % %           
% % % % %         for i = 1:length(plategroups)
% % % % %             % Extract data corresponding to the current group
% % % % %             groupData = table(table.PlateID == plategroups(i), :);
% % % % % 
% % % % %             for k = 1:length(Nbeadgroups)
% % % % %                 %extract data corresponding to the current subgroup
% % % % %                 idx = (i*length(Nbeadgroups)-1)+(k-1);
% % % % %                 subgroupData = groupData(groupData.Nbeads == Nbeadgroups(k),:);
% % % % %                 ci_widths{(idx)}.PlateID = plategroups(i);
% % % % %                 ci_widths{(idx)}.Nbeads = Nbeadgroups(k);
% % % % %                 ci_widths{(idx)}.amconfwidth = quantile(subgroupData.am,0.95) - quantile(subgroupData.am,0.05);
% % % % %                 ci_widths{(idx)}.bmconfwidth = quantile(subgroupData.bm,0.95) - quantile(subgroupData.bm,0.05);
% % % % %                 ci_widths{(idx)} = struct2table(ci_widths{(idx)});
% % % % %                 
% % % % %             end
% % % % %         end
% % % % % 
% % % % % 
% % % % %     ci_widths = vertcat(ci_widths{:});
% % % % % 
% % % % %     outs = ci_widths;
% % % % % 
% % % % % end
