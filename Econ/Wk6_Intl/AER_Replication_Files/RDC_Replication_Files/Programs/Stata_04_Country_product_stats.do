
*This program counts the number of countries for firms
*Firm-level analysis takes some time to run

set more off
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

capture log close
log using "$output/Log_Country_counts", replace text

*Bring in import data
use $data/imports2007.dta, clear
drop if substr(hs,1,2)=="27"

*Limit to sample and importing firms
merge m:1 firmid using "$data/firm_data_2007.dta", keepusing(firmid type lvap sales emp)
keep if _merge==3
drop _merge

keep if type=="M" | type=="M+"

*Create count variables
bysort firmid country: gen count_c=1 if _n==1
bysort firmid hs: gen count_h=1 if _n==1
gen count=1 

bysort firmid: egen count_country=sum(count_c)
bysort firmid: egen count_hs=sum(count_h)


preserve
collapse (sum) count_hs_ctrys=count, by(firmid hs)
gen count=1
bysort firmid: egen tot=sum(count)
gen mul=1 if count_hs_ctrys>1
replace mul=0 if mul==.
gen frac=mul/tot
collapse (mean) ctry_per_hs_mean=count_hs_ctrys (median) ctry_per_hs_med=count_hs_ctrys  (max) ctry_per_hs_max=count_hs_ctrys (sum) frac, by(firmid)
label variable frac "Fraction of HS prods sourced from multiple countries"
save $data/temp1.dta, replace
restore

preserve
collapse (sum) count_ctry_hs=count, by(firmid country)
collapse (mean) hs_per_ctry_mean=count_ctry_hs (median) hs_per_ctry_med=count_ctry_hs (max) hs_per_ctry_max=count_ctry_hs, by(firmid)
save $data/temp2.dta, replace
restore

**Collapse data to firm level**
collapse (sum) count_country=count_c count_hs=count_h (mean) sales, by(firmid)
label variable count_country "Country count"
label variable count_hs "HS count"

merge 1:1 firmid using $data/temp2
drop _merge
merge 1:1 firmid using $data/temp1
drop _merge


*Calculate means and percentiles 
 *Only do 25th percentile for 3 vars
foreach var in count_country count_hs frac {
  foreach val in 25 {
    *capture drop `var'p`val_plus' `var'p`val_min' `var'p`val' `var'`val'
     local val_plus=`val'+1
     local val_min=`val'-1
     egen `var'p`val_plus'=pctile(`var'), p(`val_plus')
     egen `var'p`val_min'=pctile(`var'), p(`val_min')
    gen `var'r`val'=1 if `var'>=`var'p`val_min' & `var'<=`var'p`val_plus'
    egen `var'`val'=mean(`var'*`var'r`val')
   }
   }

 *Do median and 95 percentiles for all vars
 foreach var in count_country count_hs hs_per_ctry_mean hs_per_ctry_med hs_per_ctry_max ctry_per_hs_mean ctry_per_hs_med ctry_per_hs_max frac {
  foreach val in 50 95 {
    *capture drop `var'p`val_plus' `var'p`val_min' `var'p`val' `var'`val'
     local val_plus=`val'+1
     local val_min=`val'-1
     egen `var'p`val_plus'=pctile(`var'), p(`val_plus')
     egen `var'p`val_min'=pctile(`var'), p(`val_min')
    gen `var'r`val'=1 if `var'>=`var'p`val_min' & `var'<=`var'p`val_plus'
    egen `var'`val'=mean(`var'*`var'r`val')
   }
   }

 *Calculate means and percentiles for sample of firms that import from at least vv countries
 foreach vv in 1 2 {
 foreach var in ctry_per_hs_mean ctry_per_hs_med ctry_per_hs_max {
  foreach val in 50 95 {
     local val_plus=`val'+1
     local val_min=`val'-1
     egen `var'_`vv'p`val_plus'=pctile(`var') if count_country>`vv', p(`val_plus')
     egen `var'_`vv'p`val_min'=pctile(`var') if count_country>`vv', p(`val_min')
     gen `var'_`vv'r`val'=1 if `var'>=`var'_`vv'p`val_min' & `var'<=`var'_`vv'p`val_plus'
     egen `var'_`vv'`val'=mean(`var'*`var'_`vv'r`val')
   }
   }  
   }
   
************************************************************************     
*************MAKE TABLES************************************************
************************************************************************   
 
capture log close   
log using "$output/Firm_Import_Stats.txt", replace text

**Product and Country Count Table
***********************************
tabstat count_country count_country25 count_country50 count_country95, stats(mean sd) 
tabstat count_hs count_hs25 count_hs50 count_hs95, stats(mean sd) 
************************************

**Product counts per country***
tabstat hs_per_ctry_mean hs_per_ctry_med hs_per_ctry_max hs_per_ctry_mean50 hs_per_ctry_med50 hs_per_ctry_max50 hs_per_ctry_mean95 hs_per_ctry_med95 hs_per_ctry_max95, stats(mean sd) columns(stats)

**Country counts per product***
tabstat ctry_per_hs_mean ctry_per_hs_med ctry_per_hs_max ctry_per_hs_mean50 ctry_per_hs_med50 ctry_per_hs_max50 ctry_per_hs_mean95 ctry_per_hs_med95 ctry_per_hs_max95, stats(mean sd) columns(stats)

*Robustness for firms that import from at least three countries  (Appendix Table C.9)
tabstat ctry_per_hs_mean ctry_per_hs_med ctry_per_hs_max ctry_per_hs_mean_250 ctry_per_hs_med_250 ctry_per_hs_max_250 ctry_per_hs_mean_295 ctry_per_hs_med_295 ctry_per_hs_max_295 if count_country>2, stats(mean sd) columns(stats) 
log close
****************************************************************************************************
  
 capture erase $data/temp.dta
 capture erase $data/temp2.dta
 
 
