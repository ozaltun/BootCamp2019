**********THIS PROGRAM MAKES A EIN_FIRMID bridge for years 97, 02, 07;

libname margins " "; /* PROJECT DATA FOLDER */

options obs=max;

***********************************************
**** 1. ECONOMIC CENSUS DATA CONCORDANCE  *****
***********************************************;
** Define yearly lists **;

%let ccn_1997 = ate cfn einum; 
%let ccn_2002 = empavt actvstat alpha ein survu_id tabstat;
%let ccn_2007 = empavg alpha ein survu_id tabbed;

%let cmf_1997 = te cfn ei;
%let cmf_2002 = te ar active alpha ein survu_id tabbed;
%let cmf_2007 = te ar alpha ein survu_id tabbed;

%let cmi_1997 = te cfn cfn6 ein;
%let cmi_2002 = empq1 actvstat alpha ein survu_id tabstat;
%let cmi_2007 = te ein alpha survu_id tabbed;

%let rem_1997 = empl alpha cfn ein tabbed;
%let rem_2002 = empl active alpha ein survu_id tabbed;
%let rem_2007 = empl active alpha ein survu_id tabbed;

/* 
macro outputs the following variables in each year:
Dataset: census&y
Unique by: CFN
1997: FIRMID CFN EIN ALPHA TABBED SOURCE EMP
2002: FIRMID CFN EIN ALPHA TABBED SOURCE EMP
2007: FIRMID CFN EIN ALPHA TABBED SOURCE EMP
*/

%macro census_concord(y);

*Pull in 1992 and 1997 census data;

%if &y=1997 %then %do;
data census&y ;
  	set 	ccn.ccn&y     (keep=&&ccn_&y     in=a)
      		cfi.cfi&y.base(keep=&&rem_&y     in=b )
      		cmf.cmf&y     (keep=&&cmf_&y     in=c rename=(ei=ein))
      		cmi.cmi&y     (keep=&&cmi_&y     in=d )
      		crt.crt&y.base(keep=&&rem_&y     in=e )
      		csr.csr&y.base(keep=&&rem_&y     in=f rename=(ein=ein_t))
      		cut.cut&y.base(keep=&&rem_&y     in=g )
      		cwh.cwh&y.base(keep=&&rem_&y     in=h );

    	*Create variable to keep track of what file the record came from ;
       	if a=1 then flag_a=1 ;
	else if b=1 then flag_b=1 ;
	else if c=1 then flag_c=1 ;
	else if d=1 then flag_d=1 ;
	else if e=1 then flag_e=1 ;
	else if f=1 then flag_f=1 ;
	else if g=1 then flag_g=1 ;
	else if h=1 then flag_h=1 ;

   	if tabbed~='N';
run;

*Fix all variables (applies to 1997);
 data census&y(keep=FIRMID CFN EIN ALPHA TABBED SOURCE EMP);
   length firmid $ 10 ;
   set census&y;	

  *Make correct EIN variable;
     if flag_f=1 then ein=left(trim(ein_t));
     if flag_a=1 then ein=einum;

  *CFN variable is already made pre-2001;

  *Make FIRMID variable;
   if substr(cfn,1,1)='0' then firmid=cfn;
   if substr(cfn,1,1)~='0' then firmid=substr(cfn,1,6)||'0000';

  *Make employment variable;
   if flag_a=1 then EMP=ate;
   if flag_b=1 | flag_e=1 | flag_f=1 | flag_g=1 | flag_h=1 then EMP=empl;
   if flag_c=1 | flag_d=1 then EMP=te;

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
data census&y(drop=temp2 surv_num ein_num survu_id AR ein_l tabstat actvstat active empavt empl empq1 te);
    	length firmid $ 10 temp2 $ 10;
  	set 	ccn.ccn&y     (keep=&&ccn_&y     in=a rename=(ein=ein_num survu_id=surv_num))
      		cfi.cfi&y.base(keep=&&rem_&y     in=b)
      		cmf.cmf&y     (keep=&&cmf_&y     in=c rename=(ein=ein_num))
      		cmi.cmi&y     (keep=&&cmi_&y     in=d rename=(ein=ein_num survu_id=surv_num))
		crt.crt&y.base(keep=&&rem_&y     in=e)
      		csr.csr&y.base(keep=&&rem_&y     in=f rename=(ein=ein_l))
		cut.cut&y.base(keep=&&rem_&y     in=g)
		cwh.cwh&y.base(keep=&&rem_&y     in=h);

  	*Make correct EIN variable (num to char, delete spacing);
     	if ein_num~=. then do;
	 	ein=put(ein_num,z9.);
     		end;
    	if f=1 then ein=left(trim(ein_l));

   	*Make CFN variable (CFN = SURVU_ID all years);
    	if a=1 | d=1 then do;
      		temp2=surv_num;
      		cfn=temp2;
      		end;
    	if b=1 | c=1 | e=1 | f=1 | g=1 | h=1 then cfn=survu_id;

  	*Make FIRMID variable (from scratch);
    	if alpha~=' ' then firmid=alpha||"0000";
    	if alpha=' ' then firmid='0'||ein;

	*Make activity code flag the same name;
    	if a=1 | d=1 then active=actvstat;

   	*Make tabbed flag the same name;
    	if a=1 | d=1 then tabbed=tabstat;

	*Make employment variable;
	if a=1 then EMP=empavt;
	if b=1 | e=1 | f=1 | g=1 | h=1 then EMP=empl;
	if c=1 then EMP=te;
	if d=1 then EMP=empq1;

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


