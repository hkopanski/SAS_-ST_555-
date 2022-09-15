x "cd C:\users\halid\Documents\SAS\";

libname code_hk "Code\";
libname data_hk "Data\";

*ods _All_ CLOSE;
ods listing;
ods trace on;
ods pdf file="L2_prac_output.pdf" style = Journal2;

proc sgplot data=sashelp.cars;
  styleattrs datasymbols=(square circle triangle);
  scatter y = mpg_city x = horsepower/group = type;
  where type in ("Sedan", "Wagon", "Sports");
run;

proc corr data = sashelp.cars;
  var mpg_city;
  with mpg_highway;
  ods select pearsoncorr;
run;
ods pdf close;
