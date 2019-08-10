/*
This file perpares the output of IDPS_x_05 into diffeernced form ready for regression

Note that we have not completely selected the sample by the end of the dataset
the final selection depends on determining what to do with domestic inputs < 0

there are 3 variations of domestic inputs, which will all get used in robustness.
additionally, we try changing domestic inputs to very small when they are negative. 

these selection steps are implemented in IDPS_x_08

Also generates some base 1997, 2007 variables per firmid for a summary stats table
*/

clear all
set more off
capture log close

cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global temp

local firmlist `""id""'
local deflist `""" "_def""'
foreach deftype of local deflist {
	foreach firmtype of local firmlist {		
		use "$data/panel_for_reg_firm`firmtype'`deftype'.dta", clear
		replace year = 1 if year==2007
		replace year=0 if year==1997
		destring firm`firmtype', replace
		xtset firm`firmtype' year
		gen time=year

		*1. PREPARE data
		**************************
		*replacing extensive margin to equal zero for non-importers
		// note extensive amrgin is already adjusting to not count china anymore
		replace imp_extensive = 0 if missing(imp_extensive)
		replace imp_extensive_nc = 0 if missing(imp_extensive_nc)
		* count if china_==1 & imp_extensive==0
		summ imp_extens*
		// adding 1 to extensive margin for everyone (do domestic sourcers have count=1)
		replace imp_extensive=imp_extensive+1
		replace imp_extensive_nc=imp_extensive_nc+1
		summ imp_extens*

		// generating alternative instrument whhere we use fixed 97 firm shares to construct shocks
		* this variable will be called fixshock3. check to make sure they are perfectly populated in 2007
		count if year==1 & share3_sal_in_fixshock3~=. & panel_manuf==1
		count if year==1 & share3_sal_in_shock3~=. & panel_manuf==1
		* now give fixshock3 in 1997 the value of shock3 in 1997, for both share and share3
		replace share3_sal_in_fixshock3 = share3_sal_in_shock3 if missing(share3_sal_in_fixshock3) & year==0
		replace share_sal_in_fixshock3 = share_sal_in_shock3 if missing(share_sal_in_fixshock3) & year==0
		* make sure they have the same occurances
		count if share3_sal_in_fixshock3~=. & panel_manuf==1
		count if share3_sal_in_shock3~=. & panel_manuf==1

		// generating alternative instrument whhere we use fixed 97 firm shares to construct shocks
		* this variable will be called fixshock3. check to make sure they are perfectly populated in 2007
		count if year==1 & share3_sal_fixshock3~=. & panel_manuf==1
		count if year==1 & share3_sal_shock3~=. & panel_manuf==1
		* now give fixshock3 in 1997 the value of shock3 in 1997, for both share and share3
		replace share3_sal_fixshock3 = share3_sal_shock3 if missing(share3_sal_fixshock3) & year==0
		replace share_sal_fixshock3 = share_sal_shock3 if missing(share_sal_fixshock3) & year==0
		* make sure they have the same occurances
		count if share3_sal_fixshock3~=. & panel_manuf==1
		count if share3_sal_shock3~=. & panel_manuf==1
		
		// for IDPS_x: generate imppen measures two ways:
		* share3_imppen (floating sale shares), instrument with share3_sal_shock3 (output shock)
		* share3_imppenus_fix (need to extend to year==0), instument with share3_imppeneu_fix (need to extend to year==0)
		count if share3_imppen~=. & panel_manuf==1
		count if share3_sal_shock3~=. & panel_manuf==1
		corr share3_sal_in_fixshock3 share3_sal_shock3 
		corr share3_sal_in_fixshock3 share3_sal_fixshock3 /* main double instrument */
		* now give fix_imppen in 1997 the value of imppen in 1997
		
		foreach var in share3_imppenus share3_imppeneu share3_imppen share_imppen share_imppenus share_imppeneu naics3_imppen naics3_imppenus naics3_imppeneu {
		  count if year==0 & `var'_fix~=. //verify these are indeed missing for ALL year=1997 obs
		  replace `var'_fix = `var' if missing(`var'_fix) & year==0
		  }

		* make sure they have the same occurances
		corr share3_sal_in_fixshock3 share3_imppeneu_fix 
		count if share3_imppenus_fix~=. & panel_manuf==1
		count if share3_imppeneu_fix~=. & panel_manuf==1
		**************************	
		
		*2. FIX VARIABLES
		**************************
		replace imp_other=imp_other/1000
		replace imp_other_nc=imp_other_nc/1000
		replace imp_other = 0 if missing(imp_other)
		replace imp_other_nc = 0 if missing(imp_other_nc)
		replace imp_china=imp_china/1000
		replace imp_china = 0 if missing(imp_china)
		label variable imp_other "Non-China imports, $000s"
		label variable imp_other_nc "Non-China, non-Canada imports, $000s"
		label variable imp_china "China imports, $000s"
		**************************

		*3. CREATE NEW VARIABLES 
		**************************
		// we will only keep year==1 data later, so only make this for year==1 firmids
		gen china_1997=1 if L1.imp_china~=0 & year==1
		gen china_2007=1 if imp_china~=0 & year==1

		gen log_imp_other=log(imp_other) 
		gen log_imp_other_nc=log(imp_other_nc) //no canada
		
		gen log_imp_ext = log(imp_extensive) //extensive count starts from 1
		gen log_imp_ext_nc = log(imp_extensive_nc) //extensive count excluding canada starts from 1
		
		gen log_dom = log(domestic) //lndom
		gen log_dom_manuf = log(domestic_manuf) //lndom_manuf
		gen log_dom_va = log(domestic_va) //lndom_manuf
		
		gen log_sales=log(sales)
		
		gen log_inputs=log(tot_inputs)
		gen log_inputs_va=log(tot_inputs_va)
		gen log_inputs_manuf = log(tot_inputs_manuf)

		drop emp_census //very close to emp
		gen log_emp=log(emp)
		foreach var of varlist emp_* {
			gen log_`var' = log(`var')
			gen `var'_share = `var'/emp
			gen log_`var'_share = log(`var'_share)
			}
		* relevant variables: log_emp*, emp*_share, emp*
		
		**************************		
		di "fraction of china M/M+ importers, before balancing panel"
		// before balancing the panel
		tab china_importer year if hasmanuf==1
		
		*4. LIMIT SAMPLE
		**************************
		keep if panel_manuf==1 | panel_manuf97==1  /*  Some manufacturing in 97 */
		**************************
	
		di "fraction of china M/M+ importers in main regression (after balancing panel)"
		// after balancing the panel
		tab china_importer year if panel_manuf==1
		
		*5. ASSESS VARIABLES
		**************************
		tab panel_domes panel_manuf if panel_manuf==1
		tab panel_domes panel_domes_manuf if panel_manuf==1
		tab panel_domes panel_domes_va if panel_manuf==1
				
		di "how persistent are negative inputs?"
		// among firms in panel with some manuf in both periods, what do the inputs of flag_neg_dom<1 look like?
		bys firmid: egen yearsnegdom = total(flag_neg_dom)
		tab yearsnegdom type if year==0 & panel_manuf==1
		tab yearsnegdom type if year==1 & panel_manuf==1
		bys type: tab flag_neg_dom year if panel_manuf==1
		
		*6. VARIABLE SELECTION
		*************************
		/* SUMMARY OF KEY REGRESSION VARIABLES that are now nonmissing for all manuf firms
		
		FIRM OUTCOME VARIABLES:
		log_sales - log (sales - ipt)
		log_inputs - log (total inputs)
		log_dom - log ( domestic inpust)
		dom_share2 - domestic inputs / total non-china inputs
		dom_share_fix - domestic inputs / total non-china inputs fixed in 1997
		log_imp_ext  - log of extensive margin that now includes sourcing from US
		imp_extens - count of extensive margin that includes sourcing from US
		imp_share - non-China imports / (non-China imports + domestic sourcing)
		imp_share_fix - above with fixed 1997 denominator (so captures scale)
		
		RHS / IV VARIABLES:
		china2_ - dummy if imp from china. prevented from being 0 in 2007 if previouly =1
		imp_china_growth - china imoport growth = chinese imports in t / average imports in t, t-1

		imp_share_manuf - the above but scaled to focus on manufacturing
		share3_sal_in_shock3 - alternative input shock instrument (variable shares)
		share3_sal_shock3 - alternate output shock instrument (variable shares)
		share3_sal_in_fixshock3 - main input shock instrument (1997 shares fixed)
		share3_sal_fixshock3 - main output shock instrument for imppen (1997 shares fixed)
		share3_imppen - main china impport penetration firm control variable (variable shares)
		share3_imppen_fix - main china impport penetration firm control variable (fix shares)
		share3_imppenus_fix - alterntive (ADH) china imppen firm control variable (fix shares)
			* diff between impen_fix and imppenus_fix is that the denom is fixed only in imppenus_fix
		share3_imppeneu_fix - alternative (ADH) china imppen firm instrument (fix shares) 
		
		ID VARIABLES:
		firmid
		year = time = 0 for 1997, =1 for 2007
		industry(_b) - firm's main industry by sales
		industry3(_b) - firm's main manuf industry by sales
		*/ 	
		#delimit ;
		keep 
		china_1997
		china_2007
		sales
		emp* log_emp*
		log_sales 
		tot_inputs tot_inputs_va tot_inputs_manuf log_inputs* //cm, va, and cmf
		domestic* log_dom* //cm, va, and cmf
		log_imp_other log_imp_other_nc // imports from other countries
		log_imp_ext  log_imp_ext_nc
		imp_extensive imp_extensive_nc
		imp_china
		imp_other imp_other_nc
		china2_
		share3_sal_in_shock3 
		share3_sal_shock3 
		share3_sal_in_fixshock3
		share3_sal_fixshock3
		share_sal_in_shock3 
		share_sal_shock3 
		share_sal_in_fixshock3
		share_sal_fixshock3 
		share3_imppen 
		share3_imppen_fix
		share3_imppenus_fix 
		share3_imppeneu_fix 
		share_imppen 
		share_imppen_fix
		share_imppenus_fix 
		share_imppeneu_fix 
		panel_manuf panel_manuf97
		firm`firmtype' year time industry*
		;
		#delimit cr
		summ
		label var imp_extensive "count of total sourcing countries including self"
		label var log_imp_ext "log count of tot sourcing ctys incl. self"
		label var log_dom "log domsetic sourcing, cost of materials + ww - imports"
		label var log_dom_va "log domsetic sourcing, sales - va + ww + merch - imports"
		label var log_dom_manuf "log domsetic sourcing, manuf materials + ww + merch - imports"
		label var log_inputs "log total sourcing, cost of materials + ww + merch"
		label var log_inputs_va "log total sourcing, sales - va + ww + merch"
		label var log_inputs_manuf "log total sourcing, manuf materials + ww + merch"
		*d
		save "$data/panel_for_reg_firm`firmtype'_clean`deftype'.dta", replace
	
		*6. Generate first differences and keep.
		*************************
		sort firm`firmtype' year
		foreach var of varlist log_emp* log_sales log_inputs* log_dom* log_imp* share* {
			gen d_`var'=`var'-L1.`var' 
			}
		* will only be populated for year==1
		
		*Create DHS growth rates for china imports and other imports
		bysort firm`firmtype': egen china_mean=mean(imp_china)
		gen china_dhs=(imp_china-L1.imp_china)/china_mean
		
		bysort firm`firmtype': egen imp_other_mean=mean(imp_other)
		gen imp_othr_dhs=(imp_other-L1.imp_other)/imp_other_mean
		
		bysort firm`firmtype': egen imp_other_mean_nc=mean(imp_other_nc)
		gen imp_othr_dhs_nc=(imp_other_nc-L1.imp_other_nc)/imp_other_mean_nc

		replace china_dhs=0 if china_dhs==.
		replace imp_othr_dhs=0 if imp_othr_dhs==.
		replace imp_othr_dhs_nc=0 if imp_othr_dhs_nc==.
			
		* Create DHS growth rates for all employment variables (emp and empshares) AND sales
		foreach var of varlist emp* sales {
			bysort firm`firmtype': egen temp_mean=mean(`var')
			gen `var'_dhs=(`var'-L1.`var')/temp_mean
			drop temp_mean
			}
		
		* Create DHS growth rates for domestic and total inputs
		bysort firm`firmtype': egen tot_inputs_mean=mean(tot_inputs)
		gen tot_inputs_dhs=(tot_inputs-L1.tot_inputs)/tot_inputs_mean
	
		bysort firm`firmtype': egen tot_inputs_manuf_mean=mean(tot_inputs_manuf)
		gen tot_inputs_manuf_dhs=(tot_inputs_manuf-L1.tot_inputs_manuf)/tot_inputs_manuf_mean
		
		bysort firm`firmtype': egen tot_inputs_va_mean=mean(tot_inputs_va)
		gen tot_inputs_va_dhs=(tot_inputs_va-L1.tot_inputs_va)/tot_inputs_va_mean
		
		bysort firm`firmtype': egen domestic_mean=mean(domestic)
		gen domestic_dhs=(domestic-L1.domestic)/domestic_mean
	
		bysort firm`firmtype': egen domestic_va_mean=mean(domestic_va)
		gen domestic_va_dhs=(domestic_va-L1.domestic_va)/domestic_va_mean
		
		bysort firm`firmtype': egen domestic_manuf_mean=mean(domestic_manuf)
		gen domestic_manuf_dhs=(domestic_manuf-L1.domestic_manuf)/domestic_manuf_mean
		
		gen china_new=china2
		replace china_new=0 if  L1.imp_china~=0 // this is equal to d_china2
		label variable china_new "New China importer"
		label variable china2 "New or continuing China importer"
		
		// generate more variables for summary stats in 1997/2007:
		sort firm`firmtype' year
		gen imp_ext_1997= L1.imp_extensive 
		gen imp_ext_2007= imp_extensive
		gen sales_1997= L1.sales
		gen sales_2007= sales
		gen emp_1997 = L1.emp //these sales and emp will be uued for weighted regressions
		gen emp_2007 = emp
		gen imp_other_1997 = L1.imp_other
		gen imp_other_2007 = imp_other
		gen imp_china_1997 = L1.imp_china
		gen imp_china_2007 = imp_china
		gen domestic_1997 = L1.domestic
		gen domestic_2007 = domestic
		gen tot_inputs_1997 = L1.tot_inputs
		gen tot_inputs_2007 = tot_inputs
		
		keep if year==1
		drop year time
		keep d_* china_dhs imp_othr_dhs imp_othr_dhs_nc china2 ///
			china_new industry3* china_1997 china_2007 sales sales_dhs ///
			firm`firmtype' imp_ext_1997 imp_ext_2007 sales_1997 ///
			emp*_dhs tot_input*_dhs domest*_dhs sales_2007 emp_1997 emp_2007 ///
			imp_other_1997 imp_other_2007 imp_china_1997 imp_china_2007 ///
			domestic_1997 domestic_2007 tot_inputs_1997 tot_inputs_2007 panel*
			
		save "$data/diff_for_reg_firm`firmtype'_clean`deftype'.dta", replace
		}
	}
	
