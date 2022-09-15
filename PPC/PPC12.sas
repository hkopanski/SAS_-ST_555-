x "cd L:\st555\Data";
libname inputds ".";

x "cd S:\Documents\hk_user";
libname outputds ".";
filename outputds ".";

proc sort data = inputds.comini out = outputds.comini_sort;
  by Region descending Jobtotal;
run;

proc sort data = inputds.o3mini out = outputds.o3mini_sort;
  by Region descending Jobtotal;
run;

data outputds.o3comini;
  set outputds.comini_sort outputds.o3mini_sort;
  by Region descending Jobtotal;
run;

proc report data = outputds.o3comini;
  attrib JobTotal format = dollar9.
         Date     format = date9.;
  columns Region Jobtotal Pol_Type Pol_Code Date;
run; 