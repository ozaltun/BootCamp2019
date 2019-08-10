% This is the main setup file.
% It generates all random draws, reads in the data, etc.

% Set seeds
rand_seed                        = 6 ;
randn_seed                       = 500;    
rand('twister',rand_seed) % This affects the data generating draws
randn('state',randn_seed)

% Set Country ID

chn_ctr_ind                      = 59;                      %NEW 
ger_ctr_ind                      = 28;
can_ctr_ind                      = 2;
gbr_ctr_ind                      = 22;
mex_ctr_ind                      = 3;
twn_ctr_ind                      = 62;
ita_ctr_ind                      = 39;
jpn_ctr_ind                      = 63;
fra_ctr_ind                      = 27;
kor_ctr_ind                      = 60;


% Read in data

country_data                     = importdata('emp2_data_for_matlab_v3.out',',',1);
add_data                         = importdata('additional_param_and_mom.out',',',1);         

m.fe_est                         = country_data.data(:,1);
m.num_firms_by_country_data      = country_data.data(:,2);
m.agg_imports_data               = country_data.data(:,3) * 10;
m.distw                          = country_data.data(:,4) ;  % in 1000km
m.contig                         = country_data.data(:,5);
m.comlang_off                    = country_data.data(:,6);
m.control_corr                   = country_data.data(:,7);
m.gdp                            = country_data.data(:,8);
m.rule_of_law                    = country_data.data(:,9);
m.rpshare                        = country_data.data(:,10);
m.export_cost                    = country_data.data(:,11);
m.int_server                     = country_data.data(:,12);

m.US_median_dom_input            = 567.5603 ./ 1000;  % in million USD

m.agg_china_import_share_percent_increase_data  =  ((0.1366 / .0492) - 1) * 100;  % 2007 share of imports over 1997 share of imports 


% More parameters and moments

m.N                              = size(m.contig,1);
m.num_importing_firms_data       = add_data.data(4);                 
m.num_all_firms_data             = add_data.data(3);                 

m.share_importers_sales0_25      = 0.058;
m.share_importers_sales25_50     = 0.112;
m.share_importers_sales50_75     = 0.245;
m.share_importers_sales75_100    = 0.620;


% Order of countries by census country code (USA comes first!)


m.theta                          = abs(add_data.data(2));            % The regression coefficient is negative (but the parameter is positive) 
m.sigma                          = add_data.data(1);                 
m.kappa                          = 3;
m.sigma_tilde                    = (1/m.sigma) * (m.sigma / (m.sigma-1)).^(1-m.sigma);
m.exp_fe_est                     = exp(m.fe_est);                     % Sourcing potential
[temps, tempi]                  = sort(m.exp_fe_est(2:end),'descend');   
rank_sourcing_potential(tempi)  = 1:1:m.N-1;

% Initial guess
fc_mean_guess                    = [.1 ; 0.5; .9 ; .1];
B_guess                          = .05;
fc_disp_guess                    = 1;
beta_guess                       = [B_guess  ; fc_mean_guess ; fc_disp_guess];

