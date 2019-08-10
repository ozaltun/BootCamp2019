
* NOTE THIS DO FILE MUST BE RUN INTERACTIVELY AND NOT IN BATCH DUE TO TRANSLATOR GRAPH2PNG PROBLEMS
/*

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

set matsize 800
set more off

**Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

**Bring in premia figures data
use $data/premia_figs.dta, clear

 tab country_count, miss  
 tab country_count if importer_2002==0, miss
 
*Only for sample of importers 
forvalues i=1/25 {
  gen imp_d07_`i'=1 if country_count>=`i' & country_count~=.
  replace imp_d07_`i'=0 if country_count<`i'
  }
  
forvalues i=1/9 {
  gen imp_d02_`i'=1 if country_count>=`i' & country_count~=.
  replace imp_d02_`i'=0 if country_count<`i'
  }
  
  
***Make back-up figures based only on importers (not in manuscript)
*************************************************  
foreach cont in imports exports {
regress log_sales imp_d07* num_`cont'_hs ind*  
capture drop samp1_`cont'
gen samp1_`cont'= e(sample)

quietly {
capture drop graph07 se07
gen graph07=.
gen se07=.

  lincom imp_d07_2
  replace graph07=r(estimate) if _n==3
  replace se07=r(se) if _n==3
   
  lincom imp_d07_2+imp_d07_3
  replace graph07=r(estimate) if _n==4
  replace se07=r(se) if _n==4
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4
  replace graph07=r(estimate) if _n==5
  replace se07=r(se) if _n==5
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5
  replace graph07=r(estimate) if _n==6
  replace se07=r(se) if _n==6
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6
  replace graph07=r(estimate) if _n==7
  replace se07=r(se) if _n==7
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7
  replace graph07=r(estimate) if _n==8
  replace se07=r(se) if _n==8
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8
  replace graph07=r(estimate) if _n==9
  replace se07=r(se) if _n==9
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9
  replace graph07=r(estimate) if _n==10
  replace se07=r(se) if _n==10
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10
  replace graph07=r(estimate) if _n==11
  replace se07=r(se) if _n==11
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11
  replace graph07=r(estimate) if _n==12
  replace se07=r(se) if _n==12
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12
  replace graph07=r(estimate) if _n==13
  replace se07=r(se) if _n==13
   
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13
  replace graph07=r(estimate) if _n==14
  replace se07=r(se) if _n==14
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13
  replace graph07=r(estimate) if _n==14
  replace se07=r(se) if _n==14
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14
  replace graph07=r(estimate) if _n==15
  replace se07=r(se) if _n==15
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15
  replace graph07=r(estimate) if _n==16
  replace se07=r(se) if _n==16
  
   lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16
  replace graph07=r(estimate) if _n==17
  replace se07=r(se) if _n==17
  
   lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17
  replace graph07=r(estimate) if _n==18
  replace se07=r(se) if _n==18
  
   lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18
  replace graph07=r(estimate) if _n==19
  replace se07=r(se) if _n==19
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19
  replace graph07=r(estimate) if _n==20
  replace se07=r(se) if _n==20
  
   lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20
  replace graph07=r(estimate) if _n==21
  replace se07=r(se) if _n==21
   
   lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21
  replace graph07=r(estimate) if _n==22
  replace se07=r(se) if _n==22
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22
  replace graph07=r(estimate) if _n==23
  replace se07=r(se) if _n==23
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23
  replace graph07=r(estimate) if _n==24
  replace se07=r(se) if _n==24
  
  lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23+imp_d07_24
  replace graph07=r(estimate) if _n==25
  replace se07=r(se) if _n==25
  
   lincom imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23+imp_d07_24+imp_d07_25
  replace graph07=r(estimate) if _n==26
  replace se07=r(se) if _n==26
  
  capture drop CI07_l
  gen CI07_l=graph07-1.96*se07
  capture drop CI07_u
  gen CI07_u=graph07+1.96*se07
  
  capture drop Num_Coun
  gen Num_Countries=_n if graph07~=.
 } 
 #delimit ;
  twoway rarea graph07 CI07_l Num_Countries, color(gs12)  
     || rarea graph07 CI07_u Num_Countries, color(gs12) 
     || line graph07 Num_Countries, sort color(blue) yaxis(1) 
     ||,
	   ytitle( "Premium", axis(1))  ylabel(0(1)6)
	   xlabel(1(2)26)
	   xtitle("Minimum number of countries from which firm sources")
           legend(order(3 "Premium" 2 "95% CI" ));	
graph save $output/Premia07_`cont'_rb.gph, replace  /* Don't disclose graph file yet */	 ;     	 
graph export $output/Premia07_`cont'_rb.png, replace	 ; 
 #delimit cr
graph export $output/Premia07_`cont'_rb.eps, replace	 
}