***Pull in 2007 Census data;
%if &y=2007 %then %do;
data census&y(drop=ein_t temp: ein_l survu_id ar active empavg empl te);
	length firmid $ 10 temp2 $ 10;
	set 	ccn.ccn&y         (keep=&&ccn_&y     in=a rename=(survu_id=temp1 ein=ein_t))
      		cfi.cfi&y.base    (keep=&&rem_&y     in=b)
      		cmf.cmf&y         (keep=&&cmf_&y     in=c rename=(ein=ein_t))
      		cmi.cmi&y         (keep=&&cmi_&y     in=d rename=(survu_id=temp1 ein=ein_t))
      		crt.crt&y.base    (keep=&&rem_&y     in=e)
      		csr.csr&y.base    (keep=&&rem_&y     in=f rename=(ein=ein_l))
      		cut.cut&y.base    (keep=&&rem_&y     in=g)
      		cwh.cwh&y.base    (keep=&&rem_&y     in=h);

    	*Make consistent EIN variable (num to char, delete spacing);
    	if ein_t~=. then do;
	 	ein=put(ein_t,z9.);
     		end;
     	if f=1 then ein=left(trim(ein_l));

   	*Make CFN variable (CFN = SURVU_ID all years);
   	if a=1 | d=1 then do;
       		temp2=temp1;
       		cfn=temp2;
       		end;
	if b=1 | c=1 | e=1 | f=1 | g=1 | h=1 then cfn=survu_id;

   	*Make FIRMID variable (from scratch);
    	if alpha~=' ' then firmid=alpha||"0000";
    	if alpha=' ' then firmid='0'||ein;

	*Make employment variable;
	if a=1 then EMP=empavg;
	if b=1 | e=1 | f=1 | g=1 | h=1 then EMP=empl;
	if c=1 | d=1 then EMP=te;
	
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

%if &y=1997 | &y=2002 | &y=2007 %then %do;
*Check for cfn dupes and remove anything that has a duplicate, systematically;

    proc sort data=census&y;
	by cfn ;
    run;
    data census&y dupes&y;
	set census&y;
	by cfn;
	if first.cfn=1 & last.cfn=1 then output census&y;
	else output dupes&y;
    run;
    * now add back unique versions of duplicated records;

    /* STEP 1: arbitrarily remove records that have the same values for ALL identifiers*/
    proc sort data=dupes&y nodupkey dupout=droppedcfn&y;
	by cfn firmid ein alpha;
    run;

    /*STEP 2: for 1997, among remaining dupes, choose records with correct EIN  and delete theone with wrong EIN*/

    %if &y=1997 %then %do;
    data dupes_add;
	set dupes&y;
	if alpha=' ' then msalpha=1;
		else msalpha=0;
	if ein=' ' then msein=1;
		else msein=0;
    run;
    data dupes_add(drop=dropv);
	set dupes_add;
	if alpha=' ' & ein~=' ' & substr(cfn,2,9)~=ein then dropv=1;
	if dropv~=1;
    run;
    proc sort data=dupes_add;
	by cfn firmid msein msalpha;
    run;
    data dupes_add(drop=msein msalpha);
	set dupes_add;
	by cfn firmid msein msalpha;
	if first.cfn=1;
    run;
    %end;

    /* if year is 2002 or 2007 then no further steps needed */
    %if &y=2002 | &y=2007 %then %do;
	data dupes_add;
		set dupes&y;
	run;
    %end;

    data census&y;
	set census&y dupes_add;
    run;
    *check there are no duplicates in CFN;
    proc freq;
	tables cfn / noprint out=cfnlist;
    run;
    proc print;
	where count ge 2;
    run;

