
%% This code generates the weighting matrix for the estimation 


m.Moment1 = (m.num_importing_firms_data/m.num_all_firms_data);       % Share of importing firms; Scalar
m.Moment2 = (m.num_firms_by_country_data ./ m.num_all_firms_data);  % Share of importing firms by country; vector
m.Moment3 = .5; % The proportion of firms that sources from the U.S. less than the median amount (m.imports50_data(1)). 


for bs = 2:2001

inFile                           = sprintf('emp2_data_for_matlab_bs%d.out', task_id);
country_data                     = importdata(inFile,',',1);
inFile                           = sprintf('additional_param_and_mom_bs%d.out', task_id);
add_data                         = importdata(inFile,',',1);          
    

num_firms_by_country_data        = country_data.data(:,5);
num_all_firms_data               = add_data.data(3);                 
num_importing_firms_data         = add_data.data(4);                 
share_less_medianUS              = add_data.data(5);               % Share of firms that buys less than the median purchase in the full data set from the U.S. 

Moment1BS(bs)                    = num_importing_firms_data / num_all_firms_data;
Moment2BS(:,bs)                  = num_firms_by_country_data ./ num_all_firms_data;
Moment3BS(bs)                    = share_less_medianUS;


% Calculate covariance matrix

diff_mom = [Moment1BS(bs);Moment2BS(:,bs);Moment3BS(bs)] - [m.Moment1 ; m.Moment2; m.Moment3];
cov_part = diff_mom * diff_mom';
cov_temp = cov_temp + cov_part;

end

cov_mat    = cov_temp ./ 2000;
weight_mat = inv(cov_mat); 


clear num_firms_by_country_data num_all_firms_data num_importing_firms_data



