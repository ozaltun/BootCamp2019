
%% Flexible Sourcing and B

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
disp('Relative total decline domestic sourcing')
(agg_imports_counter_free(1) - agg_imports_baseline(1)) / agg_imports_baseline(1)


%% Fixed sourcing

disp('Fixed SOurcing:')

dom_sourcing_increased_FS_ID = ((input_p_mat_counter_fixed_sourcing(:,1) - input_p_mat(:,1) ) > 0 );
dom_sourcing_decreased_FS_ID = ((input_p_mat_counter_fixed_sourcing(:,1) - input_p_mat(:,1) ) <= 0 );
Increase_domestic_tot_FS = M_free_entry_fixed_sourcing * (sum(dom_sourcing_after_FS(dom_sourcing_increased_FS_ID ).*m.weights_prod(dom_sourcing_increased_FS_ID ))- sum(dom_sourcing(dom_sourcing_increased_FS_ID ).*m.weights_prod(dom_sourcing_increased_FS_ID )))
Decrease_domestic_tot_FS =  M_free_entry_fixed_sourcing * (sum(dom_sourcing_after_FS(dom_sourcing_decreased_FS_ID ).*m.weights_prod(dom_sourcing_decreased_FS_ID ))- sum(dom_sourcing(dom_sourcing_decreased_FS_ID ).*m.weights_prod(dom_sourcing_decreased_FS_ID )))

%M_free_entry_post * sum(dom_sourcing_after(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB))- sum(dom_sourcing(entrants_china_id_FB).*m.weights_prod(entrants_china_id_FB))

Fall_sales_because_firms_disappear_FS = (M_free_entry_fixed_sourcing - M_free_entry_base) * sum(dom_sourcing.*m.weights_prod)

disp('Sanity check. Results from micro numbers added up')
disp(Increase_domestic_tot_FS + Decrease_domestic_tot_FS + Fall_sales_because_firms_disappear_FS)
disp('Results from aggregate differences')
disp(agg_imports_counter_fixed_sourcing(1) - agg_imports_baseline(1))
disp('Relative total decline domestic sourcing')
(agg_imports_counter_fixed_sourcing(1) - agg_imports_baseline(1)) / agg_imports_baseline(1)


