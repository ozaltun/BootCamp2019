****REPLICATION PROGRAM FOR: ANTRAS, FORT, & TINTELNOT: THE MARGINS OF GLOBAL SOURCING****

/*
This program reproduces Table 1 in the introduction using disclosed data

Table 1 can also be replicated in the RDCs when using the RDC replication programs

*/

**Set directories
cd  "C:\Users\F000KTQ\Dropbox\MultiCountryOffshoring\AER Replication\Public_Replication_Files"



insheet using "Input_data\emp2_data_for_matlab_v3.out", comma clear
rename code_td code_TD

keep code_TD iso3 inputs_rounded firm_count

rename firm_count firms

sort code_TD
local firm_tot=firms
di `firm_tot'
*Need total number of importers from Appendix Table  64400  ((238800*.23) + (11500*.77))= 64400
gen importer_share=firms/64400  

drop if code_TD==1000
egen rank_firms=rank(firms), field
egen rank_value=rank(inputs), field

egen import_tot=sum(inputs)
gen import_share=inputs/import_tot
sort rank_firms
replace inputs=inputs*10  /* Imports in Millions  */

format inputs firms %9.3gc 
format import_share importer_share %9.2fc

list iso rank_firms rank_value firms importer_share inputs import_share if rank_firms<11


outsheet iso rank_firms rank_value firms importer_share inputs import_share if rank_firms<11 using "output/Table1.csv", comma replace 
