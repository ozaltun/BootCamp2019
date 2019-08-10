/* 
This program prepares the country_clean data for use in Stata_02_Structural_estimation_inputs.do

Also prepares country_names dataset for use in Staa_07
       
*/
*************************************************************
**Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global external_data 
global data
global temp

set more off


use  "$external_data/final_dataset_v3.dta", clear
drop if code_TD=="2771" & distw==.
replace code_TD="2771" if country=="Netherlands Antilles"
keep if code_TD~="."

*Rescale variables
replace tariff_avg  = tariff_avg / 100
replace tariff_wavg = tariff_avg / 100

replace rd_stock = rd_stock / 1000
label var rd_stock "R&D stock from the WDI in billion USD"

replace distw = distw / 1000
label var distw "Weighted distance (pop-wt, 1000km)"

replace KL = KL / 1000

replace pop = pop / 1000
label var pop "country population in million"

replace sum_gen_val = sum_gen_val / 1000 
replace sum_con_val = sum_con_val /1000

replace avg_wage_usd = avg_wage_usd / 3143
label var avg_wage_usd "Average Nominal Monthly Wage in 2007 in 3143 USD (US wage)"

gen wage_hc_adj=avg_wage_usd*exp(-.06*yr_sch)


***********************************************************************

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
gen log_firms=ln(no_firms)

*Output clean dataset
keep code_TD iso3 distw log_dist log_pop log_wage_adj contig comlang_off control log_KL log_rd log_tariff gdp rule_of_law rpshare exp_cost log_firms


save "$data/country_clean.dta", replace

**************************************************************



use  "$external_data/final_dataset_v3.dta", clear
* country = 4 digit code
* country name = name,

drop if code_TD=="2771" & distw==.
replace code_TD="2771" if country=="Netherlands Antilles"
keep if code_TD~="."
keep code_TD country
ren country country_name
ren code_TD country
save "$data/country_names.dta", replace
