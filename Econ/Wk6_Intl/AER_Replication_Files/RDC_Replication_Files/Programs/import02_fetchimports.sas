**********THIS PROGRAM MAKES MATCHED IMPORT DATA FOR 97,02,07 FROM THE IMPORTER DATABASE;
* note: we use consumption imports;

options obs=max;

libname margins " "; /* PROJECT DATA FOLDER */
%let margins= ; /* PROJECT DATA FOLDER */

***********************************************
**** 1. FETCH IMPORTS  *****
***********************************************;

%macro fetch_imports(y);
    
    %macro temp();
	
%if &y<2007 %then %do;
    %let listextra=;  /*  EIN_ULT not available before 2007  */
%end;
%if &y>2006 %then %do;
    %let listextra=ein_ult;  /*  EIN_ULT available starting in 2007  */
%end;

*Bring in the aggregated import file;
  data imports_alt(drop=related value temp);
     length ein $9;
     length ein_uc $9;
     set imp.imp&y(keep=ein &listextra type value country related hs qty: rename=(ein=temp));
     if value<=0 then delete;
     ivalue=value;
    
    *Keep original ein variable;
     ein_original=temp;

    *Make ein variable;
     eint=left(temp);
     eint=left(eint);

     if substr(eint,3,1) = '-' then ein=substr(eint,1,2)||substr(eint,4,7);

     if substr(eint,3,1) ^= '-' then ein=substr(eint,1,9);
     dashflg_imp=index(ein,'-');
     if dashflg_imp>0 then ein='mu dashes';
     if dashflg_imp=7 then ein='cbp';
     if dashflg_imp=4 & substr(eint,7,1)='-' then ein='ssn';

     if substr(ein,1,1) in ('A','B','C','D','E','F','G','H','I','J',
       'K','L','M','N','O','P','Q','R','S','T',
       'U','V','W','X','W','X','Y','Z')
       then ein='letters';

     if ein=' ' then ein='missing';
      
     ein_source="importer";
     
     %if &y=2007 %then %do ;	 
      *Make ein variable from ultimate consignee (only available after 2007);
       temp2=left(ein_ult);
       temp2=left(temp2);
       if substr(temp2,3,1) = '-' then ein_uc=substr(temp2,1,2)||substr(temp2,4,7);
       if substr(temp2,3,1) ^= '-' then ein_uc=substr(temp2,1,9);
       dashflg=index(ein_uc,'-');
       if dashflg>0 then ein_uc='mu dashes';
       if dashflg=7 then ein_uc='cbp';
       if dashflg=4 & substr(ein_uc,7,1)='-' then ein_uc='ssn';
       if substr(ein_uc,1,1) in ('A','B','C','D','E','F','G','H','I','J',
       'K','L','M','N','O','P','Q','R','S','T',
       'U','V','W','X','W','X','Y','Z')
        then ein_uc='letters';
       if ein_uc=' ' then ein_uc='missing';

       *Use ultimate consignee ein when available or when it conflicts with importer;
        if ein_uc=ein then ein_source="both";
	if ein_uc~=ein then do;
	    if ein_uc~="missing" & ein_uc~='cbp' & ein_uc~='ssn' & ein_uc~='letters' & ein_uc~='mu dashes' & ein_uc~='000000000' 
             then do;
		ein=ein_uc;
		ein_source="ult cons";
		end;
	    end;    
       %end;
   
    *Make ritrans variable;
     itrans=1;
     if related='Y' then do;
        ritrans=1;
	rp_ivalue=ivalue;
	end;
    
    if related='N' then ritrans=0;  
 
   *Limit by type;
   if type in ('1','2','5');      ***** consumption imports **********;

run;


proc freq data=imports_alt;  tables ein_source; run;				     

	%mend;
    %temp();


***********************************************
**** 2. IDENTIFY IMPORTS  *****
***********************************************;

*Merge Trade data to Firmids;

proc sort data=imports_alt ; by ein; run;
proc sort data=margins.bridge&y out=bridge&y; by ein; run;

data imports_&y._alt imports_nomatch_a;
  merge imports_alt(in=a) bridge&y(in=b);
  by ein; 
  if ivalue=. then ivalue=0;
  if itrans=. then itrans=0;
  if a=1 & b=0 then firmid=ein;
  if a=1 & b=0 & firmid~='cbp' & firmid~='ssn' & firmid~='letters' & firmid~='mu dashes' & firmid~='missing' then firmid='no match';
  if a=1 then output imports_&y._alt;
  if a=1 and b=0 then output imports_nomatch_a; 
run;


*Prepare data for export to STATA;
data imports&y;
    set imports_&y._alt(keep=firmid ivalue rp_ivalue country hs);
   * where substr(hs,1,2)~='27';  *Eliminate fuels;
run;

*Aggregate to firm-hs-country level;
proc sort data=imports&y;
    by firmid country hs;
run;

proc means sum noprint data=imports&y;
    by firmid country hs;
    var ivalue rp_ivalue;
    output out=imports&y sum()=;
run;

**Export dataset to STATA;
 proc export data=imports&y(keep=firmid ivalue rp_ivalue country hs)
    outfile="&margins/imports&y..dta"
    dbms=dta replace;
    run; 
  
%mend;


%fetch_imports(1997);
%fetch_imports(2002);
%fetch_imports(2007);	

