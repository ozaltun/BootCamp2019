#!/bin/bash
#PBS -l select=1:ncpus=4:mem=30gb
#PBS -m e

# THIS IS THE FINAL BASH FILE TO RUN ALL PROGRAMS TO REPLICATE RESULTS IN AFT
####This is a script file for the disclosed programs for the paper on Multinational Margins of Offshoring#####

# LAST MODIFIED 3-10-2017

#Change directories for SAS log file output 
cd  ......$programs

##Set up shortcut for directory
dir= ......$programs
root= ......$root_folder

###Programs to make input data##################
##Make import data 
  ##Makes concordances from the BR and EC data
  ##Assigns a firmid to imports for 1997 and 2007, and exports for 2007
 sas $dir/import01_makebridge_full.sas -MEMSIZE 5G
 sas $dir/import02_fetchimports.sas 
 sas $dir/SAS_01_Make_exports.sas

##Make EC datasets
  ##Pull in data from the economic censuses
  ##Make dataset for analysis, makes it for 97,02,07
 sas $dir/SAS_02_Make_Census_data.sas 

  ##Make CMF dataset for 07 97 bridge naics (deflation procedure)
 sas $dir/SAS_04_Make_naics_bridge.sas 

## Pull CMF data for naics-level domestic purchases data - used to create imppen measures
 sas $dir/IDPS_pull_cmf_new.sas

#####Switch to STATA#############
#Prepare interdependencies preliminary data (needs to happen before Stata_01)
 stata-se -b do $dir/IDPS_x_00_prep_new.do
 stata-mp -b do $dir/Stata_00_Prepare_country_data.do  

##Create firm_data.dta which has firms and their type, lvap, etc.
 stata-mp -b do $dir/Stata_01_Make_firm_datasets.do  
 
###Do Interdependencies Regressions
 stata-mp -b do $dir/IDPS_x_02_makeshares.do
 stata-mp -b do $dir/IDPS_x_03_makeshock.do
 stata-mp -b do $dir/IDPS_x_05_makepanel.do
 stata-mp -b do $dir/IDPS_x_06_diffpanel_new.do
 stata-mp -b do $dir/IDPS_x_08_regress_final.do

##Create input for the structural estimation using all firms and bootstrapping
   #Domestic inputs defined as residuals or ww, whichever is greater
   #This program estimates:
     ## sourcing potentials
     ## Aggregate theta estimates
     ## Micro theta estimates 
     ## Potential figures
     ## Disclosed moments for SMM (estimation data and parameters)
     ## Table 1 

 stata-mp -b do  $dir/Stata_02_Structural_estimation_input_v2.do  

########Programs to create tables, figures, and summ stats######
###Premia figure in introduction and robustness figures and premia tables in the appendix
 stata-se -b do $dir/Stata_03_Premia_Figures_parta.do 
# stata-se -b do $dir/Stata_03_Premia_Figures_partb.do # note: this cannot be run in batch mode
 stata-se -b do $dir/Stata_03_Premia_Tables_partc.do 

###HS-Country Product count figures in Section 4 and robustness for the appendix
 stata-se -b do $dir/Stata_04_Country_product_stats.do 

###HS-Country HS6 Product count figures for imports for the appendix
 stata-se -b do $dir/Stata_05_Country_product_stats_HS6_imports.do 

###HS-Country HS6 Product count figures for exports for the appendix
 stata-se -b do $dir/Stata_06_Country_product_stats_HS6_exports.do 

###Hierarchy Table and Table 1 in Introduction 
 stata-se -b do $dir/Stata_07_Hierarchy_table.do 

###Counterfactual predictions table based on actual data 
 stata-se -b do $dir/Stata_08_Counterfactual_Predictions_Tables_v3.do 

###Share of firms that import from China in 1997 for counterfactuals 
 stata-se -b do $dir/Stata_09_Counterfactual_1997_stats.do 

### Robustness
 stata-se -b do $dir/Stata_10_Potential_Estimates_Robustness.do

### Decomposition Appendix
 stata-se -b do $dir/Stata_19_Gravity_Decomp.do 

### Table 1
 stata-se -b do $dir/Stata_20_Table1_stats.do 


######## Programs to Create Moments ############
### Make census establishments, including trailer file export information 
 sas $dir/Export_01_estabs.sas

### Combine EC and LFTTD exporter identifiers and compute moment
  sas $dir/Export_02_moment.sas

### Provide more tabulations in Stata and log in documentation in exports
### show that we match published totals, and finally, output moment to text file
  stata-mp -b do $dir/Export_03_make_moment_final.do

#Change permissions /*cd to paths and changepermissions, taken out for disclosure path name avoidance */