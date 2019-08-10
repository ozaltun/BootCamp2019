
clear
load est_output_smm

% NOTE: THIS FILE OVERWRITES ALL THE BASELINE RESULTS AND PRETENDS THAT THE
% WORLD AFTER THE REVERSE CHINA SHOCK  IS THE NEW BASELINE.



% We do a counterfactual change to the Chinese sourcing potential
% Then we consider 4 scenarios
% (a) B unchanged
% (b) B changed: free entry, flexible sourcing strategies
% (c) B changed: free entry, fixed sourcing strategies
% (d) B changed: fixed entry, flexible sourcing strategies  NOT discussed
% in paper

%% New part, reverse shock:

disp('Mass of firms estimated')
disp(M_free_entry_base)

disp('Share of firms importing from China in 2007 (model)')
share_importers_by_country(chn_ctr_ind)

disp('Share of imports from China in 2007 (model)')
m.agg_china_import_share_estimated_model = agg_imports_baseline(chn_ctr_ind) / sum(agg_imports_baseline(2:end));
disp(m.agg_china_import_share_estimated_model)


m.china_higher_fixed_cost_counter = 1;




if m.china_higher_fixed_cost_counter == 0
%% Calibrate the shock to Chinese Sourcing potential to match changes in aggregate trade share with China
m.beta_hat        = beta_hat; % store estimate in m structure
china_shock_guess = 0.38;
m.chn_ctr_ind     = chn_ctr_ind;

[fraction_china_sp, calibration_fval,~,~] = fminsearchbnd(@calibration_objective,china_shock_guess,0.01,1,opts,m)

disp('Calibration implies that sourcing potential of China in 1997 is percentage of 2007 sourcing potential')
disp(fraction_china_sp)
m.exp_fe_est(chn_ctr_ind)           = m.exp_fe_est(chn_ctr_ind) * fraction_china_sp;   % Chinese Sourcing Potential falls.

else
%% Calibrate the shock to Chinese Fixed Costs to match changes in aggregate trade share with China
m.beta_hat        = beta_hat; % store estimate in m structure
china_shock_fc_guess = 2;
m.chn_ctr_ind     = chn_ctr_ind;

[fraction_china_fc, calibration_fval,~,~] = fminsearchbnd(@calibration_objective,china_shock_fc_guess,1,10,opts,m)

disp('Calibration implies that fixed costs of China in 1997 is percentage of 2007 fixed costs')
disp(fraction_china_fc)
m.china_shock_fc = fraction_china_fc;

end
%%


opts_fsolve          = optimset('fsolve');
opts_fsolve.Display  = 'iter';
opts_fsolve.TolX     = 1e-15;
opts_fsolve.TolFun   = 1e-15;

eqmX_free_entry = fsolve(@(x_guess) eqm_system_free_entry(x_guess,m,beta_hat),B_est,opts_fsolve)
beta_hat(1) = eqmX_free_entry(1);

[fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec, fc_payments, sales_vec] = est_outcomes(beta_hat,m);

B_est                                       = beta_hat(1);
M_free_entry_base                = (m.sigma_tilde / B_est) * m.w_times_L_US ./ sum(price_vec .* m.weights_prod);
agg_imports_baseline          = M_free_entry_base * sum(bsxfun(@times,input_p_mat,m.weights_prod),1);

disp('Mass of firms after lower Chinese SP')
disp(M_free_entry_base)

disp('Share of firms importing from China after reverse shock')
share_importers_by_country(chn_ctr_ind)

disp('Share of imports from China after reverse shock')
disp( agg_imports_baseline(chn_ctr_ind) / sum(agg_imports_baseline(2:end)))

%% Counterfactual change

if m.china_higher_fixed_cost_counter == 0
m.exp_fe_est(chn_ctr_ind)           = m.exp_fe_est(chn_ctr_ind) / fraction_china_sp;   % Increase Chinese Sourcing Potential to estimated level
else
m.china_shock_fc = 1;                                                                  % Keep Chinese fixed costs at estimated level
end





%% (a) B unchanged

[fc_median_unconditional_counter, share_importers_counter, share_importers_by_country_counter, perc_bracket_1_counter, perc_bracket_2_counter, perc_bracket_3_counter, perc_bracket_4_counter,  median_input_purchase_counter, perc90_input_purchase_counter, input_p_mat_counter, price_vec_counter, profit_vec_counter, fc_payments_counter, sales_vec_counter] = est_outcomes(beta_hat,m);


%% (b) B changed: free entry, flexible sourcing strategies

% (a) Free entry
% Get new B and M
%eqmX_free_entry = fsolve(@(x_guess) eqm_system_free_entry(x_guess,m,beta_hat),[B_est;M_free_entry_base],optimoptions('fsolve','Display','iter','TolFun',1e-15,'TolX',1e-15))

opts_fsolve          = optimset('fsolve');
opts_fsolve.Display  = 'iter';
opts_fsolve.TolX     = 1e-15;
opts_fsolve.TolFun   = 1e-15;

