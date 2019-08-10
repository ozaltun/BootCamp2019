/*
This program pulls in the estab data and aggregates to the firm level
It adds in firm imports
It creates firm types
It assesses different share variables
It makes a firm dataset with firm type for use in limiting imports as appropriate for calculating facts
It makes a table of the firm types

*/

**Set directories
cd " "  /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global data
global temp
global output

capture log close
log using "$output/Stata_01_Make_firm_dataset_final_rep.txt",  replace text

foreach year in 1997 2002 2007 {

use "$data/estabs_sales`year'.dta", clear
set more off

if `year'==1997 {
  replace fk_naics02=naics97 if fk_naics02==""
  }
 if `year'>1997 {
  replace fk_naics02=naics02 if fk_naics02==""
  }

drop if missing(firmid) // analysis is at firm-level, these guys are useless, lbd-only sources

* deal with missing industry codes (for 1997)
drop if missing(fk_naics02) // checked, these guys mostly come from LBD, missing from EC
di "check that below count is 0"
count if missing(cfn) | missing(firmid) | missing(fk_naics02) //now no identifiers missing
tab source

** Use fk_naics02 for 1997 and 2002, use naics02 from 2007 EC (unless it is an invalid code)
************************************************************  
if `year'==2007 {
   *replace fk_naics02 with naics02 iff naics02 is a valid code and the record source is the EC
   merge m:1 naics02 using "$data/naics_02.dta", keepusing(naics02)
   drop if _m==2
   gen check=1 if _m==3 & source~="LBD" & fk_naics02~=naics02
   tab check
   replace fk_naics02=naics02 if _m==3 & source~="LBD" & fk_naics02~=naics02
   drop _merge
   }
************************************************************

* make sure fk_naics02 is a true naics02 code
ren naics02 naics02_old
gen naics02 = fk_naics02

merge m:1 naics02 using "$data/naics_02.dta"
drop if _m==2  /*  dropping reference naics_02 codes that do not exist in this dataset of plants */
tab _m if substr(naics02,1,1)=="3"
drop naics02 
ren naics02_old naics02
********************************************************************************************
********************************************************************************************


** Make plant-level productivity measures
***********************************************************
gen vap=(va*1000)/emp
replace vap=(gross_margin*1000)/emp if vap==.
gen lvap=ln(vap)
bysort fk_naics02: egen emp_ind=sum(emp)
gen wt_ind=emp/emp_ind
gen lvap_t=wt_ind*lvap
bysort fk_naics02: egen lvap_ind=sum(lvap_t)
gen lvap_r=lvap-lvap_ind

*Make employment weights
bysort firmid: egen emp_tot=sum(emp)
gen wt=emp/emp_tot
gen lvap_r_t=lvap_r*wt

*Make sectoral employment totals for shares
*Use naics codes (necessary for LBD data)
gen n1=substr(fk_naics02,1,1)
gen n2=substr(fk_naics02,1,2)
gen emp_man=emp if n1=="3"
gen emp_whole=emp if n2=="42"
gen emp_retail=emp if n2=="44" | n2=="45"
gen emp_services=emp if n1=="5" | n1=="6" | n1=="7" | n1=="8"
gen emp_public=emp if n1=="9"
gen emp_util=emp if n2=="22"
gen emp_mining=emp if n2=="21"
gen emp_agric=emp if n2=="11"
gen emp_const=emp if n2=="23"
gen emp_twh=emp if n2=="48" | n2=="49"
gen emp_manage=emp if n2=="55"
gen emp_prof=emp if n2=="54"
gen estabs=1
gen estabs_cmf=1 if source=="cmf"
gen estabs_whole=1 if source=="cwh"
gen estabs_manage=1 if n2=="55"
destring optype, gen(optype_num)
gen emp_broker=emp if optype_num>40 & optype_num<50

*Make mining VA variable
gen va_mining=va if n2=="21"
if `year'==2002 {
	replace va_mining = valaddm if source=="cmi"
	}
tab source if va~=.  

if `year'==2007 {
	replace va=valaddc if source=="ccn" 
	}
if `year'==2002 {
	replace va  = valaddc if source=="ccn"
	replace va = valaddm if source=="cmi"
	}

