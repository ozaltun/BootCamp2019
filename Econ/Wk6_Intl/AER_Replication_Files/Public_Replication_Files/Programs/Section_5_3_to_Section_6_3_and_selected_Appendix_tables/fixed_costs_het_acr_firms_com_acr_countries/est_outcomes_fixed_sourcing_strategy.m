function [fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4, median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec, fc_payments_all, sales_vec] = est_outcomes_fixed_sourcing_strategy(beta_guess,m)


B_guess                 = beta_guess(1);
fc_mean_guess           = beta_guess(2);
fc_disp_guess           = beta_guess(3);

phi_sigma_1_B           = B_guess * (((1- m.prod_draw_uniform).^(-1/m.kappa)).^(m.sigma-1));    % m.S x 2

fc_mean                 = fc_mean_guess(1) ;
fc_mat                  = bsxfun(@times,fc_mean,exp(min(m.fc_shock_randn.*fc_disp_guess,709)));  % m.S x m.N
fc_mat(:,1)             = 0; % zero f.c. for domestic sourcing              % US COMES FIRST

%if m.china_higher_fixed_cost_counter == 1
%fc_mat(:,59) = fc_mat(:,59)*2;
%end


%% Loop to solve the firm-level problem
% Lower Bound Mapping

exp_fe_est    = m.exp_fe_est;
sigma_param   = m.sigma;
theta_param   = m.theta;

Z_mat = m.Z_mat;
denom_temp        = Z_mat * exp_fe_est;
share_mat_temp = bsxfun(@rdivide,bsxfun(@times,Z_mat ,exp_fe_est'), denom_temp);

sales_vec          = sigma_param * phi_sigma_1_B .* ((denom_temp).^((sigma_param-1)/theta_param));
input_p_mat      = ((sigma_param-1) ./ sigma_param) * bsxfun(@times,sales_vec,share_mat_temp);

clear denom_temp share_mat_temp
profit_vec    =  sales_vec ./ sigma_param - sum(Z_mat .* fc_mat,2) ;
price_vec     = (sigma_param ./ (sigma_param-1))^(1-sigma_param) .* sales_vec ./ (sigma_param * B_guess);




%% Calculate Moments

% 1. Share of firms that imports from any foreign country

%share_importers = sum(sum(input_p_mat > 0,2) > 1) ./ m.S ;     % scalar
share_importers = (sum(input_p_mat > 0,2) > 1)' * m.weights_prod ;     % scalar

% 2. Share of firms in a country

%share_importers_by_country = sum(input_p_mat > 0,1) ./ m.S ;   %1xN
share_importers_by_country = sum((input_p_mat > 0) .* repmat(m.weights_prod,1,m.N),1) ;   %1xN


% 3. Percentiles
% ONLY EXTERNAL
% perc_bracket_1 = sum((input_p_mat > 0) .* (input_p_mat <= repmat(m.imports25_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);   %1xN
% perc_bracket_2 = sum((input_p_mat > repmat(m.imports25_data',m.S,1)) .* (input_p_mat <= repmat(m.imports50_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);    %1xN
% perc_bracket_3 = sum((input_p_mat > repmat(m.imports50_data',m.S,1)) .* (input_p_mat <= repmat(m.imports90_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1)./ max(share_importers_by_country,eps) ;    %1xN
% perc_bracket_4 = sum((input_p_mat > repmat(m.imports90_data',m.S,1)).* repmat(m.weights_prod,1,m.N),1) ./ max(share_importers_by_country,eps);    %1xN

perc_bracket_1 = [];
perc_bracket_2 = [];
perc_bracket_3 = []; 
perc_bracket_4 = [];

%% Calculate objective


%y = [ (share_importers - (m.num_importing_firms_data/m.num_all_firms_data)) , share_importers_by_country - (m.num_firms_by_country_data' ./ m.num_all_firms_data) , ...
%      perc_bracket_1 - .25 , perc_bracket_2 - .25 , perc_bracket_3 - .4 , perc_bracket_4 - .1];
  
%fval = sum(y.^2);  

fc_median_unconditional = fc_mean;

%% Calculate other percentiles

median_input_purchase = zeros(1,m.N);
perc90_input_purchase = zeros(1,m.N);

for country = 1:m.N
    % 1. Keep only those observations with positive import
    input_p_vec = input_p_mat(:,country);
    input_trimmed = input_p_vec(input_p_vec>0);
    weight_trimmed = m.weights_prod(input_p_vec>0);    
    weight_reweighted = weight_trimmed ./sum(weight_trimmed);
    
       
A_temp = [input_trimmed weight_reweighted];
ASort = sortrows(A_temp,1);   % based on first column

inputSort  = ASort(:,1);
wSort  = ASort(:,2);
sumVec = cumsum(wSort);

median_ind = sumVec > 0.5;
perc_90ind = sumVec > 0.9;

temp_median = inputSort(median_ind == 0);
temp_percentile = inputSort(perc_90ind == 0);

median_input_purchase(country) = temp_median(end);
perc90_input_purchase(country) = temp_percentile(end);

end
    

%% Calculate fix cost payments

fc_payments_all               = sum((input_p_mat > 0) .* fc_mat,2);  % m.num_loc_strings x 1


    