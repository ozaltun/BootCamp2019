function B_final = get_fixed_point_for_B(m,beta_hat,B_start)


beta_hat(1) = B_start;

[fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec] = est_outcomes(beta_hat,m);

    
   B_new = m.sigma_tilde * (m.w_times_L_US + m.M_fixed_entry*sum( profit_vec .* m.weights_prod)) ./ ( m.M_fixed_entry* sum(price_vec .* m.weights_prod));
   disp('Current difference')
   while abs(B_new - beta_hat(1)) > 1e-12
    beta_hat(1) = 0.9 * beta_hat(1) + 0.1 * B_new;
   [fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec] = est_outcomes(beta_hat,m);
    B_new = m.sigma_tilde * (m.w_times_L_US + m.M_fixed_entry*sum( profit_vec .* m.weights_prod)) ./ ( m.M_fixed_entry* sum(price_vec .* m.weights_prod));
    disp(abs(B_new - beta_hat(1)))
   end
    


B_final = B_new;






