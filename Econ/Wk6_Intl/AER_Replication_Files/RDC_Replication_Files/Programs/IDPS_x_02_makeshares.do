/* 
Run this after IDPS_x_00_prep.do and Stata_01_Make_firm

This program pulls in the firm*industry dataset prepared by Stata_01 and makes:

employment shares by industry (naics), and by manufacturing industry (naics3)
main industry (and manuf industry) by employment (and then sales) (name of industry)

shares of sales by industry, and by manufacturing industry
main industry (and manuf industry) by employment (and then sales) (name of industry)

it does so for 2^2 combinations:
industry = naics x 97, naics (x) B 97
year=1997 and 2007, and

output dataset is a year*firm*industry long dataset of:

share_emp (sum to one by firmid/lid)
share3_emp (manuf share divided by all manuf emp -  also sums to 1) 
share_sal (sum to one by firmid/lid)
share3_sal (manuf share divided by all manuf sales - also sums to 1) 
naics_emp (= main naics judging by emp, only varies by firm)
naics_sal (= main naics judging by sales, only varies by firm)
naics3_emp (= main manufac naics by emp)
naics3_sal (= main manufac naics by sal)
hasmanuf: whether the firm has any manufacturing content
hasnonmanuf: whether the firm has any non-manuf content 

also outputs temp datasets (will be merged back in by IDPS_03) that 
are unique by FIRM, and marks a firm's main industry by emp, sal, among 
all plants or restricted to manuf

then IDPS_x_03 attaches industry level shocks to the dataset so we can collapse
to make firm-level instruments (china shocks)
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
local nomlist `""""' 
* we actually don't need to care about deflating / not deflating sales. our regressions use fixshares computed from 1997 sales shares

foreach nom of local nomlist {
	foreach year of local yearlist {
		local yr = substr("`year'",3,2)
		*open out firm*industry level dataset prepared by Stata_01
		use "$data/firm_industry_`year'.dta", clear // recall firm_industry_year has not been deflated in Stata_01, only firm_data_year
		*convert fk_naics02 to naics97
		gen naics97 = fk_naics02 // this is a 1:1, identical mapping for manufacturers.
		//since we don't see shocks outside of manuf, everything outside gets clumped to one industry
		keep firmid sales emp naics97 
		
		// convert to naics_x97
		merge m:1 naics97 using "$data/naics97_naicsx97.dta"
		count if substr(naics97,1,1)=="3" & _m==1 //should be 0
		drop if _m==2
		replace naicsx97="999999" if _m==1
		collapse (sum) sales emp, by(firmid naicsx97) //here sales includes IPT
		gen year=`year'
		save "$data/skeleton`year'`nom'.dta", replace
		// is the basic skeleton dataset, salse emp year firmid naicsx97
		}
	}

local naicslist `""" "_b""'
local firmlist `""id""'
foreach nom of local nomlist {
foreach year of local yearlist {
	local yr="97" //this is not a typo - there is no more yr=07 since we fix naics97 notation
	foreach firmtype of local firmlist {		
		foreach naicstype of local naicslist {	// prepare a version for input shocks, and another for output shocks
			use "$data/skeleton`year'`nom'.dta", clear
			if "`naicstype'" == "_b" {
				merge m:1 naicsx`yr' using "$data/naicsx`yr'_naicsb`yr'.dta"
				keep if _m==3
				count if missing(naicsb`yr')
				collapse (sum) sales emp, by(firm year naicsb`yr') 
				ren naicsb`yr' naics`yr'
				gen ismanuf=1 if substr(naics`yr',2,1)=="3"
				}
			else {
				ren naicsx`yr' naics`yr'
				gen ismanuf=1 if substr(naics`yr',1,1)=="3"
				}
			replace ismanu=0 if missing(isma)

			// create the SHARE variables, by EMP and SALES
			bys firm: egen totalsales=total(sales)
			by firm: egen totalmanufsales=total(sales) if ismanuf==1
			by firm: egen totalemp = total(emp)
			by firm: egen totalmanufemp = total(emp) if ismanuf==1
			// create an indicator for how many relevant industries the firm has (used for tiebreakers)
			by firm: egen numnaics=count(totalsales)
			by firm: egen nummanufnaics=count(totalsales) if ismanuf==1
			gen share_emp = emp/totalemp
			gen share3_emp = emp/totalmanufemp
			gen share_sal = sal/totalsal
			gen share3_sal = sal/totalmanufsal
			// deal withe division by 0 issue by being agnostic over how emp is split (these won't matter later because we don't allow any firms with 0 emp or 0 total sales)
			replace share_emp = 1/numnaics if totalemp==0
			replace share3_emp = 1/nummanufnaics if totalmanufemp==0
			// deal withe division by 0 issue by being agnostic over how sales is split
			replace share_sal = 1/numnaics if totalsal==0
			replace share3_sal = 1/nummanufnaics if totalmanufsal==0

			// generate the main naics etc variables by EMP 
			sort firm emp sales ismanuf naics`yr'
			gen naics_emp=""
			// (let main be main, no spliting proportionally)
			// picks highest emp naic, uses sales and then manuf indicator as tiebreakers.
			// within emp-sales-manufacturing ties, pick by naics (sort by naics)
			replace naics_emp=naics`yr' if firm~=firm[_n+1]
			// resort to put ismanuf up front
			sort firm ismanuf emp sales naics`yr'
			gen naics3_emp=""
			replace naics3_emp=naics`yr' if firm~=firm[_n+1] & ismanuf==1
			// now firms missing naics3_emp do not have any manufacturing content

			// generate the main naics etc variables by SALES
			sort firm sales emp ismanuf naics`yr'
			gen naics_sal=""
			// picks highest sales naic, uses emp and then manuf indicator as tiebreakers.
			// within emp-sales-manufacturing ties, pick randomly I suppose (sort by naics)
			replace naics_sal=naics`yr' if firm~=firm[_n+1]
			// resort to put ismanuf up front
			sort firm ismanuf sales emp naics`yr'
			gen naics3_sal=""
			replace naics3_sal=naics`yr' if firm~=firm[_n+1] & ismanuf==1
			// now firms missing naics3_sal do not have any manufacturing content
				
			drop total* num*

			by firm: egen hasmanuf=max(ismanuf)
			by firm: egen hasnonmanuf= min(ismanuf) 
			replace hasnonmanuf = 1-hasnonmanuf
			
			// make sure all shares sum to one
			foreach var of varlist share_emp share_sal {
				count if missing(`var')
				by firm: egen sumtoone=total(`var')
				noisily summ sumtoone
				drop sumtoone
				}
			foreach var of varlist share3_emp share3_sal {
				by firm: egen sumtoone=total(`var')
				noisily summ sumtoone if hasmanuf==1
				drop sumtoone
				}

			if "`naicstype'" == "_b" {
				ren naics`yr' naicsb`yr'
				}
			save "$data/firm`firmtype'_shares`naicstype'_`year'`nom'.dta", replace
			
			// collect main industry codes unique by firmid for merging in in next do-file
			// have not found a way to do this w/o merge since naics is a string variable
			use "$data/firm`firmtype'_shares`naicstype'_`year'`nom'.dta", clear
			keep firm naics_emp
			drop if missing(naics_emp)
			unique firm
			ren naics firm`firmtype'_naics`naicstype'_emp
			save "$temp/firm`firmtype'`naicstype'_`year'_naics_emp`nom'.dta", replace
			
			use "$data/firm`firmtype'_shares`naicstype'_`year'`nom'.dta", clear
			keep firm naics3_emp
			drop if missing(naics3_emp)
			unique firm
			ren naics firm`firmtype'_naics3`naicstype'_emp
			save "$temp/firm`firmtype'`naicstype'_`year'_naics3_emp`nom'.dta", replace
			
			use "$data/firm`firmtype'_shares`naicstype'_`year'`nom'.dta", clear
			keep firm naics_sal
			drop if missing(naics_sal)
			unique firm
			ren naics firm`firmtype'_naics`naicstype'_sal
			save "$temp/firm`firmtype'`naicstype'_`year'_naics_sal`nom'.dta", replace
			
			use "$data/firm`firmtype'_shares`naicstype'_`year'`nom'.dta", clear
			keep firm naics3_sal
			drop if missing(naics3_sal)
			unique firm
			ren naics firm`firmtype'_naics3`naicstype'_sal
			save "$temp/firm`firmtype'`naicstype'_`year'_naics3_sal`nom'.dta", replace
			}
		}
	}
}

