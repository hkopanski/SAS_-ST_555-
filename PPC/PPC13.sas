/*
Programmed by: Jonathan W. Duggins
Programmed on: 2019-09-23
Programmed to: Create solution to PPC #13

Modified by: N/A
Modified on: N/A
Modified to: N/A
*/

*Set filerefs and librefs using only relative paths;
x "cd L:\st555\";
libname InputDS "Data";
libname Results "Results";
filename RawData "Data";

x "cd S:\SAS Working Directory";
libname PPC ".";

data Results.PPC13DugginsBlood(drop = bloodtype rbc);
  set inputds.blood(drop = sex agegroup where = (rbc ge 7));
  attrib Flag length = $ 4;
  if (chol ge 180 or chol lt 0) and bloodtype not in ('O') then flag = 'Yes';
    else flag = 'None';
  if flag eq 'Yes' or wbc ge 8000;
run;

quit;