function outs = Weighted_avg_histograms(sim_data,master_curves)
% master curves argument is the output from running resample_study(Broot,1,1,true)
% sim_data is the output from resample_study()
%



selectedRows = ~cellfun(@isempty, sim_data.FitObject);

% Use the logical index to select rows
Filtered_sim_data =  sim_data(selectedRows, :);
Number_of_failed_fits = height(sim_data) - height(Filtered_sim_data);


plategroups = unique(Filtered_sim_data.PlateID);
curvecountgroups = unique(Filtered_sim_data.CurveCount);


idx = 1;

tmpT = Filtered_sim_data(:,{'PlateID','CurveCount','SimID','CurveID','am','amconf','bm','bmconf'});
tmp_am_bm = stack(tmpT,{'am','bm'},'NewDataVariableName','m','IndexVariableName','ab');
tmp_am_bm.amconf = [];
tmp_am_bm.bmconf = [];
tmpC = tmpT;
tmpC.am = tmpC.amconf;
tmpC.bm = tmpC.bmconf;
tmpC.amconf = [];
tmpC.bmconf = [];
tmp_abconf = stack(tmpC,{'am','bm'},"NewDataVariableName",'conf','IndexVariableName','ab');

am_bm_table = innerjoin(tmp_am_bm, tmp_abconf,'Keys',{'PlateID','SimID','CurveID','CurveCount','ab'});
tmptmp = splitvars(am_bm_table, 'conf');
nanselected_ambm_rows = ~cellfun(@isnan, num2cell(tmptmp.conf_1));
am_bm_table = am_bm_table(nanselected_ambm_rows,:);
negvalselected_ambm_rows = am_bm_table.m > -10;
am_bm_table = am_bm_table(negvalselected_ambm_rows,:);
posvalselected_ambm_rows = am_bm_table.m < 10;
am_bm_table = am_bm_table(posvalselected_ambm_rows,:);
f = findgroups(am_bm_table(:,{'PlateID','CurveCount'}));

foo = splitapply(@(x1){ba_weights(x1,0.95)},am_bm_table.conf,f);

am_bm_table.weights = vertcat(foo{:});



%combine all am's and bm's into single table with their corresponding
%weights


%need to filter out m's with NAN weights
am_bm_selectedRows = ~isnan(am_bm_table.weights);

% Use the logical index to select rows
filtered_am_bm_table =  am_bm_table(am_bm_selectedRows, :);
nan_num = height(am_bm_table) - height(filtered_am_bm_table);



%%% You will need to run master_curves = splitvars(master_curves, 'amconf');
%%% and also master_curves = splitvars(master_curves, 'bmconf');
%%% for the function to work properly

idx = 1;
plategroups = unique(filtered_am_bm_table.PlateID);
curvecountgroups = unique(filtered_am_bm_table.CurveCount);

binWidth = 0.17;



%%%Plot histograms for am data
        for i = 1:length(plategroups) %%reversing loop was important to make the colors look right and match up with their legend color
            
            % Extract data corresponding to the current group
            current_plate = plategroups(i);
            groupData = filtered_am_bm_table(filtered_am_bm_table.PlateID == current_plate, :);

            for  k = length(curvecountgroups):-1:1
                
                %extract data corresponding to the current subgroup
                subgroupData = groupData(groupData.CurveCount == curvecountgroups(k),:);
                subgroupData = subgroupData(subgroupData.m <= 10,:);
                edges = -3:binWidth:max(subgroupData.m);
                figure(i);
                hold on;
                histogram(subgroupData.m, edges);

                figure(100+i);
                hold on;
                ksdensity(subgroupData.m,'Weights',subgroupData.weights)
                m_weighted_mean = sum((groupData.m.*groupData.weights))/sum(groupData.weights);
                ksyLimit = 1;
                plot([m_weighted_mean,m_weighted_mean], [0,ksyLimit], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Weighted Mean');
                hold off;

                legendStrings{k} = sprintf('%d curves', curvecountgroups(k));
                
              
            end
            title(["Combined am and bm ksdensity for ", current_plate])
            legend(legendStrings);
            xlim([min(subgroupData.m)-1,max(subgroupData.m)]);

            
            
             % Get the current y-axis limits
            figure(i)
            hold on;
            legend(legendStrings);
            yLimit = 150;
            plot([m_weighted_mean,m_weighted_mean], [0,yLimit], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Weighted Mean');
            title(["Combined am and bm histogram for ", current_plate])
            hold off;
        end


            
end

        
