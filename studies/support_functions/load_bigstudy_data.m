function BigStudy = load_bigstudy_data(adp, DataSetDirs, aggvar, improveBadFitsTF, savedatafilesTF)

    % all-data-path
    if nargin < 1 || isempty(adp)
        if ismac
            adp = '/Users/stevesnare/adhesion_data/datasets_NOTvideo/';
        else
            adp = 'K:\expts\AdhesionAssay\datasets_NOTvideo\';
        end
    end

    if nargin < 2 || isempty(DataSetDirs)
        DataSetDirs = { ...
                     '2024.01.25__COOHslide_COOHbeads_noint'; ...
                     '2024.01.26__mPEGslide_mPEGbeads_noint'; ...
                     '2024.01.29__HBEslide_HBEbeads_noint'; ...
                     '2024.01.30__HBEslide2_HBEbeads_noint'; ...
                     };
    end

    if nargin < 3 || isempty(aggvar)
        aggvar = {'PlateColumn', 'BeadChemistry', 'PlateChemistry'};
    end

    if nargin < 4 || isempty(savedatafilesTF)
        savedatafilesTF = true;
    end

    weightmethod = 'quantile';
    for k = 1:length(DataSetDirs)
        q = ba_process_expt([adp, DataSetDirs{k}, filesep], aggvar, weightmethod, improveBadFitsTF, savedatafilesTF);
        BigFileT{k,1} = q.FileTable;
        BigTimeHeightVidStatsT{k,1} = q.TimeHeightVidStatsTable;
        BigTrackingT{k,1} = q.TrackingTable;
        BigBeadInfoT{k,1} = q.BeadInfoTable;
        BigForceT{k,1} = q.BeadForceTable;
        BigForceFitT{k,1} = q.ForceFitTable;
        BigOptStartTable{k,1} = q.OptimizedStartTable;
    end

    BigStudy.FileTable = vertcat(BigFileT{:});
    BigStudy.TimeHeightVidStatsTable = vertcat(BigTimeHeightVidStatsT{:});
    BigStudy.BeadInfoTable = vertcat(BigBeadInfoT{:});
    BigStudy.TrackingTable = vertcat(BigTrackingT{:});
    BigStudy.BeadForceTable = vertcat(BigForceT{:});
    BigStudy.OptimizedStartTable = vertcat(BigOptStartTable{:});

    % This stupid try-catch block (and what comes in as contingency clean-up
    % in the catch block) is necessary because, for whatever reason, matlab 
    % refuses to concatenate several single row table when
    % they contain a single fit-object.
    try
        BigStudy.ForceFitTable = vertcat(BigForceFitT{:});
    catch
        for stupIDX = 1:length(DataSetDirs)
            tmp{stupIDX,1} = BigForceFitT{stupIDX};
            tmp{stupIDX,1}.FitObject = [];
            tmpFits{stupIDX,1} = BigForceFitT{stupIDX}.FitObject;
        end
        tmpT = vertcat(tmp{:});
        tmpT.FitObject = tmpFits;
        tmpT = movevars(tmpT, "FitObject", "before", "sse");
        BigStudy.ForceFitTable = tmpT;
    end
end

