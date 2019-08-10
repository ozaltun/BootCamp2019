/*
This program use the firm level dataset to make importer premia tables

Pulls in firm employment info
Pull in firm 
*/
set more off

**Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

**Bring in premia tables data, made by parta
use $data/premia_figs.dta, clear

*****PREMIA TABLES WITHOUT EMPLOYMENT CONTROL*****
**ALL 2007 Firms
regress log_emp importer ind*
estadd scalar Nround=round(e(N),100)   
estimates store Emp
regress log_sales importer ind*
estadd scalar Nround=round(e(N),100)   
estimates store Sales
regress lvap_r importer ind*
estadd scalar Nround=round(e(N),100)   
estimates store LVAP
gen regsample1 = "all firms 2007" if e(sample)==1
 
regress log_emp_2002 importer ind*
estadd scalar Nround=round(e(N),100)   
estimates store Emp02
regress log_sales_2002 importer ind*
estadd scalar Nround=round(e(N),100)   
estimates store Sales02
regress lvap_r_2002 importer ind*
estadd scalar Nround=round(e(N),100)   
estimates store LVAP02
gen regsample2 = "all firms 2007 and 2002" if e(sample)==1

estout Emp Sales LVAP Emp02 Sales02 LVAP02  using "$output/TableC2_Premia", replace title(Importer Premia, All Firms, No emp) ///
keep (importer ) cells(b(star fmt(%9.3f)) se(par))  stats(r2_a Nround, fmt(%9.2f %9.0gc) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) 

estout Emp Sales LVAP Emp02 Sales02 LVAP02  using "$output/Appendix_Tables_Mar2017.xls", replace title(Importer Premia, All Firms, No emp) ///
keep (importer ) cells(b(star fmt(%9.3f)) se(par(`"="("'`")""')))  stats(r2_a Nround, fmt(%9.2f %9.0gc) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tab) 

**Subset of 2007 firms that did not import in 2002
regress log_emp importer ind*  if importer_2002==0
estadd scalar Nround=round(e(N),100)   
estimates store Emp
regress log_sales importer ind* if importer_2002==0
estadd scalar Nround=round(e(N),100)   
estimates store Sales
regress lvap_r importer ind* if importer_2002==0
estadd scalar Nround=round(e(N),100)   
estimates store LVAP
gen regsample3 = "all firms 2007 non-importing in 2002" if e(sample)==1

regress log_emp_2002 importer ind* if importer_2002==0
estadd scalar Nround=round(e(N),100)   
estimates store Emp02
regress log_sales_2002 importer ind* if importer_2002==0
estadd scalar Nround=round(e(N),100)   
estimates store Sales02
regress lvap_r_2002 importer ind* if importer_2002==0
estadd scalar Nround=round(e(N),100)   
estimates store LVAP02

estout Emp Sales LVAP Emp02 Sales02 LVAP02   using "$output/TableC2_Premia", append title(Importer Premia, Non-2002 Importers , No emp) ///
keep (importer ) cells(b(star fmt(%9.3f)) se(par))  stats(r2_a Nround, fmt(%9.2f %9.0gc) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) 

estout Emp Sales LVAP Emp02 Sales02 LVAP02  using "$output/Appendix_Tables_Mar2017.xls", append title(Importer Premia, Non-2002 Importers , No emp) ///
keep (importer ) cells(b(star fmt(%9.3f)) se(par(`"="("'`")""')))  stats(r2_a Nround, fmt(%9.2f %9.0gc) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tab) 

save $data/temp.dta, replace
 