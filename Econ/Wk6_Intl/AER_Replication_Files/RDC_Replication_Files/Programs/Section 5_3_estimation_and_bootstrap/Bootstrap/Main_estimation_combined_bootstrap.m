clear;
clc;

% Set Census_internal switch and a switch whether the multi-start
% estimation runs in sequence or in parallel



% Chicago Cluster = 1 , 0 otherwise
m.multi_start_parallel = 0;
    
matlabpool('local',12)


% Run Setup structure AFT script
setup_struct_aft_boot


% % This sub-job's task_id number
% task_id = str2num(getenv('SLURM_ARRAY_TASK_ID'));
% fprintf('my task_id = %d\n', task_id);



stat_gap_all = []; 
save statistics_jia stat_gap_all



for ms_run = 1:MSRUN    
    
    disp(' Multistart number ')
    disp(ms_run)
    disp(' ')
    
beta_guess = beta_guess_all(ms_run,:)';
tic
[beta_hat, fval,exitflag,output] = fminsearchbnd(@gmm_objective,beta_guess,lb,ub,opts,m)
toc

disp(sprintf('Completed iteration %d\n', ms_run));

beta_hat_all(ms_run,:) = beta_hat'; 
fval_all(ms_run) = fval; 
exitflag_all(ms_run) = exitflag; 

end

load('statistics_jia');


[ll, idx] = min(fval_all);
disp('Likelihood')
disp(ll)
disp('Coefficients')
beta_hat = beta_hat_all(idx,:)'

%save est_output_fminsearch
save ('est_output_bs.mat','beta_hat','-v7.3')



[fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec, fc_payments, sales_vec] = est_outcomes(beta_hat,m);

m.w_times_L_US                  = sum(m.agg_imports_data) * (m.sigma/(m.sigma-1));     
B_est                                       = beta_hat(1);
M_free_entry_base                = (m.sigma_tilde / B_est) * m.w_times_L_US ./ sum(price_vec .* m.weights_prod);
% Note that M is consistent with equation (15) in the paper:  m.w_times_L_US / (m.sigma * (sum(fc_payments.*m.weights_prod) + m.fix_entry_cost))
m.fix_entry_cost                     = sum( profit_vec .* m.weights_prod);
agg_imports_baseline          = M_free_entry_base * sum(bsxfun(@times,input_p_mat,m.weights_prod),1);


print_estimation_results_to_latex


%counterfactual_run_script         % commented out Aug 1 2016
% Save file
%save('output_incl_counterfactual.mat', '-v7.3') ;

exit


