****REPLICATION PROGRAM FOR: ANTRAS, FORT, & TINTELNOT: THE MARGINS OF GLOBAL SOURCING****

/*
This program reproduces columns 1-4 of Table 4, Appendix Table B.1, and Online Appendix Table C.4

Note that:
 a) the coefficients in columns 3 & 4 of Table 4 do not match the paper perfectly since here we use publicly disclosed data that is rounded; 
 b) column 5 of Table 4 is not included since it requires non-disclosed data.
 
 Table 4 in its entirety can be replicated exactly in the RDCs when using the RDC replication programs 

*/


set more off

*1. Set directories
cd  "C:\Users\F000KTQ\Dropbox\MultiCountryOffshoring\AER Replication\Public_Replication_Files"

*2. Pull in country-level data (compiled from WDI, CEPII, etc--see online appendix for details
  /*  Note that we include some country variables not used in the final analysis.
      Use these variables at your own risk, we have not cleaned them as carefully as the variables used in the paper
  */
  
use Input_data\country_data.dta, clear  /*  renamed from final_dataset_v2.dta  */

*3. Rescale variables
replace tariff_avg  = tariff_avg / 100
replace tariff_wavg = tariff_avg / 100

replace distw = distw / 1000
label var distw "Weighted distance (pop-wt, 1000km)"

replace KL = KL / 1000
replace rd_stock= rd_stock/ 1000
label var rd_stock "R&D stock from the WDI in billion USD"
replace pop = pop / 1000
label var pop "country population in million"

replace sum_gen_val = sum_gen_val / 1000 
replace sum_con_val = sum_con_val /1000

replace avg_wage_usd=avg_wage_usd/3143
gen wage_hc_adj=avg_wage_usd*exp(-.06*yr_sch)

*4. Make variables
gen log_wage    = ln(avg_wage_usd)
gen log_rd      = ln(rd_stock)
gen log_dist    = ln(distw)
gen log_imp     = ln(sum_gen_val)
gen log_KL      = ln(KL)
gen log_yrsch   = ln(yr_sch)
gen log_hl      = ln(hl)
gen yrsch_inv   = 1 / yr_sch    
gen log_tariff  = ln(1+tariff_avg)
gen log_pop     = ln(pop)
gen log_wage_adj=ln(wage_hc_adj)
gen log_tao_wage  = ln(1+tariff_avg) + log_wage_adj
gen log_gdp= ln(gdp)
gen log_hc=log(hc)
gen log_servers=log(intserv)
gen log_firms=ln(no_firms)

***********************************************************************


*5. Label variables for regression output 
label variable comlang_off "Common language"
label variable log_tao_wage "log(1+tariff)+ log wage"
label variable log_dist "log distance"
label variable log_rd "log R\&D"
label variable control_of_corruption "Control of corruption"
label variable log_KL "log KL"
label variable log_gdp "log GDP"
label variable log_firms "log no. of firms"
label variable log_wage_adj "HC adjusted wage"
label variable log_hc "Human capital"
label variable log_wage "log wage"
label variable log_servers "log internet servers"
label variable log_tariff "log tariff"
label variable log_pop "log population" 


***********************************************************************
keep if code_TD~="."
save data\temp, replace

*6. Pull in potential estimates
insheet using "Input_data\emp2_data_for_matlab_v3.out", comma clear 

rename code_td code_TD
gen log_agg_imports = log(inputs_rounded)  /*  Note that we do not use rounded data when estimating theta in the RDC  */
tostring code_TD, replace
keep code_TD fe log_agg_imports
merge 1:m code_TD using data\temp

drop if code_TD=="1000"   /*  Drop the US  */

estimates clear

*7.  Estimate Theta
/*   Main Table   */

*7a. Firm-level share regressions
reg fe log_wage_adj comlang_off log_rd log_KL control_of_corruption log_dist log_firms 
estimates store OLS1

ivreg2 fe (log_wage_adj=log_pop) comlang_off log_rd log_KL control_of_corruption log_dist log_firms, first savefirst savefprefix(fs_) ffirst
estimates store IV1
gen samp=e(sample)

*7b. Aggregate trade flow regressions
reg log_agg_imports log_wage_adj comlang_off log_rd log_KL control_of_corruption log_dist log_firms 
estimates store OLS2

ivreg2 log_agg_imports (log_wage_adj=log_pop) comlang_off log_rd log_KL control_of_corruption log_dist log_firms, first savefirst savefprefix(fs_)ffirst
estimates store IV2

*7c. First stage regression
regress log_wage_adj log_pop comlang_off log_rd log_KL control_of_corruption log_dist log_firms if samp==1
estimates store FS

*7d. Output tables
estout OLS1 IV1 OLS2 IV2  using "output/Table4.tex", cells(b(fmt(%9.3f)) se(par))  style(tex) stats(N widstat arf arfp archi2 archi2p, fmt(%9.0gc %9.3gc) ///
label(Observations F-stat ARFtest ARpval ARChi ARChipval)) ///
varlabels(_cons Constant) order(log_wage_adj log_dist log_rd log_KL comlang_off control_of_corruption log_firms) title(Main Table 4) label replace

estout FS using "output/TableB.1.tex", cells(b(fmt(%9.2f)) se(par)) style(tex) stats(r2 N, fmt(%9.3gc %9.0gc) label(R2 Observations)) ///
varlabels(_cons Constant) order(log_pop log_dist log_rd log_KL comlang_off control_of_corruption log_firms) title(First stage table) label replace

/*  NOTES for researchers replicating AFT results:

1. The aggregate trade regression estimates run outside of the RDC labs will not match perfectly.  This is due to rounding of the disclosed 
   aggregate data.  To replicate Table 4 exactly, regressions should be run inside the RDC.  Production of these tables is included in the
   Stata replication files for internal replication purposes.
   
*/   

/* Robustness Table C.4 */

*7e. Robustness regressions for IV estimates
ivreg2 fe (log_wage_adj =log_pop) log_dist comlang_off log_rd log_KL control_of_corruption log_gdp log_firms  if samp==1, ffirst
estimates store IV_RB1	

ivreg2 fe (log_wage_adj =log_pop) log_dist comlang_off log_rd log_KL control_of_corruption log_firms log_tariff if samp==1, ffirst
estimates store IV_RB2	

ivreg2 fe (log_tao_wage =log_pop log_tariff) log_dist comlang_off log_rd log_KL control_of_corruption log_firms if samp==1, ffirst
estimates store IV_RB3	

ivreg2 fe (log_wage_adj =log_pop) log_dist comlang_off log_rd log_KL control_of_corruption , ffirst
estimates store IV_RB4


*7f.. Output table
estout IV_RB*  using "output/TableC.4.tex", cells(b(fmt(%9.2f)) se(par))  style(tex) stats(N widstat, fmt(%9.0gc %9.2fc) label(Observations F-Stat)) ///
varlabels(_cons Constant) order(log_wage_adj log_tao_wage log_dist comlang_off log_rd log_KL control_of_corruption log_gdp log_tariff) title(Robustness) label replace

