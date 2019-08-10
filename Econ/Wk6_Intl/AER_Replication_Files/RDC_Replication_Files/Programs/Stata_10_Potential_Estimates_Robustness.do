
*************************************************************
/* This program makes all the requisite inputs for the structural estimation.
    These inputs include:
       1. Domestic input use for all firms
       2. Total imports by country
       3. Input shares by country for all firms
       4. Country sourcing potential estimates based on importing firms
       5. Estimate of theta
       6. Dispersion measures      
       
    * This program replaces implied domestic sourcing with production worker wages whenever implied sourcing is negative. 
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
 log using "$output/Log_Potential_estimates_RB_12-12-16.txt", replace text

**************************************************    
      use $data/input_2007.dta, clear  /*  Dataset made in Stata_02  */
      drop if country=="" /*  Drop non-importing firms  */
       
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
    xtile size_cat=sales, nq(5)
    xi i.code_TD i.size_cat, noomit
    drop _Isize_cat_5
    
    *c. OLS with no constant
      regress share_diff _Icode_TD*
      estimates store FE2
      
      regress share_diff _Icode_TD*, nocons 
      estimates store FE
      capture drop sample
      gen samp_base=e(sample) /*This ensures dropping any negative share values later */ 
    
     gen fe_b=_b[_Icode_TD_1] if _n==1
     gen fe_se=_se[_Icode_TD_1] if _n==1
     forvalues i=2/$max {
      replace fe_b=_b[_Icode_TD_`i'] if _n==`i'
      replace fe_se=_se[_Icode_TD_`i'] if _n==`i'
      }
     gen N=_n if _n<=$max
     
    *OLS with no constant and firm size control
    gen log_sales=log(sales)
     regress share_diff _Icode_TD* _Isize_cat*, nocons 
     gen fe_b_size=_b[_Icode_TD_1] if _n==1
     forvalues i=2/$max {
      replace fe_b_size=_b[_Icode_TD_`i'] if _n==`i'
      }
     
     *d. Make a list of countries
      preserve 
      keep if samp_base==1
      contract code_TD 
      keep code_TD 
      gen N=_n
      save $data/tempa_list, replace
      restore
      
     *e. Merge countries to make dataset
     preserve
     keep N fe* /*  Select specification here  -- currently using OLS estimates */
     keep if N~=.
     merge 1:1 N using "$data/tempa_list.dta"
     keep code_TD fe*
     save "$data/country_fe_RB.dta", replace  /*Make baseline dataset with country fixed effect estimates */
     restore
     
   *Make country count groups 
     gen count_group=country_count
     replace count_group=4 if country_count>3
     replace count_group=5 if country_count>=10
     replace count_group=6 if country_count>=20
         
     
     
  *Estimate potential based on  number of import countries
  set more off
    sum count_group
    forvalues c=1/6 {
      regress share_diff _Icode_TD* if count_group==`c', nocons cluster(code_TD)
      capture drop sample
      gen samp_`c'=e(sample)
      estimates store FE`c'
      local cc=e(N_clust)     
     gen fe_b`c'=_b[_Icode_TD_1] if _n==1
     gen fe_se`c'=_se[_Icode_TD_1] if _n==1
     forvalues i=2/`cc' {
      replace fe_b`c'=_b[_Icode_TD_`i'] if _n==`i'
      replace fe_se`c'=_se[_Icode_TD_`i'] if _n==`i'
      }
     * Make a list of countries
      preserve 
      keep if samp_`c'==1
      contract code_TD 
      keep code_TD 
      gen N=_n
      save $data/tempa_list, replace
      restore
      
      * Merge countries to make dataset
     preserve
     keep N fe* 
     keep if N~=.
     merge 1:1 N using "$data/tempa_list.dta"
     keep code_TD fe*
     merge 1:1 code_TD using "$data/country_fe_RB.dta"
     drop _merge
     save "$data/country_fe_RB.dta", replace
     restore
      }
    save $data/temp_disc, replace  
      
 ***Calculate domestic shares for importers
   preserve
     keep if samp_base==1  /*  use sample of firms used for sourcing potential estimates  */
     contract firmid share_i sales tot_inputs
     summ share_i, det
     gen share_off=1-share_i
     summ share_off, det	
     tabstat share_off, stats(mean sd p50 p75 p90) format(%9.2gc)  
     
   *Disclosable median 
       gen percentile=""
       foreach val in  50 75 90 {
       local val_plus=`val'+1
       local val_min=`val'-1
       egen p`val_plus'=pctile(share_off), p(`val_plus')
       egen p`val_min'=pctile(share_off), p(`val_min')
       gen r`val'=1 if share_off>=p`val_min' & share_off<=p`val_plus'
       replace percentile="`val'" if r`val'==1
       }
      save $data/temp, replace
      
      collapse (mean) share_off, by(percentile)
      keep if percentile~=""
      gen check=round(share_off,.01)
      keep percentile share_off
      gen i=1
      rename share_off share_off_
      reshape wide share_off, i(i) j(percentile) string
      save $output/off_shares_pctiles.dta, replace
      	
      restore
      preserve  
      contract firmid share_i sales
      gen share_off=1-share_i
      collapse (mean) share_off_mean=share_off (sd) share_off_sd=share_off
      gen i=1
      merge 1:1 i using $output/off_shares_pctiles
      drop _merge
      drop i
      foreach var in mean sd 50 75 90 {
	gen double R_share_off_`var'=round(share_off_`var',.01)
	}
      keep R_*	
      save $output/off_shares_pctiles.dta, replace
      export excel using $output/Results_to_disclose2, sheet(off_share_stats, replace) firstrow(variables) 
     
    restore  
 
