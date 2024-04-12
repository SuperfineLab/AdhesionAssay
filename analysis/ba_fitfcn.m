function fitfcn = ba_fitfcn(Nmodes)
% XXX TODO @jeremy document this function 
%

    Nparams = Nmodes*3;
    plist = reshape(1:Nparams,3,[])';
    
    for k = 1:Nmodes
       eqstr{1,k} = compose('p(%d)*erfc((Fd-p(%d))/(sqrt(2)*p(%d)))',plist(k,:));
    end

    eqstr = join(string(eqstr), ' + ');
    fitfcn = str2func(['@(p,Fd)(1/2*(', char(eqstr), '))']);

end

%     % old form
%     fitfcn{1} = @(p, Fd)(1/2*(  p(1) *erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
%     fitfcn{2} = @(p, Fd)(1/2*(  p(1) *erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
%                              (1-p(1))*erfc(((Fd)-p(4))/(sqrt(2)*p(5)))));
% 

