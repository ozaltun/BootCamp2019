****This program uses the oldnaics new naics information in the CMF to make a m:m joinby 
*concordance from naics07 to naics02, among naics manuf(3) codes;

options obs=max;

libname beta " " ;   /* LBD FOLDER */
libname fknaics " " ; /* FK NAICS FOLDER, C201002 */

libname margins " "; /* PROJECT DATA FOLDER */
%let margins= ; /* PROJECT DATA FOLDER */

%let cmf_2007=ar alpha ein income_a ipt ivab ivae tib tie fib fie mib mie naics_old naics_new oe pay_ann_a sales_a sales_t survu_id tabbed te tvmc tvs va oe ow ww wie wib ;

data census2007(drop=ein_t temp: ein_l  sic_census  alpha naics_old);
    length firmid $ 10 temp2 $10  naics07_census $ 6 naics02_census $ 6 sic_census $ 4 ;
    set cmf.cmf2007         (keep=&cmf_2007 rename=(ein=ein_t));

 *Make fixed ein variable;
    if ein_t~=. then do;
	 ein=put(ein_t,z9.);
     end;
			  
   *Make cfn variable;
   cfn=survu_id; 

   *Make firmid variable;
    if alpha~=' ' then firmid=alpha||"0000";
    if alpha=' ' then firmid='0'||ein;

   *Make sales variable;
    sales=tvs;

   *Make naics variables;
    naics02_census=substr(naics_old,1,6);
    naics07_census=substr(naics_new,1,6);
    
   *Make employment variable;
    emp_cen=te;
source = 'cmf';
if tabbed~='N' ;
run;


**Put lbdnums on the data;
****First check for cfn dupes;
    proc sort data=census2007;
	by cfn ;
    run;
    data census2007 dupes2007;
	set census2007;
	by cfn;
	if first.cfn=1 & last.cfn=1 then output census2007;
	else output dupes2007;
    run;
    data dupes_add;
	set dupes2007;
	if source='cmf';
    run;
    proc sort nodupkey data=dupes_add;
	by cfn ;
    run;
    data census2007;
	set census2007 dupes_add;
    run;




***MACRO 2: GET EMPLOYMENT and PAYROLL DATA FROM THE LBD (Expands the scope of data coverage);
************************************************************************************;

**Make firm employment share data;
    proc sort data=beta.lbd2007c(keep=lbdnum cfn firmid emp naics sic bestnaics bestsic pay
                                rename=(sic=sic1 firmid=firmid_lbd naics=naics_lbd emp=emp_lbd pay=pay_lbd)) out=lbd;
	by lbdnum  ;
    run;

    data lbd;
	set lbd;
	cfn_lbd=cfn;
    run;
    


  *Add the fk naics codes;
    data fknaics(keep=lbdnum fk_naics02);
	set fknaics.naics2007;
        random_tot=sum(fk_n97_splits,fk_sic97_splits,fk_sic87_splits);
	   if random_tot=. | random_tot<900;
    run;
    
    proc sort data=fknaics;
	by lbdnum;
    run;
    
    data lbd;
	merge lbd(in=a) fknaics;
	by lbdnum;
	if a=1;
    run;

    proc sort data=lbd;
	by cfn;
    run;
    
    proc sort data=census2007;
	by cfn;
    run;
    
    data estabs2007(drop=sic1) no_lbd_match2007(drop=sic1) all_estabs2007(drop=sic1) ;
	length sic_lbd $ 4 sic $ 4 naics07 $ 6 naics02 $ 6 ;
	merge census2007(in=a rename=(emp_cen=emp_census firmid=firmid_census)) lbd(in=b);
	by cfn;
       
        *Make industry variables;
	sic_lbd=substr(sic1,1,4);
	sic=sic_census;
	if sic=' ' & sic_lbd~=' ' then sic=sic_lbd;
	if sic=' ' & bestsic~=' ' then sic=substr(bestsic,1,4); 
	naics07=naics07_census;
	if naics07=' ' & naics_lbd~=' ' then naics07=substr(naics_lbd,1,6);
	naics02=naics02_census;
	if naics02=' ' & naics_lbd~=' ' then naics02=substr(naics_lbd,1,6);
	
        *Make firmid variable;
	firmid=firmid_census;
	if firmid=' ' then firmid=firmid_lbd;
	
	if left(trim(firmid))='0' then firmid=firmid_lbd;
	if a=0 & b=1 then source="LBD";   
        
        *if Census emp missing, use LBD emp;
	emp=emp_census;
        if emp=. | emp=0 then emp=emp_lbd;
        if a=1 & b=0 then LBD_miss='yes'; 
        if a=0 & b=1 then CEN_miss='yes';   
   
       *Label variables;
       label   LBD_miss="Record missing from LBD"
	       CEN_miss="Record missing from Census"
	       emp_lbd="Emp from LBD"
               emp_census="Emp from Census" 
               EIN="EIN from Census"
               ALPHA="Alpha from Census"
               naics02="1. Naics02 from Census; 2. Naics from LBD";
       
      
       *Output datasets;
	if a=1 then output estabs2007;
	if a=1 | (b=1 & emp_lbd~=0 & emp_lbd~=. ) then output all_estabs2007;
	if a=1 & b=0 then output no_lbd_match2007;
    run;

  ****OUTPUT PERMANENT DATASET WITH CENSUS AND LBD INFORMATION*****;
    data margins.naics_bridge;
	set all_estabs2007;
    run;

    proc export data=margins.naics_bridge
    outfile="&margins/naics_bridge.dta"
    dbms=dta replace;
    run; 