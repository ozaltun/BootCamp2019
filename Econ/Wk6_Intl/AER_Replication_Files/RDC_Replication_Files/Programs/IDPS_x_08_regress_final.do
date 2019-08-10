/* 
This produces all the regressions and output tables

using:
China_dhs
industry3 (439 naics_x industries)
share3 (manuf sales shares based instrument shock)
using input and domestic computed using the cost of materials + ww + merch method

FINAL VERSION: Produces in one output table: 
=================================================================
across colums are lhs variables, and OLS / IV versions of the rhs variable:
lhs = sales, tot inputs, domestic inputs, count of foreign countries, other inputs (non-Chinese imports), tot emp, manf emp, manf emp share
all lhs variables are in dhs growth rates except for the count of foreign countries, which is in d_log
rhs = china_dhs, for the balanced sample of firms in 1997 and 2007, instrumented for using d_share3_sal_in_fixshock3

down the rows, repeat the above for:
1. no controls,
2. controlling for imppen
3. instrumenting for imppen using d_share3_sal_fixshock3

+ a first stage table for each of 1,2, and 3
*/

clear all
set more off
capture log close

cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global temp

local deftype _def

use "$data/diff_for_reg_firmid_clean`deftype'.dta", clear
		
*0 Label variables for regression output table
*******************************
label variable d_share3_imppen_fix "Import Pen, f"	
label variable china_dhs "China, DHS"
label variable d_share3_sal_fixshock "Output shock, f"	
label variable d_share3_sal_in_fixshock "Input shock, f"
	
	
*1 Additional sample selection based on dropping inputs==0, domestic<=0, selecting firms with manuf content both years
******************************************
gen accept=1 if d_log_inputs~=. & d_log_dom ~=. & panel_manuf==1
keep if accept==1
	
* FIX EMPLOYMENT DHS VARIABLES - MANY SUB CATEGORIES ARE MISSING VALUES BECAUSE DHS GROWTH CAN HAVE 0 DENOMINATOR - TREAT THIS AS 0 GROWTH
foreach var of varlist emp*_dhs {
	di "`var'"
	count if missing(`var')
	replace `var' = 0 if missing(`var')
	}
******************************************


*2 Preliminaries: Summary stats for categories of firms in 1997, based on regression sample
******************************************
*2. China importer summary stats

log using "$output/IDPS_firmstats_1997.txt", replace text
preserve
*generate 3 mutually exclusive categories of firms:
	gen firm_cat = "a) Non-importers" if imp_other_1997 + imp_china_1997 ==0 // non importers
	replace firm_cat = "b) China importers" if imp_china_1997 >0 // china importers 
	replace firm_cat = "c) Other country importers" if imp_china_1997 == 0 & imp_other_1997>0 // non-china importers
	unique firmid
	gen numfirms=1
	*replacing imp_ext to be exlcuding china count (but still including US count)
	replace imp_ext_1997 = imp_ext_1997 - 1 if imp_china_1997 >0
	save $data/temp_disc, replace
	*tabstat sales_1997 emp_1997 imp_ext_1997 domestic_1997 imp_china_1997 imp_other_1997, by(firm_cat) stats(mean N) 
	collapse (mean) sales_1997 emp_1997 imp_ext_1997 domestic_1997 imp_china_1997 imp_other_1997 (sum) numfirms, by(firm_cat)
        foreach var of varlist sales* domestic* imp_china imp_other {
          gen `var'_rounded=round(`var'/1000) //sales, domestic sourcing, imports to the nearest MILLION 
          }
	gen emp_1997_rounded=round(emp_1997/10) // employment to the nearest TEN
	gen double imp_ext_1997_rounded = round(imp_ext_1997,.1) //round number of countries to nearest .1 country for more clarity
	    
	*keep firm_cat  *1997r
	*order firm  sales emp imp_ext domestic imp_ch imp_ot
	keep firm_cat *_rounded
	order firm sales emp domestic imp*
	export excel using $output/Results_to_disclose, sheet(IDPS_firmstats_1997, replace) firstrow(variables) 
	* emp in numbers of employees
	* all $ values in nominal 1997 $000s if _def, else in inflated 2007 $000s if _inf
	* extensive margin sourcing country count excludes China but includes the US (so all firms >=1)