*Make input variables
gen input_whole=merch
gen sales_other = sales if source~="cmf" & source~="cmi" & source~="ccn" 

*Make inventory adjusted share measures
gen del_inv=(fie+wie)-(fib+wib)
gen del_miv=mie-mib

gen input_man_va=sales-va //CMF, CCN, CMI

*Create variable materials inputs
if `year'==1997 {
   gen input_mats=cm if source=="cmf" | source=="cmi" | source=="ccn" 
   }
if `year'==2002 {
	gen input_mats = cm if source=="cmf" | source=="cmi" | source=="ccn" 
	}
if `year'==2007 {
   gen input_mats=cm if source=="cmf" | source=="cmi" 
   replace input_mats=cp if  source=="ccn" 
   }
    
*Make total input variables
 egen tot_inputs_va=rowtotal(input_man_va input_whole ww) 
 egen tot_inputs=rowtotal(input_mats input_whole ww)
 gen tot_inputs_manuf=cm+ww if source=="cmf"
 gen tot_inputs_mw=cm+ww if  source=="cmf"
 replace tot_inputs_mw=merch if source=="cwh"
 egen tot_inputs_max =rowtotal(input_mats sales_other ww)
 
*Make variable for firm manuf sales (including ipt)
  foreach var in cmf cwh {
    gen sales_`var'=sales if source=="`var'"
    }  
    gen sales_net=sales-ipt
    label variable sales_net "Sales-ipt"
   
*Collapse to make firm-industry level dataset
collapse (sum) lvap_r_t emp* sales sales_net estabs* ipt sales_cmf sales_cwh cm tot_inputs* ww, by(firmid fk_naics02)
 
 /* Label variables */
 label variable tot_inputs_va "Sales-va, merch, ww"
 label variable tot_inputs "Materials, merch, ww"
 label variable tot_inputs_manuf "Manuf materials & ww" 
  
***LIMITATIONS TO SAMPLE FOR ALL SUBSEQUENT ANALYSIS
****Note that there are establishments with zero sales going into the firm variables, biggest disc is for records in LBD but not EC****
foreach var in sales emp {
  bysort firmid: egen firm_tot_`var'=sum(`var')
  }
  
drop if firm_tot_sales<=0 & firm_tot_emp<=0   /* this removes plants that are definitely bad */
* note we want to keep plants that may have 0 emp but positive sales, because things may be happening between plants within a firm
* at the firm level, we do want to drop those that have EITHER sales<=0 or emp<=0
 
* save intermediate output for IDPS to make firm*industry shocks that make firm instruments
save "$data/firm_industry_`year'.dta", replace

**** MAKE FIRM LEVEL DATASET OF SALES, INPUTS, and IMPORTS 2 ways: deflating and no deflating
local deflist `""" "_def""'  //deflate and no deflate (alternative is inflate 97 to 07)
foreach deftype of local deflist {
*open firm*industry level dataset prepared above
	use "$data/firm_industry_`year'.dta", clear
	*convert fk_naics02 to naics97
	gen naics97 = fk_naics02 // this is a 1:1, identical mapping for manufacturers.
	//since we don't see shocks outside of manuf, everything outside manuf gets clumped to one industry
	// so the lack of a 1:1 bridge doesn't matter
	if `year'==2007 & "`deftype'"=="_def" { //DEFLATE EVERYTHING IN ONE GO
		merge m:1 naics97 using "$data/deflators_2007.dta"
		drop if _m==2 //dropping 1 manuf industry that doesn't appear
		foreach var of varlist sales* ipt { //deflating all sales and ipt
			replace `var' = `var' / piship if _m==3 //deflating for manuf
			replace `var' = `var' / 1.292 if _m==1 //deflating for non-manuf
			}
		foreach var of varlist cm tot_inputs* { //deflating all inputs, materials
			replace `var' = `var'/pimat if _m==3
			replace `var' = `var'/1.292 if _m==1
			}
		drop _m
		}

	* collapse by firmid, no longer need naics. (all industry level info is made by IDPS_x_03)
	collapse (sum) lvap_r=lvap_r_t emp* sales sales_net estabs*  tot_input* ipt sales_cmf sales_cwh cm ww, by(firmid)

	 /*  Label variables  */
	 label variable sales "Total firm sales across all establishments"
	 label variable sales_net "Total firm sales across all establishments, net of ipt"
	 label variable tot_inputs_va "Sales-va, merch, ww"
	 label variable tot_inputs "Materials, merch, ww"
	 label variable tot_inputs_manuf "Manuf materials & ww"
	 label variable tot_inputs_max "CCN CMF CMI cost of materials + CMF ww + sales in other sectors"
	 
	*Restrict sample to firms with positive sales and employment (this sample will be the same regardless of whether we deflate)
	drop if sales<=0 | emp<=0

	drop empl emp_ind emp_tot
	capture drop empavg

	*Saving temp, get imports
	save $data/temp.dta, replace

