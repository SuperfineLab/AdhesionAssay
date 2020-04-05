function score = scoring_function(beadnum,logavgdist)

% %Recall:
% sigma_f = sqrt((log10((BeadNumber)))^2*(0.00131769));
% f = (-0.5126*log10(BeadNumber)+2.747);

slope_uncertainty = 0.00131769;
slope = -0.5126;
y_int = 2.747;

for k = 1:130
    beadnum = log10(metricvals(k,1));
    logavgdist = metricvals(k,2);
    sigma_f = sqrt(beadnum)^2*(slope_uncertainty);
    %Generated fit to dataset for manually collected experiments early in
    %project life; 
    f = (slope*log10(beadnum)+y_int);
    if  logavgdist < (f - sigma_f)
        metricvals(k,4) = 0;
    elseif logavgdist >= (f - sigma_f)
        clen = sqrt(((beadnum)^2)+((logavgdist)^2));
        alen = sqrt(((beadnum)^2));
        blen = sqrt(((logavgdist)^2));

        %In Degrees
        aang = acosd(blen/clen);
        bang = (-(blen)^2+(alen)^2+(clen)^2)/(2*aang*90);
        metricvals(k,4) = alen*sind(bang);
    else
        metricvals(k,4) = -1;
    end
end
