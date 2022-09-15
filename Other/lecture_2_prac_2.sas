x "cd C:\users\halid\Documents\SAS\";

ods listing;
ods trace on;
ods pdf file="L2_PPC_2.pdf" style = Journal2;


title 'Cars Column Metadata';
title2 'Columns are displayed in creation order';
proc contents data = sashelp.cars varnum;
  ods select Position;
run;

title '20 Rows from Data Set';
proc print data  = sashelp.cars(obs = 20) label;
  var:;
run;

title;
ods pdf close;
