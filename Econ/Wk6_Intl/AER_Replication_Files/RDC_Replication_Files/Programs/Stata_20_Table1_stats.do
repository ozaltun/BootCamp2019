
*************************************************************
/* This program calculates the statistics for Table 1      
*/
****
**********************************************************

*0. Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

set more off

capture log close
 log using "$output/Table1_03-10-17.txt", replace text

  
*1. Construct measure of total input use by firm       
*************************************************
  *a. Pull in data and restrict appropriately
  use "$data/firm_data_2007.dta", clear 
  keep firmid type share* tot* sales* domestic emp_* ww importer
  keep if type=="M" | type=="M+"  /*Could turn this into a loop for different samples  */
    
   keep firmid type sales
   *************************************************
  
*2. Pull imports by country  
   ***Note: US inputs are in each observation.  Observations are firm-country.  Non-importers have only one observation.  Importers have no separate domestic observation
*************************************************
   *a. add firm-country level data
   save $data/tempa.dta, replace
    use "$data/imports2007.dta", clear
    drop if substr(hs,1,2)=="27"  /*  Eliminate fuels  */
    collapse (sum) ivalue, by(firmid country)
    merge m:1 firmid using $data/tempa.dta
   *merge 1:m firmid using "imports_firm_country.dta", keepusing(firmid country ivalue)
   keep if _merge==3  /* Drop non-manufacturing importers  and non-importers */
   drop _merge
   
   *a2. calculate total number of importers
   bys firmid: gen count=1 if _n==1
   egen importer_tot=sum(count)
   global importers=importer_tot
     
   
   *b. rescale imports  (000s)
    gen imports=ivalue/1000
    label variable imports "Import value in $000s"
   
   *c. Country-level dataset
    gen code_TD=country
       merge m:1 code_TD using "$data/country_clean.dta", keepusing(code_TD iso)
       drop _merge
   save $data/temp, replace /*  for disclosure  */
    gen firm_count=1
      collapse (sum) firm_count imports, by(country iso)
      
      
    gen imports_rounded=round(imports/10000)
    replace imports_rounded=imports_rounded*10
    gen firm_count_rounded=10*(round(firm_count/10))
     
     egen rank_firms=rank(firm_count), field
     egen rank_value=rank(imports), field
     sort rank_firms
     
     foreach var in imports imports_rounded {
       egen tot_`var'=sum(`var')
       gen share_`var'=`var'/tot_`var'
       }
       
    *Importer share must be share of total importers:
       
       gen share_firm_count=firm_count/$importers
       
      
     format  share* %9.2f 
     keep iso3 rank* firm_count_rounded share_firm_count imports_rounded share_imports
     keep if rank_firms<=10 
     sort rank_fir
     
     order iso rank_firms rank_val firm_count share_firm imports_round share_imports
     *$output/ Table 1 with top 10 country stats for each year 
     save $output/Table1.dta, replace
     export excel using $output/Output_March17, first(var) sheet(Table1, replace) 
     
     *Limit disc stats to thesee countries
     keep iso 
     merge 1:m iso using $data/temp
     keep if _merge==3
