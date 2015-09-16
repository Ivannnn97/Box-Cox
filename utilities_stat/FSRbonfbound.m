function Bbound = FSRbonfbound(n,p,varargin)
%FSRbonfbound computes Bonferroni bounds for each step of the search (in linear regression)
%
%<a href="matlab: docsearchFS('fsrbonfbound')">Link to the help function</a>
%
%  Required input arguments:
%
%    n : scalar, number of obseravtions
%    p : number of explanatory variables (including the intercept if present)
%
%  Optional input arguments:
%
%       init:   scalar which specifies the initial subset size to monitor
%               minimum deletion residual, if init is not specified it will
%               be set equal to floor(0.5*(n+p+1))+1
%  prob:         1 x k vector containing quantiles for which envelopes have
%               to be computed. The default is to produce 1%, 50% and 99%
%               envelopes.
%
%  Output:
%
%  Bbound:      matrix with n-m0+1 rows and length(prob)+1 columns
%               1st col = fwd search index from m0 to n-1
%               2nd col = bound for quantile prob[1]
%               3rd col = bound for quantile prob[2]
%               ...
%               (k+1) col = bound for quantile prob[k]
%
% Subfunctions: 
%
% Other function dependencies: none.
%
% See also FSRenvmdr
%
% References:
%
%   Atkinson, A.C. and Riani, M. (2006). Distribution theory and
%   simulations for tests of outliers in regression. Journal of
%   Computational and Graphical Statistics, Vol. 15, pp. 460�476 
%   Riani, M. and Atkinson, A.C. (2007). Fast calibrations of the forward
%   search for testing multiple outliers in regression, Advances in Data
%   Analysis and Classification, Vol. 1, pp. 123�141.
%
% Copyright 2008-2015
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('FSRbonfbound')">Link to the help function</a>
% Last modified 06-Feb-2015

% Examples:

%{
% Example of creation of 1% 50% and 99% envelopes based on 1000
% observations and 5 explanatory variables using exact method
  MDRenv = FSRenvmdr(1000,5,'exact',1,'init',10,'prob',[0.01 0.5 0.99 0.999]);
  Bbound = FSRbonfbound(1000,5,'init',10,'prob',[0.01 0.5 0.99 0.999]);
  plot(MDRenv(:,1),MDRenv(:,2:5),Bbound(:,1),Bbound(:,2:5));
%}

%% Input parameters checks

if ~isscalar(n) || isempty(n) || isnan(n)
    error('FSDA:FSRbonfbound:Wrongn','n must be scalar non empty and non missing!!');
end

if ~isscalar(p) || isempty(n) || isnan(p)
    error('FSDA:FSRbonfbound:Wrongp','p must be scalar non empty and non missing!!!');
end


% The default starting point to monitor mdr is equal to the integer part of
% floor(0.5*(n+p+1))
inisearch=floor(0.5*(n+p+1))+1;

% Notice that prob must be a row vector
prob=[0.01 0.5 0.99];
options=struct('init',inisearch,'prob',prob);

if nargin>2
    for i=1:2:length(varargin);
        options.(varargin{i})=varargin{i+1};
    end
end
m0=options.init;
prob=options.prob;

% Check that the specified starting point is not greater than n-1
if m0>n-1
    error(['Initial starting point of the search (m0=' num2str(m0) ') is greater than n-1(n-1=' num2str(n-1) ')']);
end

%% Bonferroni bound generation

% Make sure that prob is a row vector.
if size(prob,1)>1;
    prob=prob';
end

% m = column vector which contains fwd search index.
m =(m0:n-1)';

% mm = fwd search index replicated lp times.
lp = length(prob);
mm = repmat(m,1,lp);
probm = repmat(prob,length(m),1);

MinBonf = abs(tinv((1-probm)./(mm+1), mm-p));

Bbound = [m MinBonf];

end

