function plot_wells(WellsCell, myclim)

    if nargin < 2 || isempty(myclim)
        myclim = [1 25];
    end
   
    figure;
    for k = 1:length(WellsCell)
        subtightplot(3,5,k,[0.01,0.01],0.01,0.01);
        imagesc(WellsCell{k});
        axis image; 
        axis off; 
        colormap(gray); 
        ax = gca; 
        ax.CLim = [1 25]; 
        drawnow; 
    end
    
end