
*************************************************************
/* This program makes a table from the data to match our predictions table in the counterfactual analysis
    Prgram steps are:
       1. Make a balanced panel of firms from 1997-2007
       2. Calculate Chinese import status in both years
       3. Calculate US inputs in both years
       4. Calculate all other foreign sourcing in both years     
*/
**********************************************************

cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs


set more off

capture log close

**************POSITIVE SHOCK TABLE******************************
****************************************************************

*Compile 1997 and 2007 datasets
foreach val in 1997 2007 {
 use $data/firm_inputs_`val'.dta, clear

 bysort firmid: egen check2=sum(inputs)

 gen china_imports=inputs if code_TD=="5700"
      replace china_imports=0 if code_TD~="5700"
      gen us_inputs=inputs if code_TD=="1000"
      replace us_inputs=0 if code_TD~="1000"
      gen other_imports=inputs if code_TD~="5700" & code_TD~="1000"
      replace other_imports=0 if code_TD=="5700" | code_TD=="1000"  
      gen imports=inputs if code_TD~="1000"
      
 collapse (mean) sales country_count (sum) china_imports us_inputs other_imports inputs imports, by(firmid)

 drop if firmid==""    
 gen firms=1
 
 foreach var in china_imports us_inputs other_imports sales firms country_count inputs imports {
    rename `var' `var'_`val'
    }

 if `val'==1997 {
   save temp.dta, replace
   }
 
 if `val'==2007 {
   merge 1:1 firmid using temp.dta
   }
 }    

foreach var in sales us_inputs other_imports china_imports country_count inputs imports {
   foreach y in 1997 2007 {
      replace `var'_`y'=0 if `var'_`y'==.
      }
      }


*Define firm status
gen status="a) Entrants" if china_imports_1997==0 & china_imports_2007>0
replace status="b) Exiters" if china_imports_1997>0 & china_imports_2007==0
replace status="c) Continuers" if china_imports_1997>0 & china_imports_2007>0
replace status="d) Others" if china_imports_1997==0 & china_imports_2007==0

tab status, miss

*save dataset 
save $data/firm_china_panel, replace

use $data/firm_china_panel, clear

*Unbalanced sample
foreach var in sales us_inputs other_imports country_count imports {
  replace `var'_1997=. if _merge==1
  replace `var'_2007=. if _merge==2
  }

save $data/firm_china_panel, replace


**Aggregate Table
*Collapse by firm status
collapse (sum) china_imports* us_inputs* other_imports* sales* firms* imports*, by(status)

*Calculate relative values
foreach var in us_inputs china_imports other_imports sales {
  gen rel_`var'=(`var'_2007/1.29)/(`var'_1997)
  }
 
*Calculate firm shares
foreach vv in 1997 2007 {
  egen total_firms_`vv'=sum(firms_`vv')
  gen firm_share_`vv'=firms_`vv'/total_firms_`vv'
  }
  
egen tot_imports=sum(imports_2007)  
egen tot_china=sum(china_imports_2007)
gen china_share=china_imports_2007/tot_china


*Output table
outsheet status rel_us rel_other rel_china firm_share_2007 china_share using "$output/predictions_table_new.csv", replace comma