***********************************************************************
 
     
 **Assess the different potential estimates

    use "$data/country_fe_RB.dta", clear
    
       gen pot=exp(fe_b)
      egen pot_tot=sum(pot)
      gen pot_size=exp(fe_b_size)
      egen pot_size_tot=sum(pot_size)
    forvalues i=1/6 {
       gen pot`i'=exp(fe_b`i')
       egen pot_tot`i'=sum(pot`i')
       gen pot_rel`i'=pot_tot`i'/pot_tot
       }
             
    
    *Assess size of China's sourcing potential estimate
    capture drop temp
    gen temp=pot if code_TD=="5700"
    egen pot_china=mean(temp)
    gen china2=pot_china*.46
    gen diff=pot-china2
    sort diff
    gen ratio=pot/china2
          
   *Flag top 10 source countries
    gen firm_count_rank=1 if code_TD=="1220"
    replace firm_count_rank=2 if code_TD=="5700"
    replace firm_count_rank=3 if code_TD=="4280"
    replace firm_count_rank=4 if code_TD=="4120"
    replace firm_count_rank=5 if code_TD=="5830"
    replace firm_count_rank=6 if code_TD=="4759"
    replace firm_count_rank=7 if code_TD=="5880"
    replace firm_count_rank=8 if code_TD=="2010"
    replace firm_count_rank=9 if code_TD=="4279"
    replace firm_count_rank=10 if code_TD=="5800"
    
     
   *Trade-weighted correlations
    merge 1:1 code_TD using "$bs/estimation_data_2007_bs1.dta", keepusing(inputs)
    keep if _merge==3
    drop _merge
    
    *Check correlations between estimates 
    pwcorr fe_b* , obs sig
    pwcorr fe_b* if firm_count_rank<=10, obs sig
    pwcorr fe_b*  [aweight=inputs], obs sig 
    
    *Create numbers to disclose
    
    *Raw correlation between baseline and firms sourcing from three countries
    corr fe_b fe_b3
    matrix A=r(C)
    matlist A
    scalar sest=A[1,2]
    di sest
    
    gen estimate_desc="Potential correlation for firms sourcing from 3 countries" if _n==1
    gen estimate=sest if _n==1
    
       
   *Raw correlation between baseline and firms sourcing from 1 country, 10 ten countries
    corr fe_b fe_b1 if firm_count_rank<=10
    matrix A=r(C)
    matlist A
    scalar sest2=A[1,2]
    di sest2
    
    replace estimate_desc="Potential correlation for firms sourcing from 1 countriy, top 10" if _n==2
    replace estimate=sest2 if _n==2
    
   
    *b. Estimate Theta
    merge 1:1 code_TD using $data/country_clean.dta
    drop _merge
        
    ivregress 2sls fe_b (log_wage_adj = log_pop) log_dist log_rd log_KL comlang control log_firms
    
    *Test h_0: coeff <= -2.85 (theta > 2.85), value comes from chi-squared distribution
    
    test _b[log_wage_adj] = -2.85
    
    *Want to reject Ho: theta<=-2.85
    local sign=sign(_b[log_wage_adj] + 2.85)
    di `sign'
    *Using the delta method, the Wald statistic is chi-squared distributed, the square root of which is the normal distribution
    display "Ho: coef<=-2.85 p-value= " 1-normal(`sign'*sqrt(r(chi2)))
   
    replace estimate_desc="Ho: coef<=-2.85 p-value= " if _n==3
    replace estimate=1-normal(`sign'*sqrt(r(chi2))) if _n==3
    
    keep estimate*
    keep if estimate~=.
    
    gen double estimate_r=round(estimate,.001)
    drop estimate
    export excel using $output/Results_to_disclose2, sheet(potential_checks, replace) firstrow(variables) 