eqmX_free_entry = fsolve(@(x_guess) eqm_system_free_entry(x_guess,m,beta_hat),B_est,opts_fsolve)
%eqmX_free_entry = fsolve(@(x_guess) eqm_system_free_entry(x_guess,m,beta_hat),B_est,optimoptions('fsolve','Display','iter','TolFun',1e-15,'TolX',1e-15))

beta_hat_counter_free    = beta_hat;
beta_hat_counter_free(1) = eqmX_free_entry(1);
% Get outcomes for new B
[fc_median_unconditional_counter_free , share_importers_counter_free, share_importers_by_country_counter_free , perc_bracket_1_counter_free, perc_bracket_2_counter_free, perc_bracket_3_counter_free, perc_bracket_4_counter_free,  median_input_purchase_counter_free, perc90_input_purchase_counter_free , input_p_mat_counter_free, price_vec_counter_free , profit_vec_counter_free, fc_payments_counter_free, sales_vec_counter_free] = est_outcomes(beta_hat_counter_free,m);
M_free_entry_post           = m.w_times_L_US ./ (m.sigma * (sum(fc_payments_counter_free .* m.weights_prod) + m.fix_entry_cost)); 
% gives same result as:  (m.sigma_tilde / beta_hat_counter_free(1)) * m.w_times_L_US ./ sum(price_vec_counter_free .* m.weights_prod)
disp('Change in Mass of firms free enty')
M_free_entry_post / M_free_entry_base

disp('Mass of firms post counterfactual back to baseline')
disp(M_free_entry_post)

%% (c) B changed: free entry, fixed sourcing strategies
m.Z_mat = (input_p_mat > 0) + 0;

eqmX_free_entry_fixed_sourcing = fsolve(@(x_guess) eqm_system_free_entry_fixed_sourcing_strategy(x_guess,m,beta_hat),B_est,opts_fsolve)
%eqmX_free_entry_fixed_sourcing = fsolve(@(x_guess) eqm_system_free_entry_fixed_sourcing_strategy(x_guess,m,beta_hat),B_est,optimoptions('fsolve','Display','iter','TolFun',1e-15,'TolX',1e-15))
beta_hat_counter_free_fixed_sourcing    = beta_hat;
beta_hat_counter_free_fixed_sourcing(1) = eqmX_free_entry_fixed_sourcing(1);
% Get outcomes for new B
[fc_median_unconditional_counter_fixed_sourcing, share_importers_counter_fixed_sourcing, share_importers_by_country_counter_fixed_sourcing , perc_bracket_1_counter_fixed_sourcing, perc_bracket_2_counter_fixed_sourcing, perc_bracket_3_counter_fixed_sourcing, perc_bracket_4_counter_fixed_sourcing,  median_input_purchase_counter_fixed_sourcing, perc90_input_purchase_counter_fixed_sourcing , input_p_mat_counter_fixed_sourcing, price_vec_counter_fixed_sourcing , profit_vec_counter_fixed_sourcing, fc_payments_counter_fixed_sourcing, sales_vec_counter_fixed_sourcing] = est_outcomes_fixed_sourcing_strategy(beta_hat_counter_free_fixed_sourcing,m);
M_free_entry_fixed_sourcing           = m.w_times_L_US ./ (m.sigma * (sum(fc_payments_counter_fixed_sourcing .* m.weights_prod) + m.fix_entry_cost)); 



%% (d) B changed: fixed entry, flexible sourcing strategies

% Solve for M
m.M_fixed_entry   = (((B_est / m.sigma_tilde) -  (sum( profit_vec .* m.weights_prod) ./ sum(price_vec .* m.weights_prod))) * sum(price_vec .* m.weights_prod) ./ m.w_times_L_US).^(-1);  
% Get new B
%B_final                    = get_fixed_point_for_B(m,beta_hat,B_est);
eqmX_fixed_entry = fsolve(@(x_guess) eqm_system_fixed_entry(x_guess,m,beta_hat),B_est,opts_fsolve)
%eqmX_fixed_entry = fsolve(@(x_guess) eqm_system_fixed_entry(x_guess,m,beta_hat),B_est,optimoptions('fsolve','Display','iter','TolFun',1e-15,'TolX',1e-15))
beta_hat_counter_fixed    = beta_hat;
beta_hat_counter_fixed(1) = eqmX_fixed_entry;
% Get outcomes for new B
[fc_median_unconditional_counter_fixed , share_importers_counter_fixed, share_importers_by_country_counter_fixed , perc_bracket_1_counter_fixed, perc_bracket_2_counter_fixed, perc_bracket_3_counter_fixed, perc_bracket_4_counter_fixed,  median_input_purchase_counter_fixed, perc90_input_purchase_counter_fixed , input_p_mat_counter_fixed, price_vec_counter_fixed , profit_vec_counter_fixed, fc_payments_counter_fixed, sales_vec_counter_fixed] = est_outcomes(beta_hat_counter_fixed,m);
disp('Difference in free and fixed entry B')
format long
eqmX_free_entry(1) - eqmX_fixed_entry


%% Execute print results to latex

print_counterfactual_results_to_latex












