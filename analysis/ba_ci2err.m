function outs = ba_ci2err(ForceIn, confint, spacein, spaceout)
%
% Adhesion Assay
% Analysis
%

if nargin < 3 || isempty(spacein)
    spacein = 'log';
end

if nargin < 4 || isempty(spaceout)
    spaceout = spacein;
end

switch spacein
    case "log"
        F = 10.^(ForceIn);
        Fl(:,1) = 10.^confint(:,1);
        Fh(:,1) = 10.^confint(:,2);
    case "lin"
        F = ForceIn;
        Fl(:,1) = confint(:,1);
        Fh(:,1) = confint(:,2);
end

El = F - Fl;
Eh = Fh - F;

switch spaceout
    case "log"
        El_out(:,1) = log10(El);
        Eh_out(:,1) = log10(Eh);
    case "lin"
        El_out(:,1) = El;
        Eh_out(:,1) = Eh;
end

outs = [El_out, Eh_out];

