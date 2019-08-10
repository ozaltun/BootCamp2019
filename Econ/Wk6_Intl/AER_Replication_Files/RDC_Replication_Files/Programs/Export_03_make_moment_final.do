*this computes (outputs) both the export and import moments, and some other tab stats


 clear all
set more off
capture log close
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

**************** compute export moments (already computed by Export_02, but done again here to output explicitly)
/* Creates 3 export moments:
(A) sales of exporters / sales of all firms
(B) sales of manufacturing exporters / sales of all manufacturers
(C) manuf sales of manufacturing exporters / manuf sales of all manufacturers

Exporting firm status is given by is_exporter (joint of LFTTD and EC exports)
Manufacturing firm status is given by is_manuf (type==M/M+)
*/

* grab firmid exporting etc identifiers
use "$data/ec_lfttd_salesexp2007.dta", clear
keep firmid lfttd_exporter ec_exporter is_manuf is_exporter
sort firmid lfttd_exporter ec_exporter is_manuf is_exporter
duplicates drop firmid lfttd_exporter ec_exporter is_manuf is_exporter, force
save "$data/export_ids.dta", replace //unique dataset of firmids

*Bring in main firm data	
use "$data/firm_data_2007.dta", clear  

**Add the export identifiers
merge 1:1 firmid using "$data/export_ids.dta"
tabstat sales, by(_m) stat(sum)
drop if _merge==2
drop _merge
ren sales_cmf sales_manuf
tab type is_manuf
* streamlining the definition of manuf to what AFT use (based on emp, not sales)
drop is_manuf
gen is_manuf = 1 if type=="M" | type=="M+"
replace is_manuf = 0 if missing(is_manuf)
save "$data/firm_lfttd_exports.dta", replace 
// THIS IS THE SAMPLE THAT WE NOW USE TO COMPUTE MOMENTS. SAME SALES, M/M+, etc as the firm_data_2007 sample

collapse (sum) sales sales_manuf, by(is_exporter)
egen tot_sales = total(sales)
gen frac=sales/tot_sales 
egen tot_sales_manuf = total(sales_manuf)
gen frac_manuf=sales_manuf/tot_sales_manuf 
file open mom using "$output/moments_final.txt", write text replace
keep if is_exporter==1
summ frac // moment (A)
file write mom "(A) sales of exporters / sales of all firms:"
file write mom %7.4f (r(max)) _n

use "$data/firm_lfttd_exports.dta", clear
keep if is_manuf==1 
collapse (sum) sales sales_manuf, by(is_exporter)
egen tot_sales = total(sales)
gen frac=sales/tot_sales
egen tot_sales_manuf = total(sales_manuf)
gen frac_manuf=sales_manuf/tot_sales_manuf 
keep if is_exporter==1
summ frac
file write mom "(B) sales of manufacturing exporters / sales of all manufacturers:"
file write mom %7.4f (r(max)) _n
summ frac_manuf
file write mom "(C) manuf sales of manufacturing exporters / manuf sales of all manufacturers:"
file write mom %7.4f (r(max)) _n


**************** compute IMPORT moments purely from LFTTD imp, restricted to the firm-level dataset created by Stata_01
/* Creates 3 import moments:
(G) sales of importers / sales of all firms
(H) sales of (M/M+) importers / sales of all (M/M+) firms
(I) CMF sales of (M/M+) importers / CMF sales of all (M/M+) firms

Importing firm status is given by importer (LFTTD)
Manufacturing firm status is given by is_manuf (type==M/M+)
*/

use "$data/firm_lfttd_exports.dta", clear
collapse (sum) sales sales_manuf, by(importer)
egen tot_sales = total(sales)
gen frac=sales/tot_sales 
egen tot_sales_manuf = total(sales_manuf)
gen frac_manuf=sales_manuf/tot_sales_manuf 
keep if importer==1
summ frac // moment (D)
file write mom "(G) sales of importers / sales of all firms:"
file write mom %7.4f (r(max)) _n

use "$data/firm_lfttd_exports.dta", clear
keep if is_manuf==1
collapse (sum)  sales sales_manuf, by(importer)
egen tot_sales = total(sales)
gen frac=sales/tot_sales 
egen tot_sales_manuf = total(sales_manuf)
gen frac_manuf=sales_manuf/tot_sales_manuf
keep if importer==1
summ frac
file write mom "(H) sales of manufacturing importers / sales of all manufacturing firms:"
file write mom %7.4f (r(max)) _n
summ frac_manuf
file write mom "(I) manuf sales of manufacturing importers / manuf sales of all manufacturers:"
file write mom %7.4f (r(max)) _n
file close mom
clear

