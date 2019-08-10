function fval = gmm_objective(beta_guess,m)

B_guess                 = beta_guess(1);
fc_mean_guess           = beta_guess(2);
fc_disp_guess           = beta_guess(3);

phi_sigma_1_B           = B_guess * (((1- m.prod_draw_uniform).^(-1/m.kappa)).^(m.sigma-1));    % m.S x 2

fc_mean                 = fc_mean_guess(1)  ;
fc_mat                  = bsxfun(@times,fc_mean,exp(min(m.fc_shock_randn.*fc_disp_guess,709)));  % m.S x m.N
fc_mat(:,1)             = 0; % zero f.c. for domestic sourcing              % US COMES FIRST


%% Loop to solve the firm-level problem
% Lower Bound Mapping

%Z_UB_mat = zeros(m.S,m.N);
%Z_LB_mat = zeros(m.S,m.N);
Z_mat    = zeros(m.S,m.N);
gap_bounds = zeros(m.S,1);

Num_ctr       = m.N;
exp_fe_est    = m.exp_fe_est;
sigma_param   = m.sigma;
theta_param   = m.theta;
rand_check_matrix = m.rand_check_matrix;
num_rand_checks = m.num_rand_checks;
S_total       = m.S;

Z_start_LB                            = zeros(1,Num_ctr); % in no country
LB_source_potential_shock_mat_start   = (Z_start_LB * exp_fe_est).^((m.sigma-1)/m.theta); 
LB_Z_check_matrix                     = min(repmat(Z_start_LB,Num_ctr,1) + eye(Num_ctr),1);
LB_source_potential_shock_mat_check   = (LB_Z_check_matrix * exp_fe_est).^((m.sigma-1)/m.theta); 

Z_start_UB                            = ones(1,Num_ctr); % in no country
UB_source_potential_shock_mat_start   = (Z_start_UB * exp_fe_est).^((m.sigma-1)/m.theta); 
UB_Z_check_matrix                     = max(repmat(Z_start_UB,Num_ctr,1) - eye(Num_ctr),0);
UB_source_potential_shock_mat_check   = (UB_Z_check_matrix * exp_fe_est).^((m.sigma-1)/m.theta); 

parfor my_firm = 1: S_total

    % Jia algorithm to get the lower bound for the optimal sourcing
    % strategy

Z_LB = lower_bound_iteration_optimized(LB_source_potential_shock_mat_start,LB_source_potential_shock_mat_check,phi_sigma_1_B(my_firm),fc_mat(my_firm,:),Num_ctr,exp_fe_est,sigma_param,theta_param);


    % Jia algorithm to get the upper bound for the optimal sourcing
    % strategy
Z_UB = upper_bound_iteration_optimized(UB_source_potential_shock_mat_start,UB_source_potential_shock_mat_check,phi_sigma_1_B(my_firm),fc_mat(my_firm,:),Num_ctr,exp_fe_est,sigma_param,theta_param);

% If upper bound equals lower bound, we are done! 
if sum(Z_LB == Z_UB) == Num_ctr
    Z_mat(my_firm,:) = Z_UB;

% If upper bound is not too different from lower bound, we evaluate all possible combinations in between and including the two bounds    
elseif sum(Z_LB == Z_UB) < Num_ctr && sum(Z_LB == Z_UB) >= Num_ctr - 26;

    ind_diffZ = (Z_LB ~= Z_UB);   
    gap_bounds(my_firm) = sum(ind_diffZ);
% disp('Number of countries for which bounds do not overlap:')
% disp(sum(ind_diffZ))
    location_string_mat           = [];
