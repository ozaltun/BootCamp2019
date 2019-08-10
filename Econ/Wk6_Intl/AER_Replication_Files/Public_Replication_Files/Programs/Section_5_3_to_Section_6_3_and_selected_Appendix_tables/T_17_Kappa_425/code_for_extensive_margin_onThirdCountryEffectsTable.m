% Code for extensive margin  

load('output_incl_counterfactual.mat')


% Define what a new or dropped market is

new_market  = (input_p_mat_counter_free >0 ) & ( input_p_mat == 0 );
dropped_market =(input_p_mat_counter_free == 0 ) & ( input_p_mat > 0 );
continued_market =(input_p_mat_counter_free > 0 ) & ( input_p_mat > 0 );

new_market_third_country  = new_market  ;
new_market_third_country(:,1) = zeros(size(new_market_third_country(:,1)));
new_market_third_country(:,chn_ctr_ind) = zeros(size(new_market_third_country(:,1)));

dropped_market_third_country = dropped_market ;
dropped_market_third_country(:,1) = zeros(size(new_market_third_country(:,1)));
dropped_market_third_country(:,chn_ctr_ind) = zeros(size(new_market_third_country(:,1)));

continued_market_third_country = continued_market ;
continued_market_third_country(:,1) = zeros(size(new_market_third_country(:,1))); 
continued_market_third_country(:,chn_ctr_ind) = zeros(size(new_market_third_country(:,1)));


% Calculate change in third market sourcing of these three groups

%imp_other          = sum(input_p_mat,2) - input_p_mat(:,1) - input_p_mat(:,chn_ctr_ind);
%imp_other_after    = sum(input_p_mat_counter_free,2) - input_p_mat_counter_free(:,1) - input_p_mat_counter_free(:,chn_ctr_ind);


imp_other_after_new_market    = sum(input_p_mat_counter_free .* new_market_third_country,2);
imp_other_new_market              = sum(input_p_mat .* new_market_third_country,2);


imp_other_after_dropped_market    = sum(input_p_mat_counter_free .* dropped_market_third_country,2);
imp_other_dropped_market              = sum(input_p_mat .* dropped_market_third_country,2);


imp_other_after_continued_market    = sum(input_p_mat_counter_free .* continued_market_third_country,2);
imp_other_continued_market              = sum(input_p_mat .*continued_market_third_country,2);

% The guts

% the stuff in the standard table (third markets)
% Decomposition along following lines
%Delta (Agg) / Agg_0 = (Delta (Agg Cont) + Delta (Agg_New) + Delta(Agg_drop) )/ Agg_0


% Entrants
disp('Total third market change Entrants')
total_third_market_entrants = sum(imp_other_after(entrants_china_id) .*m.weights_prod(entrants_china_id) ) / sum(imp_other(entrants_china_id) .* m.weights_prod(entrants_china_id))  - 1 
disp('Total third market change Entrants due to new markets')
(sum(imp_other_after_new_market(entrants_china_id) .*m.weights_prod(entrants_china_id) ) -  sum(imp_other_new_market(entrants_china_id) .*m.weights_prod(entrants_china_id) ) )/ sum(imp_other(entrants_china_id) .* m.weights_prod(entrants_china_id))  
disp('Total third market change Entrants due to dropped markets')
(sum(imp_other_after_dropped_market(entrants_china_id) .*m.weights_prod(entrants_china_id) ) - sum(imp_other_dropped_market(entrants_china_id) .*m.weights_prod(entrants_china_id) )) / sum(imp_other(entrants_china_id) .* m.weights_prod(entrants_china_id)) 
disp('Total third market change Entrants due to continued markets')
(sum(imp_other_after_continued_market(entrants_china_id) .*m.weights_prod(entrants_china_id) ) - sum(imp_other_continued_market(entrants_china_id) .*m.weights_prod(entrants_china_id) )) / sum(imp_other(entrants_china_id) .* m.weights_prod(entrants_china_id)) 


% Continuers
disp('Total third market change Continuers')
total_third_market_continuers = sum(imp_other_after(cont_china_id).*m.weights_prod(cont_china_id)) / sum(imp_other(cont_china_id) .*m.weights_prod(cont_china_id)) - 1
disp('Total third market change Continuers due to new markets')
(sum(imp_other_after_new_market (cont_china_id).*m.weights_prod(cont_china_id)) - sum(imp_other_new_market (cont_china_id).*m.weights_prod(cont_china_id))) / sum(imp_other(cont_china_id) .*m.weights_prod(cont_china_id))
disp('Total third market change Continuers due to dropped markets')
(sum(imp_other_after_dropped_market(cont_china_id).*m.weights_prod(cont_china_id)) - sum(imp_other_dropped_market(cont_china_id).*m.weights_prod(cont_china_id))) / sum(imp_other(cont_china_id) .*m.weights_prod(cont_china_id)) 
disp('Total third market change Continuers due to continued markets')
(sum(imp_other_after_continued_market(cont_china_id).*m.weights_prod(cont_china_id)) - sum(imp_other_continued_market(cont_china_id).*m.weights_prod(cont_china_id))  )/ sum(imp_other(cont_china_id) .*m.weights_prod(cont_china_id)) 

 % Others
disp('Total third market change Others')
total_third_market_others = sum(imp_other_after(non_china_id) .* m.weights_prod(non_china_id)) / sum(imp_other(non_china_id) .* m.weights_prod(non_china_id))  -1 
disp('Total third market change Others due to new markets')
(sum(imp_other_after_new_market (non_china_id) .* m.weights_prod(non_china_id)) - sum(imp_other_new_market (non_china_id) .* m.weights_prod(non_china_id))) / sum(imp_other(non_china_id) .* m.weights_prod(non_china_id)) 
disp('Total third market change Others due to dropped markets')
(sum(imp_other_after_dropped_market (non_china_id) .* m.weights_prod(non_china_id)) - sum(imp_other_dropped_market (non_china_id) .* m.weights_prod(non_china_id))) / sum(imp_other(non_china_id) .* m.weights_prod(non_china_id))
disp('Total third market change Others due to continued markets')
(sum(imp_other_after_continued_market (non_china_id) .* m.weights_prod(non_china_id)) - sum(imp_other_continued_market (non_china_id) .* m.weights_prod(non_china_id)) ) / sum(imp_other(non_china_id) .* m.weights_prod(non_china_id)) 







