/* 
Run this before any in the IDPS_x_0x series
Recall this series has 440 NAICS X manuf industries and 330 NAICS B manuf industries

This file prepares the industry datasets imported into the RDC for use by later do-files

Involves minor renaming, cleaning, and generating.
Some of this is done to facilitate legacy filenaming in the IDPS_x_0x series so 
fewer code line edits need to be done.

Output Datasets:
naics_97.dta
china_shock_1997.dta
china_shock_2007.dta
china_input_shock_1997.dta
china_input_shock_2007.dta
china_imppen_1997.dta
china_imppen_2007.dta
*/

clear all
set more off
capture log close

cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global external_data 
global data
global temp

local yearlist `""1997" "2007""'
local firmlist `""id""'
local naicslist `""" "_b""'




********************************************************************
* make a copy of external datasets inside the data folder

use "$external_data/china_input_shock_naicsb97.dta", clear
save "$data/china_input_shock_naicsb97.dta", replace

use "$external_data/china_shock_naicsx97.dta", clear
save "$data/china_shock_naicsx97.dta", replace

use "$external_data/hs10_naics07_imp_year_07.dta", clear
save "$data/hs10_naics07_imp_year_07.dta", replace

use "$external_data/hs6_naics_imp_year_97.dta", clear
save "$data/hs6_naics_imp_year_97.dta", replace

use "$external_data/hs6_naicsx_imp_year_97.dta", clear
save "$data/hs6_naicsx_imp_year_97.dta", replace

use "$external_data/industry_dataset_naicsx97.dta", clear
save "$data/industry_dataset_naicsx97.dta", replace

use "$external_data/io_table_1997.dta", clear
save "$data/io_table_1997.dta", replace

use "$external_data/naics_97_02.dta", clear
save "$data/naics_97_02.dta", replace

use "$external_data/naics97_naicsb97.dta", clear
save "$data/naics97_naicsb97.dta", replace

use "$external_data/naics97_naicsx97.dta", clear
save "$data/naics97_naicsx97.dta", replace

use "$external_data/naicsx97_naicsb97.dta", clear
save "$data/naicsx97_naicsb97.dta", replace

use "$external_data/naics_x97.dta", clear
save "$data/naics_x97.dta", replace


********************************************************************
* make naics dictionaries
*generate a unique 6-digit naics97 list
use "$data/naics97_naicsx97.dta", clear
duplicates drop naics97, force
keep naics97
save "$data/naics_97.dta", replace

*generate a unique 6-digit naics02 list
use "$data/naics_97_02.dta", clear
duplicates drop naics02, force
keep naics02
save "$data/naics_02.dta", replace

* assess how different was naics02 and naics97
use "$data/naics_97_02.dta", clear
keep if substr(naics97,1,1)=="3" | substr(naics02,1,1)=="3"
unique naics02 
unique naics97
count if naics0~=naics9 //the manufacturing mapping is 1:1 and did not change from 02 to 97!
clear
// this allows us to interpret fk_naics02 manuf codes as naics97 manuf codes

*generate unique naicsX97 list
use "$data/naics97_naicsx97.dta", clear
duplicates drop naicsx97, force
keep naicsx97
save "$data/naics_x97.dta", replace

********************************************************************
* EXTRACT RELEVANT INFORMATION from output and input shock datasets

use "$data/china_shock_naicsx97.dta", clear
keep if year==1997
ren naicsx97 naics97
keep naics97 shock_oc year
ren shock_oc shock3
***** drop the 999999 shock, limit shock to only manuf
drop if naics=="999999"
save "$data/china_shock_1997.dta", replace
* 440 industries, NAICS-X97 variable name naics97

use "$data/china_shock_naicsx97.dta", clear
keep if year==2007
ren naicsx97 naics97
keep naics97 shock_oc year
ren shock_oc shock3
***** drop the 999999 shock, limit shock to only manuf
drop if naics=="999999"
save "$data/china_shock_2007.dta", replace
* 440 industries, NAICS-X97 variable name naics97

use "$data/china_input_shock_naicsb97.dta", clear
keep if year==1997
keep year naicsb shock_oc
ren shock_oc shock3
save "$data/china_input_shock_1997.dta", replace
* 330 industries, NAICS-B97 variable name naicsb97

use "$data/china_input_shock_naicsb97.dta", clear
keep if year==2007
keep year naicsb shock_oc
ren shock_oc shock3
save "$data/china_input_shock_2007.dta", replace
* 330 industries, NAICS-B97 variable name naicsb97

********************************************************************
* make import penetration measures (control variable in regressions)

* first, manipulate industry dataset into workable form, keeping only vars we need
use $data/industry_dataset_naicsx97.dta, clear
keep if year==1997 | year==2007
ren trade_cn_ocIm us_import_china
gen us_import_other = tradeImport - us_import_china
ren EU_imp_cn_oc eu_import_china
keep us_import_china us_import_other eu_import_china vship tradeExport naics year
reshape wide us_import_china us_import_other eu_import_china vship tradeExport, i(naics) j(year)
drop if naics=="999999"
save $data/industry_dataset_naicsx97.dta, replace

* fetch industry level sales and exports from INSIDE the census
use "$data/cmf1997.dta", clear
summ
count if missing(naics97)
count if exp<0
count if tvs<exp
drop if tvs<exp // some firms report more exports than total shipments. these are bad obs, drop
collapse (sum) tvs exp, by(naics97)
merge 1:1 naics97 using "$data/naics_97.dta"
drop if _m==1 //dropping "000999" and "" naics
drop if _m==2 & substr(naics,1,1)~="3"
tab _m
drop if substr(naics,1,1)~="3" // keeping only manuf
tab naics if exp==0
count if tvs<exp
drop _m
ren naics97 naicsx97
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics6.dta", replace

replace naicsx97 = substr(naicsx97,1,5)+"X"
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics5.dta", replace

replace naicsx97 = substr(naicsx97,1,4)+"XX"
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics4.dta", replace

replace naicsx97 = substr(naicsx97,1,3)+"XXX"
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics3.dta", replace

append using "$temp/cmf_naics4.dta"
append using "$temp/cmf_naics5.dta"
append using "$temp/cmf_naics6.dta"
merge m:1 naicsx97 using "$data/naics_x97.dta"

count if substr(naicsx97,1,1)=="3" & _m==2
drop if _m==2 // dropping non-manuf 999999
drop if _m==1 // dropping non-used naics aggregate codes
unique naicsx //440 naicsx

gen year=1997
drop _m
merge 1:1 naicsx97 using "$data/industry_dataset_naicsx97.dta"
drop _m
replace tvs = tvs*1000 //from thousands to $$, to match industry dataset
replace exp = exp*1000 //from thousands to $$, since industry dataset is in $$

preserve  // this step is for 2007 data step later
ren tvs tvs1997
ren exp exp1997
save "$temp/industry_census_data1997.dta", replace
restore
gen chnimppenus_fix = us_import_china1997 / (us_import_china1997+us_import_other1997+tvs-exp)
gen chnimppen = us_import_china1997 / (us_import_china1997+us_import_other1997+tvs-exp)
gen chnimppeneu_fix = eu_import_china1997 / (us_import_china1997+us_import_other1997+tvs-exp)
keep naicsx97 chnimp*
ren naicsx naics97
save "$data/china_imppen_1997.dta", replace
* 440 industries, NAICS-X97 variable name naics97

use "$data/cmf2007.dta", clear
summ
count if missing(naics02)
count if exp<0
count if tvs<exp
drop if tvs<exp //these are bad obs, drop
gen naics97 = substr(naics02,1,6)
collapse (sum) tvs exp, by(naics97)
merge 1:1 naics97 using "$data/naics_97.dta"
drop if _m==1 
drop if _m==2 & substr(naics,1,1)~="3"
drop if _m==2
drop if substr(naics,1,1)~="3"
tab _m
tab naics if exp==0
count if tvs<exp
drop _m

ren naics97 naicsx97
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics6.dta", replace

replace naicsx97 = substr(naicsx97,1,5)+"X"
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics5.dta", replace

replace naicsx97 = substr(naicsx97,1,4)+"XX"
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics4.dta", replace

replace naicsx97 = substr(naicsx97,1,3)+"XXX"
collapse (sum) tvs exp, by(naicsx97)
save "$temp/cmf_naics3.dta", replace

append using "$temp/cmf_naics4.dta"
append using "$temp/cmf_naics5.dta"
append using "$temp/cmf_naics6.dta"
merge m:1 naicsx97 using "$data/naics_x97.dta"

count if substr(naicsx97,1,1)=="3" & _m==2
drop if _m==2 
drop if _m==1 // dropping non-used naics aggregate codes
unique naicsx

gen year=2007
drop _m
merge 1:1 naicsx97 using "$temp/industry_census_data1997.dta"
// this includes 2007, and 1997 variuables for sales, exp
drop _m
replace tvs = tvs*1000
replace exp = exp*1000
* replace one missing industry () with CES manufacturing database information since it seems to be missing from CMF
replace tvs = vship2007*1000000 if naicsx97=="316212" //vship is in millions
replace exp = tradeExport2007 if naicsx97=="316212"

gen chnimppenus_fix = us_import_china2007 / (us_import_china1997+us_import_other1997+tvs1997-exp1997)
gen chnimppen = us_import_china2007 / (us_import_china2007+us_import_other2007+tvs-exp)
gen chnimppeneu_fix = eu_import_china2007 / (us_import_china1997+us_import_other1997+tvs1997-exp1997)
keep naicsx97 chnimp*
ren naicsx naics97
save "$data/china_imppen_2007.dta", replace
* 440 industries, NAICS-X97 variable name naics97


* fetch industry deflators from NBER-CES to deflate inputs and sales later
use " ", clear /* NBER-CES DATABASE LOCATION */
keep if year==2007 | year==1997
keep naics piship pimat year
corr piship pimat 
summ
tostring naics, replace
ren naics naics97
save "$data/deflators.dta", replace

* save a 2007 version
keep if year==2007
summ pi*
drop year
save "$data/deflators_2007.dta", replace //naics6


********************************************************************
*** Section to deal with deaflating imports in 2007
* two parts: concordance from hs10-naics07, then concordance from naics07 - naics97

*grab naics07 list for manuf ps
use "$data/hs10_naics07_imp_year_07.dta", clear
duplicates drop naics07, force
keep naics07
sort naics07
keep if substr(naics,1,1)=="3"
save $data/naics_07.dta, replace

use "$data/hs10_naics07_imp_year_07.dta", clear
count if hs10_sh ~=1   
replace naics07 = "999999" if substr(naics,1,1)~="3"
save $data/hs10_naics07_imp_year_07.dta, replace  

use $data/naics_bridge.dta, clear
keep if substr(naics07,1,1)=="3"
replace naics07 = "31131X" if substr(naics07,1,5)=="31131"
replace naics07 = "31181X" if substr(naics07,1,5)=="31181"
replace naics07 = "31511X" if substr(naics07,1,5)=="31511"
replace naics07 = "33631X" if substr(naics07,1,5)=="33631"
order naics07 fk_naics02 naics02
gen naics97 = fk_naics02 
replace naics97 = "999999" if substr(naics97,1,1)~="3" | missing(naics97)
collapse (sum) sales, by(naics07 naics97)
bys naics07: egen totsales=sum(sales)
drop if totsales~=0 & sales==0
gen naics07_share = sales/totsales
* now missing shares are due to totsales being equal to 0: we assign them using equal weight fractions
bys naics07: egen numsplits = count(sales)
replace naics07_share = 1/numsplits if missing(naics07_share) & totsales==0
summ naics07_share
keep naics07 naics97 naics07_share
save $data/naics07_naics97.dta, replace

*port this over to the hs10 bridge:
use $data/hs10_naics07_imp_year_07.dta, clear
joinby naics07 using $data/naics07_naics97.dta, unmatched(master)
tab naics07 if _m==1 
replace naics97 = "999999" if _m==1
replace naics07_share = 1 if _m==1
replace hs10_share = hs10_share*naics07_share
keep hs10 naics97 hs10_share year
save $data/hs10_naics97_imp_year_07.dta, replace
* this is the joinby bridge that we bring over the the dataset in Stata_01

