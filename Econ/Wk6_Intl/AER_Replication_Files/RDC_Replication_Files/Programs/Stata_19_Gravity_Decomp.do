
**This program does a gravity decomposition of aggregate imports

set more off

**Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

* create a firmid country hs ivalue dataset
* merge with firm_data dataset, keepusing(firmid type sales)
use $data/imports2007, clear  
drop if substr(hs,1,2)=="27"  /*  Drop oil and fuels */
collapse (sum) ivalue, by(firmid country hs)

merge m:1 firmid using $data/firm_data_2007.dta, keepusing(firmid type sales)  /*Dataset made by Stata_01 */

* Limit to appropriate firm types
keep if type=="M" | type=="M+" 
keep if _m==3 /* Keep only the importing firms */
drop _merge

bysort country hs: gen prod_count=1 if _n==1
bysort country firmid: gen firm_count=1 if _n==1
gen count=1

save $data/temp_disc.dta, replace
collapse (sum) firm_count prod_count count ivalue (mean) ivalue_mean=ivalue, by(country)

label variable ivalue_mean "Avg value per firm per product"
gen ivalue_mean_f=ivalue/firm_count
gen density=ivalue/(firm_count*prod_count*ivalue_mean)

*Check the density measure
gen density_check=count/(firm_count*prod_count)
gen check=density-density_check
summ check

*Take logs
  foreach var in ivalue ivalue_mean ivalue_mean_f prod_count firm_count density {
    gen log_`var'=ln(`var')
    }
    
*Decompositions of intensive and extensive margins
foreach var in firm_count prod_count ivalue_mean density ivalue_mean_f {
   regress log_`var' log_ivalue
   estimates store `var'
   }
    
estout firm_count prod_count ivalue_mean density using "$output/Gravity_Decomp.txt", replace title(Decomposition with Products) ///
   cells(b(star fmt(%9.3f)) se(par))  stats(r2_a N, fmt(%9.2f %9.0gc) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) 

  
    
    
