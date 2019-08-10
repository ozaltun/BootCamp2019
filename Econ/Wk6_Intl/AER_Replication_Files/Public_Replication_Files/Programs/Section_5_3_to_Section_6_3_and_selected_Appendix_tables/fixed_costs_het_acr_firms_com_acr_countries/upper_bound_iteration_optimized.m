
function Z_new = upper_bound_iteration_optimized(source_potential_shock_mat_start,source_potential_shock_mat_check,phi_sigma_1_B_scalar,fc_vec,Num_ctr,exp_fe_est,sigma_param,theta_param)

k = 1;
Z_start  = ones(1,Num_ctr); % in no country

my_exponent = (sigma_param-1)/theta_param;

while k <= Num_ctr
    % Calculate Marginal Benefit = 
if k>1
        source_potential_shock_mat_start  = (Z_start * exp_fe_est).^my_exponent; 
        source_potential_shock_mat_check    = (Z_start* exp_fe_est - exp_fe_est.*Z_start').^my_exponent;   % Drop locations and see below whether marginal benefit is positive
end
    source_potential_start = phi_sigma_1_B_scalar * source_potential_shock_mat_start;
    source_potential_new_vec = phi_sigma_1_B_scalar * source_potential_shock_mat_check;
    
    MB_negative = (source_potential_start - source_potential_new_vec' - fc_vec < 0);
    Z_new = max(Z_start - MB_negative,0);
    if Z_start==Z_new
        break
    end;
    k=k+1;
    Z_start = Z_new;
end;

    
    
    