%end;
%mend;

***********************************************
************** 2. FETCH LBD DATA  *************
***********************************************;

*Fetch LBD information, all years;
*For census years, concord with census;

/* Current macro outputs the following variables in each year:
Dataset: lbd&y (all years)
Unique by: CFN
LBDNUM CFN FIRMID_LBD EMP_LBD RECNUM

Dataset: ec_lbd&y = all_estabs&y (Census years)
Unique by: CFN
FIRMID EIN CFN ALPHA TABBED SOURCE EMP FIRMID_LBD CFN_LBD LBDNUM FIRMID_CENSUS
Source=LBD records currently do not have EIN, but we will soon fetch below from SSEL
*/

%macro lbd_concord(y);

    proc sort data=lbd.lbd&y.c(keep=lbdnum cfn firmid emp recnum rename=(firmid=firmid_lbd emp=emp_lbd))
	out=lbd&y;
	by lbdnum;
    run;

    *procedure to remove duplicated CFNs (and bad CFNs) in LBD sample;
    proc sort data=lbd&y;
	by cfn;
    run;

    *lbd&y now contains unique CFN entries, rest of the records go to dupes for treatment;
    data lbd&y dupes;
	set lbd&y;
	by cfn;
	if first.cfn=1 & last.cfn=1 then output lbd&y;
	else output dupes;
    run;

    *refining dupes;
    %if &y=1997  %then %do;
    data dupes_add;
	set dupes;
	if firmid_lbd~=' ' ;
    run;
    proc sort nodupkey data=dupes_add;
	by cfn firmid_lbd;
    run;
    %end;

    *NOW ADD BACK DUPES FOR ALL YEARS EXCEPT 2002 or 2007;
    %if &y~=2002 & &y~=2007 %then %do;
    data lbd&y;
	set lbd&y dupes_add;
    run;
    %end;

    *MERGE in Census information (by CFN);
    data lbd&y;
	set lbd&y;
	cfn_lbd=cfn;
    run;
    %if  &y=1997 | &y=2002 | &y=2007 %then %do;
    proc sort data=lbd&y;
	by cfn;
    run;
    proc sort data=census&y;
	by cfn;
    run;
    *this is a 1:1 merge since both datasets are unique in cfn;
    data estabs&y(drop=emp_lbd) no_lbd_match&y all_estabs&y(drop=emp_lbd);
	merge census&y(in=a rename=(firmid=firmid_census)) lbd&y(in=b);
	by cfn;

        *Make final FIRMID variable;
	firmid=firmid_census;
	if firmid=' ' then firmid=firmid_lbd;
	%if &y=1997 %then %do;
	    if (source='cmi' | source='ccn') & firmid_lbd~=' ' then firmid=firmid_lbd;
	    /*  No alpha found in these census data  */
	    %end;
	if left(trim(firmid))='0' then firmid=firmid_lbd;
	if a=0 & b=1 then source="LBD";

	*Refine Employment data, emp=lbd emp if source is only lbd. else trust census;
	if a=0 & b=1 then EMP=emp_lbd;

       	*Label variables;
       	label  EIN="EIN from Census"
               ALPHA="Alpha from Census";

        *Output datasets;
	*We want to keep a=0 records that have positive emp in the LBD;
	if a=1 then output estabs&y;
	if a=1 | (b=1 & emp_lbd~=0 & emp_lbd~=. ) then output all_estabs&y;
	if a=1 & b=0 then output no_lbd_match&y;
    run;

    *check there are no duplicates in the resulting dataset all_estabs&y;
    proc freq data=all_estabs&y;
	tables cfn / noprint out=cfnlist;
    run;
    proc print;
	where count ge 2;
    run;
    %end;

*check there are no duplicates in the resulting dataset lbd&y;
    proc freq data=lbd&y;
	tables cfn / noprint out=cfnlist;
    run;
    proc print;
	where count ge 2;
    run;
