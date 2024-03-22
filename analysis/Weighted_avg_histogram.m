function outs = Weighted_avg_histograms(cleaned_sim_data,master_curves)
%master curves argument is the output from running resample_study(Broot,1,1,true)


%%% You will need to run master_curves = splitvars(master_curves, 'amconf');
%%% and also master_curves = splitvars(master_curves, 'bmconf');
%%% for the function to work properly

idx = 1;
plategroups = unique(cleaned_sim_data.PlateID);
curvecountgroups = unique(cleaned_sim_data.curvecount);

binWidth = 0.17;



%%%Plot histograms for am data
        for i = 1:length(plategroups) %%reversing loop was important to make the colors look right and match up with their legend color
            hold off;
            % Extract data corresponding to the current group
            current_plate = plategroups(i);
            groupData = cleaned_sim_data(cleaned_sim_data.PlateID == current_plate, :);

            for  k = length(curvecountgroups):-1:1
                
                %extract data corresponding to the current subgroup
                subgroupData = groupData(groupData.curvecount == curvecountgroups(k),:);
                edges = -3:binWidth:max(subgroupData.amconfwidth);
                histogram(subgroupData.amconfwidth, edges);
             
                legendStrings{k} = sprintf('%d curves', curvecountgroups(k));
                hold on;
              
            end
            title(["Confidence widths of am vs Curve Count for ", current_plate])
            legend(legendStrings);

            actual__am_width = master_curves.amconf_2(i)-master_curves.amconf_1(i);
            
            yLimit = 50; % Get the current y-axis limits
            
            plot([actual__am_width,actual__am_width], [0,yLimit], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Actual am'); 
            
        end

%i = 1;
        %%plot histograms for bm data
       for i = 1:length(plategroups) %%reversing loop was important to make the colors look right and match up with their legend color
            hold off;
            % Extract data corresponding to the current group
            current_plate = plategroups(i);
            groupData = cleaned_sim_data(cleaned_sim_data.PlateID == current_plate, :);

            for  k = length(curvecountgroups):-1:1
                
                %extract data corresponding to the current subgroup
                subgroupData = groupData(groupData.curvecount == curvecountgroups(k),:);
                edges = -3:binWidth:max(subgroupData.bmconfwidth);
                histogram(subgroupData.bmconfwidth, edges);
             
                legendStrings{k} = sprintf('%d curves', curvecountgroups(k));
                hold on;
               
            end
            title(["Confidence widths of bm vs Curve Count for ", current_plate])
            legend(legendStrings);

            actual__bm_width = master_curves.bmconf_2(i)-master_curves.bmconf_1(i);
            
            yLimit = 50; % Get the current y-axis limits
            
            plot([actual__bm_width,actual__bm_width], [0,yLimit], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Acutual bm'); 
            
        end
        