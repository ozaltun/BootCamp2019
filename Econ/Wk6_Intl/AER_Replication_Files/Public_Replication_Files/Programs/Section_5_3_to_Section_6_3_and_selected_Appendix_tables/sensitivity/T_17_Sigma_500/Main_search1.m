
clear;
clc;

%Chicago Cluster = 1 , 0 otherwise
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


stat_gap_all = []; 
statJiafile = sprintf('statistics_jia_%d.mat', task_id);
save(statJiafile,'stat_gap_all')

ms_run = task_id;

%for ms_run = ms_run    
    
    disp(' Multistart number ')
    disp(ms_run)
    disp(' ')
    
beta_guess = beta_guess_all(ms_run,:)';
tic
[beta_hat, fval,exitflag,output] = fminsearchbnd(@gmm_objective,beta_guess,lb,ub,opts,m)
toc

disp(sprintf('Completed iteration %d\n', ms_run));

% beta_hat_all(ms_run,:) = beta_hat'; 
% fval_all(ms_run) = fval; 
% exitflag_all(ms_run) = exitflag; 

%save('mstart_emp2', 'fval_all', 'beta_hat_all' , 'exitflag_all');
outFile = sprintf('result_%d.mat', task_id);
save(outFile, 'beta_hat', 'fval','exitflag','output')

exit