%mend;

************************************************
************** 3. FETCH SSEL DATA  *************
***********************************************;

*Fetch SSEL information, concord with census and LBD;

/* 
Current macro outputs the following variables in each year:
ssel&y: FIRMID CFN EIN PAYROLL DUPE_FLAG         (unique by EIN)
ssel_forlbd&y: FIRMID CFN EIN PAYROLL DUPE_FLAG  (unique by CFN)
*/

%let listbr=act cfn ein;

%macro ssel_concord(y);

%if &y<2002 %then %do;
    %let listbr_s= act cfn ein acqp1 acqp2 acqp3 acqp4 pdiv ac943p;  
    %let listbr_m= alpha act cfn ein rap;  

/*  The eialpha variable prior to 2002 is not meaningful  */
%end;

%if &y>2001 %then %do;
    %let listbr_s= alpha act empunit_id_char ein acqp1 acqp2 acqp3 acqp4 pdiv ac943p;  
    %let listbr_m= alpha act empunit_id_char ein rap;  
  %let listbr=alpha act  ein;
%end;

data ids(keep=firmid cfn ein payroll act alpha) ids_add(keep=firmid cfn ein payroll act alpha) subs(keep=firmid cfn ein payroll act alpha) ;
   	set 	ssl.ssl&y.mu(keep=&listbr_m in=a) 
		ssl.ssl&y.su(keep=&listbr_s in=b);
   	length firmid $10 ;

	*Make CFN variable if on or post 2002;
	%if &y>=2002 %then %do;
		cfn = empunit_id_char;
	%end;

	*Make firmid variable depending on pre or post 2002;
	%if &y<2002 %then %do;
		if substr(cfn,1,1)='0' then firmid=cfn;
		if substr(cfn,1,1)~='0' then firmid=substr(cfn,1,6)||'0000';
	%end;
	%if &y>=2002 %then %do;
		if alpha=' ' then firmid='0'||ein;
		if alpha~=' ' then firmid=left(trim(alpha))||"0000";
	%end;

	*Make payroll variable;
	payroll=rap;
	if b=1 then payroll=acqp1+acqp2+acqp3+acqp4 ;
	
	*Only records with a firmid and ein are useful;
	if firmid^=' ';
	*if cfn^=' ';
	if ein^=' ';  
	if ein^='000000000';
	if left(trim(ein))~='.';
	if left(trim(firmid))^='.';
	
	*Code to identify active establishments; 
	if act='D' | act='G' | act='N' then drop=1;  *Drop records that are deletes, ghosts or non-actives;
	if pdiv='M' then do;
		drop=1;
		add_subs=1;  *Submaster records;
	end;
	
	*Additional records to add back in if not conflicting;
	if a=1 & payroll>0 & act='D' then add_recs=1;
	if a=1 & payroll>0 &  act='N' then add_recs=1;   
*Might be possible for an MU to have act='N' and positive payroll, in which case it was a business that closed during year;
	
	*Output datasets;
	if drop~=1 then output ids;
	if add_recs=1 then output ids_add;
	if add_subs=1 then output subs;
run;


**First eliminate legitimate dupes;
  *Do this methodically in case the ein-cfn maps to multiple firmids;
    *Sum payroll for each ein-firmid-cfn combination;
	proc sort data=ids;
	    by ein firmid cfn;
	run;
	proc means sum noprint data=ids;
	    by ein firmid cfn;
	    var payroll;
	    output out=ids2(keep=ein firmid cfn payroll) sum(payroll)=;
	run;

**Add back records of firms that went out of business during the year if they do not create dupes (at EIN level) Dataset is ids_add2;
	proc sort data=ids_add;
	    by ein firmid cfn;
	run;
	proc means sum noprint data=ids_add;
	    by ein firmid cfn;
	    var payroll;
	    output out=ids_add(keep=ein firmid cfn payroll) sum(payroll)=;
	run;
	
      *Key (Unique list) of ein values in legit data, ids2;
	proc sort nodupkey data=ids2(keep=ein) out=id_ein;
	    by ein;
	run;
	*only admit records that do not clash with an existing EIN number in ids2;
	data ids_add2;
	    merge id_ein(in=a) ids_add(in=b);
	    by ein;
	    if a=0;
	run;

