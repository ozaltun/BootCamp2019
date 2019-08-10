
%% Shown in paper


% 1. Estimation results table

fileID = fopen('ParameterEstimatesStep3.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Simulated Method of Moments Estimates}\\label{tab:fc_est} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
for k = 1:length(beta_hat)
    if k==5
            fprintf(fileID, 'beta%s & %.6f \\\\ \n',m.beta_names{k},-beta_hat(k));  % control of corruption is coded with a negative sign
    else
    fprintf(fileID, 'beta%s & %.6f \\\\ \n',m.beta_names{k},beta_hat(k));
    end
end
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} Standard errors yet to be calculated.} \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');


% 2. Fixed costs: Range of median fixed costs across countries

fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Median fixed cost range across countries}\\label{tab:fc_median} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'minimum million USD & %.3f \\\\ \n',min(fc_median_unconditional(2:end)));
fprintf(fileID, 'maximum million USD & %.3f \\\\ \n',max(fc_median_unconditional(2:end)));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} ... } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');


% 3. Model fit: Shares of firms and Shares of sourcing

% (a) Share of importers by country
% Figure trade shares predicted versus actual
share_importers_by_country_data = (m.num_firms_by_country_data' ./ m.num_all_firms_data);
%plot(log(share_importers_by_country(2:end)),log(share_importers_by_country_data(2:end)),'b.')
loglog(share_importers_by_country(2:end),share_importers_by_country_data(2:end),'bo')
hold on
dummy_for_plot = (0.0001:1/100000:1);
plot(dummy_for_plot,dummy_for_plot,'k--')
xlabel('model')
ylabel('data')
saveas(gcf,'share_importers_by_country','epsc')
hold off

% (b) Agg import by contry as share of total foreign sourcing
loglog(agg_imports_baseline(2:end) / sum(agg_imports_baseline(2:end)),m.agg_imports_data(2:end) / sum(m.agg_imports_data(2:end)),'bo')
hold on
dummy_for_plot = (0: .0001:1);
plot(dummy_for_plot,dummy_for_plot,'k--')
xlabel('model')
ylabel('data')
saveas(gcf,'agg_importer_model_data_share_of_total_sourcing','epsc')
hold off


% Correlation coefficient
disp('Correlation between aggregate imports in data and model')
disp(corr(agg_imports_baseline(2:end)',m.agg_imports_data(2:end)))

fileID = fopen('TableCorrelationAggregateImports.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\caption{Correlation between aggregate imports and import share in data and model}\\label{tab:corr_agg_imports} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'Correlation Agg Imp  & %.3f  \\\\ \n',corr(agg_imports_baseline(2:end)',m.agg_imports_data(2:end)));
fprintf(fileID, 'Correlation  Agg IMP share & %.3f  \\\\ \n',corr(share_importers_by_country(2:end)',share_importers_by_country_data(2:end)'));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');

% 4. Fixed costs variance decomposition (Referee comment 2a)

fc_mean_guess             = beta_hat(2:5);
fc_disp_guess             = beta_hat(6);
fc_mean                   = fc_mean_guess(1) .* ((m.distw').^fc_mean_guess(2)) .* (fc_mean_guess(3).^(m.comlang_off')) .*exp(-fc_mean_guess(4) .*m.control_corr') ;
fc_mat                    = bsxfun(@times,fc_mean,exp(min(m.fc_shock_randn.*fc_disp_guess,709)));  % m.S x m.N
fc_mat(:,1)               = 0; % zero f.c. for domestic sourcing              % US COMES FIRST

between_variance_fc       = size(fc_mat(:,2:end),1) * sum((mean(fc_mat(:,2:end),1) - mean(mean(fc_mat(:,2:end),1))).^2);
within_variance_fc        = sum(sum((bsxfun(@minus,fc_mat(:,2:end),mean(fc_mat(:,2:end),1))).^2));
between_variance_fc_share = between_variance_fc  / (between_variance_fc + within_variance_fc);
within_variance_fc_share  = within_variance_fc  / (between_variance_fc + within_variance_fc);

%Code below is from MATLAB's ANOVA routine. It does the same as the above.
%[decomp_res,decomp_results]                 = anova1(fc_mat,[],'off');
%FracColSS = decomp_results{2,2}/decomp_results{4,2}
%FracErrorSS = decomp_results{3,2}/decomp_results{4,2}

fid = fopen('Est_Variance_Decomposition.tex','w');
fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{Variance Decomposition of Estimated Fixed Costs of Entry}}\\label{tab:vardecomp} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular*}{.82\\textwidth}{cc} \n \\hline \n \\hline \\\\ \n');
% %The Headers...
fprintf(fid, ' Country-Level Variation (Fraction) & Firm-Country-Level Variation (Fraction) \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 
% %The Guts...
fprintf(fid, ' %.3f & %.3f \\\\ \n',between_variance_fc_share,within_variance_fc_share )
% %The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} This table reports the variance decomposition of the simulated fixed costs of entry. It reports the sum of squares due to firm-level variation and country-level variation divided by the total sum of squares.} \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');



