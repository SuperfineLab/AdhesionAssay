function fitfcn = ba_fitfcn(Nmodes)

    Nparams = Nmodes*3;
    plist = reshape(1:Nparams,3,[])';
    for k = 1:Nmodes
       eqstr{1,k} = compose('p(%d)*erfc((Fd-p(%d))/(sqrt(2)*p(%d)))',plist(k,:));
    end
    eqstr = join(string(eqstr), ' + ');
    fitfcn = str2func(['@(p,Fd)(1/2*(', char(eqstr), '))']);

%     % old form
%     fitfcn{1} = @(p, Fd)(1/2*(  p(1) *erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
%     fitfcn{2} = @(p, Fd)(1/2*(  p(1) *erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
%                              (1-p(1))*erfc(((Fd)-p(4))/(sqrt(2)*p(5)))));
% 
%     % new form
%     fitfcnNew{1} = @(p, Fd)(1/2*(p(1)*erfc((Fd)-p(2))/(sqrt(2)*p(3)))));
%     fitfcnNew{2} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
%                                  p(4)*erfc(((Fd)-p(5))/(sqrt(2)*p(6))))); 
%     fitfcnNew{3} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
%                                  p(4)*erfc(((Fd)-p(5))/(sqrt(2)*p(6))) + ...
%                                  p(7)*erfc(((Fd)-p(8))/(sqrt(2)*p(9))))); 
% 
%     switch fittype
%         case "erf-old"
%             if Nmodes > 2
%                 warning('This model not defined for more than 2 modes. Resetting to two modes.');
%                 Nmodes = 2;
%             end
%             fiteq = fitfcn{Nmodes};
%             Nparams = 2*Nmodes + 1;
%         case "erf-new"
%             fiteq = fitfcnNew{Nmodes};
%             Nparams = 3*Nmodes;
%         otherwise
%             error('Fit type not defined.');           
%     end
% 
%     switch nargout
%         case 1
%             varargout{1} = fitfcn;
%         case 2
%             varargout{1} = fitfcn;
%             varargout{2} = Nparams;
%     end

end