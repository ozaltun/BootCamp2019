****This program pulls in data from the economic censuses to make the main dataset;

***PROGRAM CREATES FOLLOWING PERMANENT DATSETS***
***1997, 2002, 2007 establishment files with sales, employment and industry;
***1997, 2002, 2007 sector totals;
******************************************************************************;

***The first macro brings in the sales data by industry from the Censuses;
***The second macro brings in employment data from the LBD;
***This program makes a dataset for each census year with sales, emp & industry, and with lbdnum and lbd emp;

options obs=max;


libname beta " " ;  /* LBD MICRO DATA */
libname fknaics " " ; /* FK NAICS FOLDER, C201002 */

libname margins " "; /* PROJECT DATA FOLDER */
%let margins= ; /* PROJECT DATA FOLDER */


****MACRO 1: BRING IN SALES DATA FROM THE CENSUSES;
************************************************************************************;

*****Make firm sales and employment;

**Get firm sales from the censuses;
***************************************************************;
**Define yearly lists;
%let ccn_1997=ate cfn einum naics tr va cm ; 
%let ccn_2002=actvstat alpha ein empavt naicnew rcptot survu_id tabstat valaddc ;
%let ccn_2007=alpha ein empavg naics_old sales_t survu_id tabbed valaddc cp;

%let cfi_1997=alpha cfn ein empl naics_new sales tabbed;
%let cfi_2002=active alpha ein empl naics_new sales survu_id tabbed;
%let cfi_2007=active alpha ein empl naics_old sales sales_t survu_id tabbed;

%let cmf_1997=bridge cfn ei  ind nind te tvs va fie fib tib tie mib mie wie wib ww oe ;
%let cmf_2002=ar active alpha ein ipt naics_new oe survu_id tabbed te tvs va tib tie fib fie mib mie wie wib ww ;
%let cmf_2007=ar alpha ein income_a ipt ivab ivae tib tie fib fie mib mie naics_old oe pay_ann_a sales_a sales_t survu_id tabbed te tvmc tvs va oe ow ww wie wib ;

*Census of Mining: Note that there are also production and non-production workers here: ww;
%let cmi_1997=cfn cfn6 ein nind6 te tvps va cm ;
%let cmi_2002=actvstat alpha ein empq1 naicold rcptot survu_id tabstat valaddm ;
%let cmi_2007=ein alpha naics_old tvps survu_id tabbed te tvs va cm ; 
   
%let rem_1997=alpha cfn ein empl naics_new sales tabbed;
%let rem_2002=active alpha ein empl naics_new sales survu_id tabbed;
%let rem_2007=active alpha ein empl naics_old sales survu_id tabbed;

**Lists for expenses and costs, etc.;
%let costs_cmf_2007=cw cp cm cost_goodsold_A ee cr cf exp ccmpq cexso cdapr sw  cmea cmec cbe cme cmeo ctemp ecom_sales fipsst cou invfor nummats numprods  tce tpw ipt vr  ;
%let costs_cwh_2007=gross_margin gross_profit merch merch_r opexp opexp_r weight state_fips sales_t optype;

%let costs_cmf_2002=cw cp cm cost_goodsold_A ee cr cf exp sw  cmea cmec cbe cme cmeo  ecom_sales fipsst cou nummats numprods tce tpw vr;
%let costs_cwh_2002=gross_margin gross_profit merch merch_r opexp opexp_r weight state_fips sales_t optype;

%let costs_cmf_1997=cw cp cm ee cr cf cet crm cpc cs exp fcm1 fcm2  sw  fipsst cou ne nummats numprods rm seqnmats tce tdcp tme tpw tr tvmc tvpsd ub ue um ipt vr  ;
%let costs_cwh_1997=gross_margin gross_profit merch merch_r opexp opexp_r weight state_fips  optype;


%macro firm_sales(y);
*Pull in 1992 and 1997 census data;
%if &y<2001 %then %do;
    
