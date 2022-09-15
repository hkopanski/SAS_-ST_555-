x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\SAS_Data";

libname ppc08 ".";
filename ppc08 ".";

data ppc08.furniture_sales;
  infile ppc08("FurnitureV1.txt") dlm = "2E"x firstobs = 2;
  input Actual & comma. Predicted & comma. Country & $10. Region : $8. ProdType : $9. Date : yymmdd10.;
run;

proc compare base = ppc08.furnituresales compare = ppc08.furniture_sales;
run;

proc compare base = sashelp.prdsale compare = ppc08.furniture_sales;
run;

quit;
