
clear;
clc;


% Note: The first bootstrap sample is the actual full data!!!
% So the bootstrap in its actual meaning is from 2-26...
my_root                         = pwd;


num_bootstrap = 25;
for j=1:num_bootstrap+1
%my_dir_name = ['cocsample',num2str(j)];
my_dir_name = ['sample_sn',num2str(j)];    % New Aug 1 2016, re-do to account for simulation noise
mkdir(my_dir_name);
cd(my_dir_name)
my_directory                     = pwd;   

% Get the code
cd %% GO TO PLACE WEHERE BASELINE CODE IS STORED
copyfile('*.m',my_directory)

cd(my_root)
copyfile('Main_estimation_combined_bootstrap.m',my_directory)
copyfile('setup_struct_aft_boot.m',my_directory)

% Get the submission script
copyfile('*.bash',my_directory)     % NOTE: ! NEed to manually change the location in which the log files etc are stored to the respective directory.

cd(my_root)

end




