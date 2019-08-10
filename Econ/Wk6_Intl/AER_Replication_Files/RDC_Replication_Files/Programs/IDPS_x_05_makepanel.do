/*
This program combines 2 major datasets, and then combines them over time
	" firmid_data_`year'.dta" (1997, 2007)
	" firmid_all_shocks.dta"

	- The resulting panel of firms are:
		those with positive sales AND emp
		those with some manufacturing content 
		generate indicator variables for regression so we can select easily on manuf / importer
		(can change the above selection)
		flag variable for negative domestic
	
Outputs:
"$data/firmid_regpanel.dta"

* Note: output panel is not balanced, we leave this selection step to IDPS_x_06!
*/

**Set directories
clear all
set more off
capture log close
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global temp

local yearlist `""1997" "2007""'
local firmlist `""id""'
local deflist `""" "_def""'

foreach deftype of local deflist {
	foreach firmtype of local firmlist {	
		*append two years together
		use "$data/firm_data_1997`deftype'.dta", clear
		append using "$data/firm_data_2007`deftype'.dta"

		* merge in shocks (based on 1997 nominal value
		merge 1:1 year firm`firmtype' using "$data/firm`firmtype'_all_shocks.dta", keep(match)
		/* note we would expect some _m==1 because some firms are missing shocks due to missing naics
			_m==2 is because we have already restricted firms to pos emp and sales
			*/
		keep if _m==3
		drop _m
		
		bys year: tab importer type, missing
		bys year: tab hasmanuf type, missing
		
		* discrepancy between hasmanuf (sales) based measure and type (emp) based measure of manuf content in 1997
		* hasmanuf can be 1 when type~=M/M+, not the other way around. selecting type==M/M+ is stricter.
		
		* select firms with some manuf content, for each year (meaning do we not include firms that switch in and out of manuf)
		drop if year==1997 & type~="M" & type~="M+" 
		
		*generate regression selection variables
		tab hasmanuf type, missing //hasmanuf comes from firm shock construction, type comes from Stata_01
		// now hasmanuf is a proxy for M/M+ type
		
		*define main panel_manuf =1 if a firm exists in both periods and has manuf content in both
		bys firm`firmtype': egen numperiods=total(hasmanuf)     
		gen panel_manuf = 1 if numperiods==2
		replace panel_manuf=0 if missing(panel_manuf)

		*define secondary panel_manuf97 =1 if a firm exists in both periods and hasmanuf in year1997
		*this is for robustness
		gen hasmanuf97 = 1
		replace hasmanuf97 = hasmanuf97 + 10 if year==1997 & hasmanuf==1
		bys firm`firmtype': egen numperiods2=total(hasmanuf97) 
		gen panel_manuf97 = 1 if numperiods2==12
		replace panel_manuf97=0 if missing(panel_manuf97)
		tab panel_manuf panel_manuf97
	
		bys firm`firmtype': egen numimport=total(importer)
		gen panel_impor = 1 if numimport ==2
		replace panel_impor = 0 if missing(panel_imp)
		
		drop numperiods numperiods2 numimport
		
		bys firm`firmtype': egen numperiods=total(flag_neg_dom)
		gen panel_domes = 1 if numperiods==0
		replace panel_domes = 0 if missing(panel_domes)
		
		gen flag_neg_dom_manuf=1 if domestic_manuf<0
		replace flag_neg_dom_manuf=0 if domestic_manuf>=0     

		bys firm`firmtype': egen numperiods2 = total(flag_neg_dom_manuf)
		gen panel_domes_manuf = 1 if numperiods2==0
		replace panel_domes_manuf = 0 if missing(panel_domes_manuf)
		drop numperiods2 numperiods
		
		gen flag_neg_dom_va=1 if domestic_va<0
		replace flag_neg_dom_va=0 if domestic_va>=0     

		bys firm`firmtype': egen numperiods2 = total(flag_neg_dom_va)
		gen panel_domes_va = 1 if numperiods2==0
		replace panel_domes_va = 0 if missing(panel_domes_va)
		drop numperiods2
		
		tab panel_manuf panel_impor, missing
		tab panel_manuf panel_domes, missing
		tab panel_manuf panel_domes_manuf, missing
		tab panel_manuf panel_domes_va, missing
		
		*generate second china_importer variable to disallow defiers
		gen china2_importer = china_importer
		bys firm`firmtype': egen tempv=total(china_importer)
		di "how many china defiers were there?"
		count if tempv==1 & year==2007 & china_importer==0
		replace china2=1  if china2==0 & tempv==1 & year==2007 // now china2 cannot go from 1 to 0 for a firm btw 97 and 07
		tab china_importer china2_importer
				
		*generate industryvariables for each firm (based on their 1997 majority SALES industry)
		gen industry = firm`firmtype'_naics_sal if year==1997
		gen industry3 = firm`firmtype'_naics3_sal if year==1997
		sort firm`firmtype' year
		replace industry = industry[_n-1] if year==2007 & firm`firmtype'==firm`firmtype'[_n-1]
		replace industry3 = industry3[_n-1] if year==2007 & firm`firmtype'==firm`firmtype'[_n-1]

		*generate industryvariables for each firm (based on their 1997 majority SALES industry)	
		gen industry_b = firm`firmtype'_naics_b_sal if year==1997
		gen industry3_b = firm`firmtype'_naics3_b_sal if year==1997
		sort firm`firmtype' year
		replace industry_b = industry_b[_n-1] if year==2007 & firm`firmtype'==firm`firmtype'[_n-1]
		replace industry3_b = industry3_b[_n-1] if year==2007 & firm`firmtype'==firm`firmtype'[_n-1]

		* dropping legacy variables
		drop share_input*
		drop firm`firmtype'_naics* //these are now under industry* variables
		drop tempv
		
		//label variables nicely
		label var imp_other "imports from non-China, in $"
		label var imp_other_nc "imports from non-China non-Canada, in $"
		label var imp_china "imports from China, in $"
		label var imp_extensive "num importing countries excl. China"
		label var imp_extensive_nc "num importing countries excl. China and Canada"
		label var ivalue "total import value, in $"
		label var panel_manuf "=1 if firm manufactred in both periods"
		label var panel_manuf97 "=1 if firm manufactred in 1997 and is active in 2007"
		label var panel_impor "=1 if firm imported in both periods"
		label var panel_domes "=1 if firm had positive domestic sourcing computed from cm in both periods"
		label var panel_domes_manuf "=1 if firm had positive domestic manuf sourcing in both periods"
		label var panel_domes_va "=1 if firm had positive domestic sourcing computed from sales-va in both periods"
		label var china_importer "=1 if firm imports from china in that year"
		label var china2_importer "= china_importer removing 459 defiers (those that switch from 1 to 0)"
		label var importer "=1 if imported in that year"
		label var sales "firm total sales, $000s"
		 label variable tot_inputs_va "Sales-va, merch, ww"
		 label variable tot_inputs "Materials, merch, ww"
		 label variable tot_inputs_manuf "Manuf materials & ww"
		label var domestic "domestic sourcing = tot_inputs - imports"
		label var domestic_manuf "domestic manuf sourcing = tot_inputs_manuf - imports"
		label var domestic_va "domestic sales-va-based sourcing = tot_inputs_va - imports"
		label var flag_neg_dom "=1 if domestic <0, =0 if domestic>0"
		label var flag_neg_dom_manuf "=1 if domestic_manuf <0, =0 if domestic_manuf>0"
		label var hasmanuf "=1 if firm has manuf content, from firm shock side"
		label var hasnonmanuf "=1 if firm has nonmanuf content, from firm shock side"

		label var ms_input "missing input shock due to naics not in IO table"
		label var industry "firm's 1997 naics industry"
		label var industry3 "firm's 1997 naics3 industry"
		label var industry "firm's 1997 naics (bea level) industry"
		label var industry3 "firm's 1997 naics3 (bea level) industry"
		label var type "=M if manuf only, =M+ if has nonmanuf content"
		d
		save "$data/panel_for_reg_firm`firmtype'`deftype'.dta", replace
		}
	}
