

%%

% Compare aggregate input purchases by country

%m.weights_prod(m.prod_draw_uniform>0.99) = 0;

agg_imports_counter_free = M_free_entry_post * sum(bsxfun(@times,input_p_mat_counter_free,m.weights_prod),1);

relative_agg_imports = agg_imports_counter_free ./ agg_imports_baseline;
[sortedValues,sortIndex] = sort(relative_agg_imports(:),'descend');


% Look at firm-level stuff
change_dom = input_p_mat_counter_free(:,1) ./ input_p_mat(:,1);
interesting_firms = change_dom > 1;
disp('Num of firms that increase domestic sourcing')
sum(interesting_firms)


check = num_locations(interesting_firms);
chinese_before = input_p_mat(:,chn_ctr_ind);
check_china_before=chinese_before(interesting_firms); 
chinese_after = input_p_mat_counter_free(:,chn_ctr_ind);
check_china_after = chinese_after(interesting_firms);
new_importers_from_china = (chinese_after > 0) - (chinese_before >0 );
disp('Num of new_importers_from_china')
sum(new_importers_from_china)

% Gross and Net employment effects

dom_sourcing_counter_free  = input_p_mat_counter_free(:,1) ;
dom_sourcing_baseline = input_p_mat(:,1);

gross_domestic_sourc_increase = sum(bsxfun(@times,(dom_sourcing_counter_free-dom_sourcing_baseline) .*((dom_sourcing_counter_free-dom_sourcing_baseline) >0),m.weights_prod),1);
gross_domestic_sourc_decrease = sum(bsxfun(@times,(dom_sourcing_counter_free-dom_sourcing_baseline) .*((dom_sourcing_counter_free-dom_sourcing_baseline) <0),m.weights_prod),1);

%% Firm level results

% 1. Relative total imports (previous importers)
relative_firm_total = sum(input_p_mat_counter_free(:,2:end),2) ./ sum(input_p_mat(:,2:end),2);
relative_firm_total = relative_firm_total(sum(input_p_mat(:,2:end),2)>0);
weight_relative_firm_total = m.weights_prod(sum(input_p_mat(:,2:end),2)>0);
[histw, vinterval] = histwc(relative_firm_total, weight_relative_firm_total, 100);
% Visualize
bar(vinterval, histw) 
%hist(relative_firm_total,50)
xlabel('Relative Total Imports (previous importers)')
ylabel('Share of firms')
saveas(gcf,'counter_relative_total_imports','epsc')

% 2. Relative Dom Sourcing (all firms)

% [histw, vinterval] = histwc(sum(input_p_mat_counter_free(:,1),2) ./ sum(input_p_mat(:,1),2), m.weights_prod, 100);
% %hist(sum(input_p_mat_counter_free(:,1),2) ./ sum(input_p_mat(:,1),2),50)
% bar(vinterval, histw) 
% xlabel('Relative Domestic Sourcing (all firms)')
% ylabel('Share of firms')
% saveas(gcf,'counter_relative_domestic_sourcing','epsc')
% 
% % 3. Rel. China Sourcing (previous China importers) 
% 
% relative_firm_china = sum(input_p_mat_counter_free(:,chn_ctr_ind),2) ./ sum(input_p_mat(:,chn_ctr_ind),2);
% relative_firm_china = relative_firm_china(input_p_mat(:,chn_ctr_ind)>0);
% weight_relative_firm_china = m.weights_prod(input_p_mat(:,chn_ctr_ind)>0);
% [histw, vinterval] = histwc(relative_firm_china, weight_relative_firm_china, 100);
% %hist(relative_firm_china,50)
% bar(vinterval, histw) 
% xlabel('Relative Imports from China (previous importers from China)')
% ylabel('Share of firms')
% saveas(gcf,'counter_relative_china_imports','epsc')

% 4. Difference in the Number of importing countries (all firms)

diff_num_countries = sum(input_p_mat_counter_free>0,2) - sum(input_p_mat>0,2) ;
[histw, vinterval] = histwc(diff_num_countries, m.weights_prod, 100);
bar(vinterval, histw) 
%hist(diff_num_countries,50)
xlabel('Difference in the number of import countries (all firms)')
ylabel('Share of firms')
saveas(gcf,'counter_diff_num_countries','epsc')

% 5. New importers and exiters Table

%% Changed B

% Table Statistics on Entrants, Exiters, ...

entrants_china_id = (input_p_mat_counter_free(:,chn_ctr_ind)>0 ) & ( input_p_mat(:,chn_ctr_ind) == 0 );
exit_china_id     = (input_p_mat_counter_free(:,chn_ctr_ind)== 0 ) & ( input_p_mat(:,chn_ctr_ind) > 0 );
cont_china_id     = (input_p_mat_counter_free(:,chn_ctr_ind)>0 ) & ( input_p_mat(:,chn_ctr_ind) > 0 );
non_china_id      = (input_p_mat_counter_free(:,chn_ctr_ind)==0 ) & ( input_p_mat(:,chn_ctr_ind) == 0 );