**Add back submaster records if they do not create dupes (at EIN level). Dataset is ids_subs;
	proc sort data=subs;
	    by ein firmid cfn;
	run;
	proc means sum noprint data=subs;
	    by ein firmid cfn;
	    var payroll;
	    output out=subs(keep=ein firmid cfn payroll) sum(payroll)=;
	run;
	
	*only admit records that do not clash with an existing EIN number in ids2;
	data ids_subs;
	    merge id_ein(in=a) subs(in=b);
	    by ein;
	    if a=0;	    
	run;

	data ids3;
	    set ids2 ids_add2 ids_subs;
	run;

  *Double check no dupes were created;
    **If records deleted, this indicates a problem in code;
	proc sort nodupkey data=ids3;
	    by ein firmid cfn;
	run;
	
*output final datasets ssel and ssel_forlbd in a way that ensures CFN matches to unique EIN (and FIRMID) in output ssel_forlbd&y;
	proc sort data=ids3;
	    by cfn payroll ein firmid;
	run;
	data ssel_forlbd&y;
	    set ids3;
	    by cfn payroll ein firmid;
	    if last.cfn then output ssel_forlbd&y;
	run;
**Ensures that EIN matches to unique FIRMID in output ssel&y;
	proc sort data=ids3;
	    by ein firmid;
	run;
	proc means sum noprint data=ids3;
	    by ein firmid;
	    var payroll;
	    output out=ids3(keep=ein firmid payroll) sum(payroll)=;
	run;
	data ssel&y sseldupes&y;
	    set ids3;
	    by ein firmid;
	    if first.ein=1 & last.ein=1 then dupe_flag=0;
	    else dupe_flag=1;
	    if last.ein then output ssel&y;
	    else output sseldupes&y;
	run;
*check there are no duplicates in the resulting datasets;
    proc freq data=ssel&y;
	tables ein / noprint out=einlist;
    run;
    proc print;
	where count ge 2;
    run;
    proc freq data=ssel_forlbd&y;
	tables cfn / noprint out=cfnlist;
    run;
    proc print;
	where count ge 2;
    run;
%mend;


***********************************************
************* 4. BUILDING BRIDGES  ************
***********************************************;

*This final step constructs the EIN-FIRMID bridge and saves to permanent library;
*The next script calls these bridge&y output files;

*For census years, concord all_estabs&y with ssel_forlbd&y, by CFN;
*For remaining years, concord lbd&y with ssel_forlbd&y, by CFN;

/* 
Current macro outputs the following variables in each year:
EIN-FIRMID, unique by EIN, accompanied by
SOURCE_CONCORD FIRMID_LBD FIRMID_CEN FIRMID_BR CONFLICT EIN_BR EIN_CEN
*/

%macro build_bridge(y);

*years where census data is available;

%if &y=1997 | &y=2002 | &y=2007 %then %do;

*split all_estabs&y into two datasets, one which we match by CFN and one which we match by EIN;
*remember allestabs is combination of EC and LBD data. LBD-only data could be missing EIN;
/* if record is missing both EIN and CFN, then cannot help. dump it -these are bad anyway, 
checked. EIN = 999999999 and 000000000 records are just as if EIN is missing
*/

data missingein(keep=cfn firmid_ms_ein firmid_lbd firmid_census source_ms_ein);
	set all_estabs&y(rename=(source=source_ms_ein firmid=firmid_ms_ein));
	if (ein=' ' | ein='999999999' | ein='000000000') & cfn~=' ';
run;

data existingein(keep=ein firmid firmid_census firmid_lbd priori emp);
	set all_estabs&y;
	if source='LBD' then priori=0;
	else priori=1;
	if ein~=' ' & ein~='999999999' & ein~='000000000';
run;

*1. merge missingein with ssel_forlbd by CFN, to pull EIN info;

proc sort data=missingein;
	by cfn;
run;

proc sort data=ssel_forlbd&y;
	by cfn;
run;

*data missing(keep = ein firmid firmid_lbd firmid_census source_concord source_ms_ein);
data missing;
	length source_concord $6;
	merge missingein(in=a) ssel_forlbd&y(in=b rename=(firmid=firmid_br));
	by cfn;
	if a=1 & firmid_ms_ein~=' ' then firmid=firmid_ms_ein;
	if a=1 & firmid_ms_ein=' ' then firmid=firmid_br;
	source_concord = 'BR'; /*all the EINs here are from BR*/
	if a=1 & b=1 then output missing;
	/*b=1 chosen because those with just a=1 contain missing ein - these are useless*/
