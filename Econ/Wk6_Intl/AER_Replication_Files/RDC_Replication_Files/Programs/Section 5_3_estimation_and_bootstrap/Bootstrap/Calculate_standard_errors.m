
clear;
clc;




% Note: The first bootstrap sample is the actual full data!!!
% So the bootstrap in its actual meaning is from 2-26...

num_bootstrap = 25;
for j=1:num_bootstrap+1
%my_dir_name = ['cocsample',num2str(j)];
my_dir_name = ['sample_sn',num2str(j)];             % Changed August 1 2016 to compute s.e. accounting for suimulation noise
cd(my_dir_name)

if j == 1
load('est_output_bs.mat','beta_hat')
beta_hat_main = beta_hat;
clear beta_hat
else
load('est_output_bs.mat','beta_hat')
beta_hat_bootstrap(j-1,:) = beta_hat;
clear beta_hat
end

cd ..

end
beta_hat_bootstrap = beta_hat_bootstrap';
B = size(beta_hat_bootstrap,2);

se = ((1/B) * sum((repmat(beta_hat_main,1,B) - beta_hat_bootstrap).^2,2)).^(1/2);


beta_hat_main
se


m.beta_names                      = {'B';'fcconstant';'fcdist';'fclang';'fccoc';'fcdisp'};


fileID = fopen('ParameterEstimatesStep3_withSE.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Simulated Method of Moments Estimates}\\label{tab:fc_est} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
for k = 1:length(beta_hat_main)
    if k==5
            fprintf(fileID, 'beta%s & %.6f & %.6f \\\\ \n',m.beta_names{k},-beta_hat_main(k),se(k));  % control of corruption is coded with a negative sign
    else
    fprintf(fileID, 'beta%s & %.6f & %.6f \\\\ \n',m.beta_names{k},beta_hat_main(k),se(k));
    end
end
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} Bootstrapped standard errors.} \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');




