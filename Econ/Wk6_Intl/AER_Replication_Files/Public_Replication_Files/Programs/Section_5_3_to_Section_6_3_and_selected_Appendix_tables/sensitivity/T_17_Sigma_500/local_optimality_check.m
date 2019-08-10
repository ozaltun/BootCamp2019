
% Check how objective function changes with parameters.

% B 

stat_gap_all = []; 
statJiafile = sprintf('statistics_jia_%d.mat', []);
save(statJiafile,'stat_gap_all')

for kk = 1 : length(beta_hat)

beta_hat_vec_test_temp = beta_hat(kk) * .98 : beta_hat(kk)/400 : beta_hat(kk) * 1.02;
beta_hat_vec_test = repmat(beta_hat,1,length(beta_hat_vec_test_temp));
beta_hat_vec_test(kk,:) = beta_hat_vec_test_temp;

for jj = 1:size(beta_hat_vec_test,2)
fval_vec(jj) = gmm_objective(beta_hat_vec_test(:,jj),m);
end

scatter(beta_hat_vec_test(kk,:),fval_vec)
beta_k = sprintf('beta_%d', kk);
optim_beta_k = sprintf('optimality_%s',beta_k);

xlabel(beta_k)
ylabel('objective value')
saveas(gcf,optim_beta_k,'epsc')

end