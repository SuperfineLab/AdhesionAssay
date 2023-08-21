function display_montage(cim, titlestring)
    figure;
    montage(cim);
    ax = gca;
    ax.CLimMode = 'auto';
    title(titlestring);
    drawnow
end