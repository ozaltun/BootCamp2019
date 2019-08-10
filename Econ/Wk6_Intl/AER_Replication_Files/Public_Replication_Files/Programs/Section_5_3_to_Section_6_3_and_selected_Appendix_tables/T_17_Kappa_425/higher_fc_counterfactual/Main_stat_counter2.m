
clear;
clc;

% Chicago Cluster = 1 , 0 otherwise
chicago_cluster = 1;  
if chicago_cluster == 1 

% create a local cluster object
pc = parcluster('local')
% explicitly set the JobStorageLocation to the temp directory that was created in your sbatch script
pc.JobStorageLocation = strcat('/tmp/tintelnot/', getenv('SLURM_JOB_ID'), '/', getenv('SLURM_ARRAY_TASK_ID'))
% start the matlabpool with 12 workers
matlabpool(pc, 12)

else
    
matlabpool open 6 

end

% Run Setup structure AFT script
setup_struct_aft


% This sub-job's task_id number
task_id = str2num(getenv('SLURM_ARRAY_TASK_ID'));
fprintf('my task_id = %d\n', task_id);


%stat_gap_all = []; 
%save statistics_jia stat_gap_all
stat_gap_total = []; 


for ms_run = 1:MSRUN    
    
%     disp(' Multistart number ')
%     disp(ms_run)
%     disp(' ')
%     
% beta_guess = beta_guess_all(ms_run,:)';
% tic
% [beta_hat, fval,exitflag,output] = fminsearchbnd(@gmm_objective,beta_guess,lb,ub,opts,m)
% toc
% 
% disp(sprintf('Completed iteration %d\n', ms_run));
% 
% beta_hat_all(ms_run,:) = beta_hat'; 
% fval_all(ms_run) = fval; 
% exitflag_all(ms_run) = exitflag; 
% 
% save('mstart_emp2', 'fval_all', 'beta_hat_all' , 'exitflag_all');

 inFile = sprintf('result_%d.mat', ms_run);
 load(inFile);
 beta_hat_all(ms_run,:) = beta_hat'; 
 fval_all(ms_run) = fval; 
 exitflag_all(ms_run) = exitflag; 
 
 inFile = sprintf('statistics_jia_%d.mat', ms_run);
 load(inFile);
 stat_gap_total = [stat_gap_total ; stat_gap_all];


 clear beta_hat fval exitflag output stat_gap_all
 
end
stat_gap_all = stat_gap_total;


[ll, idx] = min(fval_all);
disp('Likelihood')
disp(ll)
disp('Coefficients')
beta_hat = beta_hat_all(idx,:)'

%save est_output_fminsearch

% option_anneal.Verbosity = 2;
% 
% [beta_hat_anneal, fval] = anneal(@gmm_objective,beta_hat',option_anneal,lb',ub',m)
% if fval < ll
%     beta_hat = beta_hat_anneal;
% end

m.china_higher_fixed_cost_counter = 0;

[fc_median_unconditional , share_importers, share_importers_by_country , perc_bracket_1, perc_bracket_2, perc_bracket_3, perc_bracket_4,  median_input_purchase, perc90_input_purchase , input_p_mat, price_vec , profit_vec, fc_payments, sales_vec, share_importers_cell] = est_outcomes(beta_hat,m);

m.w_times_L_US                  = sum(m.agg_imports_data) * (m.sigma/(m.sigma-1));     
B_est                                       = beta_hat(1);
M_free_entry_base                = (m.sigma_tilde / B_est) * m.w_times_L_US ./ sum(price_vec .* m.weights_prod);
% Note that M is consistent with equation (15) in the paper:  m.w_times_L_US / (m.sigma * (sum(fc_payments.*m.weights_prod) + m.fix_entry_cost))
m.fix_entry_cost                     = sum( profit_vec .* m.weights_prod);
agg_imports_baseline          = M_free_entry_base * sum(bsxfun(@times,input_p_mat,m.weights_prod),1);

m.post_estimation = 1;

gmm_objective(beta_hat,m);

print_estimation_results_to_latex

save est_output_smm



%% Counterfactual

clear

%counterfactual_run_script
counterfactual_run_script_reverse_shock
% Save file
save('output_incl_counterfactual.mat', '-v7.3') ;

exit