* RETRIEVE IMPORTS

	use $data/imports`year', clear  
	drop if substr(hs,1,2)=="27"  /*  Drop oil and fuels */

	*merge in naics97 deflators for 2007 data to deflate ivalues:
	if "`year'"=="2007" & "`deftype'"=="_def" {
		ren hs hs10
		collapse (sum) ivalue, by(firmid country hs10)
		joinby hs10 using "$data/hs10_naics97_imp_year_07.dta", unmatched(master)
		tab _m
		* some hs6 codes do not get merged _m==1
		* nothing we can do - apply CPI deflator of 1.292
		replace ivalue = ivalue*hs10_share if _m==3
		replace naics = "999999" if substr(naics,1,1)~="3"
		* 999999 will be deflated by 1.292
		collapse (sum) ivalue, by(firmid country naics)
		merge m:1 naics97 using "$data/deflators_2007.dta"
		tab naics if _m==1, missing //should be only missing and 999999
		drop if _m==2 //dropping several untraded manuf industries
		replace ivalue = ivalue/piship if _m==3 //deflating for manuf
		replace ivalue = ivalue/1.292 if _m==1 //deflating by average urban CPI for non-manuf
		drop _m		
		}	
		
	*make trade LHS variables
	collapse (sum) i*, by(firmid country)	
	gen imp_china = ivalue if country=="5700"
	gen imp_other = ivalue if country~="5700"
	gen imp_other_nc = ivalue if country~="5700" & country~="1220"
	gen imp_extensive = 1 if country~="5700" //extensive margin, 1 obs per firm-country
	gen imp_extensive_nc = 1 if country~="5700" & country~="1220"
	collapse (sum) imp* ivalue, by(firmid)

	*make china indicator variable, per firm
	gen china_importer = 1 if imp_china > 0 // no missing since this is after a collapse
	replace china_importer = 0 if imp_china==0
	
	*merge with domestic firm variables
	merge 1:1 firmid using $data/temp.dta
	// _m==1 here are bad firmids

	*Assess match rates
	bysort _merge: egen ivalue_tot=sum(ivalue)
	egen ivalue_`year'=sum(ivalue)
	gen rate=ivalue_tot/ivalue_`year'
	di "display match rate"
	tab rate _m
	
	*Note that this match rate tells me how much of the "matched" data actually matches to records.
	
	* dropping _m==1 firms (these guys are import firmids without a corresponding firmid in our firm dataset)
	keep if _merge~=1
	drop _merge

	*replacing china importer variable to cover entire universe
	replace china_importer=0 if missing(china_importer)
		
	*Make import variable in 000s
	gen double imports=ivalue/1000
	label variable imports "Imports, ($000s)"

	***MAKE FIRM TYPE VARIABLES***
	gen emp_services2=emp_prof+emp_manage
	gen emp_other=emp_public+emp_util+emp_mining+emp_agric+emp_const+emp_twh+emp_services-emp_services2
	foreach var in man whole retail services2 other {
	   gen emp_share_`var'=emp_`var'/emp
	   }

	*Make firm type variable for analysis
	*Define firm type for paper
	gen emp_share_other2=1-emp_share_man-emp_share_whole
	gen type="M" if emp_share_man==1
	replace type="W" if emp_share_whole==1
	replace type="O" if emp_share_other2==1
	replace type="M+" if emp_share_man>0 & emp_share_man~=. & ((emp_share_whole>0 & emp_share_whole~=.) | (emp_share_other2>0 & emp_share_other2~=.))
	replace type="check" if emp_share_man>0 & emp_share_man<1 & type~="M+"
	replace type="WO" if emp_share_whole>0 & emp_share_whole~=. & emp_share_man==0 & emp_share_other2>0 & emp_share_other2~=.

	** Create importer dummy
	gen importer=1 if ivalue>0 & ivalue~=.
	replace importer=0 if sales~=. & importer==.
	
	**Analyze dataset
	gen count=1
	tabstat count ivalue emp sales importer, by(type) stat(sum)

	** create foreign sourcing shares - these shares come from imports (line 345) which are missing for domestic-only firms
	foreach var in inputs inputs_va inputs_manuf inputs_mw {
	   capture drop share_`var'
	  gen share_`var'=imports/tot_`var'
	  }
	  
	capture log close

	if `year'==1997 & "`deftype'"=="" {
		log using "$output/Share_summ.txt", replace text
		di "`year'"
		tabstat share*, by(type)  stat(mean p10 p50 p90 p99 min max)
		log close  
		log using "$output/Share_summ_paper.txt", replace text
		di "`year'"
		tabstat share* if type=="M" | type=="M+", by(type)  stat(mean sd)
		log close  
		}
	if `year'==2007 {
		log using "$output/Share_summ.txt", append text
		di "`year'`deftype'"
		tabstat share*, by(type)  stat(mean p10 p50 p90 p99 min max)
		log close  
		log using "$output/Share_summ_paper.txt", append text
		di "`year'`deftype'"
		tabstat share* if type=="M" | type=="M+", by(type)  stat(mean sd)
		log close  
		}
