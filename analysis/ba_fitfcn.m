function fitfcn = ba_fitfcn(Nmodes)
% BA_FITFCN returns the fitting function for the requested number of modes.
%
% This function generates a fitting function object for the "standard form"
% detached bead percentage as a function of detachment force. It works for
% 1 to Nmodes.
%
% fitfcn = ba_fitfcn(Nmodes)
%
% Output:
%    fitfcn is the outputted function object for Nmodes
% 
% Input:
%    Nmodes is the number of modes for the standard erf fitting equation.
%

    if Nmodes == 0
        fitfcn = '@(p,Fd)(0)';
        return
    end

    Nparams = Nmodes*3;
    plist = reshape(1:Nparams,3,[])';
    
    eqstr = cell(1,Nmodes);
    for k = 1:Nmodes
       eqstr{1,k} = compose('p(%d)*erfc((Fd-p(%d))/(sqrt(2)*p(%d)))',plist(k,:));
    end

    eqstr = join(string(eqstr), ' + ');

    if Nmodes == 1 
        eqstr = strrep(eqstr,"p(1)","1");
    end
    
    fitfcn = str2func(['@(p,Fd)(1/2*(', char(eqstr), '))']);


end


