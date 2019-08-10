*************************************************************
/* This program makes all the requisite inputs for the structural estimation.
    These inputs include:
       1. Domestic input use for all firms
       2. Total imports by country
       3. Input shares by country for all firms
       4. Country sourcing potential estimates based on importing firms
       5. Estimate of theta
       6. Dispersion measures      
*/
**********************************************************

*0. Set directories
cd " " /* PROJECT ROOT FOLDER */

/* DEFINE GLOBALS PATHS HERE */
global output 
global data
global bs

set more off

capture log close
 log using "$output/Log_Structural_estimation_input_bs.txt", replace text

*Debugging and quick runs
global year=2007

foreach year_val in 1997 2007 {
  global year=`year_val' 
  
  /*  Set number of replications  */
  if $year==1997 {
  global bootstrap_num=1  
  }
  
  
  if $year==2007 {
  global bootstrap_num=1
  }
  
*1. Construct measure of total input use by firm       
*************************************************
  *a. Pull in data and restrict appropriately
  use "$data/firm_data_$year.dta", clear 
  keep firmid type share* tot* sales* domestic emp_* ww importer
  keep if type=="M" | type=="M+" 
    
  *b. Make manufacturing and wholesale shares
  gen man_share=sales_cmf/sales
  tabstat  man_share, by(type) stats(mean median sd)
  summ man_share if type=="M+", detail
  gen whole_share=sales_cwh/sales
  
*1b Identify importer share moments
  summ sales, detail
    global Q1=`r(p25)'
    global Q2=`r(p50)'
    global Q3=`r(p75)'
    di $Q1 
    di $Q2
    di $Q3
    
   keep firmid type tot_inputs* sales man_share whole_share domestic emp_* ww importer
   rename importer firm_importer
*************************************************
  
*2. Calculate inputs by country  
   ***Note: US inputs are in each observation.  Observations are firm-country.  Non-importers have only one observation.  Importers have no separate domestic observation
*************************************************
   *a. add firm-country level data
   save $data/tempa.dta, replace
    use "$data/imports$year.dta", clear
    drop if substr(hs,1,2)=="27"  /*  Eliminate fuels  */
    collapse (sum) ivalue, by(firmid country)
    merge m:1 firmid using $data/tempa.dta
   drop if _merge==1  /* Drop non-manufacturing importers  */
   drop _merge
   
   gen temp1=1 if ivalue~=.
   bysort firmid: egen temp2=sum(temp1)
   gen importer=1 if temp2>0
   replace importer=0 if temp2==0
   drop temp*
      
   *b. rescale imports to match inputs (000s)
    gen imports=ivalue/1000
    label variable imports "Import value in $000s"
    
   *b2. Construct domestic inputs
     bysort firmid: egen double firm_imports=sum(imports)
     gen double inputs1000=tot_inputs-firm_imports      
    
   *c. Identify countries with fewer than 200 US importers
    gen count=1
    bysort country: egen firm_count=sum(count)
    gen country_excluded=1 if firm_count<200
    replace country_excluded=0 if firm_count>=200    
    
   *d. Adjust firm inputs by the amount of imports from excluded countries
     bysort firmid country_excluded: egen tot_imports=sum(imports)
     gen excluded_imports=tot_imports if country_excluded==1
     bysort firmid: egen tot_excl_imports=mean(excluded_imports)
     label variable tot_excl_imports "Value of imports from excluded countries"
     replace tot_excl_imports=0 if tot_excl_imports==.
    
    *e. Need to drop excluded countries from the analysis, but don't want to drop entire firm since need its domestic sourcing
      /*  drop if country_excluded==1 	  This dropped firms with imports only from these countries  */
      bysort firmid: egen country_count=sum(count)
      drop if country_excluded==1 & country_count>1
      replace country="" if country_excluded==1  /*  Keep a domestic observation for firms that only import from excluded countries*/
       
    *f. Construct total inputs net of imports from excluded countries
     gen double inputs_net=tot_inputs-tot_excl_imports
     label variable inputs_net "Total inputs, minus excl country imports"
    
    *g. Make an alternative measure of domestic inputs that is the max of ww or residuals
     gen double inputs1000_alt=max(ww,inputs1000)
     gen in_diff=1 if inputs1000<inputs1000_alt 
     replace in_diff=0 if inputs1000>=inputs1000_alt
     
     gen flag_neg_dom=1 if inputs1000<0
     replace flag_neg_dom=0 if inputs1000>=0      
     
     tab in_diff flag_neg_dom
     
      *j. Assess number of firms and values of these guys
       preserve
         bysort firmid: gen firm2=1 if _n==1
	 gen firm_sales=sales if firm2==1
	 collapse (sum) firm2 imports firm_sales, by(in_diff flag_neg)
	 foreach var in firm2 imports firm_sales {
	   egen tot_`var'=sum(`var')
	   gen share_`var'=`var'/tot_`var'
	   }
	  /*  Aggregate numbers above seem to match with problem firms */ 
	 save $data/Estimation_changed, replace
	restore   
       
    *h. Replace input measures using alternative 
       drop inputs1000 inputs_net
       rename inputs1000_alt inputs1000
       
       gen inputs_net=tot_imports+inputs1000
        
 *************************************************
   
     
*3. Construct share differences for estimating country potential
*************************************************
  *a. Make country share variable
   gen share_j=imports/inputs_net
   gen log_share_j=log(share_j)
   
   *b. Make domestic share variable
   gen share_i=inputs1000/inputs_net
   gen log_share_i=log(share_i)
   
   *c. Make normalized share difference
   gen share_diff=log_share_j-log_share_i
   
   
   *d. Check all bad observations dropped
   gen check=1 if share_diff==. & importer==1
   tab check
   replace check=0 if check==.
   preserve
     bysort firmid: gen firm2=1 if _n==1
	 gen firm_sales=sales if firm2==1
	 collapse (sum) firm2 imports firm_sales, by(check)
	 foreach var in firm2 imports firm_sales {
	   egen tot_`var'=sum(`var')
	   gen share_`var'=`var'/tot_`var'
	   }
   restore
   
 *************************************************
 
 sort firmid
 save "$data/input_${year}.dta", replace
 
 forvalues ft=1/$bootstrap_num { 
 use "$data/input_${year}.dta", clear
 drop if firmid==""
 
 if `ft'>1 { 
 
 contract firmid
 drop _freq
 
  if `ft'==2 {
    di "set seed"
    set seed 1
    }
    
   bsample _N
   
   gen firmid_bs=_n
  
  joinby firmid using "$data/input_${year}.dta", unmatched(none)
  drop firmid
  rename firmid_bs firmid
  }