****************************************************
	*keep relevant variables

	keep firmid emp emp_census emp_man emp_whole emp_retail emp_services2 emp_twh emp_manage emp_prof sales* type estabs estabs_cmf ///
	share* lvap_r cm tot_* importer imports imp* ivalue china*  ww

	gen year = `year' 

	*f. Construct domestic inputs = total inputs - imports net of fuels, in $k
	replace imports = 0 if imports ==. 
	// recall imports is in thousands so we can do the following
	gen double domestic = tot_inputs - imports
	gen double domestic_manuf = tot_inputs_manuf - imports
	gen double domestic_va = tot_inputs_va - imports
	gen double domestic_max = tot_inputs_max - imports

	*h. Count firms with negative domestic inputs
	gen flag_neg_dom=1 if domestic<0
	replace flag_neg_dom=0 if domestic>=0

	tab type flag, miss
	tab importer flag, miss
	summ

	save "$data/firm_data_`year'`deftype'.dta", replace
	}
}

* delete temp dataset
capture erase temp.dta


******APPENDIX SAMPLE TABLE*******
******************************************
use $data/firm_data_2007, clear

*do we need to add the export stuff here?

*Rescale variables
replace imports=imports/1000
replace sales=sales/1000000
replace emp=emp/1000
gen count=1
*Sales are in billions
*Emp is in thousands
*Imports are in millions
*Table with Re-scaled variables


foreach var in importer count {
   bysort type: egen `var'_tot=sum(`var')
   }

gen importer_share=importer_tot/count_tot

/*  Importer Shares Match Table */
tabstat importer_share, by(type) stat(mean) format(%9.2f)


collapse (sum) count imports emp sales importer, by(type)

gen firm_count_rounded=100*(round(count/100))
gen importer_share=importer/count

tabstat firm_count imports emp sales importer_share, by(type) stat(sum) format(%9.3gc %9.3gc %9.3gc %9.3gc %9.3fc)

format firm_count imports emp sales %9.3gc
format importer_share %9.2fc

capture log close
log using "$output/Appendix_Table.txt", replace text
tabstat firm_count imports emp sales importer_share, by(type) stat(sum) format  
log close