% 5. Table with estimates for selected countries (equivalent to data in Table 1) 

% [temps, tempi]                  = sort(m.exp_fe_est(2:end),'descend');   % DONE NOW IN SETUP STRUCT
% rank_sourcing_potential(tempi)  = 1:1:m.N-1;
[temps, tempi]                  = sort(fc_mean(2:end)','ascend');
rank_fixed_costs(tempi)         = 1:1:m.N-1;
share_agg_imports               = agg_imports_baseline(2:end) / sum(agg_imports_baseline(2:end));

fileID = fopen('Table1replica.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Table 1 in the simulated model}\\label{tab:table1_replica} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcccc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' & Rank of Sourcing Potential & Rank of Fixed Costs & Share of Importers & Share of Imports  \\\\ \n');
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'Canada & %.0f  & %.0f & %.3f & %.3f \\\\ \n',              rank_sourcing_potential(can_ctr_ind- 1),rank_fixed_costs(can_ctr_ind- 1),share_importers_by_country(can_ctr_ind)/ share_importers,share_agg_imports(can_ctr_ind- 1));
fprintf(fileID, 'China & %.0f  & %.0f  & %.3f & %.3f \\\\ \n',                 rank_sourcing_potential(chn_ctr_ind- 1),rank_fixed_costs(chn_ctr_ind- 1),share_importers_by_country(chn_ctr_ind)/ share_importers,share_agg_imports(chn_ctr_ind- 1));
fprintf(fileID, 'Germany & %.0f  & %.0f & %.3f & %.3f \\\\ \n',            rank_sourcing_potential(ger_ctr_ind- 1),rank_fixed_costs(ger_ctr_ind- 1),share_importers_by_country(ger_ctr_ind)/ share_importers,share_agg_imports(ger_ctr_ind- 1));
fprintf(fileID, 'UK & %.0f  & %.0f & %.3f & %.3f \\\\ \n',                       rank_sourcing_potential(gbr_ctr_ind- 1),rank_fixed_costs(gbr_ctr_ind- 1),share_importers_by_country(gbr_ctr_ind)/ share_importers,share_agg_imports(gbr_ctr_ind- 1));
fprintf(fileID, 'Taiwan & %.0f  & %.0f & %.3f  & %.3f \\\\ \n',               rank_sourcing_potential(twn_ctr_ind- 1),rank_fixed_costs(twn_ctr_ind- 1),share_importers_by_country(twn_ctr_ind)/ share_importers,share_agg_imports(twn_ctr_ind- 1));
fprintf(fileID, 'Italy & %.0f  & %.0f & %.3f  & %.3f \\\\ \n',                     rank_sourcing_potential(ita_ctr_ind- 1),rank_fixed_costs(ita_ctr_ind- 1),share_importers_by_country(ita_ctr_ind)/ share_importers,share_agg_imports(ita_ctr_ind- 1));
fprintf(fileID, 'Japan & %.0f  & %.0f & %.3f  & %.3f \\\\ \n',                 rank_sourcing_potential(jpn_ctr_ind- 1),rank_fixed_costs(jpn_ctr_ind- 1),share_importers_by_country(jpn_ctr_ind)/ share_importers,share_agg_imports(jpn_ctr_ind- 1));
fprintf(fileID, 'Mexico & %.0f  & %.0f & %.3f  & %.3f \\\\ \n',               rank_sourcing_potential(mex_ctr_ind- 1),rank_fixed_costs(mex_ctr_ind- 1),share_importers_by_country(mex_ctr_ind)/ share_importers,share_agg_imports(mex_ctr_ind- 1));
fprintf(fileID, 'France & %.0f  & %.0f & %.3f  & %.3f \\\\ \n',               rank_sourcing_potential(fra_ctr_ind- 1),rank_fixed_costs(fra_ctr_ind- 1),share_importers_by_country(fra_ctr_ind)/ share_importers,share_agg_imports(fra_ctr_ind- 1));
fprintf(fileID, 'South Korea & %.0f  & %.0f & %.3f  & %.3f \\\\ \n',      rank_sourcing_potential(kor_ctr_ind- 1),rank_fixed_costs(kor_ctr_ind- 1),share_importers_by_country(kor_ctr_ind)/ share_importers,share_agg_imports(kor_ctr_ind- 1));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} Rank for fixed costs (sourcing potential) is calculated such that a low fixed cost (high sourcing potential) country has the highest rank.} \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');