*4a. Calcuate importer share moments  
*************************************************
preserve
contract firmid sales importer

xtile sales_quartiles=sales, nq(4)

forvalues i=1/4 {
   summ importer if sales_quartile==`i'
   global Q`i'_imp_share=r(mean)
   }

    di $Q1_imp_share
    di $Q2_imp_share
    di $Q3_imp_share
    di $Q4_imp_share
    
    xtile sales_quartiles2=sales, nq(2)
    summ importer if sales_quartiles2==1
    global Q_med_imp_share=r(mean)
    di $Q_med_imp_share
 save $data/disc_importer_share_moments_${year}.dta, replace   
 
    keep if sales_quartiles2==1
 

   gen importer_share=$Q_med_imp_share
   gen double importer_share_r=round(importer_share,.001)
   keep importer_share_r
   keep if _n==1
   gen desc="Share of importers in bottom half of distribution"
  export excel using $output/Results_to_disclose, sheet(importer_share, replace) firstrow(variables) 
 
restore

**************************************************    
       
*4. Estimate country sourcing potential
 *************************************************  
 set more off
   *a. Set global macro on number of countries and importers
   rename country code_TD
   areg share_diff, absorb(code_TD) cluster(code_TD)
   global max=e(N_clust) 
   
   areg share_diff, absorb(code_TD) cluster(firmid)
   global num_importers=e(N_clust)
   di $num_importers  /* This should get number of importers since regression only runs on firms that import */
 
 
    *b. Create fixed effects
    xi i.code_TD, noomit
    
    *c. OLS with no constant
      regress share_diff _Icode_TD*
      estimates store FE2
      
      regress share_diff _Icode_TD*, nocons 
      estimates store FE
      capture drop sample
      gen sample=e(sample) /*This ensures dropping any negative share values later */ 
    
     gen fe=_b[_Icode_TD_1] if _n==1
     gen fe_se=_se[_Icode_TD_1] if _n==1
     forvalues i=2/$max {
      replace fe=_b[_Icode_TD_`i'] if _n==`i'
      replace fe_se=_se[_Icode_TD_`i'] if _n==`i'
      }
     gen N=_n if _n<=$max
 
   *d. Make a list of countries
    preserve 
    keep if sample==1
    contract code_TD 
    keep code_TD 
    gen N=_n
    save $data/tempa_list, replace
    restore

      
   
  *h. $output dataset with parameters
     ***NOTE: This code works only when  the specification we use is the last one that was run.  Must adjust if using another specification for country potential estimates */
   preserve
   gen var= "sigma" if _n==1
   gen value = 3.85 if _n==1
   replace var="theta" if _n==2
   replace var="importers in potential estimates" if _n==4
   replace value = $num_importers if _n==4
   replace var="firms" if _n==3
   replace var="share_us" if _n==5
   replace var="total importers" if _n==6
   replace var="US p50 inputs" if _n==7
   replace var="US p50 disclosed" if _n==8
   replace var="US median full samp" if _n==9
   *replace var="agg theta" if _n==10
   replace var="Q1 importer share" if _n==10
   replace var="Q2 importer share" if _n==11
   replace var="Q3 importer share" if _n==12
   replace var="Q4 importer share" if _n==13
   replace value=$Q1_imp_share if _n==10
   replace value=$Q2_imp_share if _n==11
   replace value=$Q3_imp_share if _n==12
   replace value=$Q4_imp_share if _n==13
   replace var="US p25 inputs" if _n==14
   replace var="US p25 disclosed" if _n==15
   replace var="US p75 inputs" if _n==16
   replace var="US p75 disclosed" if _n==17
   replace var="US p90 inputs" if _n==18
   replace var="US p90 disclosed" if _n==19
   replace var="China share 2007" if _n==20
   replace var="China share 1997" if _n==21
   keep if var~=""
   keep var value
   save "$bs/parameters_${year}_bs`ft'.dta", replace
   restore
 

     *j. Output table of estimates 
  
   estout FE* using "$output/Country_FE_estimation_$year", replace title(Share Estimation Regressions) keep(_Icode* ) ///
   cells(b(star fmt(%9.3f)) se(par))  stats(r2_a rmse N, fmt(%9.2f %9.3g) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) 
    
    estout FE2* using "$output/Country_FE_estimation_$year", append title(Share Estimation Regressions) keep(_Icode* ) ///
   cells(b(star fmt(%9.3f)) se(par))  stats(r2_a rmse N, fmt(%9.2f %9.3g) labels(Adj.R2)) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) 
    
 
  *5. Output country potential dataset and estimate theta 
     ***NOTE: country potential dataset will get merged back later ****
   preserve
   
    *a. Make country fe dataset for later 
     keep N fe*  /*  Select specification here  -- currently using OLS estimates */
     keep if N~=.
     merge 1:1 N using "$data/tempa_list.dta"
     keep code_TD fe*
     save "$data/country_fe.dta", replace  /*Make baseline dataset with country fixed effect estimates */
    
    
    *b. Estimate Theta
    merge 1:1 code_TD using $data/country_clean.dta
    drop _merge
        
    ivregress 2sls fe (log_wage_adj = log_pop) log_dist log_rd log_KL comlang control log_firms
    
    save "$data/check.dta", replace
    *c. Add theta to the parameter dataset
     use "$bs/parameters_${year}_bs`ft'.dta", clear
     replace value=_b[log_wage_adj] if var=="theta"  /* Select parameter that identifies theta here */
     save "$bs/parameters_${year}_bs`ft'.dta", replace
     
   restore
  *************************************************       
 
 *6. Prepare inputs dataset
 ************************************************* 
   
       
   *b. Create dataset with US observation for all firms 
    preserve
       contract firmid inputs1000  importer sales
       gen code_TD="1000"
       drop _freq
       rename inputs1000 inputs
      
       *NEW CODE with multiple percentiles   
      *Define macro with cptiles of US inputs and disclosable pctiles of US inputs 
       summ inputs, det
       foreach val in 25 50 75 90 { 
         global us_p`val'=r(p`val')
         di ${us_p`val'}
         }
       
      *Disclosable median 
       foreach val in 25 50 75 90 {
       local val_plus=`val'+1
       local val_min=`val'-1
       egen p`val_plus'=pctile(inputs), p(`val_plus')
       egen p`val_min'=pctile(inputs), p(`val_min')

       gen r`val'=1 if inputs>=p`val_min' & inputs<=p`val_plus'
       summ inputs if r`val'==1
       global us_p`val'_disclose=r(mean)  /*  Define global macro of perturbed median  */
       di ${us_p`val'_disclose}
       }
       ************************************************************
       
       
       *Define macro with total number of importers in dataset
       egen importers=sum(importer)
       global num_imps=importers
       di $num_imps
       drop importer* p* 
       save $data/us_inputs.dta, replace
       if `ft'==1 {
          global num_imps_full=$num_imps
	  }
       
       global num_firms=_N  /* Define macro with total number of firms */
       
       *Define macro with median US purchases for the full sample 
       if `ft'==1 {
          summ inputs, detail
	  global dom_med=r(p50)
	  }
	
       *Define macro with the share of firms that sources fewer domestic inputs than the median firm in the full sample
       if `ft'>1 {
         gen dom_med_less=1 if inputs<$dom_med
	 egen dom_med_tot=sum(dom_med_less)
	 global share_less=dom_med_tot/_N
	 }      
	  
       **Add values to paramenters dataset
       use "$bs/parameters_${year}_bs`ft'.dta", clear
       replace value=$num_firms if var=="firms"  
       *foreach val in 25 50 75 90 {
       foreach val in 25 50 75 90 {
         replace value=${us_p`val'} if var=="US p`val' inputs"
         replace value=${us_p`val'_disclose} if var=="US p`val' disclosed"  /*  NOTE: I only actually disclose this for the full sample, not each BS */
	 }
       replace value=$dom_med if var=="US median full samp"
       if `ft'==1 {
       replace value=.5 if var=="share_us"
       }
       if `ft'>1 {
       replace value=$share_less if var=="share_us"
       }
       replace value=$num_imps if var=="total importers"
       save "$bs/parameters_${year}_bs`ft'.dta", replace
       *outsheet using "$bs/parameters_${year}_bs`ft'.out", comma replace
    restore
    
    *c. Append US data to importer data only   
      drop if code_TD==""
      
      if `ft'==1 {
        preserve
        gen share_us=inputs1000/inputs_net  if inputs1000>0
        gen sales_us_share=sales*share_us
        collapse (sum) inputs1000 sales_us_share sales, by(code_TD)
        save $data/us_sales_country.dta, replace
        restore
        }
      
      drop inputs1000* 
      rename imports inputs
      append using $data/us_inputs.dta
      
    *c2. Output firm dataset for predictions table (full sample only) and for disclosure
    if `ft'==1  {
      save $data/firm_inputs_${year}.dta, replace
      }
          
    *d. Collapse to country level
      drop firm_count
      gen firm_count=1
      collapse (sum) firm_count inputs   , by(code_TD)
      
    *e. Get the required country data
     merge 1:1 code_TD using "$data/country_clean.dta", keepusing(code_TD iso distw contig comlang_off control gdp rule_of_law rpshare exp_cost)  
     drop if _merge==2
     tab _merge  /* Double check country data for all obs  */
     drop _merge
     
     *f. Merge in the country sourcing potential estimates  (NOTE: these are still in logs)
      merge 1:1 code_TD using "$data/country_fe.dta"
      replace fe=0 if code_TD=="1000"   
      *Fix the rp_share for the US
      replace rpshare=1 if iso3=="USA"
      drop _merge
      
     *g. Reorder variables

      order code_TD iso fe firm_count inputs distw contig comlang control gdp rule_of_law rpshare exp_cost
      keep code_TD iso fe firm_count inputs distw contig comlang control gdp rule_of_law rpshare exp_cost
      
      
     *h. Save dataset and outsheet for Matlab
       save  "$bs/estimation_data_${year}_bs`ft'.dta", replace
       outsheet using "$bs/emp2_data_for_matlab_fe_${year}_bs`ft'.out", comma replace
         
  ************************************************* 
}

  *h2. Calculate stats for Intro Table 1
   use "$bs/estimation_data_${year}_bs1.dta", clear
    drop if code_TD=="1000"
    
    gen inputs_rounded=round(inputs/10000)
    replace inputs_rounded=inputs_rounded*10
    gen firm_count_rounded=100*(round(firm_count/100))
     
     egen rank_firms=rank(firm_count), field
     egen rank_value=rank(inputs), field
     sort rank_firms
     
     foreach var in inputs inputs_rounded {
       egen tot_`var'=sum(`var')
       gen share_`var'=`var'/tot_`var'
       }
       
    *Importer share must be share of total importers:
       gen share_firm_count=firm_count/$num_imps_full
       
     format  share* %9.2f 
     keep iso3 rank* firm_count_rounded share_firm_count inputs_rounded share_inputs*
     keep if rank_firms<=10 
     *Output Table 1 with top 10 country stats for each year 
     save $output/Table1_stats_${year}.dta, replace
     
    *Add China import share to parameters dataset
    gen temp1=share_inputs if iso3=="CHN"
    egen temp2=mean(temp1)
    local china_${year}=temp2
    di `china_${year}'
    if ${year}==2007 {
    forvalues ft=1/$bootstrap_num { 
      use "$bs/parameters_${year}_bs`ft'.dta", clear
      replace value=`china_2007' if var=="China share 2007" 
      replace value=`china_1997' if var=="China share 1997" 
      save "$bs/parameters_${year}_bs`ft'.dta", replace
      outsheet using "$bs/parameters_${year}_bs`ft'.out", comma replace
    }
    }
  ***************************************************
     
    
  *i. Outsheet stats for external SMM
   use "$bs/estimation_data_${year}_bs1.dta", clear 
    *Make rounded disclosable numbers
     gen inputs_rounded=round(inputs/10000)  /*  inputs to the nearest 10 million (imports already rounded to 1000s)  */
     gen firm_count_rounded=100*(round(firm_count/100))  /*  firm count to the nearest 100  */
    
     *drop inputs25 inputs50 inputs90 firm_count inputs rpshare
     drop firm_count inputs rpshare
    outsheet using "$output/AER_moments_${year}.out", comma replace
    
     
    
   *j Estimate aggregate theta (full sample)
   use "$bs/estimation_data_${year}_bs1.dta", clear
   merge 1:1 code_TD using $data/country_clean.dta, keepusing(log_wage_adj log_pop log_KL log_firms log_dist log_rd rule_of_law)
   drop if _merge==2
   drop _merge
   
   merge 1:1 code_TD using $data/us_sales_country
   
      gen log_agg_imports=log(inputs)   
      gen log_sales_us_share=ln(sales_us_share)
      gen log_us_inputs=ln(inputs1000)
      gen log_sales=ln(sales)
      
      gen log_agg_imp_res_sales= log_agg_imports-log_sales_us_share
      gen log_agg_imp_res_usinp= log_agg_imports-log_us_inputs
      
      *Make theta table with control of corruption
      regress fe log_wage_adj log_dist log_rd log_KL comlang control log_firms if fe~=0
      estimates store Firm_OLS
      gen theta_sample=e(sample)
      ivregress 2sls fe (log_wage_adj = log_pop) log_dist log_rd log_KL comlang control log_firms if fe~=0
      estimates store Firm_IV
      
      regress log_agg_imports log_wage_adj log_dist log_rd log_KL comlang control log_firms if fe~=0
      estimates store Agg_OLS
      ivregress 2sls log_agg_imports (log_wage_adj = log_pop) log_dist log_rd log_KL comlang control log_firms if fe~=0
      estimates store Agg_IV
      global agg_theta=_b[log_wage_adj]   
     
     ivregress 2sls log_agg_imports (log_wage_adj = log_pop) log_dist log_rd log_KL comlang control log_firms log_us_inputs if fe~=0
     estimates store Agg_IV_dom
     
     ivregress 2sls log_agg_imp_res_usinp (log_wage_adj = log_pop) log_dist log_rd log_KL comlang control log_firms if fe~=0
     estimates store Agg_IV_dom_res
     
     tab code_TD if theta_sample==1
     tab iso if theta_sample==1
           
   *k. Output table of estimates  
   label variable log_wage "log HC adjusted wage"
   label variable log_dist "log distance"
   label variable comlang "common language"
   label variable control_of "control corrupt"
   label variable log_firms "log no. of firms"
   label variable log_us_inputs "log dom purchases"
   label variable log_sales_us_share "log sales x dom share"
   label variable log_rd "log R\&D"
   label variable log_KL "log capital/worker"
   label variable rule "Rule of law"
   
   estout Firm_OLS Firm_IV Agg_OLS Agg_IV Agg_IV_dom Agg_IV_dom_res using "$output/Theta_estimation_${year}", replace title(Share Estimation Regressions) ///
   cells(b(star fmt(%9.3f)) se(par))  stats(r2_a N, fmt(%9.2f %9.3g) labels(Adj.R2 Observations )) starlevels(* 0.10 ** 0.05 *** 0.01) style(tex) label
     
   *m. Outsheet parameters for structural estimation 
    use "$bs/parameters_${year}_bs1.dta", clear
     keep if var=="theta" | var=="total importers" | var=="US median disclosed" | var=="China share 2007" | var=="China share 1997"
    replace value= 100*(round(value/100)) if var=="total importers"
    outsheet using "$output/AER_parameters_${year}.out", comma replace
     
   ************************************************* 

  *9. Make sourcing potenial figures
 ************************************************* 
use "$bs/estimation_data_${year}_bs1.dta", clear

gen log_firms=ln(firm_count)
gen log_imports=ln(inputs)

drop if fe==0
twoway (scatter log_firms fe)


 twoway (lfit log_firms fe, lcolor(navy) lwidth(medium)) ///
        (scatter log_firms fe, mcolor(navy) mlabel(iso3) mlabcolor(navy) mlabposition(6)), ///
	ytitle(Log of Number of Importers) xtitle(Log of Estimated Sourcing Potentials) legend(off)
 graph save "$output/Fig_FE_firms_${year}.gph", replace
	
 twoway (lfit log_imports fe, lcolor(navy) lwidth(medium)) ///
        (scatter log_imports fe, mcolor(navy) mlabel(iso3) mlabcolor(navy) mlabposition(6)), ///
	ytitle(Log of Total Imports) xtitle(Log of Estimated Sourcing Potentials) legend(off)
 graph save "$output/Fig_FE_imports_${year}.gph", replace
 ************************************************ 
 
}