restore
log close

/*

OUTPUT TO CREATE:
1. FIRST STAGE REGRESSIONS  WITH KP AND OTHER STATS
2. SECOND STAGE REGRESSIONS 	
	
1. BASELINE, NO CONTROL
2. WITH IMP PEN AS CONTROL
3. WITH IMP PEN INSTRUMENTED
4. DO 1-3 FOR DHS CHINA AND FOR NEW CHINA IMPORTER

EACH SET OF REGS SHOULD INCLUDE:
 1. LOG_INPUTS
 2. LOG_DOMESTIC
 3. IMP_OTHER_DHS
 4. LOG_IMP_EXT
 
*/
log using "$output/IDPS_Regs_final_rep`deftype'_FINAL.txt", replace text		

*foreach var in china_dhs {
*global china `var'

	
global china china_dhs	
	
*1. IV REGRESSIONS
 *a. Baseline
 set more off
 ivreg2 d_log_imp_ext ($china = d_share3_sal_in_fixshock3), cluster(industry3) first  savefirst savefprefix(base_)
 estadd scalar Nround=round(e(N),100)
 estimates store IV_ext
 gen sample=e(sample)
 
 ivreg2 domestic_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst 
 estadd scalar Nround=round(e(N),100)
 estimates store IV_dom  
 
 ivreg2 imp_othr_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst 
 estadd scalar Nround=round(e(N),100)
 estimates store IV_othr
 
 ivreg2 tot_inputs_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst 
 estadd scalar Nround=round(e(N),100)
 estimates store IV_inputs
 
  ivreg2 sales_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst 
  estadd scalar Nround=round(e(N),100)
 estimates store IV_sal
 
 ivreg2 emp_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst
 estadd scalar Nround=round(e(N),100)
 estimates store IV_emp
 
 ivreg2 emp_man_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst 
 estadd scalar Nround=round(e(N),100)
 estimates store IV_man  
 
 ivreg2 emp_man_share_dhs ($china = d_share3_sal_in_fixshock3), cluster(industry3) savefirst 
 estadd scalar Nround=round(e(N),100)
 estimates store IV_msh

 *b. OLS Regressions, baseline
regress d_log_imp_ext $china, cluster(industry3)
estadd scalar Nround=round(e(N),100)
estimates store OLS_ext

regress domestic_dhs $china, cluster(industry3)
estadd scalar Nround=round(e(N),100)
estimates store OLS_dom

regress imp_othr_dhs $china, cluster(industry3)
estadd scalar Nround=round(e(N),100)
estimates store OLS_othr

regress tot_inputs_dhs $china , cluster(industry3)	
estadd scalar Nround=round(e(N),100)   
estimates store OLS_inputs
 
 regress sales_dhs $china, cluster(industry3)
 estadd scalar Nround=round(e(N),100)
estimates store OLS_sal

regress emp_dhs $china, cluster(industry3)
estadd scalar Nround=round(e(N),100)
estimates store OLS_emp

regress emp_man_dhs $china, cluster(industry3)
estadd scalar Nround=round(e(N),100)
estimates store OLS_man

regress emp_man_share_dhs $china, cluster(industry3)	  
estadd scalar Nround=round(e(N),100) 
estimates store OLS_msh
 
***Output Regressions*** 
estout OLS_sal OLS_inputs OLS_dom OLS_ext OLS_othr OLS_emp OLS_man OLS_msh IV_sal IV_inputs IV_dom IV_ext IV_othr IV_emp IV_man IV_msh ///
           using "$output/IDPS_Tables_${china}`deftype'_FINAL.txt", replace title(Baseline Regressions China Var is : $china) ///
	   order($china) cells(b(star fmt(%9.3f)) se(par))  ///
	   stats(r2_a Nround N_clust widstat arf arfp archi2 archi2p, fmt(%9.2f %9.3gc %9.3g %9.2f %9.2f %9.3f %9.2f %9.3f) ///
	   labels(Adj.R2 N Clusters K-PFstat ARFtest ARpval ARChi ARChip)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) label
	   
estout OLS_sal OLS_inputs OLS_dom OLS_ext OLS_othr OLS_emp OLS_man OLS_msh IV_sal IV_inputs IV_dom IV_ext IV_othr IV_emp IV_man IV_msh ///
           using "$output/IDPS_Tables_${china}`deftype'_FINAL.xls", replace title(Baseline Regressions China Var is : $china ) ///
	   order($china ) cells(b(star fmt(%9.3f)) se(par(`"="("'`")""')))  ///
	   stats(r2_a Nround N_clust widstat arf arfp archi2 archi2p, fmt(%9.2f %9.3gc %9.3g %9.2f %9.2f %9.3f %9.2f %9.3f) ///
	   labels(Adj.R2 N Clusters K-PFstat ARFtest ARpval ARChi ARChip)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tab) label
	   
**How to capture Stock and Yogo critical value of: 16.38 for 10 perecent maximal IV size?	 	

*2. With import penetration as a control
set more off
 ivreg2 d_log_imp_ext ($china =d_share3_sal_in_fixshock3 ) d_share3_imppen_fix, cluster(industry3) first  savefirst savefprefix(cimp_)
 estimates store IV_ext
 
 ivreg2 domestic_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_dom 
 
 ivreg2 imp_othr_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_othr
 
 ivreg2 tot_inputs_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_inputs

 ivreg2 sales_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_sal
 
 ivreg2 emp_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_emp

 ivreg2 emp_man_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_man
 
 ivreg2 emp_man_share_dhs ($china =d_share3_sal_in_fixshock3) d_share3_imppen_fix, cluster(industry3) savefirst 
 estimates store IV_msh


 *e. OLS Regressions, with import penetration as control
regress d_log_imp_ext $china d_share3_imppen_fix, cluster(industry3)
estimates store OLS_ext

regress domestic_dhs $china d_share3_imppen_fix, cluster(industry3)
estimates store OLS_dom

regress imp_othr_dhs $china d_share3_imppen_fix, cluster(industry3)
estimates store OLS_othr

regress tot_inputs_dhs $china d_share3_imppen_fix, cluster(industry3)	   
estimates store OLS_inputs

regress sales_dhs $china d_share3_imppen_fix, cluster(industry3)
estimates store OLS_sal

regress emp_dhs $china d_share3_imppen_fix, cluster(industry3)
estimates store OLS_emp

regress emp_man_dhs $china d_share3_imppen_fix, cluster(industry3)
estimates store OLS_man

regress emp_man_share_dhs $china d_share3_imppen_fix, cluster(industry3)	   
estimates store OLS_msh

estout OLS_sal OLS_inputs OLS_dom OLS_ext OLS_othr OLS_emp OLS_man OLS_msh IV_sal IV_inputs IV_dom IV_ext IV_othr IV_emp IV_man IV_msh ///
	using "$output/IDPS_Tables_${china}`deftype'_FINAL.txt", append title(Imp Pen Control Regressions, China Var is : $china) ///
	   order($china) cells(b(star fmt(%9.3f)) se(par))  ///
	    stats(r2_a     N_clust widstat arf arfp archi2 archi2p, fmt(%9.2f  %9.3g %9.2f %9.2f %9.3f %9.2f %9.3f) ///
	   labels(Adj.R2  Clusters K-PFstat ARFtest ARpval ARChi ARChip)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) label
	   
estout OLS_sal OLS_inputs OLS_dom OLS_ext OLS_othr OLS_emp OLS_man OLS_msh IV_sal IV_inputs IV_dom IV_ext IV_othr IV_emp IV_man IV_msh ///
	using "$output/IDPS_Tables_${china}`deftype'_FINAL.xls", append title(Imp Pen Control Regressions, China Var is : $china) ///
	   order($china ) cells(b(star fmt(%9.3f)) se(par(`"="("'`")""')))  ///
	    stats(r2_a     N_clust widstat arf arfp archi2 archi2p, fmt(%9.2f  %9.3g %9.2f %9.2f %9.3f %9.2f %9.3f) ///
	   labels(Adj.R2  Clusters K-PFstat ARFtest ARpval ARChi ARChip)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tab) label

*3. Instrumenting for import penetration	
set more off
ivreg2 d_log_imp_ext ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) first  savefirst savefprefix(ivimp_)
 estimates store IV_ext

ivreg2 domestic_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_dom 

 ivreg2 imp_othr_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_othr

 ivreg2 tot_inputs_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_inputs
 
  ivreg2 sales_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_sal

 ivreg2 emp_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_emp
 	
 ivreg2 emp_man_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_man

 ivreg2 emp_man_share_dhs ($china d_share3_imppen_fix=d_share3_sal_in_fixshock3 d_share3_sal_fixshock3), cluster(industry3) savefirst 
 estimates store IV_msh
 	
estout OLS_sal OLS_inputs OLS_dom OLS_ext OLS_othr OLS_emp OLS_man OLS_msh IV_sal IV_inputs IV_dom IV_ext IV_othr IV_emp IV_man IV_msh ///
	using "$output/IDPS_Tables_${china}`deftype'_FINAL.txt", append title(Imp Pen Instrumented Regressions, China Var is : $china) ///
	   order($china) cells(b(star fmt(%9.3f)) se(par))  ///
	   stats(r2_a     N_clust widstat arf arfp archi2 archi2p, fmt(%9.2f  %9.3g %9.2f %9.2f %9.3f %9.2f %9.3f) ///
	   labels(Adj.R2  Clusters K-PFstat ARFtest ARpval ARChi ARChip)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) label

estout OLS_sal OLS_inputs OLS_dom OLS_ext OLS_othr OLS_emp OLS_man OLS_msh IV_sal IV_inputs IV_dom IV_ext IV_othr IV_emp IV_man IV_msh ///
	using "$output/IDPS_Tables_${china}`deftype'_FINAL.xls", append title(Imp Pen Instrumented Regressions, China Var is : $china) ///
	   order($china ) cells(b(star fmt(%9.3f)) se(par(`"="("'`")""')))  ///
	   stats(r2_a     N_clust widstat arf arfp archi2 archi2p, fmt(%9.2f  %9.3g %9.2f %9.2f %9.3f %9.2f %9.3f) ///
	   labels(Adj.R2  Clusters K-PFstat ARFtest ARpval ARChi ARChip)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tab) label


estout base_$china cimp_$china ivimp_$china ivimp_d_share3_imppen_fix using "$output/IDPS_Tables_${china}`deftype'_FINAL.txt", append title(First Stage Regressions, China Var is : $china) ///
	   order(d_share3_sal_in_fixshock3 d_share3_imppen_fix d_share3_sal_fixshock3) cells(b(star fmt(%9.3f)) se(par))  ///
	   stats(r2_a    F  , fmt(%9.2f %9.2f) ///
	   labels(Adj.R2 F  )) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) label

estout base_$china cimp_$china ivimp_$china ivimp_d_share3_imppen_fix using "$output/IDPS_Tables_${china}`deftype'_FINAL.xls", append title(First Stage Regressions, China Var is : $china) ///
	   order(d_share3_sal_in_fixshock3 d_share3_imppen_fix d_share3_sal_fixshock3) cells(b(star fmt(%9.3f)) se(par(`"="("'`")""')))  ///
	   stats(r2_a    F  , fmt(%9.2f %9.2f) ///
	   labels(Adj.R2 F  )) starlevels(* 0.10 ** 0.05 *** 0.01) style(tab) label

log close	   


