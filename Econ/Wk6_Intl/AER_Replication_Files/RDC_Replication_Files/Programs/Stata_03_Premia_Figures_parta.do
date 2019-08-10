/* PART A
section at the beginning to make firm industry controls dataset.

Figures Made:
1. Intro figure of importer premia and number of countries from which firm sources
2. Robustness figures:
	a. Firms that did not import in 2002
	b. Controlling for number of products imported by the firm
	c. Controlling for number of products exported by the firm
3.  Internal robustness figures (not to disclose but for our own peace of mind)
        a. Using only importers (relative to firms that import from just one country)
	b. No. of imports (or exports) using the importer only sample.
*/

set matsize 11000
set more off

**Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

********************************************************
* CREATE FIRM INDUSTRY CONTROLS
*************************************************************
* create wide firmid naics4 dataset where entries in naics columns are share of firm total sales in that industry
* include an other industry for all non-manuf naics4
* limit to firms with at least one manufacturing establishment

use $data/firm_industry_2007.dta, clear
keep firmid fk_naics02 emp sales // note emp_tot and sales_tot are not firm totals, their values have been inflated by double collapse
gen naics= substr(fk_naics,1,4)
replace naics = "9999" if substr(naics,1,1)~="3"
collapse (sum) emp sales, by(firmid naics)
bys firmid: egen sales_firm = sum(sales)
bys firmid: egen emp_firm = sum(emp)
gen double ind = sales/sales_firm
* some firms here have 0 sales but positive emp, for them, replace sal_share = emp_share
replace ind = emp / emp_firm if missing(ind)
drop if naics=="9999" // this step is needed to get rid of firms with no manuf estabs
keep firm naics ind
reshape wide ind, i(firm) j(naics) s
egen ind9999 = rowtotal(ind*)
replace ind9999 = 1-ind9999 // ind9999 is now the residual
save $data/firm_industry_controls.dta, replace
* checked that this set of controls has a corr of 1.000 with the old set. only difference is it introduces a few more firms
* among the new firms, we don't care, because they will all get discplined out by the limitation to type=="M/M+" below

*Make export and import product count data
*************************************************
**Exports
use "$data/exports_tf_match.dta", clear

drop if substr(hs,1,2)=="27"  /*  Eliminate fuels  */
collapse (sum) evalue, by(firmid hs)  /* Ensure data are hs-firm level  */
*Count distinct number of products
gen num_exports_hs=1
collapse (sum) num_exports_hs, by(firmid)
keep firmid num_exports_hs
save $data/temp, replace
*******************

**Imports
************
*Make product count data
 use $data/imports2007.dta, clear /* Updated import data */
 drop if substr(hs,1,2)=="27"  /*  Eliminate fuels  */
 collapse (sum) ivalue, by(firmid hs)  /* Ensure data are hs-firm level  */
*Count distint products imported by firm
 gen num_imports_hs=1
 collapse (sum) num_imports_hs, by(firmid)

*Combine import and export product counts
keep firmid num_imports_hs
merge 1:1 firmid using $data/temp
drop _merge
drop if firmid==""
save $data/temp, replace
*******
************************************************

*Bring in main firm data	
use $data/firm_data_2007.dta, clear  /*Dataset made by Stata_01 */

**Limit dataset to appropriate sample
keep if type=="M" | type=="M+"

**Add the trade data
merge 1:1 firmid using $data/temp
drop if _merge==2
drop _merge

**Get firm industry controls
merge 1:1 firmid using "$data/firm_industry_controls.dta", keepusing(firmid ind*)
keep if _merge==3   /* A few records with no industry match---not worrying about them.  */
drop _merge

**Get 2002 firm data
save $data/temp, replace
use  "$data/firm_data_2002.dta", clear
keep firmid emp sales lvap_r imports importer
foreach var in emp sales lvap_r imports importer {
  rename `var' `var'_2002
  }

merge 1:1 firmid using $data/temp.dta  
drop if _merge==1
drop _merge

**Pull in the import and export product counts
merge 1:1 firmid using $data/temp
drop if type==""  /*  Drop non-manufacturing importers  */
drop _merge

**Make log variables
foreach var in emp sales emp_2002 sales_2002 {
  gen log_`var'=ln(`var')
  }

 **Replace missing values 
 foreach vv of varlist ind* {
   replace `vv'=0 if `vv'==.
   } 
   
 *Fix export/import count variable to include non-exporters
replace num_exports_hs=0 if num_exports_hs==.
replace num_imports_hs=0 if num_imports_hs==.
  

***COUNTRY COUNT DUMMIES ANALYSIS***
**Number of markets from which firms import dummies***
*Get firm number of countries

save $data/temp, replace
use $data/imports2007.dta, clear
collapse (sum) ivalue, by(firmid country)
gen country_count=1
collapse (sum) country_count, by(firmid)
merge 1:1 firmid using $data/temp
drop if _merge==1 /* Relimit to sample */

save $data/premia_figs.dta, replace


