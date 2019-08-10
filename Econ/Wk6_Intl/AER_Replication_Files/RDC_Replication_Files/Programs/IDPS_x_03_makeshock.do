/* 
generates shocks in each year data: 
	 based on fixed 1997 shares (fixshock3)
	and one based on current year sales shares (shock3)
for: share_emp share_sal share3_emp share3_sal naics3_sal naics3_emp

generatse four types of import penetration shocks in each year data
	one based on fixed 1997 shares (_fix)
	one based on current year shares (no suffix)
	*
	one based on US/EU imppen fixing denominator to 1997 total imports (imppenus, imppeneu)
	one based on US imppen with current year denominator total imports (imppen)
for: share3_sal share_sal naics3_sal

Run this after IDPS_x_02_makeshares.do 

This file takes prepared year*firmid/lid*naics long dataset and merges in:
	- year*naics finalgood shock and inputgood shock industry dataset ported over to the RDC
	- year*naics import penetration in US dataset ported over to the RDC

collapses (weighted sum using various sales shares)
shock variables , and imppen variable by FIRMID/LID

	(will also send a version for 2007 in naics1997)
(imppen) total imp from china / (total imp + domsetic sales) - china_imppen_`year'.dta

output is a year*firmid dataset of Nshare*Nshock + Nnaics*Nshock =24 instruments
	(in practice we will only use 1-2 instruments at a time)
	(for 2007 create an alternative set of shocks using 1997 sales shares)
		(caveat: to make this work, only attempt the merge for manufacturing
			and obviously only for firms that existed in 97)
		(so we can only have share3 naics3 shock variables)

for each firmid, 
years 1997 and 2007 will be appended toegther in one dataset in long
input and final shocks and imppen will be merged toegther in wide
= 2 output datasets (one for each firm type) each of 24 "instruments"

$idps/firmid_all_shocks.dta

So the above will be FIRM LEVEL datasets.
*/

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
local naicslist `""" "_b""'

foreach year of local yearlist {
	local yr = "97"
	foreach firmtype of local firmlist {		
		foreach naicstype of local naicslist {		
			if "`naicstype'"== "_b" {
				local isinput = "_input"
				local isin = "_in"
				local naicstypeshort = "b"
				}
			else {
				local isinput = ""
				local isin = ""
				local naicstypeshort = ""
				}
			*extra step if year==1997: create 2007 shocks using 1997 shares (fixshock)
			*as well as time-invariant Imppen variables that need time-invariant shares
			if "`year'"== "1997" {
				use "$data/firm`firmtype'_shares`naicstype'_`year'.dta"
				*merge in 2007 shocks
				merge m:1 naics`naicstypeshort'97 using "$data/china`isinput'_shock_2007.dta"
				drop if _m==2
				drop _m
				foreach var of varlist share_emp share_sal share3_emp share3_sal {
					gen `var'`isin'_fixshock3 = `var' * shock3
					}
				foreach var of varlist naics3_emp naics3_sal {
					gen `var'`isin'_fixshock3 = shock3 if `var'==naics`naicstypeshort'97
					}
				*fixed imppen shares: just need to do it on one side: choose output side
				if "`naicstype'"== "" {
					merge m:1 naics`yr' using "$data/china_imppen_2007.dta"
					drop if _m==2
					drop _m		
					di "how many manuf industries are missing imppen/chnimppen variable?"
					*count if imppen==. & substr(naics`yr',1,1)=="3"
					count if chnimppen==. & substr(naics`yr',1,1)=="3"
					gen share3_imppen_fix = share3_sal * chnimppen
					gen share_imppen_fix = share_sal * chnimppen
					gen naics3_imppen_fix = chnimppen if naics3_sal==naics`yr'
					
					gen share3_imppenus_fix = share3_sal * chnimppenus_fix
					gen share_imppenus_fix = share_sal * chnimppenus_fix
					gen naics3_imppenus_fix = chnimppenus_fix if naics3_sal==naics`yr'
					
					gen share3_imppeneu_fix = share3_sal * chnimppeneu_fix
					gen share_imppeneu_fix = share_sal * chnimppeneu_fix
					gen naics3_imppeneu_fix = chnimppeneu_fix if naics3_sal==naics`yr'
					// collapsing 15 instruments, treating mising values as zeros as we should
					collapse (sum) naics*shock* share*shock* *_imppen*, by(firm* year)
					}
				else {
					// collapsing 9 instruments, treating mising values as zeros as we should
					collapse (sum) naics*shock* share*shock*, by(firm* year)
					}
				replace year=2007 if year==1997 //firms that did not survive will egt dropped later
				// firms that got born will not enter into regression
				save "$data/firm`firmtype'`isinput'_shocks_2007_n97.dta", replace	
				}

			*make original shocks, for firmid and firm_lid
			use "$data/firm`firmtype'_shares`naicstype'_`year'.dta", clear

			// give firms their best industry identifiers, made at the end of IDPS_02 separately 
			// because easier to merge in than to create internally
			merge m:1 firm`firmtype' using "$temp/firm`firmtype'`naicstype'_`year'_naics_emp.dta"
			drop _m
			merge m:1 firm`firmtype' using "$temp/firm`firmtype'`naicstype'_`year'_naics3_emp.dta"
			drop _m
			merge m:1 firm`firmtype' using "$temp/firm`firmtype'`naicstype'_`year'_naics_sal.dta"
			drop _m
			merge m:1 firm`firmtype' using "$temp/firm`firmtype'`naicstype'_`year'_naics3_sal.dta"
			drop _m
		
			// merge in naics shocks
			merge m:1 naics`naicstypeshort'`yr' using "$data/china`isinput'_shock_`year'.dta"
			
			drop if _m==2
			drop _m
			foreach var of varlist share_emp share3_emp share_sal share3_sal {
				gen `var'`isin'_shock3 = `var' * shock3
				}
			foreach var of varlist naics3_emp naics3_sal {
				gen `var'`isin'_shock3 = shock3 if `var'==naics`naicstypeshort'`yr'
				}

			*merge in import penetration variables (just need to do it on one side - choose output side)
			if "`naicstype'"== "" {
				merge m:1 naics`yr' using "$data/china_imppen_`year'.dta"
				drop if _m==2
				drop _m		
				di "how many manuf industries are missing imppen/chnimppen variable?"
				*count if imppen==. & substr(naics`yr',1,1)=="3"
				count if chnimppen==. & substr(naics`yr',1,1)=="3"
				
				gen share3_imppen = share3_sal * chnimppen
				gen share_imppen = share_sal * chnimppen
				gen naics3_imppen = chnimppen if naics3_sal==naics`yr'
					
				gen share3_imppenus = share3_sal * chnimppenus_fix
				gen share_imppenus = share_sal * chnimppenus_fix
				gen naics3_imppenus = chnimppenus_fix if naics3_sal==naics`yr'
					
				gen share3_imppeneu = share3_sal * chnimppeneu_fix
				gen share_imppeneu = share_sal * chnimppeneu_fix
				gen naics3_imppeneu = chnimppeneu_fix if naics3_sal==naics`yr'
				// collapsing 15 instruments, treating mising values as zeros as we should
				collapse (sum) naics*shock* share*shock* *_imppen*, by(firm* year hasmanuf hasnonmanuf)
				}
			else {
				// collapsing 6 instruments, treating mising values as zeros as we should
				collapse (sum) naics*shock* share*shock*, by(firm* year hasmanuf hasnonmanuf)
				}
			save "$data/firm`firmtype'`isinput'_shocks_`year'.dta", replace
			}
		}
	}

* INPUT SIDE
use "$data/firmid_input_shocks_2007.dta", clear
*merge in fixed shocks for 2007 $data
merge 1:1 firmid year using "$data/firmid_input_shocks_2007_n97.dta"
drop if _m==2 //these firms died (was in 1997 - the n97 dataset but not in 2007 dataset)
drop _m
*append long 1997 firms
append using "$data/firmid_input_shocks_1997.dta"
save "$temp.dta", replace

* OUTPUT SIDE
use "$data/firmid_shocks_2007.dta", clear
*merge in fixed shocks for 2007 data (these also have the imppen - this is why only need to do it on one side)
*merge in fixed shocks for 2007 data
merge 1:1 firmid year using "$data/firmid_shocks_2007_n97.dta"
drop if _m==2 //these firms died
drop _m
*append long 1997 firms
append using "$data/firmid_shocks_1997.dta"
*merge wide with INPUT side
merge 1:1 year firmid using "$temp.dta"
gen ms_input=1 if _m==1
replace ms_input=0 if ms_input==.
drop _m
save "$data/firmid_all_shocks.dta", replace


