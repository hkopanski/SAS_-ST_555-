/* 
Author: Halid Kopanski
Date: 08JAN2020
Purpose: SAS Example Script
Program Name: SAS_example
*/

x "cd L:\";
libname OurData "ST555\Data";
libname ST445 "ST445\Data";

x "cd S:\Documents\TEACHING\NCSU\NCSU COURSES\ST 555 v3.0";
libname Demo '.';

*Set options;

options ps=150 ls95 number pageno=1 nodate;

data demo.fun(drop = lt);
  set OurData.fish(keep = name lt--dam hg);
  
  select(lt);
    when(1) type = 'Eutrophic';
	when(2,3) type = 'Other';
	otherwise put 'Error';
  end;
  
  if hg gt 0.75 then HgFlag='Y';
    else HgFlag = 'N';
run;

*Request quantiles;
proc means data = data.fun min p10 p25 p50 p75 p90 max;
  class dam type / missing;
  var hg;
run;

*Hg graph based on derived variables;
proc sgplot data = demo.fun;
  hbar type / group = HgFlag stat = percent;
run;

quit;
