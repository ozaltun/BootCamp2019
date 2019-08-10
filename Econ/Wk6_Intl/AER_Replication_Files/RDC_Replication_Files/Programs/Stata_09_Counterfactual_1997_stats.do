
*************************************************************
/* This program calculates stats for the 1997 data for our negative 
counterfactual shock   
*/
**********************************************************

cd " " /* PROJECT ROOT FOLDER */


/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

capture log close

*1. Bring in appropriate 1997 data
use "$bs/estimation_data_1997_bs1.dta", clear

gen temp=firm_count if code_TD=="1000"
egen total_firms=mean(temp)
drop temp
gen importer_share=firm_count/total_firms

egen firm_rank=rank(firm_count), field
sort firm_rank
*browse code_TD iso3 firm_count importer_share firm_rank

log using "$output/China_share_1997.txt", replace text
list code_TD iso3 importer_share if iso3=="CHN"
log close
 