m.beta_names                      = {'B';'fcconstant';'fcdist';'fclang';'fccoc';'fcdisp'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Simulate firms
% Draw shocks

% Draw productivity levels, using stratified random sampling
bounds_intervals = [0,.2,.35,.45,.57,.7,.8,.9,.95,.98,.99,.999,1];  % we oversample more productive firms
%bounds_intervals = [0,.6,.8,.9,.95,.98,.99,.999,1];

length_intervals = bounds_intervals(2:end) - bounds_intervals(1:end-1);
num_draws_per_stratum = 10;

for k =1:size(length_intervals,2);
m.prod_draw_uniform((k-1)*num_draws_per_stratum+1:k*num_draws_per_stratum,1) = bounds_intervals(k) + rand(num_draws_per_stratum,1)*length_intervals(k);
m.weights_prod((k-1)*num_draws_per_stratum+1:k*num_draws_per_stratum,1) = length_intervals(k) ./ num_draws_per_stratum ;
end

% Fixed cost draws. We use a van der Corput sequence. 
%PF_sobol          = sobolset(1);
S_fixed           = 18000;                                          % number of fixed costs draws (later interacted with the productivity draws)
%PF_sobol          = scramble(PF_sobol,'MatousekAffineOwen');
%sobol_points      = net(PF_sobol,S_fixed);  

corput_sequence       = corput(S_fixed);
m.fc_shock_randn      = zeros(S_fixed,m.N);
for dimen = 1:m.N
    m.fc_shock_randn(:,dimen) = norminv(corput_sequence(randperm(S_fixed)),0,1);
end

m.fc_shock_randn   = repmat(m.fc_shock_randn,num_draws_per_stratum*size(length_intervals,2),1);

m.prod_draw_uniform = kron(m.prod_draw_uniform,ones(S_fixed,1));
m.weights_prod      = kron(m.weights_prod ,ones(S_fixed,1)) ./ S_fixed ;
m.S                 = size(m.weights_prod,1);            % number of simulated firms (productivity draw x fixed cost draw


% In case the Jia algorithm would stall so early that there are an
% infeasible number of sourcing strategies yet to be evaluated, firms may
% just evaluate a subset of them. However, in practice, this is never used,
% as we can always accurately solve the problem of the firm.
m.num_rand_checks                 = 100;
m.rand_check_matrix               = rand(m.num_rand_checks,m.N);



%% GMM options

opts = optimset('fminsearch');
opts.Display = 'iter';
opts.MaxFunEvals = 5000;
opts.MaxIter=2000;
opts.TolX = 1e-006;
opts.TolFun = 1e-006;

%%% Parameter: bk, dkw, dkk, dks; bw, dwk,dww,dws; rho; bs, dsk,dsw,dss
lb    = 1e-006* ones(size(beta_guess));
%lb(2) = 1.0001;  % kappa
ub = 10 * ones(size(beta_guess));
ub(6) = 6;       % Upper bound for the dispersion parameter of the the fixed cost distribution

MSRUN = 10;     % Number of Multistarts
beta_guess_all(1,1:length(beta_guess)) = beta_guess';
Guess_LB = [0.1  ;0.001 ; 0.1 ; .3 ; .05 ; .5  ];
Guess_UB = [0.15 ;0.2   ; 0.8 ; 1  ; .8   ; 1.5 ];
beta_guess_all(2:MSRUN,1:length(beta_guess)) =  bsxfun(@times,Guess_UB'-Guess_LB',rand(MSRUN - 1,length(beta_guess))) + repmat(Guess_LB',MSRUN-1,1);  % Starting point guesses are uniform random numbers in this interval

if MSRUN > 3
   beta_guess_all(4,:)   =     [0.1250 ,   0.0300  ,  0.3500  ,  0.8250  ,  0.2750 ,  1.2500];
end

if MSRUN > 4
   beta_guess_all(5,:)   =      [   0.1240 ,  0.0282 ,  0.3524 , 0.7704 , 0.3609 , 1.1641 ];
end

   
if MSRUN > 5
   beta_guess_all(6,:)   =      [0.1236, 0.0230, 0.1923, 0.8647, 0.3917, 0.9370] ;
end

if MSRUN > 6 
   beta_guess_all(7,:)   =      [0.126 , 0.011,   0.1 ,   0.5111 , .2 , 1.2912  ] ;
end

if MSRUN > 7 
   beta_guess_all(8,:)   =      [0.126 , 0.011,    0.1 ,   0.8 , .15, .6 ] ;
end


beta_hat_all          = -100 * ones(MSRUN,length(beta_guess)); 
fval_all              = 99999 * ones(MSRUN,1); 
exitflag_all          = -100 * ones(MSRUN,1); 

m.post_estimation = 0;