*************************************************  

*Without employment controls, including non-importers

gen imp_d07_0=1 if country_count==.
replace imp_d07_0=0 if country_count~=.
forvalues i=1/25 {
  replace imp_d07_`i'=0 if country_count<`i' | country_count==.
  }

gen imp_d02_0=1 if country_count==.
replace imp_d02_0=0 if country_count~=.
forvalues i=1/9 {
  replace imp_d02_`i'=0 if country_count<`i' | country_count==.
  }
  
  
  
****MAKE BASELINE FIGURES HERE****  
   ****this is the intro figure  ****
   ****also, the appendix table limited to non-2002 importers***
 
regress log_sales imp_d07* ind*  
capture drop samp5
gen samp5= e(sample)

quietly {
capture drop graph07 se07
gen graph07=.
gen se07=.
forvalues i=1/2  {
  local j=`i'-1
  replace graph07=_b[imp_d07_`j']  if _n==`i'
  replace se07=_se[imp_d07_`j']  if _n==`i'
  }
  
  lincom imp_d07_1+imp_d07_2
  replace graph07=r(estimate) if _n==3
  replace se07=r(se) if _n==3
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3
  replace graph07=r(estimate) if _n==4
  replace se07=r(se) if _n==4
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4
  replace graph07=r(estimate) if _n==5
  replace se07=r(se) if _n==5
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5
  replace graph07=r(estimate) if _n==6
  replace se07=r(se) if _n==6
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6
  replace graph07=r(estimate) if _n==7
  replace se07=r(se) if _n==7
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7
  replace graph07=r(estimate) if _n==8
  replace se07=r(se) if _n==8
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8
  replace graph07=r(estimate) if _n==9
  replace se07=r(se) if _n==9
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9
  replace graph07=r(estimate) if _n==10
  replace se07=r(se) if _n==10
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10
  replace graph07=r(estimate) if _n==11
  replace se07=r(se) if _n==11
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11
  replace graph07=r(estimate) if _n==12
  replace se07=r(se) if _n==12
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12
  replace graph07=r(estimate) if _n==13
  replace se07=r(se) if _n==13
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13
  replace graph07=r(estimate) if _n==14
  replace se07=r(se) if _n==14
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13
  replace graph07=r(estimate) if _n==14
  replace se07=r(se) if _n==14
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14
  replace graph07=r(estimate) if _n==15
  replace se07=r(se) if _n==15
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15
  replace graph07=r(estimate) if _n==16
  replace se07=r(se) if _n==16
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16
  replace graph07=r(estimate) if _n==17
  replace se07=r(se) if _n==17
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17
  replace graph07=r(estimate) if _n==18
  replace se07=r(se) if _n==18
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18
  replace graph07=r(estimate) if _n==19
  replace se07=r(se) if _n==19
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19
  replace graph07=r(estimate) if _n==20
  replace se07=r(se) if _n==20
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20
  replace graph07=r(estimate) if _n==21
  replace se07=r(se) if _n==21
   
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21
  replace graph07=r(estimate) if _n==22
  replace se07=r(se) if _n==22
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22
  replace graph07=r(estimate) if _n==23
  replace se07=r(se) if _n==23
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23
  replace graph07=r(estimate) if _n==24
  replace se07=r(se) if _n==24
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23+imp_d07_24
  replace graph07=r(estimate) if _n==25
  replace se07=r(se) if _n==25
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23+imp_d07_24+imp_d07_25
  replace graph07=r(estimate) if _n==26
  replace se07=r(se) if _n==26
  
  capture drop CI07_l
  gen CI07_l=graph07-1.96*se07
  capture drop CI07_u
  gen CI07_u=graph07+1.96*se07
  
  capture drop Num_Coun
  gen Num_Countries=_n if graph07~=.
 } 
 #delimit ;
  twoway rarea graph07 CI07_l Num_Countries, color(gs12)  
     || rarea graph07 CI07_u Num_Countries, color(gs12) 
     || line graph07 Num_Countries, sort color(blue) yaxis(1) 
     ||,
	   ytitle( "Premium", axis(1))  ylabel(0(1)6)
	   xlabel(1(2)26)
	   xtitle("Minimum number of countries from which firm sources")
           legend(order(3 "Premium" 2 "95% CI" ));	
graph save $output/Premia07.gph, replace   ;     	 
graph export $output/Premia07.png, replace	 ; 
 #delimit cr
graph export $output/Premia07.eps, replace	 

*2002 figure**
regress log_sales_2002 imp_d02*  ind*  if importer_2002==0
gen samp6=e(sample)
quietly {
capture drop graph02 se02
gen graph02=.
gen se02=.
forvalues i=1/2  {
  local j=`i'-1
  replace graph02=_b[imp_d02_`j']  if _n==`i'
  replace se02=_se[imp_d02_`j']  if _n==`i'
  }
  
  lincom imp_d02_1+imp_d02_2
  replace graph02=r(estimate) if _n==3
  replace se02=r(se) if _n==3
   
  lincom imp_d02_1+imp_d02_2+imp_d02_3
  replace graph02=r(estimate) if _n==4
  replace se02=r(se) if _n==4
   
  lincom imp_d02_1+imp_d02_2+imp_d02_3+imp_d02_4
  replace graph02=r(estimate) if _n==5
  replace se02=r(se) if _n==5
   
  lincom imp_d02_1+imp_d02_2+imp_d02_3+imp_d02_4+imp_d02_5
  replace graph02=r(estimate) if _n==6
  replace se02=r(se) if _n==6
   
  lincom imp_d02_1+imp_d02_2+imp_d02_3+imp_d02_4+imp_d02_5+imp_d02_6
  replace graph02=r(estimate) if _n==7
  replace se02=r(se) if _n==7
   
  lincom imp_d02_1+imp_d02_2+imp_d02_3+imp_d02_4+imp_d02_5+imp_d02_6+imp_d02_7
  replace graph02=r(estimate) if _n==8
  replace se02=r(se) if _n==8
  
  lincom imp_d02_1+imp_d02_2+imp_d02_3+imp_d02_4+imp_d02_5+imp_d02_6+imp_d02_7+imp_d02_8
  replace graph02=r(estimate) if _n==9
  replace se02=r(se) if _n==9
   
  lincom imp_d02_1+imp_d02_2+imp_d02_3+imp_d02_4+imp_d02_5+imp_d02_6+imp_d02_7+imp_d02_8+imp_d02_9
  replace graph02=r(estimate) if _n==10
  replace se02=r(se) if _n==10
  
  capture drop CI02_l
  gen CI02_l=graph02-1.96*se02
  capture drop CI02_u
  gen CI02_u=graph02+1.96*se02
  
  capture drop Num_Coun
  gen Num_Countries=_n if graph02~=.
  }

*Draw figure
 #delimit ;
  twoway rarea graph02 CI02_l Num_Countries, color(gs12)  
     || rarea graph02 CI02_u Num_Countries, color(gs12) 
     || line graph02 Num_Countries, sort color(blue) yaxis(1) 
     ||,
	   ytitle( "2002 Premium", axis(1))
	   xlabel(1(1)10)
	   xtitle("Minimum number of countries from which firm sources")
           legend(order(3 "Premium" 2 "95% CI" ));	
graph save $output/Premia02.gph, replace	 ;     	 
graph export $output/Premia02.png, replace	 ;
  #delimit cr
 graph export $output/Premia02.eps, replace	

  
***ROBUSTNESS FIGURES CONTROLLING FOR THE NUMBER OF EXPORTED PRODUCTS OR IMPORTED PRODUCTS***  
*Make a figure 
*2007 figure**
foreach cont in imports exports {
regress log_sales imp_d07* num_`cont'_hs ind*  
capture drop samp5
gen samp5= e(sample)

quietly {
capture drop graph07 se07
gen graph07=.
gen se07=.
forvalues i=1/2  {
  local j=`i'-1
  replace graph07=_b[imp_d07_`j']  if _n==`i'
  replace se07=_se[imp_d07_`j']  if _n==`i'
  }
  
  lincom imp_d07_1+imp_d07_2
  replace graph07=r(estimate) if _n==3
  replace se07=r(se) if _n==3
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3
  replace graph07=r(estimate) if _n==4
  replace se07=r(se) if _n==4
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4
  replace graph07=r(estimate) if _n==5
  replace se07=r(se) if _n==5
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5
  replace graph07=r(estimate) if _n==6
  replace se07=r(se) if _n==6
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6
  replace graph07=r(estimate) if _n==7
  replace se07=r(se) if _n==7
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7
  replace graph07=r(estimate) if _n==8
  replace se07=r(se) if _n==8
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8
  replace graph07=r(estimate) if _n==9
  replace se07=r(se) if _n==9
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9
  replace graph07=r(estimate) if _n==10
  replace se07=r(se) if _n==10
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10
  replace graph07=r(estimate) if _n==11
  replace se07=r(se) if _n==11
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11
  replace graph07=r(estimate) if _n==12
  replace se07=r(se) if _n==12
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12
  replace graph07=r(estimate) if _n==13
  replace se07=r(se) if _n==13
   
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13
  replace graph07=r(estimate) if _n==14
  replace se07=r(se) if _n==14
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13
  replace graph07=r(estimate) if _n==14
  replace se07=r(se) if _n==14
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14
  replace graph07=r(estimate) if _n==15
  replace se07=r(se) if _n==15
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15
  replace graph07=r(estimate) if _n==16
  replace se07=r(se) if _n==16
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16
  replace graph07=r(estimate) if _n==17
  replace se07=r(se) if _n==17
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17
  replace graph07=r(estimate) if _n==18
  replace se07=r(se) if _n==18
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18
  replace graph07=r(estimate) if _n==19
  replace se07=r(se) if _n==19
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19
  replace graph07=r(estimate) if _n==20
  replace se07=r(se) if _n==20
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20
  replace graph07=r(estimate) if _n==21
  replace se07=r(se) if _n==21
   
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21
  replace graph07=r(estimate) if _n==22
  replace se07=r(se) if _n==22
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22
  replace graph07=r(estimate) if _n==23
  replace se07=r(se) if _n==23
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23
  replace graph07=r(estimate) if _n==24
  replace se07=r(se) if _n==24
  
  lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23+imp_d07_24
  replace graph07=r(estimate) if _n==25
  replace se07=r(se) if _n==25
  
   lincom imp_d07_1+imp_d07_2+imp_d07_3+imp_d07_4+imp_d07_5+imp_d07_6+imp_d07_7+imp_d07_8+imp_d07_9+imp_d07_10+imp_d07_11+imp_d07_12+imp_d07_13+imp_d07_14+imp_d07_15+ ///
   imp_d07_16+imp_d07_17+imp_d07_18+imp_d07_19+imp_d07_20+imp_d07_21+imp_d07_22+imp_d07_23+imp_d07_24+imp_d07_25
  replace graph07=r(estimate) if _n==26
  replace se07=r(se) if _n==26
  
  capture drop CI07_l
  gen CI07_l=graph07-1.96*se07
  capture drop CI07_u
  gen CI07_u=graph07+1.96*se07
  
  capture drop Num_Coun
  gen Num_Countries=_n if graph07~=.
 } 
 #delimit ;
  twoway rarea graph07 CI07_l Num_Countries, color(gs12)  
     || rarea graph07 CI07_u Num_Countries, color(gs12) 
     || line graph07 Num_Countries, sort color(blue) yaxis(1) 
     ||,
	   ytitle( "Premium", axis(1))  ylabel(0(1)6)
	   xlabel(1(2)26)
	   xtitle("Minimum number of countries from which firm sources")
           legend(order(3 "Premium" 2 "95% CI" ));	
graph save $output/Premia07_`cont'.gph, replace   ;     	 
graph export $output/Premia07_`cont'.png, replace	 ; 
 #delimit cr
graph export $output/Premia07_`cont'.eps, replace	 
}
