
****This program grabs list of firmids that export from margins.exports_2007;
****Using this unique firmid list, it merges to the margins.ec_salesexp2007 dataset to identify
more firms that are exporters;
**** All this is because the EC data can only match x% of total exports while matching >y% of total sales.;
**** Finally, using the combined sources, it computes the value sales of exporters / total sales of all firms;

options obs=max;

libname margins " "; /* PROJECT DATA FOLDER */
%let margins= ; /* PROJECT DATA FOLDER */

libname beta " " ;  /* LBD FOLDER */
%let libs=asm aux ccn cfi cmf cmi crt csr cut cwh lbd lfttd ssl imp exp ; 
%macro libs;
  %let k=1;
  %do %while (1);
      %let lib=%scan(&libs,&k);
      %if &lib eq %then %goto exit;
      libname &lib ""; /* RELEVANT ECONOMIC DATA FOLDER */
      %let k=%eval(&k+1);
  %end;
 %exit: %mend;
%libs;

******************GRAB FIRMID LIST OF EXPORTERS, MANUFACTUERS from LFTTD AND EC********************;
data firmlist;
	set margins.exports_2007;
run;
proc sort data=firmlist nodupkey;
	by firmid;
run;

data ec_firmlist(keep=firmid);
	set margins.ec_salesexp2007;
	if exp>0;
run;
proc sort data=ec_firmlist nodupkey;
	by firmid;
run;

data manuf_firmlist(keep=firmid);
	set margins.ec_salesexp2007;
	if source='cmf';
run;
proc sort data=manuf_firmlist nodupkey;
	by firmid;
run;

******************ATTACH IDENTIFIERS TO PLANT-LEVEL DATASET ********************;


proc sort data = margins.ec_salesexp2007;
	by firmid;
run;

data margins.ec_lfttd_salesexp2007;
	merge margins.ec_salesexp2007(in=a) firmlist(in=b) ec_firmlist(in=c) manuf_firmlist(in=d);
	by firmid;
	if b=1 then lfttd_exporter=1;
	if c=1 then ec_exporter=1;
	if d=1 then is_manuf=1;
	if lfttd_exporter="" then lfttd_exporter=0;
	if ec_exporter="" then ec_exporter=0;
	if is_manuf="" then is_manuf=0;
	is_exporter = max(lfttd_exporter,ec_exporter);
	if a=1;
run;

  ****OUTPUT PERMANENT DATASET WITH CENSUS AND LBD INFORMATION*****;
    proc export data=margins.ec_lfttd_salesexp2007
    outfile="&margins/ec_lfttd_salesexp2007.dta"
    dbms=dta replace;
    run; 

/*

********** Make export and sales totals conditional on the firm exporting;
proc sort data=margins.ec_lfttd_salesexp2007;
	by is_exporter;
	run;

* (A) find 2 moments, one overall, and one over manuf sales;
proc means sum noprint data=margins.ec_lfttd_salesexp2007;
	by is_exporter;
	var sales sales_manuf;
	output out=firms2007(keep=sales sales_manuf is_exporter) sum(sales sales_manuf)=;
	run;

proc means sum data=firms2007;
	by is_exporter;
	var sales sales_manuf;
	title 'Total Sales and Exports of All Exporting Firms';
	run;

* (B) find 3rd moment which is total sales of exporting manufacturers / total sales of all manufacturers;
* note total sales include non manuf sales;
data manuf_only;
	set margins.ec_lfttd_salesexp2007;
	if is_manuf=1;
run;
proc sort data=manuf_only;
	by is_exporter;
	run;
proc means sum noprint data=manuf_only;
	by is_exporter;
	var sales sales_manuf;
	output out=firms2007(keep=sales sales_manuf is_exporter) sum(sales sales_manuf)=;
	run;

proc means sum data=firms2007;
	by is_exporter;
	var sales sales_manuf;
	title 'Total Sales and Exports of All Exporting Firms w/ Manuf content';
	run;

*/