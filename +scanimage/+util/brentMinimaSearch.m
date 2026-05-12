%%%%%% BRENT'S MINIMA SEARCH
%  Minima search in a 1D function using Brent's method of optimal
%  iterative search.
%  Adapted from Sci-Py's Python implementation of Brent's method (Nelson D).
%  https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.brent.html
%  https://en.wikipedia.org/wiki/Brent%27s_method

% FUNCTION ARGUMENTS:
%  func:       function pointer of the form func(x,args...)
%  bracket:    the [a,b] region to search within
%  tolerance:  solution tolerance
%  maxIter:    maximum number of iterations
%  args:       function arguments to pass in after "x"
%  callback:   callback function pointer of the form cb(x,func(x)) to call each iteration

% FUNCTION OUTPUTS:
%  x_min:      the x where func(x) is minimized
%  f_min:      the value of func(x_min)
%  xs:         the x values searched
%  fs:         the function values at points "xs"
%  numIters:   the number of algorithm iterations to find minima
%  numCalls:   the number of calls to "func" made

function [x_min,f_min,xs,fs,numIters,numCalls] = brentMinimaSearch(func,bracket,tolerance,maxIter,args,callback)
    if nargin < 5 || isempty(args)
        args = {};
    end
    if nargin < 6 || isempty(callback)
        callback = @(x,fx)[];
    end

    currentIter = 0;
    numCalls = 0;

    minTolerance = 1e-11;   % internal algorithm minimum tolerance
    cg = 0.3819660;         % golden section algorithm constant

    % the bracket [a,b] will be updated iteratively
    if diff(bracket) > 0
        a = bracket(1);
        b = bracket(2);
    else
        a = bracket(2);
        b = bracket(1);
    end

    x = b;
    w = b;
    v = b;
    delta_x = 0.0;

    fx = func(b,args{:});
    numCalls = numCalls + 1;
    fw = fx;
    fv = fx;

    xs = [];
    fs = [];

    while currentIter < maxIter
        tol1 = tolerance * x + minTolerance;
        tol2 = 2 * tol1;
        x_mid = (a + b) / 2;

        xs(end+1) = x;
        fs(end+1) = fx;
        callback(x,fx);

        % check convergence
        if abs(x - x_mid) < tol2 - ((b - a) / 2)
            break
        end

        if abs(delta_x) <= tol1
            % golden section step
            if (x >= x_mid)
                delta_x = a - x;  
            else
                delta_x = b - x;
            end
            rat = cg * delta_x;
        else
            % parabolic step
            tmp1 = (x - w) * (fx - fv);
            tmp2 = (x - v) * (fx - fw);
            p = ((x - v) * tmp2) - ((x - w) * tmp1);
            tmp2 = 2 * (tmp2 - tmp1);
            if (tmp2 > 0)
                p = -p;
            end
            tmp2 = abs(tmp2);
            dx_temp = delta_x;
            delta_x = rat;

            % check parabolic fit
            if (p > tmp2 * (a - x)) && (p < tmp2 * (b - x)) && (abs(p) < abs(tmp2 * dx_temp / 2))
                rat = p / tmp2;
                u = x + rat;
                if ((u - a) < tol2) || ((b - u) < tol2)
                    if x_mid - x >= 0
                        rat = tol1;
                    else
                        rat = -tol1;
                    end
                end
            else % otherwise do a golden section step
                if (x >= x_mid)
                    delta_x = a - x;
                else
                    delta_x = b - x;
                end
                rat = cg * delta_x;
            end
        end

        % update by at least tol1
        if abs(rat) < tol1
            if rat >= 0
                u = x + tol1;
            else
                u = x - tol1;
            end
        else
            u = x + rat;
        end

        % compute new output value
        fu = func(u,args{:});
        numCalls = numCalls + 1;

        if (fu > fx)
            if (u < x)
                a = u;
            else
                b = u;
            end

            if (fu <= fw) || (w == x)
                v = w;
                w = u;
                fv = fw;
                fw = fu;
            elseif (fu <= fv) || (v == x) || (v == w)
                v = u;
                fv = fu;
            end
        else
            if (u >= x)
                a = x;
            else
                b = x;
            end

            v = w;
            w = x;
            x = u;
            fv = fw;
            fw = fx;
            fx = fu;
        end

        currentIter = currentIter + 1;
    end

    numIters = currentIter;
    x_min = x;
    f_min = fx;
end

% ---------------------------------------------------------------------------
% Copyright (C) 2025 MBF Bioscience
% 
% ScanImage (R) 2025 is software to be used under the purchased terms
% Code may be modified, but not redistributed without the permission
% of MBF Bioscience
% 
% MBF BIOSCIENCE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, WITH
% RESPECT TO THIS PRODUCT, AND EXPRESSLY DISCLAIMS ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
% IN NO CASE SHALL MBF BIOSCIENCE BE LIABLE TO ANYONE FOR ANY
% CONSEQUENTIAL OR INCIDENTAL DAMAGES, EXPRESS OR IMPLIED, OR UPON ANY OTHER
% BASIS OF LIABILITY WHATSOEVER, EVEN IF THE LOSS OR DAMAGE IS CAUSED BY
% MBF BIOSCIENCE'S OWN NEGLIGENCE OR FAULT.
% CONSEQUENTLY, MBF BIOSCIENCE SHALL HAVE NO LIABILITY FOR ANY
% PERSONAL INJURY, PROPERTY DAMAGE OR OTHER LOSS BASED ON THE USE OF THE
% PRODUCT IN COMBINATION WITH OR INTEGRATED INTO ANY OTHER INSTRUMENT OR
% DEVICE.  HOWEVER, IF MBF BIOSCIENCE IS HELD LIABLE, WHETHER
% DIRECTLY OR INDIRECTLY, FOR ANY LOSS OR DAMAGE ARISING, REGARDLESS OF CAUSE
% OR ORIGIN, MBF BIOSCIENCE MAXIMUM LIABILITY SHALL NOT IN ANY
% CASE EXCEED THE PURCHASE PRICE OF THE PRODUCT WHICH SHALL BE THE COMPLETE
% AND EXCLUSIVE REMEDY AGAINST MBF BIOSCIENCE.
% ---------------------------------------------------------------------------
