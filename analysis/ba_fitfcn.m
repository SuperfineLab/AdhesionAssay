function fitfcn = ba_fitfcn(Nmodes)
% BA_FITFCN returns the fitting function for the requested number of modes.
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

%     % old form
%     fitfcn{1} = @(p, Fd)(1/2*(  p(1) *erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
%     fitfcn{2} = @(p, Fd)(1/2*(  p(1) *erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
%                              (1-p(1))*erfc(((Fd)-p(4))/(sqrt(2)*p(5)))));
% 

