
****This program pulls in as much data from the 2007 x-section as we can get, related to firm exports;

******************************************************************************;

options obs=max;

libname margins " "; /* data folder LOCATION */

libname beta " " ; /* CENSUS LBD MICRO DATA LOCATION */
%let libs=asm aux ccn cfi cmf cmi crt csr cut cwh lbd lfttd ssl imp exp ; 
%macro libs;
  %let k=1;
  %do %while (1);
      %let lib=%scan(&libs,&k);
      %if &lib eq %then %goto exit;
      libname &lib " "; /* CENSUS ECONOMIC DATA LOCATION */
      %let k=%eval(&k+1);
  %end;
 %exit: %mend;
%libs;

**Define yearly lists;
%let ccn_2007=alpha ein empavg naics_old sales_t survu_id tabbed valaddc cp;
* cannot find exports for ccn, convinced it does not export;

%let cmi_2007=ein exp alpha naics_old tvps survu_id tabbed te tvs va cm ; 

%let cmf_2007=ar alpha ein exp income_a ipt ivab ivae tib tie fib fie mib mie naics_old oe pay_ann_a
 sales_a sales_t survu_id tabbed te tvmc tvs va oe ow ww wie wib ;

%let cfi_2007=active alpha ein empl naics_old sales sales_t survu_id tabbed;
%let rem_2007=active alpha ein empl naics_old sales survu_id tabbed;

**Lists for expenses and costs, etc.;
%let costs_cmf_2007=cw cp cm cost_goodsold_A ee cr cf exp ccmpq cexso cdapr sw  cmea cmec cbe cme
 cmeo ctemp ecom_sales fipsst cou invfor nummats numprods  tce tpw ipt vr  ;
%let costs_cwh_2007=gross_margin gross_profit merch merch_r opexp opexp_r weight state_fips sales_t optype;

****** STEP 0: BRIDGE TOGETHER MISC/TRAL FILES IN CENSUS TO GET EXPORTS *******;
* give all census files a "exp" variable column = exports (subset of sales) in $K;
* crt2007, cwh2007, cut2007, csr2007, cfi2007;

data crt2007tral;
	set crt.crt2007tral(keep = itemcode itemvalue useflag itemname survu_id);
	if itemcode=0262;
	run;
proc sort nodupkey data=crt2007tral;
	by survu_id;
	run;
data crt2007base;
	set crt.crt2007base(keep = active alpha ein empl naics_old sales survu_id tabbed);
	run;
proc sort data=crt2007base;
	by survu_id;
	run;
data crt2007;
	merge crt2007base(in=isbase) crt2007tral(in=istral);
	by survu_id;
	exp = sales*itemvalue/100;
	if isbase=1;
	run;

data cwh2007tral;
	set cwh.cwh2007tral(keep = itemcode itemvalue useflag itemname survu_id);
	if itemcode=0262;
	run;
proc sort nodupkey data=cwh2007tral;
	by survu_id;
	run;
data cwh2007base;
	set cwh.cwh2007base(keep = active alpha ein empl naics_old sales survu_id tabbed 
	gross_margin gross_profit merch merch_r opexp opexp_r weight state_fips sales_t optype);
	run;
proc sort data=cwh2007base;
	by survu_id;
	run;
data cwh2007;
	merge cwh2007base(in=isbase) cwh2007tral(in=istral);
	by survu_id;
	exp = sales*itemvalue/100;
	if isbase=1;
	run;

data cut2007tral;
	set cut.cut2007tral(keep = itemcode itemvalue useflag itemname survu_id);
	if itemcode=4320;
	run;
proc sort nodupkey data=cwh2007tral;
	by survu_id;
	run;
data cut2007base;
	set cut.cut2007base(keep = active alpha ein empl naics_old sales survu_id tabbed);
	run;
proc sort data=cut2007base;
	by survu_id;
	run;
data cut2007;
	merge cut2007base(in=isbase) cut2007tral(in=istral);
	by survu_id;
	exp = itemvalue;
	if isbase=1;
	run;

data csr2007tral;
	set csr.csr2007tral(keep = itemcode itemvalue useflag itemname survu_id);
	if itemcode=0914;
	run;
proc sort nodupkey data=csr2007tral;
	by survu_id;
	run;
data csr2007base;
	set csr.csr2007base(keep = active alpha ein empl naics_old sales survu_id tabbed);
	run;
proc sort data=csr2007base;
	by survu_id;
	run;
data csr2007;
	merge csr2007base(in=isbase) csr2007tral(in=istral);
	by survu_id;
	exp=itemvalue;
	if isbase=1;
	run;

data cfi2007tral;
	set cfi.cfi2007tral(keep = itemcode itemvalue useflag itemname survu_id);
	if itemcode=0914;
	run;
proc sort nodupkey data=cfi2007tral;
	by survu_id;
	run;
data cfi2007base;
	set cfi.cfi2007base(keep = active alpha ein empl naics_old sales survu_id tabbed);
	run;
proc sort data=cfi2007base;
	by survu_id;
	run;
data cfi2007;
	merge cfi2007base(in=isbase) cfi2007tral(in=istral);
	by survu_id;
	exp=itemvalue;
	if isbase=1;
	run;


****MACRO 1: BRING IN SALES and EXPORT DATA FROM THE CENSUSES;
************************************************************************************;
%macro firm_sales(y);
***Pull in 2007 Census data;
%if &y=2007 %then %do;
data census&y(drop=ein_t temp: ein_l alpha naics_old);
    length firmid $ 10 temp2 $10  naics02_census $ 6 ;
    set ccn.ccn&y       (keep=&&ccn_&y     in=a rename=(survu_id=temp1 ein=ein_t) )
      cfi&y    (in=b)
      cmf.cmf&y         (keep=&&cmf_&y &&costs_cmf_&y    in=c rename=(ein=ein_t))
      cmi.cmi&y         (keep=&&cmi_&y     in=d rename=(survu_id=temp1 ein=ein_t))
      crt&y    (in=e)
      csr&y    (in=f rename=(ein=ein_l))
      cut&y    (in=g)
      cwh&y    (in=h);
   
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

if tabbed~='N';
run;
%end;


**Put lbdnums on the data;
****First check for cfn dupes;
***** NO DUPES IN 2007! wonderful;
***NEED TO use the tabbed variable here first....;

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
 	if source='cmf' then sales_manuf = sales;
    run;

%mend;
%firm_sales(2007);

  ****OUTPUT PERMANENT DATASET WITH CENSUS AND LBD INFORMATION*****;
    data margins.ec_salesexp2007;
	set census2007;
    run;