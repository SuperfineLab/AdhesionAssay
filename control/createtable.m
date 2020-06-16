function [table] = createtable(filelist)

for k = 1:numel(filelist)
    Frames(k,1) = imread(filelist(k).name); 
end


for k = 1:numel(Frames)
    
    %Declaring variables for single integer value categories later
    avgval = 0;
    medval = 0;
    minval = 0;
    maxval = 0;
    
    [centers, radii] = imfindcircles(Frames(k),[15 40]);
    
    % Storing Ncircles as number of circles detected
    Ncircles = numel(centers);

    
    
    % Creating distances array category via finding distances between lth circle and each of the other circles
    for l = 1:Ncircles
       distances = zeros(1,Ncircles);
       m = 0;
       while m <= Ncircles
           if m ~= l
               distances(l) = sqrt(((centers{l,1}-centers{m,1})^2)+((centers{l,2}-centers{m,2})^2));
           end
       end
    end
       
    %Looping through each of l distance arrays per image to find max, min,
    %average, and median distances
    statsarray = zeros(4,Ncircles);
    
    for l = 1:Ncircles
        
        statsarray{1,l} = mean(currentarray);
        statsarray{2,l} = median(currentarray);
        statsarray{3,l} = min(currentarray);
        statsarray{4,l} = max(currentarray);
               
    end
    
    %Creating overall statistics for each image file
    avgval = mean(statsarray{1,:});
    medval = median(statsarray{2,:});
    minval = min(statsarray{3,:});
    maxval = max(statsarray{4,:});
    
end