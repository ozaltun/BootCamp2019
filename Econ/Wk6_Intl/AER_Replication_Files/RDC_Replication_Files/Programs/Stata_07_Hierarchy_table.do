
*Modify to limit firm type and to do all the firm country calculations/stats

set more off
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

capture log close
log using "$output/12-06-16_Hierarchy_Table.txt", replace text

*Bring in import data
use $data/imports2007, clear
drop if substr(hs,1,2)=="27"
collapse (sum) ivalue, by(firmid country)


*Limit to appropriate firm types
merge m:1 firmid using "$data/firm_data_2007.dta", keepusing(firmid type sales)
keep if type=="M" | type=="M+"
drop if _merge==1
drop _merge

*Critical step or null countries get counted!!
drop if country==""

*Get country names
merge m:1 country using "$data/country_names.dta", keepusing(country_name)
keep if _merge~=2
drop _merge

set more off
capture log close
log using "$output/Table_Hierarchy.txt", replace text
**Begin analysis
qui log off


**Pecking Order Analysis****
*****************************
*Country import totals
gen count=1
bysort country: egen count_tot=sum(count)

*Limit dataset to top 10 countries (by firm count)
preserve
collapse (sum) count ivalue, by(country country_name)
*Make disclosable numbers
gen imports=round(ivalue/10000000)
gen firm_count_rounded=100*(round(count/100))
*Make ranks
egen rank_no=rank(count), field
egen rank_val=rank(ivalue), field
save $data/country_rank.dta, replace
sort count
di "List by Number of Firms"
list country_name count rank_no rank_val ivalue if rank_no<=10
list country_name firm_count rank_no rank_val imports if rank_no<=10
sort ivalue
qui log on
di "Spearman Correlation"
spearman count ivalue

qui log off


label variable imports "Imports in 10 millions"

keep if count>200
keep country_name firm_count_rounded rank_no rank_val imports country

save $data/country_list_table.dta, replace
restore

merge m:1 country using $data/country_rank.dta, keepusing(country rank_no)
drop _merge



*Create country count for firms, including ALL countries
bysort firmid: egen cc_all=sum(count)
label variable cc_all "Firm country count, including non-top countries"

*****MAKE PECKING ORDER VARIABLE***********
*****With 10 countries*********************
preserve
	keep if rank_no<11
	*Recount firm count
	bysort firmid: egen cc_10=sum(count)

	*Reshape dataset
	keep firmid rank_no ivalue cc_10 cc_all sales
	rename ivalue i_
	reshape wide i, i(firmid cc_10 cc_all sales) j(rank_no) 

	*Make pecking order variables
	forvalues i=1/10 {
	  replace i_`i'=0 if i_`i'==.
	  }

	foreach var in 10 all {  
	  gen peck_`var'=1 if i_1>0 & cc_`var'==1
	  replace peck_`var'=2 if i_1>0 & i_2>0 & cc_`var'==2
	  replace peck_`var'=3 if i_1>0 & i_2>0 & i_3>0 & cc_`var'==3
	  replace peck_`var'=4 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & cc_`var'==4
	  replace peck_`var'=5 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & i_5>0 & cc_`var'==5
	  replace peck_`var'=6 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & i_5>0 & i_6 & cc_`var'==6
	  replace peck_`var'=7 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & i_5>0 & i_6 & i_7 & cc_`var'==7
	  replace peck_`var'=8 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & i_5>0 & i_6 & i_7 & i_8 & cc_`var'==8
	  replace peck_`var'=9 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & i_5>0 & i_6 & i_7 & i_8 & i_9 & cc_`var'==9
	  replace peck_`var'=10 if i_1>0 & i_2>0 & i_3>0 & i_4>0 & i_5>0 & i_6 & i_7 & i_8 & i_9 & i_10 & cc_`var'>=10
	  replace peck_`var'=0 if peck_`var'==.
	}

	**Output to Log file
	*********************
	*qui log on
	di "Pecking Order count with top 10 countries, excluding non top 10 countries"
	tab peck_10

	*di "Pecking Order count with top 10 countries, including non top 10 countries"
	*tab peck_all
	*qui log off
	*********************

	**Check
	tab peck_10 peck_all
	save $data/peck.dta, replace

	**Make rounded pecking numbers
	gen count=1 
	collapse (sum) count, by(peck_10)
	gen count_rounded=10*(round(count/10))
	qui log on
	list peck_10 count_rounded
	log close
	use $data/peck.dta, clear
 
restore


gen tvs=sales
save $data/temp.dta, replace 

***
 

****Calculate Number of firms based on probabilities
use $data/temp.dta, clear

keep firmid country country_name count count_tot rank_no
keep if rank_no<=10
bysort firmid: gen denom1=1 if _n==1
egen denom=sum(denom1)
gen prob_j=count_tot/denom

contract country denom prob_j
merge 1:1 country using $data/country_rank.dta
keep if rank_no<=10
drop _merge _freq
sort rank_no

*Make pecking order probabilities
forvalues i=1/10 {
  gen prob`i'a=prob_j if rank_no==`i'
  egen prob`i'=mean(prob`i'a)
  drop prob`i'a
  gen iprob`i'=1-prob`i'
  }
  
gen ran_prob1=prob1*iprob2*iprob3*iprob4*iprob5*iprob6*iprob7*iprob8*iprob9*iprob10
gen ran_prob2=prob1*prob2*iprob3*iprob4*iprob5*iprob6*iprob7*iprob8*iprob9*iprob10
gen ran_prob3=prob1*prob2*prob3*iprob4*iprob5*iprob6*iprob7*iprob8*iprob9*iprob10
gen ran_prob4=prob1*prob2*prob3*prob4*iprob5*iprob6*iprob7*iprob8*iprob9*iprob10
gen ran_prob5=prob1*prob2*prob3*prob4*prob5*iprob6*iprob7*iprob8*iprob9*iprob10
gen ran_prob6=prob1*prob2*prob3*prob4*prob5*prob6*iprob7*iprob8*iprob9*iprob10
gen ran_prob7=prob1*prob2*prob3*prob4*prob5*prob6*prob7*iprob8*iprob9*iprob10
gen ran_prob8=prob1*prob2*prob3*prob4*prob5*prob6*prob7*prob8*iprob9*iprob10
gen ran_prob9=prob1*prob2*prob3*prob4*prob5*prob6*prob7*prob8*prob9*iprob10
gen ran_prob10=prob1*prob2*prob3*prob4*prob5*prob6*prob7*prob8*prob9*prob10

gen pred_cat=denom*ran_prob1
forvalues i=2/10 {
  replace pred_cat=denom*ran_prob`i' if rank_no==`i'
  }
label variable pred_cat "Number of firms predicted in each category, 1=only import from No. 1 Country"
  
*Calculate predicted number of firms
forvalues i=1/10 {
  egen firm_no`i'=sum(pred_cat) if rank_no>=`i'
}

gen pred_firms=firm_no1
forvalues i=2/10 {
  replace pred_firms=firm_no`i' if rank_no==`i'
  }
label variable pred_firms "Number of predicted firms"  
  
*browse country denom prob_j rank_no  pred_cat pred_firms
gen percent_peck=pred_cat/denom
egen tot_peck=sum(pred_cat)
gen percent_tot=tot_peck/denom

*Make rounded numbers
foreach var in pred_cat pred_firms {
  gen `var'_rounded=10*(round(`var'/10))
  }
  gen denom_rounded=100*(round(denom/100))


outsheet country_name rank_no denom_rounded pred_cat_r pred_firms_r using $output/Random_Numbers, comma replace