%if &y=1992 %then %do;	
data census&y;
  set ccn.ccn&y     (keep=&&ccn_&y     in=a)
      cfi.cfi&y.base(keep=&&cfi_&y     in=b rename=(sic=sic6))
      cmf.cmf&y     (keep=&&cmf_&y     in=c )
      cmi.cmi&y     (keep=&&cmi_&y     in=d rename=(ind=sic))
      crt.crt&y.base(keep=&&rem_&y     in=e rename=(sic=sic6))
      csr.csr&y.base(keep=&&rem_&y     in=f rename=(ein=ein_t sic=sic6))
      cut.cut&y.base(keep=&&rem_&y     in=g rename=(sic=sic6)) 
      cwh.cwh&y.base(keep=&&rem_&y     in=h rename=(sic=sic6));
    *Create variable to keep track of what file the record came from ;
       if a=1        then flag_a=1 ;
         else if b=1 then flag_b=1 ;
         else if c=1 then flag_c=1 ;
         else if d=1 then flag_d=1 ;
         else if e=1 then flag_e=1 ;
         else if f=1 then flag_f=1 ;
         else if g=1 then flag_g=1 ;
         else if h=1 then flag_h=1 ;
    if tabbed~='N';
run;
%end;

%if &y=1997 %then %do;
data census&y ;
  set ccn.ccn&y     (keep=&&ccn_&y     in=a)
      cfi.cfi&y.base(keep=&&cfi_&y     in=b )
      cmf.cmf&y     (keep=&&cmf_&y &&costs_cmf_&y in=c rename=(ei=ein))
      cmi.cmi&y     (keep=&&cmi_&y     in=d ) 
      crt.crt&y.base(keep=&&rem_&y     in=e )
      csr.csr&y.base(keep=&&rem_&y     in=f rename=(ein=ein_t))
      cut.cut&y.base(keep=&&rem_&y     in=g ) 
      cwh.cwh&y.base(keep=&&rem_&y &&costs_cwh_&y  in=h ); 

    *Create variable to keep track of what file the record came from ;
       if a=1        then flag_a=1 ;
         else if b=1 then flag_b=1 ;
         else if c=1 then flag_c=1 ;
         else if d=1 then flag_d=1 ;
         else if e=1 then flag_e=1 ;
         else if f=1 then flag_f=1 ;
         else if g=1 then flag_g=1 ;
         else if h=1 then flag_h=1 ;
   if tabbed~='N';
run;
%end;
	
 *Fix all variables;
 data census&y (drop=temp: );
   length firmid $ 10 temp $ 8 temp2 $ 6 naics97_census $ 6  sic_census $ 4 naics02_census $ 6 ;
   set census&y;	    
   
  *Make correct ein variable;
     if flag_f=1 then ein=left(trim(ein_t));
     if flag_a=1 then ein=einum;

   *Make firmid variable;
   if substr(cfn,1,1)='0' then firmid=cfn;
   if substr(cfn,1,1)~='0' then firmid=substr(cfn,1,6)||'0000';

  *Makes sales variable;
    if flag_a=1 then sales=tr;
    if flag_d=1 then sales=tvps;
    if flag_c=1 then sales=tvs;

  *Make employment variable;
   if flag_a=1 then emp_cen=ate;
   if flag_b=1 | flag_e=1 | flag_f=1 | flag_g=1 | flag_h=1 then emp_cen=empl;
   if flag_c=1 | flag_d=1 then emp_cen=te;

  *Make industry variable;
  %if &y=1992 %then %do;
      temp=ind;
      temp2=left(trim(temp));
      if flag_b=1 | flag_e=1 | flag_f=1 | flag_g=1 | flag_h=1 then sic_census=substr(sic6,1,4);     
      if flag_c=1 then sic_census=substr(temp2,1,4);      
      naics97_census=' ' ; 
      naics02_census=' '; 
      %end;
  %if &y=1997 %then %do;
      temp=ind;
      naics97_census=substr(naics_new,1,6);
      if flag_c=1 then naics97_census=nind;
      if flag_a=1 then naics97_census=naics;
      sic_census=' ';
      naics02_census=' ';
      %end;    
  *Make source variable;
       if flag_a=1        then source='ccn' ;
         else if flag_b=1 then source='cfi' ;
         else if flag_c=1 then source='cmf' ;
         else if flag_d=1 then source='cmi' ;
         else if flag_e=1 then source='crt' ;
         else if flag_f=1 then source='csr' ;
         else if flag_g=1 then source='cut' ;
         else if flag_h=1 then source='cwh' ;   
run;
%end;


