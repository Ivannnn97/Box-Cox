function [out] = FSRHeda(y,X,Z,bsb,varargin)
%FSRHeda enables to monitor several quantities in each step of the forward search
%
%<a href="matlab: docsearchFS('FSRHeda')">Link to the help function</a>
%
% Required input arguments:
%
%   y:          A vector with n elements that contains the response variables.
%               Missing values (NaN's) and infinite values (Inf's) are
%               allowed, since observations (rows) with missing or infinite
%               values will automatically be excluded from the
%               computations.
%   X :         Data matrix of explanatory variables (also called 'regressors')
%               of dimension (n x p-1). Rows of X represent observations, and
%               columns represent variables. Missing values (NaN's) and
%               infinite values (Inf's) are allowed, since observations
%               (rows) with missing or infinite values will automatically
%               be excluded from the computations.
%     Z :       Predictor variables in the regression equation. Matrix. 
%               n x r matrix or vector of length r.
%               If Z is a n x r matrix it contains the r variables which
%               form the scedastic function as follows (if input option art==1)
%               \[
%               \omega_i = 1 + exp(\gamma_0 + \gamma_1 Z(i,1) + ...+ \gamma_{r} Z(i,r))
%               \]
%               If Z is a vector of length r it contains the indexes of the
%               columns of matrix X which form the scedastic function as
%               follows
%               \[
%               \omega_i = 1 +  exp(\gamma_0 + \gamma_1 X(i,Z(1)) + ...+
%               \gamma_{r} X(i,Z(r)))
%               \]
%               Therefore, if for example the explanatory variables
%               responsible for heteroscedasticity are columns 3 and 5
%               of matrix X, it is possible to use both the sintax:
%                    FSRH(y,X,X(:,[3 5]))
%               or the sintax:
%                    FSRH(y,X,[3 5])
%   bsb :       list of units forming the initial
%               subset. Vector or scalar. If bsb=0 (default) then the procedure starts with p
%               units randomly chosen else if bsb is not 0 the search will
%               start with m0=length(bsb).
%
% Optional input arguments:
%
%   intercept : Indicator for constant term. Scalar.
%                     If 1, a model with constant term will be fitted (default),
%                     if 0, no constant term will be included.
%                       Example - 'intercept',1
%                       Data Types - double
%        init :      Search initialization. Scalar.
%                      It specifies the point where to initialize the search
%                       and start monitoring required diagnostics. if init is not
%                       specified it will be set equal to :
%                       p+1, if the sample size is smaller than 40;
%                       min(3*p+1,floor(0.5*(n+p+1))), otherwise.
%                       Example - 'init',100 starts monitoring from step m=100
%                       Data Types - double
%        tstat:      the kind of t-statistics which have to be monitored.
%                       Character.
%                       tstat = 'trad' implies  monitoring of traditional t
%                       statistics (out.Tgls). In this case the estimate of \sigma^2 at step m
%                       is based on s^2_m (notice that s^2_m<<\sigma^2 when m/n is
%                       small) tstat = 'resc' (default) implies monitoring of
%                       rescaled t statistics In this scale the estimate of
%                       \sigma^2 at step m is based on s^_m / var_truncnorm(m/n)
%                       where var_truncnorm(m/n) is the variance of the truncated
%                       normal distribution.
%                       Example - 'tstat','trad'
%                       Data Types - char
%      nocheck:  Check input arguments. Scalar.
%                       If nocheck is equal to 1 no check is performed on
%                       matrix y and matrix X. Notice that y and X are left
%                       unchanged. In other words the additional column of ones for
%                       the intercept is not added. As default nocheck=0. The
%                       controls on h, alpha and nsamp still remain
%                       Example - 'nocheck',1
%                       Data Types - double
%        conflev:  confidence levels to be used to compute confidence interval
%                       for the elements of $\beta$ and for $\sigma^2$. Vector.
%                       The default value of conflev is [0.95 0.99] that
%                       is 95% and 99% confidence intervals are computed.
%                       Example - 'conflev',[0.90 0.93] 
%                       Data Types - double
% gridsearch:   Algorithm to be used. Scalar.
%                       If gridsearch ==1 grid search will be used else the
%                       scoring algorith will be used.
%                       Example - 'gridsearch',0
%                       Data Types - double
%                       REMARK: the grid search has only been implemented when
%                       there is just one explantory variable which controls
%                       heteroskedasticity
%                       Example - 'gridsearch',1 
%                       Data Types - double
% modeltype:    Parametric function to be used in the skedastic equation.
%                       String.
%                       If modeltype is 'arc' (default) than the skedastic function is
%                       modelled as follows
%                       \[
%                       \sigma^2_i = \sigma^2 (1 + \exp(\gamma_0 + \gamma_1 Z(i,1) +
%                           \cdots + \gamma_{r} Z(i,r)))
%                       \]
%                        on the other hand, if modeltype is 'har' then traditional
%                       formulation due to Harvey is used as follows
%                       \[
%                       \sigma^2_i = \exp(\gamma_0 + \gamma_1 Z(i,1) + \cdots +
%                           \gamma_{r} Z(i,r)) =\sigma^2 (\exp(\gamma_1
%                           Z(i,1) + \cdots + \gamma_{r} Z(i,r))
%                       \]
%                       Example - 'modeltype','har' 
%                       Data Types - string
%  constr :         units which are forced to join the search in the last r steps. Vector.
%                       r x 1 vector. The default is constr=''.  No constraint is imposed
%                       Example - 'constr',[1 6 3]
%                       Data Types - double
% Remark:       The user should only give the input arguments that have to
%                       change their default value. The name of the input arguments
%                       needs to be followed by their value. The order of the input
%                       arguments is of no importance.
%
%                       Missing values (NaN's) and infinite values (Inf's) are allowed,
%                       since observations (rows) with missing or infinite values
%                       will automatically be excluded from the computations. y can
%                       be both a row of column vector.
%
% Output:
%
%         out:   structure which contains the following fields
%
%   out.RES=        n x (n-init+1) = matrix containing the monitoring of
%               scaled residuals
%               1st row = residual for first unit ......
%               nth row = residual for nth unit.
%   out.LEV=        (n+1) x (n-init+1) = matrix containing the monitoring of
%               leverage
%               1st row = leverage for first unit ......
%               nth row = leverage for nth unit.
%    out.BB=        n x (n-init+1) matrix containing the information about the units belonging
%               to the subset at each step of the forward search.
%               1st col = indexes of the units forming subset in the initial step
%               ...
%               last column = units forming subset in the final step (all units)
%   out.mdr=        n-init x 3 matrix which contains the monitoring of minimum
%               deletion residual or (m+1)ordered residual  at each step of
%               the forward search.
%               1st col = fwd search index (from init to n-1)
%               2nd col = minimum deletion residual
%               3rd col = (m+1)-ordered residual
%               Remark: these quantities are stored with sign, that is the
%               min deletion residual is stored with negative sign if
%               it corresponds to a negative residual
%   out.msr=        n-init+1 x 3 = matrix which contains the monitoring of
%               maximum studentized residual or m-th ordered residual
%               1st col = fwd search index (from init to n)
%               2nd col = maximum studentized residual
%               3rd col = (m)-ordered studentized residual
%   out.nor=        (n-init+1) x 4 matrix containing the monitoring of
%               normality test in each step of the forward search
%               1st col = fwd search index (from init to n)
%               2nd col = Asymmetry test
%               3rd col = Kurtosis test
%               4th col = Normality test
%  out.Bgls=        (n-init+1) x (p+1) matrix containing the monitoring of
%               estimated beta coefficients in each step of the forward search
%    out.S2=       (n-init+1) x 4 matrix containing the monitoring of S2 or R2
%               in each step of the forward search
%               1st col = fwd search index (from init to n)
%               2nd col = monitoring of S2
%               3rd col = monitoring of R2
%               4th col = monitoring of rescaled S2. In this case the
%               estimated of $\sigma^2$ at step m is divided by the
%               consistency factor (to make the estimate asymptotically
%               unbiased)
%   out.Coo=    (n-init+1) x 3 matrix containing the monitoring of Cook or
%               modified Cook distance in each step of the forward search
%               1st col = fwd search index (from init to n)
%               2nd col = monitoring of Cook distance
%               3rd col = monitoring of modified Cook distance
%  out.Tgls=    (n-init+1) x (p+1) matrix containing the monitoring of
%               estimated t-statistics (as specified in option input 'tstat'
%               in each step of the forward search
%   out.Un=        (n-init) x 11 Matrix which contains the unit(s)
%               included in the subset at each step of the fwd search
%               REMARK: in every step the new subset is compared with the
%               old subset. Un contains the unit(s) present in the new
%               subset but not in the old one Un(1,2) for example contains
%               the unit included in step init+1 Un(end,2) contains the
%               units included in the final step of the search
%  out.betaint = Confidence intervals for the elements of $\beta$.
%                 betaINT is a (n-init+1)-by-2*length(confint)-by-p 3D array.
%                 Each third dimension refers to an element of beta
%                 betaINT(:,:,1) is associated with first element of beta
%                 .....
%                 betaINT(:,:,p) is associated with last element of beta
%                 The first two columns contain the lower
%                 and upper confidence limits associated with conflev(1).
%                 Columns three and four contain the lower
%                 and upper confidence limits associated with conflev(2)
%                 ....
%                 The last two columns contain the lower
%                 and upper confidence limits associated with conflev(end)
%                 For example betaint(:,3:4,5) contain the lower and upper
%                 confidence limits for the fifth element of beta using
%                 confidence level specified in the second element of input
%                 option conflev.
%out.sigma2INT = confidence interval for $\sigma^2$.
%                1st col = fwd search index;
%                2nd col = lower confidence limit based on conflev(1);
%                3rd col = upper confidence limit based on conflev(1);
%                4th col = lower confidence limit based on conflev(2);
%                5th col = upper confidence limit based on conflev(2);
%                ... 
%                penultimate col = lower confidence limit based on conflev(end);
%                last col = upper confidence limit based on conflev(end);
%out.Hetero =  estimate of coefficients of scedastic equation
%                    1st col = fwd search index
%                    2nd col = estimate of first coeff of scedastic equation
%                     ...
%                   (r+1) col = estimate of last coeff of scedastic
%                   equation.
%out.WEI =   Matrix which contains in each column the estimate of the
%                   weights.
%     out.y=     A vector with n elements that contains the response
%               variable which has been used
%     out.X=    Data matrix of explanatory variables
%               which has been used (it also contains the column of ones if
%               input option intercept was missing or equal to 1)
%  out.class =  string FSRHeda.
%
%
% See also FSRH.m, FSRHmdr.m, FSReda
%
% References:
%
%   Atkinson and Riani (2000), Robust Diagnostic Regression Analysis,
%   Springer Verlag, New York.
%
%
% Copyright 2008-2015.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('FSRHeda')">Link to the help function</a>
% Last modified 06-Feb-2015

% Examples:

%{
    % FSRHeda with all default options.
    % Example of use of FSRHeda based on a starting point coming
    % from LMS.
    n=200;
    p=1;
    randn('state', 123456);
    X=randn(n,p);
    % Uncontaminated data
    y=randn(n,1);
    % Contaminated data
    ycont=y;
    ycont(1:5)=ycont(1:5)+6;
    [out]=LXS(y,X,'nsamp',1000);
    out=FSRHeda(y,X,log(X),out.bs);
%}

%{
    % FSRHeda with optional argument.
    % Example of use of function FSRHeda using a random start and traditional
    % t-stat monitoring.
    out=FSRHeda(y,X,log(log(X)),0,'tstat','trad');
%}

%{
    %Examples with real data: wool data.
    xx=load('wool.txt');
    X=xx(:,1:3);
    y=log(xx(:,4));
    [out]=LXS(y,X,'nsamp',0);
    [out]=FSRHeda(y,X,log(X),out.bs,'tstat','scal');
%}

%{
    %% Example with artificial dataset.
    n=100;
    p=8;
    state=1;
    randn('state', state);
    X=randn(n,p);
    y=randn(n,1);
    y(1:10)=y(1:10)+5;
    % Run the forward search with Exploratory Data Analysis purposes
    % LMS using 10000 subsamples
    [outLXS]=LXS(y,X,'nsamp',10000);
    % Forward Search
    [out]=FSRHeda(y,X,log(X),outLXS.bs);
    %The monitoring residuals plot shows a set of positive residuals which
    %starting from the central part of the search tend to have a residual much
    %larger than that of the other units.
    resfwdplot(out);
    %The minimum deletion residual from m=90 starts going above the 99% threshold.
    mdrplot(out);
    %The curve which monitors the normality test shows a sudden big increase with the outliers are included
    figure;
    lwdenv=2;
    xlimx=[10 100];
    subplot(2,2,1);
    plot(out.nor(:,1),out.nor(:,2));
    title('Asimmetry test');
    xlim(xlimx);
    quant=chi2inv(0.99,1);
    v=axis;
    line([v(1),v(2)],[quant,quant],'color','r','LineWidth',lwdenv);
    subplot(2,2,2)
    plot(out.nor(:,1),out.nor(:,3))
    title('Kurtosis test');
    xlim(xlimx);
    v=axis;
    line([v(1),v(2)],[quant,quant],'color','r','LineWidth',lwdenv);
    subplot(2,2,3:4)
    plot(out.nor(:,1),out.nor(:,4));
    xlim(xlimx);
    quant=chi2inv(0.99,2);
    v=axis;
    line([v(1),v(2)],[quant,quant],'color','r','LineWidth',lwdenv);
    title('Normality test');
    xlabel('Subset size m');
%}

%{
    %% Monitoring of 95 per cent and 99 per cent confidence intervals of
    % beta and sigma2.
    % House price data 
    load hprice.txt;
    n=size(hprice,1);
    y=hprice(:,1);
    X=hprice(:,2:5);
    out=FSR(y,X,'plots',0,'msg',0);
    dout=n-length(out.ListOut);
    % init = point to start monitoring diagnostics along the FS
    init=20;
    [outLXS]=LXS(y,X,'nsamp',10000);
    outEDA=FSRHeda(y,X,log(X),outLXS.bs,'conflev',[0.95 0.99],'init',init);
    p=size(X,2)+1;
    % Set font size, line width and line style
    figure;
    lwd=2.5;
    FontSize=14;
    linst={'-','--',':','-.','--',':'};
    nr=3;
    nc=2;
    xlimL=init; % lower value fo xlim
    xlimU=n+1;  % upper value of xlim
    close all
    for j=1:p
        subplot(nr,nc,j);
        hold('on')
        % plot 95% and 99% HPD  trajectories
        plot(outEDA.Bgls(:,1),outEDA.betaINT(:,1:2,j),'LineStyle',linst{4},'LineWidth',lwd,'Color','b')
        plot(outEDA.Bgls(:,1),outEDA.betaINT(:,3:4,j),'LineStyle',linst{4},'LineWidth',lwd,'Color','r')

        % plot estimate of beta1_j
        plot(outEDA.Bgls(:,1),outEDA.Bgls(:,j+1)','LineStyle',linst{1},'LineWidth',lwd,'Color','k')


        % Set ylim
        ylimU=max(outEDA.betaINT(:,4,j));
        ylimL=min(outEDA.betaINT(:,3,j));
        ylim([ylimL ylimU])

        % Set xlim
        xlim([xlimL xlimU]);

        % Add vertical line in correspondence of the step prior to the
        % entry of the first outlier
        line([dout; dout],[ylimL; ylimU],'Color','r','LineWidth',lwd);

        ylabel(['$\hat{\beta_' num2str(j-1) '}$'],'Interpreter','LaTeX','FontSize',20,'rot',-360);
        set(gca,'FontSize',FontSize);
        if j>(nr-1)*nc
            xlabel('Subset size m','FontSize',FontSize);
        end
    end

    % Subplot associated with the monitoring of sigma^2
    subplot(nr,nc,6);
    hold('on')
    % 99%
    plot(outEDA.sigma2INT(:,1),outEDA.sigma2INT(:,4:5),'LineStyle',linst{4},'LineWidth',lwd,'Color','r')
    % 95%
    plot(outEDA.sigma2INT(:,1),outEDA.sigma2INT(:,2:3),'LineStyle',linst{2},'LineWidth',lwd,'Color','b')
    % Plot rescaled S2
    plot(outEDA.S2(:,1),outEDA.S2(:,4),'LineWidth',lwd,'Color','k')
    ylabel('$\hat{\sigma}^2$','Interpreter','LaTeX','FontSize',20,'rot',-360);
    set(gca,'FontSize',FontSize);

    % Set ylim
    ylimU=max(outEDA.sigma2INT(:,5));
    ylimL=min(outEDA.sigma2INT(:,4));
    ylim([ylimL ylimU])
    % Set xlim
    xlim([xlimL xlimU]);

    % Add vertical line in correspondence of the step prior to the
    % entry of the first outlier
    line([dout; dout],[ylimL; ylimU],'Color','r','LineWidth',lwd);
    xlabel('Subset size m','FontSize',FontSize);

    % Add multiple title
    suplabel(['Housing data; confidence intervals of the parameters monitored in the interval ['...
        num2str(xlimL) ',' num2str(xlimU) ...
        ']'],'t');
    disp(['The vertical lines are located in the' ...
        ' step prior to the inclusion of the first outlier'])
%}

%% Input parameters checking
%this example is run as a demonstration in case the user runs FSRHeda
%without input parameters.
if nargin < 1
    stack_loss = load('stack_loss.txt');
    y = stack_loss(:,4);
    X = stack_loss(:,1);
    Z = stack_loss(:,1);
    % LMS using all subsets
    [out] = LXS(y,X,'nsamp',0);
    % Forward search with EDA purposes
    [out1] = FSRHeda(y,X,Z,out.bs,'init',5);
    % Create scaled squared residuals
    out1.RES = out1.RES.^2;
    % Specify the characteristics of the highlighted trajectories
    fground=struct;
    fground.LineStyle={'-';'--';':';'-.'};
    fground.LineWidth=3;
    fground.Color={'r'};
    % Plot of monitoring of scaled squared residuals
    resfwdplot(out1,'fground',fground)
    title('Monitoring squared scaled residuals for Stack loss dataset')
    noargmsg = sprintf(['To use FSRHeda with your own data y (response vector) and X (design matrix), type:\n\n' ...
        '    [out]=LXS(y,X) \n' ...
        '    [out]=FSRHeda(y,X,out.bs)\n' ...
        '    resfwdplot(out) \n\n' ...
        'Type "help FSRHeda" for more information\n\n' ...
        'Click OK to view the monitoring residual plot for the stack loss data.']);
    titl = 'Example of the use of the Forward search with EDA purposes';
    [cdata, colormap] = imread('logo.png','BackgroundColor',(240/255)*[1 1 1]);
    msgbox(noargmsg,titl,'custom',cdata,colormap,'modal');
    return
end

nnargin = nargin;
vvarargin = varargin;
[y,X,n,p] = chkinputR(y,X,nnargin,vvarargin);

%% User options
if n < 40
    init = p+1;
else
    init = min(3*p+1,floor(0.5*(n+p+1)));
end

conflevdef = [0.95 0.99];
options = struct('intercept',1,'init',init,'tstat','scal',...
    'nocheck',0,'conflev',conflevdef,'gridsearch',0,'modeltype','art', 'constr', '');

UserOptions = varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
        error('FSDA:FSRHeda:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
    end
    % Check if user options are valid options
    chkoptions(options,UserOptions)
end
constr = options.constr;
if nargin > 3
    % We now overwrite inside structure options the default values with
    % those chosen by the user
    % Notice that in order to do this we use dynamic field names
    for i = 1:2:length(varargin);
        options.(varargin{i}) = varargin{i+1};
    end
end

if bsb == 0
    Ra = 1; nwhile = 0;
    while and(Ra,nwhile<100)
        bsb = randsample(n,p);
        Xb = X(bsb,:);
        Zb = Z(bsb,:);
        Ra =~ (rank(Xb)==p);
        nwhile = nwhile+1;
    end
    if nwhile == 100
        warning('FSDA:FSRHeda:NoFullRank','Unable to randomly sample full rank matrix');
    end
    yb = y(bsb);
else
    Xb = X(bsb,:);
    Zb = Z(bsb,:);
    yb = y(bsb);
end

ini0 = length(bsb);

% check init
init = options.init;
if  init < p;
    mess = sprintf(['Attention : init should be larger than p+1. \n',...
        'It is set to p.']);
    disp(mess);
    init = p;
elseif init < ini0;
    mess = sprintf(['Attention : init should be >= length of supplied subset. \n',...
        'It is set equal to ' num2str(length(bsb)) ]);
    disp(mess);
    init = ini0;
elseif init >= n;
    mess = sprintf(['Attention : init should be smaller than n. \n',...
        'It is set to n-1.']);
    disp(mess);
    init = n-1;
end

%% Declare matrices to store quantities

% sequence from 1 to n
seq = (1:n)';

% complementary of bsb
%ncl = setdiff(seq,bsb);

% The second column of matrix R will contain the OLS residuals
% at each step of the forward search
r = [seq zeros(n,1)];

% If n is very large, the step of the search is printed every 100 step
% seq100 is linked to printing
seq100 = 100*(1:1:ceil(n/100));

zer = NaN(n-init,2);
zer1 = NaN(n-init+1,2);

% Matrix Bgls will contain the beta coeff. in each step of the fwd search
% The first row will contain the units forming initial subset
Bgls = [(init:n)' NaN(n-init+1,p)];

% Vector of the beta coefficients from the last correctly calculated step
% Used in case the rank of Xb is less than p
blast = NaN(p,1);

% S2=(n-init+1) x 3  matrix which will contain
% 1st col = fwd search index
% 2nd col = S2= \sum e_i^2 / (m-p)
% 3rd col = R^2
% 4th col = (\sum e_i^2 / (m-p)) / (consistency factor) to make the
% estimate asymptotically unbiased
S2 = [(init:n)' NaN(n-init+1,3);];

% mdr= (n-init) x 3 matrix
% 1st column = fwd search index
% 2nd col min deletion residual among observerations non belonging to the
% subset
% 3rd column (m+1)-th ordered residual
% They are stored with sign, that is the min deletion residual
% is stored with negative sign if it corresponds to a negative residual
mdr = [(init:n-1)'  zer];

% mdr= (n-init+1) x 3 matrix which will contain max studentized residual
%  among bsb and m-th studentized residual
msr = [(init:n)'  zer1];

% coo= (n-init) x 3 matrix which will contain Cook distances
%  (2nd col) and modified Cook distance (3rd col)
coo = [((init+1):n)'  NaN(n-init,6)];

% nor= (n-init+1) x 3 matrix which will contain asymmetry (2nd col)
% kurtosis (3rd col) and normality test (4th col)
nor = [(init:n)'  zer1];

% Matrix RES will contain the resisuals for each unit in each step of the forward search
% The first row refers to the residuals of the first unit
RES = NaN(n,n-init+1);
RES(:) = NaN;

% Matrix BB will contain the units forming subset in each step of the forward search
% The first column contains the units forming subset at step init
% The first row is associated with the first unit
BB = RES;

% Matrix LEV will contain the leverage of the units forming subset in each step of the forward search
% The first column contains the leverage associated with the units forming subset at step init
% The first row is associated with the first unit
LEV = RES;

%  Un= Matrix whose 2nd column:11th col contain the unit(s) just included
Un = NaN(n-init,10);
Un = [(init+1:n)' Un];

%  Tgls = Matrix whose columns contain t statistics specified in option
%  tstat
Tgls = Bgls;

% Matrix which contains in each column the estimate of the weights
WEI = NaN(n,n-init+1);

% Hetero = (n-init1+1) x (r+1) matrix which will contain:
% 1st col = fwd search index
% 2nd col = estimate of first coeff of scedastic equation
%...
% (r+1) col = estimate of last coeff of scedastic equation
Hetero = [(init:n)' NaN(n-init+1,size(Z,2)+1)];

% vector conflev
conflev = options.conflev;
conflev = 1-(1-conflev)/2;
lconflev = length(conflev);

% betaINT will contain the confidence intervals for the elements of $\beta$
% betaINT is a (n-init+1)-by-2*length(confint)-by-p 3D array.
% Each third dimension refers to an element of beta
% betaINT(:,:,1) is associated with first element of beta
% .....
% betaINT(:,:,p) is associated with last element of beta
% The first two columns contain the lower
% and upper confidence limits associated with conflev(1).
% Columns three and four contain the lower
% and upper confidence limits associated with conflev(2)
% ....
% The last two columns contain the lower
% and upper confidence limits associated with conflev(end)
betaINT = NaN(n-init+1,2*lconflev,p);
% sigma2INT confidence interval for $\sigma^2$
sigma2INT = [(init:n)' zeros(n-init+1,2*lconflev)];


% Z = n-by-r matrix which contains the explanatory variables for
% heteroskedasticity
if size(Z,1) ~= n
    % Check if interecept was true
    if options.intercept == 1
        Z = X(:,Z+1);
    else
        Z = X(:,Z);
    end
end

gridsearch = options.gridsearch;
if gridsearch == 1 && size(Z,2) > 1
    warning('FSDA:FSRHmdr:WrongInputOpts','To perform a grid search you cannot have more than one varaible responsible for heteroskedasticity');
    warning('FSDA:FSRHmdr:WrongInputOpts','Scoring algorith is used');
    gridsearch = 0;
end

modeltype = options.modeltype;

if strcmp(modeltype,'art') == 1
    art = 1;
else
    art = 0;
end

hhh = 1;
%% Start of the forward search
if (rank(Xb) ~= p)
    warning('FSDA:FSRHeda:NoFullRank','The provided initial subset does not form full rank matrix');
    % FS loop will not be performed
else
    for mm = ini0:n;
        
        % if n>200 show every 100 steps the fwd search index
        if n > 200;
            if length(intersect(mm,seq100)) == 1;
                disp(['m=' int2str(mm)]);
            end
        end
        
        NoRankProblem = (rank(Xb) == p);
        if NoRankProblem  % rank is ok
           if art == 1
                if  mm > 5  && gridsearch ~=1
                    % Use scoring
                    HET = regressHart(yb,Xb(:,2:end),Zb,'intercept',options.intercept);
                else
                    if size(Zb,2) == 1
                        % Use grid search algorithm if Z has just one column
                        HET = regressHart_grid(yb,Xb(:,end),exp(Zb),'intercept',options.intercept);
                    else
                        HET = regressHart(yb,Xb(:,2:end),Zb,'intercept',options.intercept);
                    end
                end
                
                % gam=HET.GammaOLD;
                % alp=HET.alphaOLD;
                % omegahat=1+real(X(:,end).^alp)*gam;%equaz 6 di paper
                
                omegahat = 1+exp(HET.Gamma(1,1))*exp(Z*HET.Gamma(2:end,1));
            else
                if  mm > 5  && gridsearch ~= 1
                    % Use scoring
                    HET = regressHhar(yb,Xb(:,2:end),Zb,'intercept',intercept);
                else
                    if size(Zb,2) == 1
                        % Use grid search algorithm if Z has just one column
                        HET = regressHhar_grid(yb,Xb(:,end),exp(Zb),'intercept',intercept);
                    else
                        HET = regressHhar(yb,Xb(:,2:end),Zb,'intercept',intercept);
                    end
                end
                omegahat = exp(Z*HET.Gamma(2:end,1));
            end
            
            sqweights = omegahat.^(-0.5);
            
            % Xw and yw are referred to all the observations
            % They contains transformed values of X and y using estimates
            % at step m
            % Xw = [X(:,1) .* sqweights X(:,2) .* sqweights ... X(:,end) .* sqweights]
            Xw = bsxfun(@times, X, sqweights);
            if (mm >= init);
                % Store weights
                WEI(:,mm-init+1) = sqweights;
            end
            yw = y .* sqweights;
            Xb = Xw(bsb,:);
            yb = yw(bsb);
            % The instruction below should not be necessary
            % Zb=Z(bsb,:);
            
            % b=Xb\yb;   % HHH
            b = HET.Beta(:,1);
            resBSB = yb-Xb*b;
            blast = b; 
            %{
            b=Xb\yb;
            resBSB=yb-Xb*b;
            blast=b;   % Store correctly computed b for the case of rank problem
            %}
        else   % number of independent columns is smaller than number of parameters
            warning('FSDA:FSRHeda','Rank problem in step %d: Beta coefficients are used from the most recent correctly computed step',mm);
            b = blast;
        end
        
        if hhh == 1
            e = yw-Xw*b;  % e = vector of residual for all units using b estimated using subset
        else
            e = y-X*b;  % e = vector of residual for all units using b estimated using subset
        end
        
        if (mm >= init);
            
            % Store Units belonging to the subset
            BB(bsb,mm-init+1) = bsb;
            
            if NoRankProblem
                
                % Store beta coefficients if there is no rank problem
                Bgls(mm-init+1,2:p+1) = b';
                % Store parameters of the scedastic equation
                Hetero(mm-init+1,2:end) = HET.Gamma(:,1)';
                
                % Compute and store estimate of sigma^2
                % using y and X transformed
                Sb = (resBSB)'*(resBSB)/(mm-p);
                S2(mm-init+1,2) = Sb;
                % Store R2
                S2(mm-init+1,3) = 1-var(resBSB)/var(yb);

                % Store beta coefficients
                Bgls(mm-init+1,2:p+1) = b';
                
                % Measure of asymmetry
                sqb1 = (sum(resBSB.^3)/mm) / (sum(resBSB.^2)/mm)^(3/2);
                
                % Measure of Kurtosis  */
                b2 = (sum(resBSB.^4)/mm) / (sum(resBSB.^2)/mm)^2;
                
                % Asymmetry test
                nor(mm-init+1,2) = (mm/6)*  sqb1  ^2  ;
                
                % Kurtosis test
                nor(mm-init+1,3) = (mm/24)*((b2 -3)^2);
                
                % Normality test
                nor(mm-init+1,4) = nor(mm-init+1,2)+nor(mm-init+1,3);
                
                % Store leverage for the units belonging to subset
                % hi contains leverage for all units
                % It is a proper leverage for the units belonging to susbet
                % It is a pseudo leverage for the unit not belonging to the subset
                mAm = Xb'*Xb;
                
                mmX = inv(mAm);
                dmmX = diag(mmX);
                
                % Notice that we could replace the lowwing line with
                % hi=sum((X/mAm).*X,2); but there is no gain since we need
                % to compute dmmX=diag(mmX);
                hi = sum((Xw*mmX).*Xw,2); %#ok<MINV>
                LEV(bsb,mm-init+1) = hi(bsb);
                % Take units not belonging to bsb
%                 if hhh == 1
%                     Xncl = Xw(ncl, :);
%                 else
%                     Xncl = X(ncl,:); % HHH
%                 end          
            end % no rank problem
        end
        
        if (mm>p)
            
            % store res. sum of squares/(mm-k)
            % Store estimate of \sigma^2 using units forming subset
            if NoRankProblem
                Sb = (resBSB)'*(resBSB)/(mm-p);
            end
            
        else
            Sb = 0;
        end
        
        % e= vector of residual for all units using b estimated using subset
        %e=y-X*b;
        
        if (mm >= init)
            % Store all residuals
            RES(:,mm-init+1) = e;
            
            if NoRankProblem
                % Store S2 for the units belonging to subset
                S2(mm-init+1,2) = Sb;
                
                % Store rescaled version of S2 in the fourth column
                % Compute the variance of the truncated normal distribution
                if mm < n
                    a = norminv(0.5*(1+mm/n));
                    corr = 1-2*(n./mm).*a.*normpdf(a);
                else
                    corr = 1;
                end
                Sbrescaled = Sb/corr;
                S2(mm-init+1,4) = Sbrescaled;
                
                % Store maximum studentized residual
                % among the units belonging to the subset
                msrsel = sort(abs(resBSB)./sqrt(Sb*(1-hi(bsb))));
                msr(mm-init+1,2) = msrsel(mm);
                
                % Store R2
                S2(mm-init+1,3) = 1-var(resBSB)/var(yb);
            end
            
        end
        
        r(:,2) = e.^2;
        
        if mm > init;
            
            if NoRankProblem
                
                % Store in the second column of matrix coo the Cook
                % distance
                bib = Bgls(mm-init+1,2:p+1)-Bgls(mm-init,2:p+1);
                if S2(mm-init+1,2) > 0;
                    coo(mm-init,2) = bib*mAm*(bib')/(p*S2(mm-init+1,2));
                end
                
                if length(unit) > 5;
                    unit = unit(1:5);
                end
                if S2(mm-init,2) > 0;
                    coo(mm-init,3:length(unit)+2) = 1./(1-hi(unit)).* sqrt(((mm-p)/p)*hi(unit).*r(unit,2)./S2(mm-init,2));
                end
            end % NoRankProblem
        end
        
        if mm < n;
            if mm >= init;
                if NoRankProblem
                    % ord = matrix whose first col (divided by S2(i)) contains the deletion residuals
                    % for all units. For the units belonging to the subset these are proper deletion residuals
                     if hhh == 1
                        ord = [(r(:,2)./(1+hi)) e];
                    else
                        ord = [(r(:,2)./(omegahat+hi)) e];
                    end
                    
                    % Store minimum deletion residual in 2nd col of matrix mdr
                     selmdr = sortrows(ord,1);
                    if S2(mm-init+1,2) == 0
                        warning('FSDA:FSRHmdr:ZeroS2','Value of S2 at step %d is zero, mdr is NaN',mm-init+1);
                    else
                        %mdr(mm-init+1,2)=sqrt(selmdr(1,1)/HET.sigma2);
                        mdr(mm-init+1,2) = sign(selmdr(1,2))*sqrt(selmdr(1,1)/S2(mm-init+1,2));
                    end
       
                    % Store (m+1) ordered pseudodeletion residual in 3rd col of matrix
                    % mdr
                    selmdr = sortrows(ord,1);
                    mdr(mm-init+1,3) = sign(selmdr(mm+1,2))*sqrt(selmdr(mm+1,1)/S2(mm-init+1,2));
                end % NoRankProblem
            end
            
            % store units forming old subset in vector oldbsb
            oldbsb = bsb;
            
            if ~isempty(options.constr) && mm < n-length(options.constr)
                r(constr,2) = Inf;
            end
            % order the r_i and include the smallest among the units
            %  forming the group of potential outliers
            ord = sortrows(r,2);
            
            % bsb= units forming the new  subset
            bsb = ord(1:(mm+1),1);
            
            Xb = X(bsb,:);  % subset of X
            yb = y(bsb);    % subset of y
            Zb = Z(bsb,:);  % subset of Z
            
            if mm >= init;
                unit = setdiff(bsb,oldbsb);
                if length(unit) <= 10
                    Un(mm-init+1,2:(length(unit)+1)) = unit;
                else
                    disp(['Warning: interchange greater than 10 when m=' int2str(mm)]);
                    Un(mm-init+1,2:end) = unit(1:10);
                end
            end
            
            
            if mm < n-1;
                
                % ncl= units forming the new noclean
                %ncl = ord(mm+2:n,1);
                
            end
        end
        
        if mm >= init;
            if NoRankProblem
                if strcmp(options.tstat,'scal')
                    
                 Tgls(mm-init+1,2:end) = sqrt(corr)*Bgls(mm-init+1,2:end)./sqrt(Sb*dmmX');
                    
                elseif strcmp(options.tstat,'trad')
                    Tgls(mm-init+1,2:end) = Bgls(mm-init+1,2:end)./sqrt(Sb*dmmX');
                end
                
                
                
                % Compute highest posterior density interval for each value of
                % Tinvcdf = required quantiles of T distribution
                % consider just upper quantiles due to simmetry
                Tinvcdf = tinv(conflev,mm-p);
                % IGinvcdf = required quantiles of Inverse Gamma distribution
                Chi2invcdf = chi2inv([conflev 1-conflev],mm-p);
                
                c = sqrt(Sbrescaled*dmmX);
                for j = 1:lconflev
                    betaINT(mm-init+1,j*2-1:j*2,:) = [ b-Tinvcdf(j)*c  b+Tinvcdf(j)*c]';
                    sigma2INT(mm-init+1,(j*2):(j*2+1)) = [Sbrescaled*(mm-p)/Chi2invcdf(j) Sbrescaled*(mm-p)/Chi2invcdf(j+lconflev)];
                end
                
            end % NoRankProblem
        end
    end
end   %Rank check

%% Structure returned by function FSRHeda
out                    = struct;
out.RES           =RES/sqrt(S2(end,2));
out.LEV           =LEV;
out.BB             =BB;
out.mdr            =mdr;
out.msr            =msr;
out.nor             =nor;
out.Bgls           =Bgls;
out.S2              =S2;
out.coo            =coo;
out.Tgls           =Tgls;
out.Un              =Un;
out.betaINT     =betaINT;
out.sigma2INT=sigma2INT;
out.y                 =y;
out.X                =X;
out.Z                =Z;
out.Hetero       = Hetero;
out.WEI           = WEI;
out.class          ='FSRHeda';
end
