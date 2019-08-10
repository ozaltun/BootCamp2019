****This program builds a firmid export database for 2007 using the same EIN-FIRMID bridge used to identify imports;

libname margins " "; /* PROJECT DATA FOLDER */
%let margins= ; /* PROJECT DATA FOLDER */

options obs=max;

**Bring in bridge file;
  data ein_clean;
    set margins.bridge2007;
  run;

************* Bring in Export Data ***********************;

%macro dome(year,month);

data e&year.&month(keep=ein evalue etrans retrans hs country qty: orig_ein monyear obs_num);
  set exp.exp&year.&month(keep=ein value hs country qty:  related rename=(ein=temp));
  length ein $9;
 
  if value<=0 then delete;
    
  evalue=value;
  exporter=left(temp);
  exporter=left(exporter);

  orig_ein=temp ;

  *Make variables to match to lfftd;
  monyear="&month&year";
  obs_num=_N_;
  
  
  *Make reitrans variable;
  etrans=1;
  if related='Y' then retrans=1;
  if related='N' then retrans=0;

  *Clean up the ein field;
  if substr(exporter,3,1) = '-' then ein=substr(exporter,1,2)||substr(exporter,4,7);
  if substr(exporter,3,1) ^= '-' then ein=substr(exporter,1,9);
  dashflg=index(ein,'-');
  if dashflg>0 then ein='mu dashes';
  if substr(ein,1,1) in ('A','B','C','D','E','F','G','H','I','J',
       'K','L','M','N','O','P','Q','R','S','T',
       'U','V','W','X','W','X','Y','Z')
     then ein='letters';
     if ein=' ' then ein='missing';
run;

%mend dome;

%dome(2007,01);
%dome(2007,02);
%dome(2007,03);
%dome(2007,04);
%dome(2007,05);
%dome(2007,06);
%dome(2007,07);
%dome(2007,08);
%dome(2007,09);
%dome(2007,10);
%dome(2007,11);
%dome(2007,12);

data exports;
  set e200701 e200702 e200703 e200704 e200705 e200706
       e200707 e200708 e200709 e200710 e200711 e200712;
  year=2007;
 run;



**Add firmid from the LFTTD where available;
proc sort data=lfttd.exp_comb2007 out=lfttd;
    by monyear obs_num;
run;

data lfttd(keep=monyear obs_num firmid_lfttd);
    length firmid_lfttd $10 cfn $10 temp1 $9 ;
    set lfttd;
    
    if substr(alpha,7,1)="" then firmid_lfttd=left(trim(alpha))||'0000';
    if substr(alpha,7,1)~="" then cfn=left(trim(alpha));
    
   *Try to make a proper firmid variable for the single-units;
    if firmid_lfttd~="" then firmid_lfttd_source="alpha";
    if firmid_lfttd="" then do;
       temp1=substr(ein2,1,9);
       firmid_lfttd="0"||left(trim(temp1));
       firmid_lfttd_source="ein2";
       end;
   if alpha~="";
   if left(trim(firmid_lfttd))='0' then firmid_lfttd='';
   if substr(firmid_lfttd,9,1)='' then firmid_lfttd='';
run;

proc sort data=exports;
    by monyear obs_num;
run;

data exports_lft_firm no_lfttd no_exp;
    merge lfttd(in=a) exports(in=b);
    by monyear obs_num;
    if b=1 then output exports_lft_firm;
    if a=1 & b=0 then output no_exp;
    if a=0 & b=1 then output no_lfttd; /* Note: this is fine since only matching to lfttd with firmids */
run;


**Add firmid from the TF Concordance;
proc sort data=exports_lft_firm;
    by ein;
run;
proc sort data=ein_clean; by ein; run;

data exports_matched;
    merge exports_lft_firm(in=a) ein_clean(in=b);
    by ein;
   if a=1 & b=1 then firmid_source=source_concord; 
    if a=1 & b=1 then firmid_source=source_concord;
    if a=1;
run;

data exports_matched2 exports_unmatched;
    set exports_matched;
    if firmid='' &  firmid_lfttd~=' ' then do;
	firmid=firmid_lfttd;
	firmid_source='LFTTD';
	end;
    if firmid~='' & firmid_lfttd~='' then do;
	if firmid=firmid_lfttd then firmid_match='yes';
	if firmid~=firmid_lfttd then firmid_match='no';
	end;
    if firmid~='' & firmid_lfttd='' then firmid_match='TF';
    if firmid~='' then output exports_matched2;
    else output exports_unmatched;
run;

proc freq data=exports_matched2;
    tables firmid_source firmid_match;
run;
*************************************;



**Sum export values and transactions over firmid  HS country;     
*************************************;
proc sort data=exports_matched2; by firmid hs country ; run;

proc means sum noprint data=exports_matched2;
   by firmid hs country ;  
   var evalue etrans ;  
output out=margins.exports_2007(drop=_TYPE_ _FREQ_) sum=;
run;

*Export dataset to STATA;
 proc export data=margins.exports_2007(keep=firmid country hs evalue)
    outfile="&margins/exports_tf_match.dta"
    dbms=dta replace;
    run; 
*************************************;