***Pull in 2002 Census data;
%if &y=2002 %then %do;
data census&y(drop=temp2 surv_num ein_num empavt );
    length firmid $ 10 temp2 $ 10 temp3 $ 11 naics97_census $ 6 naics02_census $ 6 sic_census $ 4 ;
  set ccn.ccn&y     (keep=&&ccn_&y     in=a rename=(ein=ein_num survu_id=surv_num))
      cfi.cfi&y.base(keep=&&cfi_&y     in=b)
      cmf.cmf&y     (keep=&&cmf_&y   &&costs_cmf_&y  in=c rename=(ein=ein_num))
      cmi.cmi&y     (keep=&&cmi_&y     in=d rename=(ein=ein_num survu_id=surv_num))
      crt.crt&y.base(keep=&&rem_&y     in=e)
      csr.csr&y.base(keep=&&rem_&y     in=f rename=(ein=ein_l))
      cut.cut&y.base(keep=&&rem_&y     in=g)
      cwh.cwh&y.base(keep=&&rem_&y   &&costs_cwh_&y    in=h);
   *Make correct ein variable;
     if ein_num~=. then do;
	 ein=put(ein_num,z9.);
     end;
    if f=1 then ein=left(trim(ein_l));
   *Make cfn variable;
    if a=1 | d=1 then do;
      temp2=surv_num;
      cfn=temp2;
      end;
    if b=1 | c=1 | e=1 | f=1 | g=1 | h=1 then cfn=survu_id;  
  *Make firmid variable;
    if alpha~=' ' then firmid=alpha||"0000";
    if alpha=' ' then firmid='0'||ein;
   *Make activity code flag;
    if a=1 | d=1 then active=actvstat;
   *Make tabbed flag;
    if a=1 | d=1 then tabbed=tabstat;

  *Make employment variable;
   if a=1 then emp_cen=empavt;
   if b=1 | e=1 | f=1 | g=1 | h=1 then emp_cen=empl;
   if c=1 then emp_cen=te;
   if d=1 then emp_cen=empq1;

   *Create variable to keep track of what file the record came from ;
       if a=1        then source='ccn' ;
         else if b=1 then source='cfi' ;
         else if c=1 then source='cmf' ;
         else if d=1 then source='cmi' ;
         else if e=1 then source='crt' ;
         else if f=1 then source='csr' ;
         else if g=1 then source='cut' ;
         else if h=1 then source='cwh' ;
   *Make sales variable;
   if a=1 | d=1 then sales=rcptot;
   if c=1 then sales=tvs;

   *Make industry variables;
   naics02_census=substr(naics_new,1,6);
   if a=1 then naics02_census=substr(naicnew,1,6);
   sic_census=' ';
   naics97_census=' ';
if tabbed~='N' ;  
run;
%end;

***Pull in 2007 Census data;
%if &y=2007 %then %do;
data census&y(drop=ein_t temp: ein_l  sic_census naics97_census alpha naics_old);
    length firmid $ 10 temp2 $10  naics97_census $ 6 naics02_census $ 6 sic_census $ 4 ;
    set ccn.ccn&y       (keep=&&ccn_&y     in=a rename=(survu_id=temp1 ein=ein_t) )
      cfi.cfi&y.base    (keep=&&cfi_&y     in=b)
      cmf.cmf&y         (keep=&&cmf_&y &&costs_cmf_&y    in=c rename=(ein=ein_t))
      cmi.cmi&y         (keep=&&cmi_&y     in=d rename=(survu_id=temp1 ein=ein_t))
      crt.crt&y.base    (keep=&&rem_&y     in=e)
      csr.csr&y.base    (keep=&&rem_&y     in=f rename=(ein=ein_l))
      cut.cut&y.base    (keep=&&rem_&y     in=g) 
      cwh.cwh&y.base    (keep=&&rem_&y  &&costs_cwh_&y    in=h);
   
 *Make fixed ein variable;
    if ein_t~=. then do;
	 ein=put(ein_t,z9.);
     end;
     if f=1 then ein=left(trim(ein_l));
			  
   *Make cfn variable;
   if a=1 | d=1 then do;
       temp2=temp1;
       cfn=temp2;
       end;
    if b=1 | c=1 | e=1 | f=1 | g=1 | h=1 then cfn=survu_id; 
   *Make firmid variable;
    if alpha~=' ' then firmid=alpha||"0000";
    if alpha=' ' then firmid='0'||ein;
   *Make sales variable;
    if a=1 then sales=sales_t;
    if c=1 | d=1 then sales=tvs;
   *Make naics variables;
    naics02_census=substr(naics_old,1,6);
    sic_census=' ';
    naics97_census=' ';
    
   *Make employment variable;
    if a=1 then emp_cen=empavg;
    if b=1 | e=1 | f=1 | g=1 | h=1 then emp_cen=empl;
    if c=1 | d=1 then emp_cen=te;
  
   *Create variable to keep track of what file the record came from ;
       if a=1        then source='ccn' ;
         else if b=1 then source='cfi' ;
         else if c=1 then source='cmf' ;
         else if d=1 then source='cmi' ;
         else if e=1 then source='crt' ;
         else if f=1 then source='csr' ;
         else if g=1 then source='cut' ;
         else if h=1 then source='cwh' ;