for K=1:sum(ind_diffZ)
    index_I                   = repmat((1:1:nchoosek(sum(ind_diffZ),K))',K,1);
    index_J                   = nchoosek(1:sum(ind_diffZ),K);
    index_J                   = index_J(:);
    ind                       = sub2ind([nchoosek(sum(ind_diffZ),K),sum(ind_diffZ)],index_I,index_J);
    temp_1                    = zeros(nchoosek(sum(ind_diffZ),K),sum(ind_diffZ));
    temp_1(ind)               = 1;
    location_string_mat       = [location_string_mat ; temp_1];   % This builds a large matrix with as many rows as possible location strings and in each row a column has a one if the firm has a location there                 
end

location_string_mat =  [zeros(1,sum(ind_diffZ)) ; location_string_mat];   % Consider Z_LB in the set of alternatives. Z_UB is also part of the set as location_string_mat contains a row with all ones.

Z_check = repmat(Z_LB,size(location_string_mat,1),1);
K_diff = find(ind_diffZ);
for K=1:sum(ind_diffZ)
    Z_check(:,K_diff(K)) = location_string_mat(:,K);
end

fc_payments               = sum(bsxfun(@times,Z_check,fc_mat(my_firm,:)),2);  % m.num_loc_strings x 1
source_potential_shock_mat_check   = (Z_check * exp_fe_est).^((sigma_param-1)/theta_param); 
source_potential_vec      = phi_sigma_1_B(my_firm) * source_potential_shock_mat_check;                             %m.num_loc_strings x1
 
total_profits             = source_potential_vec - fc_payments;
[bla , loc_firm_best ]   = max(total_profits,[],1);
Z_mat(my_firm,:)         = Z_check(loc_firm_best,:);


% If the upper bound is widely different from the lower bound, we would
% have to revert to this script below.  
else %  sum(Z_LB == Z_UB) < m.N && sum(Z_LB == Z_UB) < m.N - 10;
disp('Warning: The Sourcing strategy may not be solved correctly')
Z_check          = repmat(Z_LB,num_rand_checks,1);
ind_diffZ = (Z_LB ~= Z_UB);
gap_bounds(my_firm) = sum(ind_diffZ);
K_diff = find(ind_diffZ);
for K=1:sum(ind_diffZ)
    Z_check(:,K_diff(K)) = rand_check_matrix(:,K_diff(K)) > 0.5;
end
Z_check  = [Z_check; Z_LB; Z_UB];   % Include lower and upper bound into the set of Sourcing strategies that is evaluated

fc_payments               = sum(bsxfun(@times,Z_check,fc_mat(my_firm,:)),2);  % m.num_loc_strings x 1
source_potential_shock_mat_check   = (Z_check * exp_fe_est).^((sigma_param-1)/theta_param); 
source_potential_vec      = phi_sigma_1_B(my_firm) * source_potential_shock_mat_check;                             %m.num_loc_strings x1
 
total_profits             = source_potential_vec - fc_payments;
[bla , loc_firm_best ]   = max(total_profits,[],1);
Z_mat(my_firm,:)         = Z_check(loc_firm_best,:);

end
    
end


    % Get input purchases and sales

denom_temp        = Z_mat * exp_fe_est;
share_mat_temp = bsxfun(@rdivide,bsxfun(@times,Z_mat ,exp_fe_est'), denom_temp);

sales_vec          = sigma_param * phi_sigma_1_B .* ((denom_temp).^((sigma_param-1)/theta_param));
input_p_mat      = ((sigma_param-1) ./ sigma_param) * bsxfun(@times,sales_vec,share_mat_temp);

clear denom_temp share_mat_temp  % These are big objects, so to save memory we get rid of them


%% Statistics on Jia algorithm

if m.post_estimation == 0
stat_gap = zeros(1,Num_ctr+1);
for my_country = 1:Num_ctr+1
   stat_gap(my_country) = sum(gap_bounds == my_country-1)  ;
end

task_id = str2num(getenv('SLURM_ARRAY_TASK_ID'));
inFile = sprintf('statistics_jia_%d.mat', task_id);
load(inFile);
stat_gap_all = [stat_gap_all ; stat_gap];

%save statistics_jia stat_gap_all
statJiafile = sprintf('statistics_jia_%d.mat', task_id);
save(statJiafile,'stat_gap_all')
end

%% Calculate Moments

% 1. Share of firms that imports from any foreign country

%share_importers = sum(sum(input_p_mat > 0,2) > 1) ./ m.S ;     % scalar
share_importers = (sum(input_p_mat > 0,2) > 1)' * m.weights_prod ;     % scalar

% Sort sales in ascending order
[sales_sorted ,sort_indicator ] = sort(sales_vec);
prod_weight_sorted              = m.weights_prod(sort_indicator);
importer_dummy                  = (sum(input_p_mat > 0,2) > 1);
importer_dummy_sorted           = importer_dummy(sort_indicator);
q1_ind                          = (cumsum(prod_weight_sorted) <= .25);
q2_ind                          = (cumsum(prod_weight_sorted) > .25) &  (cumsum(prod_weight_sorted) <= .5) ;
q3_ind                          = (cumsum(prod_weight_sorted) > .5) &  (cumsum(prod_weight_sorted) <= .75) ;
q4_ind                          = (cumsum(prod_weight_sorted) > .75);

share_importers_q1              = sum(prod_weight_sorted(q1_ind) .* importer_dummy_sorted(q1_ind)) / sum(prod_weight_sorted(q1_ind));
share_importers_q2              = sum(prod_weight_sorted(q2_ind) .* importer_dummy_sorted(q2_ind)) / sum(prod_weight_sorted(q2_ind));
share_importers_q3              = sum(prod_weight_sorted(q3_ind) .* importer_dummy_sorted(q3_ind)) / sum(prod_weight_sorted(q3_ind));
share_importers_q4              = sum(prod_weight_sorted(q4_ind) .* importer_dummy_sorted(q4_ind)) / sum(prod_weight_sorted(q4_ind));

% 2. Share of firms in a country

%share_importers_by_country = sum(input_p_mat > 0,1) ./ m.S ;   %1xN
share_importers_by_country = sum((input_p_mat > 0) .* repmat(m.weights_prod,1,m.N),1) ;   %1xN

% 3. Percentiles 

% perc_bracket_1 = sum((input_p_mat > 0) .* (input_p_mat <= repmat(m.imports25_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);   %1xN
% perc_bracket_2 = sum((input_p_mat > repmat(m.imports25_data',m.S,1)) .* (input_p_mat <= repmat(m.imports50_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);    %1xN
% perc_bracket_3 = sum((input_p_mat > repmat(m.imports50_data',m.S,1)) .* (input_p_mat <= repmat(m.imports90_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1)./ max(share_importers_by_country,eps) ;    %1xN
% perc_bracket_4 = sum((input_p_mat > repmat(m.imports90_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);    %1xN

% ONLY EXTERNAL
%perc_less_median = sum((input_p_mat > 0) .* (input_p_mat <= repmat(m.imports50_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);   %1xN
perc_less_median = sum((input_p_mat(:,1) > 0) .* (input_p_mat(:,1) <= repmat(m.US_median_dom_input,m.S,1)).* m.weights_prod,1) ./ max(share_importers_by_country(1),eps);   %1xN


%% Calculate objective

y = [ (share_importers - (m.num_importing_firms_data/m.num_all_firms_data)) , .5 * (share_importers_q1 + share_importers_q2 - m.share_importers_sales0_25 - m.share_importers_sales25_50)  ...
      share_importers_by_country - (m.num_firms_by_country_data' ./ m.num_all_firms_data) , ...
      perc_less_median(1) - .5 ];
  
if m.post_estimation == 1
    moment1 = [share_importers; .5 * (share_importers_q1 + share_importers_q2)];
    moment2 = share_importers_by_country;
    moment3 = perc_less_median(1);
    save moments_for_table moment1 moment2 moment3
end
  
  
fval = sum(y.^2);  