run;
*splitting missing into PART A and PART B;
proc sort data=missing;
	by ein;
run;
data part_a(keep = ein firmid firmid_lbd firmid_census source_concord source_ms_ein) part_b;
	set missing;
	by ein;
	if first.ein=1 & last.ein=1 then output part_a;
	else if payroll>0 then output part_b;
run;
data part_b;
	set part_b;
	if source_ms_ein='LBD' then priori=0;
	else priori=1;
run;
proc sort data=part_b;
	by ein priori firmid firmid_lbd firmid_census source_concord;
run;
proc means sum noprint data=part_b;
	by ein priori firmid firmid_lbd firmid_census source_concord;
	var payroll;
	output out=part_b(keep=ein priori firmid payroll firmid_lbd firmid_census source_concord) sum(payroll)=;
run;
proc sort data=part_b;
	by ein priori payroll;
run;
data part_a2(keep = ein firmid firmid_lbd firmid_census source_concord source_ms_ein conflict);
	set part_b;
	by ein priori payroll;
	if priori=1 then source_ms_ein='cens';
	else source_ms_ein='LBD';
	conflict = 1;
	if last.ein then output part_a2;
run;
data missing;
	length source_ms_ein $ 6;
	set part_a part_a2;
run;
*check there are no duplicates in the dataset missing;
    proc freq data=missing;
	tables ein / noprint out=einlist;
    run;
    proc print;
	where count ge 2;
    run;

*2. now merge 3 datasets together by EIN: existingein, missing (just got ein in step above), and ssel&y;

*existingein dataset can have one EIN mapping to multiple FIRMID not allowed, fixing this;
*collapse by ein priority (whether it is census or LBD) firmid;
proc sort data=existingein;
	by ein priori firmid firmid_census firmid_lbd;
run;
proc means sum noprint data=existingein;
	by ein priori firmid firmid_census firmid_lbd;
	var emp;
	output out=existingein(keep=ein priori firmid firmid_census firmid_lbd emp) sum(emp)=;
run;
proc sort data=existingein;
	by ein priori emp;
run;
data existingein(keep = ein firmid firmid_census firmid_lbd source conflict);
	set existingein;
	by ein priori emp;
	if priori=1 then source='cens';
	else source='LBD';
	if  first.ein~=1 & last.ein=1 then conflict=1;
	if last.ein then output existingein;
run;

proc sort data=ssel&y out=ssel(keep=ein firmid);
	by ein;
run;

proc sort data=existingein;
	by ein;
run;

proc sort data=missing;
	by ein;
run;

data margins.bridge&y(keep = ein firmid firmid_lbd firmid_br firmid_census source_concord source conflict);
	length source_concord $ 6;
	merge existingein(in=a rename=(firmid=firmid_ec)) missing(in=b rename=(firmid=firmid_ms)) ssel(in=c rename=(firmid=firmid_br));
	by ein;
	if a=1 & firmid_ec~=' ' then firmid=firmid_ec;
	if a=1 & firmid_ec=firmid_br then source_concord = 'Both';
	if a=1 & firmid_ec~=firmid_br & firmid_ec~=' ' then source_concord = 'Census';
	if a=0 & b=1 & firmid_ms~=' ' then firmid=firmid_ms;
	if a=0 & b=1 & firmid_ms~=' ' then source=source_ms_ein;
	if a=0 & b=0 then firmid=firmid_br;
	if a=0 & b=0 then source_concord = 'BR';
	if a=0 & b=0 then source="BR";
	/*still end up with some records (from dataset missing) without EIN numbers. nothing we can do about these*/
	if EIN~=' ';
run;

*now bridge97,02,07 should be unique by EIN (and hence EIN-FIRMID);

%end;

*check there are no duplicates in the dataset bridge;
    proc freq data=margins.bridge&y;
	tables ein / noprint out=einlist;
    run;
    proc print;
	where count ge 2;
    run;
%mend;


%macro looper(y);
	%census_concord(&y);
	%lbd_concord(&y);
	%ssel_concord(&y);
	%build_bridge(&y);
%mend;
%looper(1997);
%looper(2002);
%looper(2007);
