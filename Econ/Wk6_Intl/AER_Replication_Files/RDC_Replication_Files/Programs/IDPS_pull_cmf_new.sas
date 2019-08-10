****This program pulls in CMF data used to create sales and exports for import penetration;

options obs=max;

libname margins " "; /* PROJECT DATA FOLDER */
%let margins= ; /* PROJECT DATA FOLDER */

data cmf1997 (keep=cfn ein exp naics97 te tvs va);
  set  margins.estabs_sales1997; 
  if source='cmf';
run;

    proc export data=cmf1997
    outfile="&margins/cmf1997.dta"
    dbms=dta replace;
    run; 


data cmf2007 (keep=cfn ein exp naics02 te tvs va); 
  set  margins.estabs_sales2007; 
  if source='cmf';
run;

    proc export data=cmf2007
    outfile="&margins/cmf2007.dta"
    dbms=dta replace;
    run; 

************************************************************************************;