if tabbed~='N' ;
run;
%end;


**Put lbdnums on the data;
****First check for cfn dupes;

    proc sort data=census&y;
	by cfn ;
    run;
    data census&y dupes&y;
	set census&y;
	by cfn;
	if first.cfn=1 & last.cfn=1 then output census&y;
	else output dupes&y;
    run;
    data dupes_add;
	set dupes&y;
	if source='cmf';
    run;
    proc sort nodupkey data=dupes_add;
	by cfn ;
    run;
    data census&y;
	set census&y dupes_add;
    run;
    


%mend;
%firm_sales(1997);
%firm_sales(2002);
%firm_sales(2007);


***MACRO 2: GET EMPLOYMENT and PAYROLL DATA FROM THE LBD (Expands the scope of data coverage);
************************************************************************************;

**Make firm employment share data;
%macro firm_emp(y,ind);
    proc sort data=beta.lbd&y.c(keep=lbdnum cfn firmid emp naics sic bestnaics bestsic pay
                                rename=(sic=sic1 firmid=firmid_lbd naics=naics_lbd emp=emp_lbd pay=pay_lbd)) out=lbd;
	by lbdnum  ;
    run;

    data lbd;
	set lbd;
	cfn_lbd=cfn;
    run;
    


  *Add the fk naics codes;
    data fknaics(keep=lbdnum fk_naics02);
	set fknaics.naics&y;
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
    
    proc sort data=census&y;
	by cfn;
    run;
    
    data estabs&y(drop=sic1) no_lbd_match&y(drop=sic1) all_estabs&y(drop=sic1) ;
	length sic_lbd $ 4 sic $ 4 naics97 $ 6 naics02 $ 6 ;
	merge census&y(in=a rename=(emp_cen=emp_census firmid=firmid_census)) lbd(in=b);
	by cfn;
       
        *Make industry variables;
	sic_lbd=substr(sic1,1,4);
	sic=sic_census;
	if sic=' ' & sic_lbd~=' ' then sic=sic_lbd;
	if sic=' ' & bestsic~=' ' then sic=substr(bestsic,1,4); 
	naics97=naics97_census;
	if naics97=' ' & naics_lbd~=' ' then naics97=substr(naics_lbd,1,6);
	naics02=naics02_census;
	if naics02=' ' & naics_lbd~=' ' then naics02=substr(naics_lbd,1,6);
	
        *Make firmid variable;
	firmid=firmid_census;
	if firmid=' ' then firmid=firmid_lbd;
	%if &y=1997 %then %do;
	    if source='cmi' | source='ccn' then firmid=firmid_lbd;  /*  No alpha found in this census data  */
	    %end;
	
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
	if a=1 then output estabs&y;
	if a=1 | (b=1 & emp_lbd~=0 & emp_lbd~=. ) then output all_estabs&y;
	if a=1 & b=0 then output no_lbd_match&y;
    run;

  ****OUTPUT DATASET WITH CENSUS AND LBD INFORMATION*****;
    data margins.estabs_sales&y;
	set all_estabs&y;
    run;

    proc export data=margins.estabs_sales&y
    outfile="&margins/estabs_sales&y..dta"
    dbms=dta replace;
    run; 


%mend;
%firm_emp(1997,fk_naics02);
%firm_emp(2002,fk_naics02);
%firm_emp(2007,fk_naics02);

************************************************************************************;