[temps, tempi]                                                 = sort(m.num_firms_by_country_data(2:end)','descend');
rank_country_num_firms_data(tempi)         = 1:1:m.N-1;
[temps, tempi]                                                 = sort(m.agg_imports_data(2:end)','descend');
rank_country_agg_imports_data(tempi)         = 1:1:m.N-1;

fileID = fopen('Table1replicaWithData.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\scalebox{.8}{ \n');
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Table 1 in the simulated model and data}\\label{tab:table1_replica_with_data} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcccccccc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' &\\multicolumn{4}{c}{Model}  &\\multicolumn{4}{c}{Data}  \\\\ \n');
fprintf(fileID, ' & Rank by  & Rank by  & Share of  & Share of  & Rank by  & Rank by  & Share of  & Share of  \\\\ \n');
fprintf(fileID, ' & Sourcing Potential & Fixed Costs & Importers & Imports & Firms & Value & Importers & Imports \\\\ \n');

fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'Canada & %.0f  & %.0f & %.3f & %.3f  & %.0f  & %.0f & %.3f & %.3f \\\\ \n',        rank_sourcing_potential(can_ctr_ind- 1),rank_fixed_costs(can_ctr_ind- 1),share_importers_by_country(can_ctr_ind)/ share_importers,share_agg_imports(can_ctr_ind- 1), rank_country_num_firms_data(can_ctr_ind- 1), rank_country_agg_imports_data(can_ctr_ind- 1) ,m.num_firms_by_country_data(can_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(can_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'China & %.0f  & %.0f  & %.3f & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',            rank_sourcing_potential(chn_ctr_ind- 1),rank_fixed_costs(chn_ctr_ind- 1),share_importers_by_country(chn_ctr_ind)/ share_importers,share_agg_imports(chn_ctr_ind- 1), rank_country_num_firms_data(chn_ctr_ind- 1), rank_country_agg_imports_data(chn_ctr_ind- 1) ,m.num_firms_by_country_data(chn_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(chn_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'Germany & %.0f  & %.0f & %.3f & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',        rank_sourcing_potential(ger_ctr_ind- 1),rank_fixed_costs(ger_ctr_ind- 1),share_importers_by_country(ger_ctr_ind)/ share_importers,share_agg_imports(ger_ctr_ind- 1),rank_country_num_firms_data(ger_ctr_ind- 1), rank_country_agg_imports_data(ger_ctr_ind- 1) ,m.num_firms_by_country_data(ger_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(ger_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'UK & %.0f  & %.0f & %.3f & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',                  rank_sourcing_potential(gbr_ctr_ind- 1),rank_fixed_costs(gbr_ctr_ind- 1),share_importers_by_country(gbr_ctr_ind)/ share_importers,share_agg_imports(gbr_ctr_ind- 1),rank_country_num_firms_data(gbr_ctr_ind- 1), rank_country_agg_imports_data(gbr_ctr_ind- 1) ,m.num_firms_by_country_data(gbr_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(gbr_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'Taiwan & %.0f  & %.0f & %.3f  & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',          rank_sourcing_potential(twn_ctr_ind- 1),rank_fixed_costs(twn_ctr_ind- 1),share_importers_by_country(twn_ctr_ind)/ share_importers,share_agg_imports(twn_ctr_ind- 1),rank_country_num_firms_data(twn_ctr_ind- 1), rank_country_agg_imports_data(twn_ctr_ind- 1) ,m.num_firms_by_country_data(twn_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(twn_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'Italy & %.0f  & %.0f & %.3f  & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',                rank_sourcing_potential(ita_ctr_ind- 1),rank_fixed_costs(ita_ctr_ind- 1),share_importers_by_country(ita_ctr_ind)/ share_importers,share_agg_imports(ita_ctr_ind- 1),rank_country_num_firms_data(ita_ctr_ind- 1), rank_country_agg_imports_data(ita_ctr_ind- 1) ,m.num_firms_by_country_data(ita_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(ita_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'Japan & %.0f  & %.0f & %.3f  & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',            rank_sourcing_potential(jpn_ctr_ind- 1),rank_fixed_costs(jpn_ctr_ind- 1),share_importers_by_country(jpn_ctr_ind)/ share_importers,share_agg_imports(jpn_ctr_ind- 1),rank_country_num_firms_data(jpn_ctr_ind- 1), rank_country_agg_imports_data(jpn_ctr_ind- 1) ,m.num_firms_by_country_data(jpn_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(jpn_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'Mexico & %.0f  & %.0f & %.3f  & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',          rank_sourcing_potential(mex_ctr_ind- 1),rank_fixed_costs(mex_ctr_ind- 1),share_importers_by_country(mex_ctr_ind)/ share_importers,share_agg_imports(mex_ctr_ind- 1),rank_country_num_firms_data(mex_ctr_ind- 1), rank_country_agg_imports_data(mex_ctr_ind- 1) ,m.num_firms_by_country_data(mex_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(mex_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'France & %.0f  & %.0f & %.3f  & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n',          rank_sourcing_potential(fra_ctr_ind- 1),rank_fixed_costs(fra_ctr_ind- 1),share_importers_by_country(fra_ctr_ind)/ share_importers,share_agg_imports(fra_ctr_ind- 1),rank_country_num_firms_data(fra_ctr_ind- 1), rank_country_agg_imports_data(fra_ctr_ind- 1) ,m.num_firms_by_country_data(fra_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(fra_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
fprintf(fileID, 'South Korea & %.0f  & %.0f & %.3f  & %.3f & %.0f  & %.0f & %.3f & %.3f \\\\ \n', rank_sourcing_potential(kor_ctr_ind- 1),rank_fixed_costs(kor_ctr_ind- 1),share_importers_by_country(kor_ctr_ind)/ share_importers,share_agg_imports(kor_ctr_ind- 1),rank_country_num_firms_data(kor_ctr_ind- 1), rank_country_agg_imports_data(kor_ctr_ind- 1) ,m.num_firms_by_country_data(kor_ctr_ind) ./ m.num_importing_firms_data, m.agg_imports_data(kor_ctr_ind) ./ sum(m.agg_imports_data(2:end)));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} Rank for fixed costs (sourcing potential) is calculated such that a low fixed cost (high sourcing potential) country has the highest rank. } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable}} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');

% 6. Table Hierarchies (model's equivalent to data in Table 4 in the paper)

string_top10data          = zeros(length(input_p_mat),10);
string_top10data(:,1)   = input_p_mat(:,can_ctr_ind) >0;
string_top10data(:,2)   = input_p_mat(:,chn_ctr_ind) >0;
string_top10data(:,3)   = input_p_mat(:,ger_ctr_ind) >0;
string_top10data(:,4)   = input_p_mat(:,gbr_ctr_ind) >0;
string_top10data(:,5)   = input_p_mat(:,twn_ctr_ind) >0;
string_top10data(:,6)   = input_p_mat(:,ita_ctr_ind) >0;
string_top10data(:,7)   = input_p_mat(:,jpn_ctr_ind) >0;
string_top10data(:,8)   = input_p_mat(:,mex_ctr_ind) >0;
string_top10data(:,9)   = input_p_mat(:,fra_ctr_ind) >0;
string_top10data(:,10) = input_p_mat(:,kor_ctr_ind)>0;

fileID = fopen('Table4replica.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Table 4 in the simulated model}\\label{tab:table4_replica} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' String & Percentage of Importers  \\\\ \n');
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'CA &  %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,0,0,0,0,0,0,0,0,0],length(string_top10data),1),2) == 10)) / share_importers);
fprintf(fileID, 'CA-CH & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,0,0,0,0,0,0,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,0,0,0,0,0,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,0,0,0,0,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB-TW & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,1,0,0,0,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB-TW-IT & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,1,1,0,0,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB-TW-IT-JP & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,1,1,1,0,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB-TW-IT-JP-MX & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,1,1,1,1,0,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB-TW-IT-JP-MX-FR & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,1,1,1,1,1,0],length(string_top10data),1),2) == 10))/ share_importers);
fprintf(fileID, 'CA-CH-DE-GB-TW-IT-JP-MX-FR-KR & %.2f  \\\\ \n',100*sum(m.weights_prod(sum(string_top10data == repmat([1,1,1,1,1,1,1,1,1,1],length(string_top10data),1),2) == 10))/ share_importers);
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} ... } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');



% 7. Scatter Plot: Sourcing Potential and Estimated Fixed Cost (Ref comment 2a)
%NB: I've downloaded the file lscatter to make this code work

%Create the Cell Array with country labels.
ISO_LAB = java_array('java.lang.String', 66);
ISO_LAB(1) = java.lang.String('CAN');
ISO_LAB(2) = java.lang.String('MEX');
ISO_LAB(3) = java.lang.String('GTM');
ISO_LAB(4) = java.lang.String('SLV');
ISO_LAB(5) = java.lang.String('HND');
ISO_LAB(6) = java.lang.String('CRI');
ISO_LAB(7) = java.lang.String('PAN');
ISO_LAB(8) = java.lang.String('DOM');
ISO_LAB(9) = java.lang.String('TTO');
ISO_LAB(10) = java.lang.String('COL');
ISO_LAB(11) = java.lang.String('VEN');
ISO_LAB(12) = java.lang.String('ECU');
ISO_LAB(13) = java.lang.String('PER');
ISO_LAB(14) = java.lang.String('CHL');
ISO_LAB(15) = java.lang.String('BRA');
ISO_LAB(16) = java.lang.String('ARG');
ISO_LAB(17) = java.lang.String('SWE');
ISO_LAB(18) = java.lang.String('NOR');
ISO_LAB(19) = java.lang.String('FIN');
ISO_LAB(20) = java.lang.String('DNK');
ISO_LAB(21) = java.lang.String('GBR');
ISO_LAB(22) = java.lang.String('IRL');
ISO_LAB(23) = java.lang.String('NLD');
ISO_LAB(24) = java.lang.String('BEL');
ISO_LAB(25) = java.lang.String('LUX');
ISO_LAB(26) = java.lang.String('FRA');
ISO_LAB(27) = java.lang.String('DEU');
ISO_LAB(28) = java.lang.String('AUT');
ISO_LAB(29) = java.lang.String('CZE');
ISO_LAB(30) = java.lang.String('SVK');
ISO_LAB(31) = java.lang.String('HUN');
ISO_LAB(32) = java.lang.String('CHE');
ISO_LAB(33) = java.lang.String('POL');
ISO_LAB(34) = java.lang.String('RUS');
ISO_LAB(35) = java.lang.String('UKR');
ISO_LAB(36) = java.lang.String('ESP');
ISO_LAB(37) = java.lang.String('PRT');
ISO_LAB(38) = java.lang.String('ITA');
ISO_LAB(39) = java.lang.String('SVN');
ISO_LAB(40) = java.lang.String('GRC');
ISO_LAB(41) = java.lang.String('ROM');
ISO_LAB(42) = java.lang.String('BGR');
ISO_LAB(43) = java.lang.String('TUR');
ISO_LAB(44) = java.lang.String('ISR');
ISO_LAB(45) = java.lang.String('SAU');
ISO_LAB(46) = java.lang.String('ARE');
ISO_LAB(47) = java.lang.String('IND');
ISO_LAB(48) = java.lang.String('PAK');
ISO_LAB(49) = java.lang.String('BGD');
ISO_LAB(50) = java.lang.String('LKA');
ISO_LAB(51) = java.lang.String('THA');
ISO_LAB(52) = java.lang.String('VNM');
ISO_LAB(53) = java.lang.String('MYS');
ISO_LAB(54) = java.lang.String('SGP');
ISO_LAB(55) = java.lang.String('IDN');
ISO_LAB(56) = java.lang.String('PHL');
ISO_LAB(57) = java.lang.String('MAC');
ISO_LAB(58) = java.lang.String('CHN');
ISO_LAB(59) = java.lang.String('KOR');
ISO_LAB(60) = java.lang.String('HKG');
ISO_LAB(61) = java.lang.String('TWN');
ISO_LAB(62) = java.lang.String('JPN');
ISO_LAB(63) = java.lang.String('AUS');
ISO_LAB(64) = java.lang.String('NZL');
ISO_LAB(65) = java.lang.String('EGY');
ISO_LAB(66) = java.lang.String('ZAF');

LAB = cell(ISO_LAB);
mean_fc = mean(fc_mat);
hold on
lscatter(m.exp_fe_est([2:15,17,19:20,22:35,37:41,43:53,56:61,63,65:67]),mean_fc([2:15,17,19:20,22:35,37:41,43:53,56:61,63,65:67]),LAB([1:14,16,18:19,21:34,36:40,42:52,55:60,62,64:66]),'Marker','.','VerticalAlignment','bottom','MarkerEdgeColor','k')
set(gca,'xscale','log');
set(gca,'yscale','log');
axisLimits = axis; % get the current limits
axis([.8 * min(m.exp_fe_est(2:67)), 1.2 * max(m.exp_fe_est(2:67)), .95 * min(mean_fc(2:67)), 1.15* max(mean_fc(2:67))]) % reset x-axis and y-axis limits
xlabel('Sourcing Potential')
ylabel('Median Fixed Cost')
lscatter(m.exp_fe_est([16,18,21,36,42,54,55,62,64]),mean_fc([16,18,21,36,42,54,55,62,64]),LAB([15,17,20,35,41,53,54,61,63]),'Marker','.','VerticalAlignment','top','MarkerEdgeColor','k')
saveas(gcf,'mean_fc_versus_sourcing_potential','epsc')
hold off



mean_fc = mean(fc_mat);
lscatter(m.exp_fe_est(2:67),mean_fc(2:67),LAB)    %Generate the scatter plot
set(gca,'xscale','log');
set(gca,'yscale','log');
axisLimits = axis; % get the current limits
axis([.8 * min(m.exp_fe_est(2:67)), 1.2 * max(m.exp_fe_est(2:67)), .95 * min(mean_fc(2:67)), 1.15* max(mean_fc(2:67))]) % reset x-axis and y-axis limits
xlabel('Sourcing Potential')
ylabel('Median Fixed Cost')
saveas(gcf,'mean_fc_versus_sourcing_potential','epsc')


%lscatter(log(m.exp_fe_est(2:67)),log(mean_fc(2:67)),LAB)    %Generate the scatter plot
%xlabel('log(Sourcing Potential)')
%ylabel('log(Median Fixed Cost)')
%saveas(gcf,'mean_fc_versus_sourcing_potential_log','epsc')

% 8. Jia cardinality of bound differences

stat_gap_total = sum(stat_gap_all,1);

fileID = fopen('jia_stat_table.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Jia statistics table}\\label{tab:fc_median} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcccccccccccc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'Cardinality of difference in bounds  & 0 & 1 & 2 & 3 & 4 & 5 & 6 & 7 & 8 & 9 & 10-25 & $\\geq 26$  \\\\ \n');
fprintf(fileID, 'Number of occasions & %.0f  & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\ \n',stat_gap_total(1),stat_gap_total(2),stat_gap_total(3),stat_gap_total(4), ...
    stat_gap_total(5),stat_gap_total(6),stat_gap_total(7),stat_gap_total(8),stat_gap_total(9),stat_gap_total(10),sum(stat_gap_total(11:26)),sum(stat_gap_total(27:end)));
%fprintf(fileID, 'Share of occasions & %.0f  & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\ \n',stat_gap_total(1)/sum(stat_gap_total),stat_gap_total(2)/sum(stat_gap_total),stat_gap_total(3)/sum(stat_gap_total),stat_gap_total(4)/sum(stat_gap_total), ...
%    stat_gap_total(5)/sum(stat_gap_total),stat_gap_total(6)/sum(stat_gap_total),stat_gap_total(7)/sum(stat_gap_total),stat_gap_total(8)/sum(stat_gap_total),stat_gap_total(9)/sum(stat_gap_total),sum(stat_gap_total(10:26))/sum(stat_gap_total),sum(stat_gap_total(27:end))/sum(stat_gap_total));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} ... } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');


%% Additional Figures and Tables

%ONLY EXTERNAL

% Figure percentiles by market 
% Median data and model
% loglog(median_input_purchase(2:end),m.imports50_data(2:end)','bo')
% hold on
% dummy_for_plot = (10^(-1.6):1/1000:10^(-1));
% plot(dummy_for_plot,dummy_for_plot,'k--')
% xlabel('model')
% ylabel('data')
% saveas(gcf,'median_purchases_pred_act','epsc')
% hold off

% 90th percentile data and model
% loglog(perc90_input_purchase(2:end),m.imports90_data(2:end)','bo')
% hold on
% dummy_for_plot = (1:1/1000:10);
% plot(dummy_for_plot,dummy_for_plot,'k--')
% xlabel('model')
% ylabel('data')
% saveas(gcf,'perc90_purchases_pred_act','epsc')
% hold off


disp('Domestic median model:')
disp(median_input_purchase(1))
disp('Domestic median data:')
%m.imports50_data(1)
m.US_median_dom_input

% disp('Domestic 90th percentile model:')
% disp(perc90_input_purchase(1))
% disp('Domestic 90th percentile data:')
% m.imports90_data(1)

% Table domestic input purchase
fileID = fopen('TableDomesticPurchases.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Domestic Sourcing}\\label{tab:fc_median} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' & Data & Model  \\\\ \n');
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
% fprintf(fileID, 'Domestic median  & %.3f  & %.3f \\\\ \n',m.imports50_data(1),median_input_purchase(1));
% fprintf(fileID, 'Domestic 90th percentile & %.3f  & %.3f \\\\ \n',m.imports90_data(1),perc90_input_purchase(1));
fprintf(fileID, 'Domestic median  & %.3f  & %.3f \\\\ \n',m.US_median_dom_input,median_input_purchase(1));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} ... } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');



% Premium plot in the model 
num_locations=sum(input_p_mat>0,2);
reg_loc_dummies = zeros(size(sales_vec));
for k = 2:25
reg_loc_dummies(:,k-1) = (num_locations > k);
end
%unweighted
%premium_coeff = (reg_loc_dummies' * reg_loc_dummies) \ (reg_loc_dummies' * log(sales_vec));
% weighted
premium_coeff = lscov(reg_loc_dummies,log(sales_vec),m.weights_prod);
premium_coeff = [0; premium_coeff];
premium_cumulative = cumsum(premium_coeff);
plot(1:1:25,premium_cumulative)
xlabel('Minimum number of countries from which firm sources')
ylabel('Premium')
saveas(gcf,'Sales_premia_number_countries','epsc')

% Rank Rank plot in the model

[temps, tempi]          = sort(agg_imports_baseline(2:end),'descend');
rank_agg_import(tempi)  = 1:1:m.N-1;
[temps, tempi]          = sort(share_importers_by_country(2:end),'descend');
rank_num_imports(tempi)  = 1:1:m.N-1;      
dummy_for_plot = (1:1:m.N);
plot(dummy_for_plot,dummy_for_plot,'k--')
hold on
text(rank_num_imports',rank_agg_import',country_data.textdata(3:end,2))
xlabel('Rank Number of Firms')
ylabel('Rank Total Imports')
saveas(gcf,'rank_rank_plot','epsc')
hold off




% Number of production locations
[histw, vinterval] = histwc(num_locations, m.weights_prod, 65);
bar(vinterval, histw) 
xlabel('Number of sourcing countries')
ylabel('Share of firms')
saveas(gcf,'Histogram_number_countries','epsc')


% Table share importers

fileID = fopen('Share_importers_countries.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{Share importers selected countries}\\label{tab:share_importers} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' & Data & Model  \\\\ \n');
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'Any foreign country  & %.3f  & %.3f \\\\ \n',m.num_importing_firms_data/m.num_all_firms_data,share_importers);
fprintf(fileID, 'Canada & %.3f  & %.3f \\\\ \n',m.num_firms_by_country_data(can_ctr_ind) ./ m.num_all_firms_data,share_importers_by_country(can_ctr_ind));
fprintf(fileID, 'Mexico & %.3f  & %.3f \\\\ \n',m.num_firms_by_country_data(mex_ctr_ind) ./ m.num_all_firms_data,share_importers_by_country(mex_ctr_ind));
fprintf(fileID, 'China & %.3f  & %.3f \\\\ \n',m.num_firms_by_country_data(chn_ctr_ind) ./ m.num_all_firms_data,share_importers_by_country(chn_ctr_ind));
fprintf(fileID, 'Taiwan & %.3f  & %.3f \\\\ \n',m.num_firms_by_country_data(twn_ctr_ind) ./ m.num_all_firms_data,share_importers_by_country(twn_ctr_ind));
fprintf(fileID, 'Germany & %.3f  & %.3f \\\\ \n',m.num_firms_by_country_data(ger_ctr_ind) ./ m.num_all_firms_data,share_importers_by_country(ger_ctr_ind));
fprintf(fileID, 'UK & %.3f  & %.3f \\\\ \n',m.num_firms_by_country_data(gbr_ctr_ind) ./ m.num_all_firms_data,share_importers_by_country(gbr_ctr_ind));
%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} ... } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');


% Aggregate imports data and model 
loglog(agg_imports_baseline,m.agg_imports_data,'bo')
hold on
dummy_for_plot = (.8 * min(m.agg_imports_data): range(m.agg_imports_data)/1000:max(m.agg_imports_data)*1.2);
plot(dummy_for_plot,dummy_for_plot,'k--')
xlabel('model')
ylabel('data')
saveas(gcf,'agg_importer_model_data','epsc')
hold off


fileID = fopen('TableAggImportsShare.tex','w');
fprintf(fileID, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fileID, '\\begin{threeparttable} \n');
fprintf(fileID, '\\caption{TableAggImportsShare}\\label{tab:fc_median} \n');
fprintf(fileID, '\\vspace{0.05in} \n \\begin{tabular}{lcc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fileID, ' & Data & Model  \\\\ \n');
fprintf(fileID, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fileID, 'Share of agg imports in total sourcing  & %.3f  & %.3f \\\\ \n',sum(m.agg_imports_data(2:end))/sum(m.agg_imports_data),sum(agg_imports_baseline(2:end))/sum(agg_imports_baseline));
fprintf(fileID, 'Share of China in agg imports & %.3f  & %.3f \\\\ \n',m.agg_imports_data(chn_ctr_ind)/sum(m.agg_imports_data(2:end)),agg_imports_baseline(chn_ctr_ind)/sum(agg_imports_baseline(2:end)));

%The bottom
fprintf(fileID, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fileID, '\\begin{tablenotes}[para] \n')
fprintf(fileID, ' \\footnotesize{\\textit{Notes:} ... } \n');
fprintf(fileID, '\\end{tablenotes} \n');
fprintf(fileID, '\\end{threeparttable} \n')
fprintf(fileID, '\\end{center} \n \\end{table} \n');









% % Fit share of firms by country
% 
% text(share_importers_by_country,(m.num_firms_by_country_data/m.num_all_firms_data)',country_data.textdata(2:end,2)')
% xlabel('Share of firms importing from this country MODEL')
% ylabel('Share of firms importing from this country DATA')
% saveas(gcf,'share_of_firms_by_country_fit','epsc')


