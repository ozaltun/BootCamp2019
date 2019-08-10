function equa = eqm_system_free_entry_fixed_sourcing_strategy(x_guess,m,beta_hat)

B_sol      = x_guess(1);
%M_sol      = x_guess(2);


beta_hat(1) = B_sol;
[fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec, fc_payments, sales_vec] = est_outcomes_fixed_sourcing_strategy(beta_hat,m);


%equa(1) = B_sol - ((m.sigma_tilde / M_sol ) * m.w_times_L_US ./ sum(price_vec .* m.weights_prod));
%equa(2) = m.fix_entry_cost - sum( profit_vec .* m.weights_prod);

% Alternative code


%B_numerator   = sum(fc_payments .* m.weights_prod) + m.fix_entry_cost;
%B_denominator = sum(sales_vec .* m.weights_prod) / (m.sigma * beta_hat(1));

%equa = B_sol - ( B_numerator / B_denominator) ; 

equa = m.fix_entry_cost  - sum( profit_vec .* m.weights_prod);


%M = m.w_times_L_US ./ (m.sigma * B_numerator); 