dom_sourcing_after = input_p_mat_counter_free(:,1);
dom_sourcing       =  input_p_mat(:,1);

imp_other_after    = sum(input_p_mat_counter_free,2) - input_p_mat_counter_free(:,1) - input_p_mat_counter_free(:,chn_ctr_ind);
imp_other          = sum(input_p_mat,2) - input_p_mat(:,1) - input_p_mat(:,chn_ctr_ind);

imp_china_after    = input_p_mat_counter_free(:,chn_ctr_ind); 
imp_china          = input_p_mat(:,chn_ctr_ind);

%fid = 1; % Print to screen
fid = fopen('third_country_effects_table.tex','w');
% Use \\ to produce a backslash character
% \n new line

fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{Third country sourcing effects of Positive Chinese Sourcing Potential shock}}\\label{tab:entryexit} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular}{lccccc} \n \\hline \n \\hline \\\\ \n');

%The Headers...
fprintf(fid, ' Chinese & Change sourcing & Change Sourcing & Change Sourcing & Share & Share of   \\\\ \n');
fprintf(fid, ' import status & from US & from other countries & from China & of firms & China imports \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 

%The Guts...
% fprintf(fid, ' Entrants & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(entrants_china_id)) / sum(dom_sourcing(entrants_china_id)),sum(imp_other_after(entrants_china_id)) / sum(imp_other(entrants_china_id)) ,sum(m.weights_prod(entrants_china_id)))
% fprintf(fid, ' Exiters &  %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(exit_china_id)) / sum(dom_sourcing(exit_china_id)), sum(imp_other_after(exit_china_id)) / sum(imp_other(exit_china_id)) , sum(m.weights_prod(exit_china_id)))
% fprintf(fid, ' Continuers &  %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(cont_china_id)) / sum(dom_sourcing(cont_china_id)), sum(imp_other_after(cont_china_id)) / sum(imp_other(cont_china_id)),sum(m.weights_prod(cont_china_id)))
% fprintf(fid, ' Others &  %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(non_china_id)) / sum(dom_sourcing(non_china_id)), sum(imp_other_after(non_china_id)) / sum(imp_other(non_china_id)) , sum(m.weights_prod(non_china_id)))
fprintf(fid, ' Entrants & %.3f & %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(entrants_china_id) .* m.weights_prod(entrants_china_id)) / sum(dom_sourcing(entrants_china_id) .* m.weights_prod(entrants_china_id)),sum(imp_other_after(entrants_china_id) .*m.weights_prod(entrants_china_id) ) / sum(imp_other(entrants_china_id) .* m.weights_prod(entrants_china_id)) ,sum(imp_china_after(entrants_china_id) .*m.weights_prod(entrants_china_id) ) / sum(imp_china(entrants_china_id) .* m.weights_prod(entrants_china_id)) , sum(m.weights_prod(entrants_china_id)),sum(imp_china_after(entrants_china_id) .*m.weights_prod(entrants_china_id) ) / sum(imp_china_after .*m.weights_prod ))
fprintf(fid, ' Exiters &  %.3f & %.3f & %.3f & %.3f  & %.3f \\\\ \n',sum(dom_sourcing_after(exit_china_id) .* m.weights_prod(exit_china_id)) / sum(dom_sourcing(exit_china_id) .*m.weights_prod(exit_china_id)), sum(imp_other_after(exit_china_id) .*m.weights_prod(exit_china_id)) / sum(imp_other(exit_china_id) .* m.weights_prod(exit_china_id)) , sum(imp_china_after(exit_china_id) .*m.weights_prod(exit_china_id)) / sum(imp_china(exit_china_id) .* m.weights_prod(exit_china_id)) , sum(m.weights_prod(exit_china_id)),sum(imp_china_after(exit_china_id) .*m.weights_prod(exit_china_id) ) / sum(imp_china_after .*m.weights_prod ))
fprintf(fid, ' Continuers &  %.3f & %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(cont_china_id).*m.weights_prod(cont_china_id)) / sum(dom_sourcing(cont_china_id).*m.weights_prod(cont_china_id)), sum(imp_other_after(cont_china_id).*m.weights_prod(cont_china_id)) / sum(imp_other(cont_china_id) .*m.weights_prod(cont_china_id)),sum(imp_china_after(cont_china_id).*m.weights_prod(cont_china_id)) / sum(imp_china(cont_china_id) .*m.weights_prod(cont_china_id)),sum(m.weights_prod(cont_china_id)),sum(imp_china_after(cont_china_id) .*m.weights_prod(cont_china_id) ) / sum(imp_china_after .*m.weights_prod ))
fprintf(fid, ' Others &  %.3f & %.3f & %.3f & %.3f  & %.3f \\\\ \n',sum(dom_sourcing_after(non_china_id).*m.weights_prod(non_china_id)) / sum(dom_sourcing(non_china_id) .* m.weights_prod(non_china_id)), sum(imp_other_after(non_china_id) .* m.weights_prod(non_china_id)) / sum(imp_other(non_china_id) .* m.weights_prod(non_china_id)) , sum(imp_china_after(non_china_id) .* m.weights_prod(non_china_id)) / sum(imp_china(non_china_id) .* m.weights_prod(non_china_id)) , sum(m.weights_prod(non_china_id)),sum(imp_china_after(non_china_id) .*m.weights_prod(non_china_id) ) / sum(imp_china_after .*m.weights_prod ))

%The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} This table contains only surviving firms. Entrants (exiters) are those firms that begin (stop) offshoring to China. Columns 1, 2 and 3 contain the ratio of the total sourcing by this group of firms before and after the counterfactual change.} \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');

% Table Statistics on Importers, Non-importers ...

importer_china_id = (input_p_mat_counter_free(:,chn_ctr_ind)>0 ) | ( input_p_mat(:,chn_ctr_ind) > 0 );

%fid = 1; % Print to screen
fid = fopen('third_country_effects_table_importer.tex','w');
% Use \\ to produce a backslash character
% \n new line

fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{Third country sourcing effects of Positive Chinese Sourcing Potential shock}}\\label{tab:importernonimporter} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular}{lcccc} \n \\hline \n \\hline \\\\ \n');

%The Headers...
fprintf(fid, ' Chinese & Change sourcing & Change Sourcing & Change Sourcing & Share  \\\\ \n');
fprintf(fid, ' import status & from US & from other countries & from China & of firms  \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 

%The Guts...
fprintf(fid, ' Importers & %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(importer_china_id) .* m.weights_prod(importer_china_id)) / sum(dom_sourcing(importer_china_id) .* m.weights_prod(importer_china_id)),sum(imp_other_after(importer_china_id) .*m.weights_prod(importer_china_id) ) / sum(imp_other(importer_china_id) .* m.weights_prod(importer_china_id)) ,sum(imp_china_after(importer_china_id) .*m.weights_prod(importer_china_id) ) / sum(imp_china(importer_china_id) .* m.weights_prod(importer_china_id)) , sum(m.weights_prod(importer_china_id)))
fprintf(fid, ' Non-importers &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(non_china_id).*m.weights_prod(non_china_id)) / sum(dom_sourcing(non_china_id) .* m.weights_prod(non_china_id)), sum(imp_other_after(non_china_id) .* m.weights_prod(non_china_id)) / sum(imp_other(non_china_id) .* m.weights_prod(non_china_id)) , sum(imp_china_after(non_china_id) .* m.weights_prod(non_china_id)) / sum(imp_china(non_china_id) .* m.weights_prod(non_china_id)) , sum(m.weights_prod(non_china_id)))

%The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} This table contains only surviving firms. Columns 1, 2 and 3 contain the ratio of the total sourcing by the respective group of firms before and after the counterfactual change.} \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');



%% Fixed B

entrants_china_id_FB  = (input_p_mat_counter(:,chn_ctr_ind)>0 ) & ( input_p_mat(:,chn_ctr_ind) == 0 );
exit_china_id_FB      = (input_p_mat_counter(:,chn_ctr_ind)== 0 ) & ( input_p_mat(:,chn_ctr_ind) > 0 );
cont_china_id_FB      = (input_p_mat_counter(:,chn_ctr_ind)>0 ) & ( input_p_mat(:,chn_ctr_ind) > 0 );
non_china_id_FB       = (input_p_mat_counter(:,chn_ctr_ind)==0 ) & ( input_p_mat(:,chn_ctr_ind) == 0 );

dom_sourcing_after_FB = input_p_mat_counter(:,1);
dom_sourcing          =  input_p_mat(:,1);

imp_other_after_FB    = sum(input_p_mat_counter,2) - input_p_mat_counter(:,1) - input_p_mat_counter(:,chn_ctr_ind);
imp_other             = sum(input_p_mat,2) - input_p_mat(:,1) - input_p_mat(:,chn_ctr_ind);

imp_china_after_FB    = input_p_mat_counter(:,chn_ctr_ind); 
imp_china             = input_p_mat(:,chn_ctr_ind);


fid = fopen('third_country_effects_table_fixedB.tex','w');
% Use \\ to produce a backslash character
% \n new line

fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{FIXED B: Third country sourcing effects of Positive Chinese Sourcing Potential shock}}\\label{tab:entryexit} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular}{lcccc} \n \\hline \n \\hline \\\\ \n');

%The Headers...
fprintf(fid, ' Chinese & Change sourcing & Change Sourcing & Share  \\\\ \n');
fprintf(fid, ' import status & from US & from other countries & of firms  \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 

%The Guts...
% fprintf(fid, ' Entrants & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(entrants_china_id_FB)) / sum(dom_sourcing(entrants_china_id_FB)),sum(imp_other_after(entrants_china_id_FB)) / sum(imp_other(entrants_china_id_FB)) ,sum(m.weights_prod(entrants_china_id_FB)))
% fprintf(fid, ' Exiters &  %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(exit_china_id_FB)) / sum(dom_sourcing(exit_china_id_FB)), sum(imp_other_after(exit_china_id_FB)) / sum(imp_other(exit_china_id_FB)) , sum(m.weights_prod(exit_china_id_FB)))
% fprintf(fid, ' Continuers &  %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(cont_china_id_FB)) / sum(dom_sourcing(cont_china_id_FB)), sum(imp_other_after(cont_china_id_FB)) / sum(imp_other(cont_china_id_FB)),sum(m.weights_prod(cont_china_id_FB)))
% fprintf(fid, ' Others &  %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after(non_china_id_FB)) / sum(dom_sourcing(non_china_id_FB)), sum(imp_other_after(non_china_id_FB)) / sum(imp_other(non_china_id_FB)) , sum(m.weights_prod(non_china_id_FB)))
fprintf(fid, ' Entrants & %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FB(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB)) / sum(dom_sourcing(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB)),sum(imp_other_after_FB(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB)) / sum(imp_other(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB)) ,sum(imp_china_after_FB(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB)) / sum(imp_china(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB)) ,sum(m.weights_prod(entrants_china_id_FB)))
fprintf(fid, ' Exiters &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FB(exit_china_id_FB).*m.weights_prod(exit_china_id_FB)) / sum(dom_sourcing(exit_china_id_FB).*m.weights_prod(exit_china_id_FB)), sum(imp_other_after_FB(exit_china_id_FB).*m.weights_prod(exit_china_id_FB)) / sum(imp_other(exit_china_id_FB).*m.weights_prod(exit_china_id_FB)) , sum(imp_china_after_FB(exit_china_id_FB).*m.weights_prod(exit_china_id_FB)) / sum(imp_china(exit_china_id_FB).*m.weights_prod(exit_china_id_FB)) ,  sum(m.weights_prod(exit_china_id_FB)))
fprintf(fid, ' Continuers &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FB(cont_china_id_FB).*m.weights_prod(cont_china_id_FB)) / sum(dom_sourcing(cont_china_id_FB).*m.weights_prod(cont_china_id_FB)), sum(imp_other_after_FB(cont_china_id_FB).*m.weights_prod(cont_china_id_FB)) / sum(imp_other(cont_china_id_FB).*m.weights_prod(cont_china_id_FB)), sum(imp_china_after_FB(cont_china_id_FB).*m.weights_prod(cont_china_id_FB)) / sum(imp_china(cont_china_id_FB).*m.weights_prod(cont_china_id_FB)) , sum(m.weights_prod(cont_china_id_FB)))
fprintf(fid, ' Others &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FB(non_china_id_FB).*m.weights_prod(non_china_id_FB)) / sum(dom_sourcing(non_china_id_FB).*m.weights_prod(non_china_id_FB)), sum(imp_other_after_FB(non_china_id_FB).*m.weights_prod(non_china_id_FB)) / sum(imp_other(non_china_id_FB).*m.weights_prod(non_china_id_FB)) , sum(imp_china_after_FB(non_china_id_FB).*m.weights_prod(non_china_id_FB)) / sum(imp_china(non_china_id_FB).*m.weights_prod(non_china_id_FB)) , sum(m.weights_prod(non_china_id_FB)))


%The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} } \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');


% 6. Aggregate Sourcing by country

hist(relative_agg_imports,100)
xlabel('Change in the agg sourcing by country (incl US)')
ylabel('Num Countries')
saveas(gcf,'counter_agg_sourcing','epsc')

% 7. Size distribution 

[sorted_sales,sort_sales_index] = sort(sales_vec,'ascend');
sorted_sales_counter = sales_vec_counter_free(sort_sales_index);
sorted_sales_weight = m.weights_prod(sort_sales_index);
cum_sales_weight    = cumsum(sorted_sales_weight);
cum_sales           = cumsum(sorted_sales);

%bounds_size = bounds_intervals;
bounds_size = 0:0.02:1;

change_sales_fivep = zeros(size(bounds_size,2)-1,1);
for k =1:size(bounds_size,2)-1;
    ind_size_dist     = (cum_sales_weight > bounds_size(k) & cum_sales_weight <= bounds_size(k+1));
change_sales_fivep(k) = sum(sorted_sales_counter(ind_size_dist)) ./ sum(sorted_sales(ind_size_dist));
end

bar(2:2:100, change_sales_fivep - 1)
xlabel('Percentiles size distribution')
ylabel('Growth in Sales')
axis([0 101 min(change_sales_fivep - 1)*1.2 max(change_sales_fivep - 1) * 1.2]) 
saveas(gcf,'sales_growth_dist','epsc')




%% 11. Agg import figure

% Changed B

share_importers_by_country_fig = share_importers_by_country;
relative_agg_imports_fig       = relative_agg_imports;


share_importers_by_country_fig(chn_ctr_ind) =[];
share_importers_by_country_fig(1)  = [];
relative_agg_imports_fig(chn_ctr_ind) = [];
relative_agg_imports_fig(1)  = [];
scatter(share_importers_by_country_fig,relative_agg_imports_fig)
xlabel('Share of firms importing from this country')
ylabel('Rel. aggregate sourcing')
saveas(gcf,'agg_imp_shock','epsc')

% Fixed B


agg_imports_counter_FB = M_free_entry_base * sum(bsxfun(@times,input_p_mat_counter,m.weights_prod),1);
relative_agg_imports_FB = agg_imports_counter_FB ./ agg_imports_baseline;

share_importers_by_country_fig_FB = share_importers_by_country;
relative_agg_imports_fig_FB       = relative_agg_imports_FB;


share_importers_by_country_fig_FB(chn_ctr_ind) =[];
share_importers_by_country_fig_FB(1)  = [];
relative_agg_imports_fig_FB(chn_ctr_ind) = [];
relative_agg_imports_fig_FB(1)  = [];
scatter(share_importers_by_country_fig,relative_agg_imports_fig_FB)
xlabel('Share of firms importing from this country')
ylabel('Rel. aggregate sourcing')
saveas(gcf,'agg_imp_shock_fixedB','epsc')




%% 13. Change to US and China Sourcing 

disp('Change in US sourcing:')
disp(relative_agg_imports(1))
disp('Change in China sourcing:')
disp(relative_agg_imports(chn_ctr_ind))


%% 14. Calculate change in price index

price_index_baseline = (M_free_entry_base * sum(price_vec .* m.weights_prod))^(1/(1-m.sigma));  % note that price_vec is really p^(1-m.sigma)
price_index_counter_free = (M_free_entry_post * sum(price_vec_counter_free .* m.weights_prod))^(1/(1-m.sigma));  % note that price_vec is really p^(1-m.sigma)

% Change in price index

disp('Change in price index')
disp((price_index_counter_free / price_index_baseline) -1)

% Fixed souring (flexible B) and free entry
price_index_counter_fixed_sourcing = (M_free_entry_fixed_sourcing * sum(price_vec_counter_fixed_sourcing .* m.weights_prod))^(1/(1-m.sigma));  % note that price_vec is really p^(1-m.sigma)
disp('Change in price index: Fixed sourcing strategy')
disp((price_index_counter_fixed_sourcing / price_index_baseline) -1)

%% 15. Analysis with fixed sourcing strategy

% Suppose we held the sourcing strategy of a firm fixed. 




% Agg import figure

agg_imports_counter_fixed_sourcing = M_free_entry_fixed_sourcing* sum(bsxfun(@times,input_p_mat_counter_fixed_sourcing,m.weights_prod),1);
relative_agg_imports_fixed_sourcing = agg_imports_counter_fixed_sourcing ./ agg_imports_baseline;

% Changed B

share_importers_by_country_fig = share_importers_by_country;
relative_agg_imports_fig_fixed_sourcing       = relative_agg_imports_fixed_sourcing;

share_importers_by_country_fig(chn_ctr_ind) =[];
share_importers_by_country_fig(1)  = [];
relative_agg_imports_fig_fixed_sourcing(chn_ctr_ind) = [];
relative_agg_imports_fig_fixed_sourcing(1)  = [];
scatter(share_importers_by_country_fig,relative_agg_imports_fig_fixed_sourcing)
xlabel('Share of firms importing from this country')
ylabel('Rel. aggregate sourcing')
saveas(gcf,'agg_imp_shock_fixed_sourcing','epsc')

% Change in USA and China sourcing

disp('Change in US sourcing:Fixed sourcing strategy')
disp(relative_agg_imports_fixed_sourcing(1))
disp('Change in China sourcing:fixed sourcing strategy')
disp(relative_agg_imports_fixed_sourcing(chn_ctr_ind))

% Size distribution fixed sourcing strategy

[sorted_sales,sort_sales_index] = sort(sales_vec,'ascend');
sorted_sales_counter_fixed_sourcing = sales_vec_counter_fixed_sourcing(sort_sales_index);
sorted_sales_weight = m.weights_prod(sort_sales_index);
cum_sales_weight    = cumsum(sorted_sales_weight);
cum_sales                 = cumsum(sorted_sales);

%bounds_size = bounds_intervals;
bounds_size = 0:0.02:1;

change_sales_fixed_sourcing = zeros(size(bounds_size,2)-1,1);
for k =1:size(bounds_size,2)-1;
    ind_size_dist     = (cum_sales_weight > bounds_size(k) & cum_sales_weight <= bounds_size(k+1));
change_sales_fixed_sourcing(k) = sum(sorted_sales_counter_fixed_sourcing(ind_size_dist)) ./ sum(sorted_sales(ind_size_dist));
end

bar(2:2:100, change_sales_fixed_sourcing - 1)
xlabel('Percentiles size distribution')
ylabel('Growth in Sales')
axis([0 101 min(change_sales_fixed_sourcing - 1)*1.2 max(change_sales_fixed_sourcing - 1) * 1.2]) 
saveas(gcf,'sales_growth_dist_fixed_sourcing','epsc')

% Third country effects Table

entrants_china_id_FS = (input_p_mat_counter_fixed_sourcing(:,chn_ctr_ind)>0 ) & ( input_p_mat(:,chn_ctr_ind) == 0 );
exit_china_id_FS     = (input_p_mat_counter_fixed_sourcing(:,chn_ctr_ind)== 0 ) & ( input_p_mat(:,chn_ctr_ind) > 0 );
cont_china_id_FS     = (input_p_mat_counter_fixed_sourcing(:,chn_ctr_ind)>0 ) & ( input_p_mat(:,chn_ctr_ind) > 0 );
non_china_id_FS      = (input_p_mat_counter_fixed_sourcing(:,chn_ctr_ind)==0 ) & ( input_p_mat(:,chn_ctr_ind) == 0 );

dom_sourcing_after_FS = input_p_mat_counter_fixed_sourcing(:,1);
dom_sourcing_FS       =  input_p_mat(:,1);

imp_other_after_FS    = sum(input_p_mat_counter_fixed_sourcing,2) - input_p_mat_counter_fixed_sourcing(:,1) - input_p_mat_counter_fixed_sourcing(:,chn_ctr_ind);
imp_other             = sum(input_p_mat,2) - input_p_mat(:,1) - input_p_mat(:,chn_ctr_ind);

imp_china_after_FS    = input_p_mat_counter_fixed_sourcing(:,chn_ctr_ind); 
imp_china             = input_p_mat(:,chn_ctr_ind);


fid = fopen('third_country_effects_table_fixed_sourcing.tex','w');
% Use \\ to produce a backslash character
% \n new line
fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{FIXED SOURCING: Third country sourcing effects of Positive Chinese Sourcing Potential shock}}\\label{tab:entryexit_fixed_sourcing} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular}{lcccc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fid, ' Chinese & Change sourcing & Change Sourcing & Change Sourcing & Share  \\\\ \n');
fprintf(fid, ' import status & from US & from other countries & from China & of firms  \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fid, ' Entrants & %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FS(entrants_china_id_FS).*m.weights_prod(entrants_china_id_FS)) / sum(dom_sourcing(entrants_china_id_FS).*m.weights_prod(entrants_china_id_FS)),sum(imp_other_after_FS(entrants_china_id_FS).*m.weights_prod(entrants_china_id_FS)) / sum(imp_other(entrants_china_id_FS).*m.weights_prod(entrants_china_id_FS)) ,sum(imp_china_after_FS(entrants_china_id_FS).*m.weights_prod(entrants_china_id_FS)) / sum(imp_china(entrants_china_id_FS).*m.weights_prod(entrants_china_id_FS)),sum(m.weights_prod(entrants_china_id_FS)))
fprintf(fid, ' Exiters &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FS(exit_china_id_FS).*m.weights_prod(exit_china_id_FS)) / sum(dom_sourcing(exit_china_id_FS).*m.weights_prod(exit_china_id_FS)), sum(imp_other_after_FS(exit_china_id_FS).*m.weights_prod(exit_china_id_FS)) / sum(imp_other(exit_china_id_FS).*m.weights_prod(exit_china_id_FS)) , sum(imp_china_after_FS(exit_china_id_FS).*m.weights_prod(exit_china_id_FS)) / sum(imp_china(exit_china_id_FS).*m.weights_prod(exit_china_id_FS))  ,sum(m.weights_prod(exit_china_id_FS)))
fprintf(fid, ' Continuers &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FS(cont_china_id_FS) .*m.weights_prod(cont_china_id_FS)) / sum(dom_sourcing(cont_china_id_FS) .* m.weights_prod(cont_china_id_FS)), sum(imp_other_after_FS(cont_china_id_FS) .* m.weights_prod(cont_china_id_FS)) / sum(imp_other(cont_china_id_FS) .* m.weights_prod(cont_china_id_FS)), sum(imp_china_after_FS(cont_china_id_FS) .* m.weights_prod(cont_china_id_FS)) / sum(imp_china(cont_china_id_FS) .* m.weights_prod(cont_china_id_FS)),sum(m.weights_prod(cont_china_id_FS)))
fprintf(fid, ' Others &  %.3f & %.3f & %.3f & %.3f \\\\ \n',sum(dom_sourcing_after_FS(non_china_id_FS) .* m.weights_prod(non_china_id_FS)) / sum(dom_sourcing(non_china_id_FS) .* m.weights_prod(non_china_id_FS)), sum(imp_other_after_FS(non_china_id_FS) .* m.weights_prod(non_china_id_FS)) / sum(imp_other(non_china_id_FS) .* m.weights_prod(non_china_id_FS)) ,sum(imp_china_after_FS(non_china_id_FS) .* m.weights_prod(non_china_id_FS)) / sum(imp_china(non_china_id_FS) .* m.weights_prod(non_china_id_FS)), sum(m.weights_prod(non_china_id_FS)))
%The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} This table contains only surviving firms. Entrants (exiters) are those firms that begin (stop) offshoring to China. Columns 1 , 2, and 3 contain the ratio of the total sourcing by this group of firms before and after} \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');




%% Table that decomposes total change in U.S. Sourcing and contains change in price index 

% Net versus gross Flexible Sourcing and B
dom_sourcing_increased_ID = ((input_p_mat_counter_free(:,1) - input_p_mat(:,1) ) > 0 );
dom_sourcing_decreased_ID = ((input_p_mat_counter_free(:,1) - input_p_mat(:,1) ) <= 0 );
Increase_domestic_tot = M_free_entry_post * (sum(dom_sourcing_after(dom_sourcing_increased_ID ).*m.weights_prod(dom_sourcing_increased_ID ))- sum(dom_sourcing(dom_sourcing_increased_ID ).*m.weights_prod(dom_sourcing_increased_ID )))
Decrease_domestic_tot =  M_free_entry_post * (sum(dom_sourcing_after(dom_sourcing_decreased_ID ).*m.weights_prod(dom_sourcing_decreased_ID ))- sum(dom_sourcing(dom_sourcing_decreased_ID ).*m.weights_prod(dom_sourcing_decreased_ID )))
%M_free_entry_post * sum(dom_sourcing_after(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB))- sum(dom_sourcing(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB))
Fall_sales_because_firms_disappear = (M_free_entry_post - M_free_entry_base) * sum(dom_sourcing.*m.weights_prod)
disp('Sanity check. Results from micro numbers added up')
disp(Increase_domestic_tot + Decrease_domestic_tot + Fall_sales_because_firms_disappear)
disp('Results from aggregate differences')
disp(agg_imports_counter_free(1) - agg_imports_baseline(1))
disp('Net change in U.S. sourcing (in percent of total US sourcing)')
(agg_imports_counter_free(1) - agg_imports_baseline(1)) / agg_imports_baseline(1)



% Net versus gross Fixed sourcing
disp('Fixed Sourcing:')
dom_sourcing_increased_FS_ID = ((input_p_mat_counter_fixed_sourcing(:,1) - input_p_mat(:,1) ) > 0 );
dom_sourcing_decreased_FS_ID = ((input_p_mat_counter_fixed_sourcing(:,1) - input_p_mat(:,1) ) <= 0 );
Increase_domestic_tot_FS = M_free_entry_fixed_sourcing * (sum(dom_sourcing_after_FS(dom_sourcing_increased_FS_ID ).*m.weights_prod(dom_sourcing_increased_FS_ID ))- sum(dom_sourcing(dom_sourcing_increased_FS_ID ).*m.weights_prod(dom_sourcing_increased_FS_ID )))
Decrease_domestic_tot_FS =  M_free_entry_fixed_sourcing * (sum(dom_sourcing_after_FS(dom_sourcing_decreased_FS_ID ).*m.weights_prod(dom_sourcing_decreased_FS_ID ))- sum(dom_sourcing(dom_sourcing_decreased_FS_ID ).*m.weights_prod(dom_sourcing_decreased_FS_ID )))
Fall_sales_because_firms_disappear_FS = (M_free_entry_fixed_sourcing - M_free_entry_base) * sum(dom_sourcing.*m.weights_prod)
disp('Sanity check. Results from micro numbers added up')
disp(Increase_domestic_tot_FS + Decrease_domestic_tot_FS + Fall_sales_because_firms_disappear_FS)
disp('Results from aggregate differences')
disp(agg_imports_counter_fixed_sourcing(1) - agg_imports_baseline(1))
disp('Relative total decline domestic sourcing')
(agg_imports_counter_fixed_sourcing(1) - agg_imports_baseline(1)) / agg_imports_baseline(1)


% Flexible Sourcing and B

fid = fopen('US_sourcing_outcomes.tex','w');
fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{Gross and Net US Sourcing effects, and Price index change}}\\label{tab:us_sourcing} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular}{lcc} \n \\hline \n \\hline \\\\ \n');

%The Headers...
fprintf(fid, ' & Difference in sourcing & Change in   \\\\ \n');
fprintf(fid, ' & in billion USD & percent of total  \\\\ \n');
fprintf(fid, ' &                & US sourcing  \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fid, ' Increase domestic sourcing & %.3f & %.3f  \\\\ \n',m.agg_imports_data(1) * (Increase_domestic_tot / agg_imports_baseline(1) ) / 1000, 100 * Increase_domestic_tot / agg_imports_baseline(1))
fprintf(fid, ' Decrease domestic sourcing by firms that continue to operate & %.3f  & %.3f   \\\\ \n',m.agg_imports_data(1) * ( Decrease_domestic_tot / agg_imports_baseline(1) ) / 1000,100* Decrease_domestic_tot /agg_imports_baseline(1))
fprintf(fid, ' Decrease domestic sourcing by firms that shut down & %.3f & %.3f   \\\\ \n', m.agg_imports_data(1) * (Fall_sales_because_firms_disappear / agg_imports_baseline(1) ) / 1000 ,100 * Fall_sales_because_firms_disappear / agg_imports_baseline(1))
fprintf(fid, ' \\hline \\\\ \n'); 
fprintf(fid, ' Total     & %.3f  & %.3f  \\\\ \n',m.agg_imports_data(1) * ( (Increase_domestic_tot / agg_imports_baseline(1) )  + ( Decrease_domestic_tot / agg_imports_baseline(1) ) + (Fall_sales_because_firms_disappear / agg_imports_baseline(1) ))/ 1000,100 * (agg_imports_counter_free(1) - agg_imports_baseline(1)) / agg_imports_baseline(1))
fprintf(fid, ' Price Index in percent &  & %.3f  \\\\ \n',100 * ((price_index_counter_free / price_index_baseline) -1))
%The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} We use the model prediction for the U.S. sourcing in the baseline and after the shock to the Chinese sourcing potential in order to calculate the percentage changes in U.S. sourcing. We then use the actual aggregate U.S. sourcing purchases in the data and the percentage differences in order to calculate the differences in USD.} \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');

% Fixed Sourcing

fid = fopen('US_sourcing_outcomes_fixed_sourcing.tex','w');
fprintf(fid, '\\begin{table}[htb] \n \\begin{center} \n'); 
fprintf(fid, '\\begin{threeparttable} \n');
fprintf(fid, '\\caption{\\textsc{FIXED SOURCING: Gross and Net US Sourcing effects, and Price index change}}\\label{tab:us_sourcing_FS} \n');
fprintf(fid, '\\vspace{0.05in} \n \\begin{tabular}{lcc} \n \\hline \n \\hline \\\\ \n');
%The Headers...
fprintf(fid, ' & Difference in sourcing & Change in   \\\\ \n');
fprintf(fid, ' & in billion USD & percent of total  \\\\ \n');
fprintf(fid, ' &                & US sourcing  \\\\ \n');
fprintf(fid, ' \\hline \\\\ \n'); 
%The Guts...
fprintf(fid, ' Increase domestic sourcing & %.3f & %.3f  \\\\ \n',m.agg_imports_data(1) * (Increase_domestic_tot_FS / agg_imports_baseline(1) ) / 1000, 100 * Increase_domestic_tot_FS / agg_imports_baseline(1))
fprintf(fid, ' Decrease domestic sourcing by firms that continue to operate & %.3f  & %.3f   \\\\ \n',m.agg_imports_data(1) * ( Decrease_domestic_tot_FS / agg_imports_baseline(1) ) / 1000,100* Decrease_domestic_tot_FS /agg_imports_baseline(1))
fprintf(fid, ' Decrease domestic sourcing by firms that shut down & %.3f & %.3f   \\\\ \n', m.agg_imports_data(1) * (Fall_sales_because_firms_disappear_FS / agg_imports_baseline(1) ) / 1000 ,100 * Fall_sales_because_firms_disappear_FS / agg_imports_baseline(1))
fprintf(fid, ' \\hline \\\\ \n'); 
fprintf(fid, ' Total     & %.3f  & %.3f  \\\\ \n',m.agg_imports_data(1) * ( (Increase_domestic_tot_FS / agg_imports_baseline(1) )  + ( Decrease_domestic_tot_FS / agg_imports_baseline(1) ) + (Fall_sales_because_firms_disappear_FS / agg_imports_baseline(1) ))/ 1000,100 * (agg_imports_counter_fixed_sourcing(1) - agg_imports_baseline(1)) / agg_imports_baseline(1))
fprintf(fid, ' Price Index in percent &  & %.3f  \\\\ \n',100 * ((price_index_counter_fixed_sourcing / price_index_baseline) -1))
%The bottom
fprintf(fid, '\\hline \n \\hline \n \\end{tabular} \n')
fprintf(fid, '\\begin{tablenotes}[para] \n')
fprintf(fid, ' \\footnotesize{\\textit{Notes:} We use the model prediction for the U.S. sourcing in the baseline and after the shock to the Chinese sourcing potential in order to calculate the percentage changes in U.S. sourcing. We then use the actual aggregate U.S. sourcing purchases in the data and the percentage differences in order to calculate the differences in USD.} \n');
fprintf(fid, '\\end{tablenotes} \n');
fprintf(fid, '\\end{threeparttable} \n')
fprintf(fid, '\\end{center} \n \\end{table} \n');



