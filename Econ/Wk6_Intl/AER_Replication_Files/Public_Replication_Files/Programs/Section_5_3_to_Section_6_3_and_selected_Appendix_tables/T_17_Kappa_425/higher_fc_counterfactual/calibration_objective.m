function fval = calibration_objective(china_shock_guess,m)

beta_hat = m.beta_hat;

if m.china_higher_fixed_cost_counter == 0
fraction_china_sp = china_shock_guess; % Fraction of 2007 Chinese SP which equals 1997 Chinese SP   %  number less than 1 
m.exp_fe_est(m.chn_ctr_ind)           = m.exp_fe_est(m.chn_ctr_ind) * fraction_china_sp;   % Chinese Sourcing Potential falls.
else
m.china_shock_fc =  china_shock_guess;
end
    
    
opts_fsolve          = optimset('fsolve');
opts_fsolve.Display  = 'iter';
opts_fsolve.TolX     = 1e-15;
opts_fsolve.TolFun   = 1e-15;

eqmX_free_entry = fsolve(@(x_guess) eqm_system_free_entry(x_guess,m,beta_hat),beta_hat(1),opts_fsolve)
beta_hat(1) = eqmX_free_entry(1);


[fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec, fc_payments, sales_vec] = est_outcomes(beta_hat,m);

m.w_times_L_US                  = sum(m.agg_imports_data) * (m.sigma/(m.sigma-1));     
B_est                                       = beta_hat(1);
M_free_entry_base                = (m.sigma_tilde / B_est) * m.w_times_L_US ./ sum(price_vec .* m.weights_prod);
% Note that M is consistent with equation (15) in the paper:  m.w_times_L_US / (m.sigma * (sum(fc_payments.*m.weights_prod) + m.fix_entry_cost))
agg_imports_baseline          = M_free_entry_base * sum(bsxfun(@times,input_p_mat,m.weights_prod),1);
agg_china_import_share_guess = agg_imports_baseline(m.chn_ctr_ind) / sum(agg_imports_baseline(2:end));

y      = (100*((m.agg_china_import_share_estimated_model  / agg_china_import_share_guess) - 1 )) - m.agg_china_import_share_percent_increase_data ;
  
fval = y^2;


