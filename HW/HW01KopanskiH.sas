/*
@Author: Halid Kopanski
@Date:   21-Jan-2020
@Email:  hkopans@ncsu.edu
@Project: ST555
@Purpose: To create a summary report from the cars dataset.
@Last modified by:   Halid Kopanski
@Last modified time: 21-Jan-2020
*/

*Assigning options and inputing source data. Also defining output locations.;
options ps=100 ls=90 nodate FORMCHAR="|----|+|---+=|-/\<>*";

x "cd C:\Users\halid\Documents\SAS\Data\";
libname inputds ".";

x "cd C:\Users\halid\Documents\SAS\Data\HW1\";
libname HW1 ".";

*Turning off all outputs;
ods _all_ close;

*Creating new format for use throughout code;
proc format fmtlib;
  value bckt(fuzz=0) 0 - 15 = 'Tier 1'
                     15  <- 20 = 'Tier 2'
                     20  <- 30 = 'Tier 3'
                     30  <- high = 'Tier 4';
run;

ods select attributes;
ods noproctitle;

*Creating pdf to print program output;
ods pdf file = 'HW1 Kopanski Cars Report.pdf' style = meadow;

*Creating summary of raw data;
title 'Descriptor Information Before Sorting';

proc contents data = inputds.cars varnum;
  ods select position;
run;

title;

*Creating newly sorted data set from raw data;
proc sort data = inputds.cars 
           out = HW1.cars_srtd;
  by type DESCENDING Origin Make;
run;

ods select attributes sortedby;

title 'Descriptor Information After Sorting';

*Creating a summary of the new dataset;
proc contents data = HW1.cars_srtd varnum;
  ods select position;
run;

title;

title 'Listing of Prices';
title2 h=8pt 'Including Type and Type by Origin Totals';

*Tabulating and printing sorted data by type with Origin and Make in descending order.;
proc print data = HW1.cars_srtd noobs label;
  by Type descending Origin Make;
  id Type Origin Make;
  sum MSRP Invoice;
  sumby Type;
  pageby Origin;
  var Model MSRP Invoice DriveTrain EngineSize Cylinders Horsepower MPG_City MPG_Highway Weight wheelbase length;
  attrib Type   label = 'Use Classification'  /* relabeling variables to be more descriptive*/
         Origin label = 'Region of Origin'
         Make   label = 'Car Make'
         Model  label = 'Car Model'
         MSRP        label = "Manufacturer's Suggested Retail Price"
         Invoice     label = "Invoice Price"
         DriveTrain  label = "Drive Train"
         EngineSize  label = "Engine Size (in)"
         Cylinders   label = "# Of Cylinders"
         Horsepower  label = "Horsepower (lb-ft)"
         MPG_City    label = "City Mileage (mpg)"
         MPG_Highway label = "Highway Mileage (mpg)"
         Weight      label = "Weight (lb)"
         Wheelbase   label = "Wheelbase (in)";
  label Length = 'Length (in)';
  format MSRP dollar12. Invoice dollar12.; /* formatting the dollar amounts to ensure all characters (commas included) are printed in the table*/
run;
/* Adding a title*/ 
title 'Selected Numerical Summaries of Car Prices and Measurements';
title2 h=8pt 'by Type, Origin, and City MPG Classification';
footnote j=left 'Excluding Acura and Land Rover';
footnote2 j=left 'Tier 1=Up to 15mpg, Tier 2=Up to 20, Tier 3=Up to 30, Tier 4=Over 30';

*Overview of data categorized by MPG_city.;
proc means data = HW1.cars_srtd nonobs n min q1 median q3 max maxdec = 1; 
  where Make not in ('Acura' 'Land Rover');
  class type origin MPG_City;
  var MSRP Invoice EngineSize Cylinders Horsepower Weight Wheelbase Length;
  label length = 'Length (in)';
  attrib MPG_City    label = "City Mileage (mpg)"
         MSRP        label = "Manufacturer's Suggested Retail Price"
         Invoice     label = "Invoice Price"
         EngineSize  label = "Engine Size (in)"
         Cylinders   label = "# Of Cylinders"
         Horsepower  label = "Horsepower (lb-ft)"
         Weight      label = "Weight (lb)"
         wheelbase   label = "Wheelbase (in)";
  
  format MPG_City bckt.;
run;
title;

*Creating 3 frequncy summary tables of sorted data. This table excludes Acura and Landrover.;
title 'Frequency Breakdown of Types, Types by Origin';
title2 'and Type by City Mileage Classification';

proc freq data = HW1.cars_srtd;
  where Make NOT in ('Land Rover' 'Acura');
  tables type;
  tables type*origin;
  tables type*MPG_City / nocol;
  format MPG_City bckt.;
  attrib Type   label = 'Use Classification'
         MPG_City label = 'City Mileage (mpg)'
         Origin label = 'Region of Origin';
run;
title;
footnote;

*Close pdf file;
ods pdf close;
