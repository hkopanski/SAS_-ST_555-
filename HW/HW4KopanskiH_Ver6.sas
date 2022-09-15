x 'cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW4';

libname inputds ".";
filename RawData ".";

x 'cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW4_J';

libname HW4 ".";
filename HW4 ".";

options nodate FMTSEARCH = (HW4);
ods _all_ close;

data HW4.HW4kopanskilead_raw (DROP = _:);
  infile RawData('LeadProjects.txt') dlm = '2C'x DSD firstobs = 2 TRUNCOVER;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          PolType     length = $4                           label = 'Pollutant Name'
          PolCode     length = $8                           label = 'Pollutant Code'
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.
          JobTotal                      format = dollar11.;
  input StName : $ _JobID : $ _DatReg : $char25. _CodType : $ Equipment : dollar11. Personnel : dollar11.;
  StName = upcase(StName);
  _JobID = tranwrd(tranwrd(_JobID,'O','0'), 'l','1');
  JobID = abs(input(_JobID, 8.));
  Date = compress(_DatReg,,'KD');
  Region = propcase(compress(_DatReg,,'d'));
  PolCode = compress(_CodType,,'KD');
  PolType = compress(_CodType,,'d');
  JobTotal = Equipment + Personnel;
run;

proc sort data = hw4.hw4kopanskilead_raw out = HW4.hw4kopanskilead;
  by Region StName DESCENDING Jobtotal;
run;

proc compare base = inputds.hw4dugginslead compare = HW4.HW4kopanskilead
  method = absolute criterion = 1E-15; 
run;

proc contents data = HW4.HW4kopanskilead varnum;
  ods output position = hw4.hw4kopanskidesc (drop = member); 
run;

proc compare base = inputds.hw4dugginsdesc compare = hw4.hw4kopanskidesc
  method = absolute;
run;

proc format library = HW4;
  value quarter
    '01JAN1998'd - '31MAR1998'd = 'Jan/Feb/Mar'
    '01APR1998'd - '30JUN1998'd = 'Apr/May/Jun'
    '01JUL1998'd - '30SEP1998'd = 'Jul/Aug/Sep'
    '01OCT1998'd - '31DEC1998'd = 'Oct/Nov/Dec';
run;

ods pdf file = 'HW4 Kopanski Lead Report.pdf';
ods noproctitle;

title '90th Percentile of Total Job Cost By Region and Quarter';
title2 'Data for 1998';

proc means data = HW4.HW4KOPANSKILEAD p90;
  class Region Date;
  var JobTotal;
  format Date quarter.;
  ods output summary = HW4.leadmean;
run; 

title;
title2;

ods listing;
ods graphics on / imagename= 'HW4Graph1';

proc sgplot data = HW4.leadmean;
  hbar region / group = Date
                groupdisplay = cluster
                response = JobTotal_P90
                datalabel = NObs datalabelattrs=(size=7pt);
 keylegend / position = top;
 xaxis label = '90th Percentile of Total Job Cost'
       grid gridattrs = (color = gray10)
       valuesformat = dollar11.
       offsetmax = 0.05;
 format Date quarter.;
run;

title 'Frequency of Cleanup by Region and Date';
title2 'Data for 1998';

ods listing close;

proc freq data = HW4.HW4KOPANSKILEAD;
  table Region*Date / nocol nopercent;
  format Date quarter.;
  ods output CrossTabFreqs = HW4.leadfreq (drop = _TYPE_ Table _TABLE_ Frequency);
run;

title;
title2;

ods listing;
ods graphics on / imagename= 'HW4Graph2';

proc sgplot data = HW4.leadfreq;
  vbar Region / response = RowPercent
                group = Date
                groupdisplay = cluster;
  keylegend / position = topright
              across = 2
              location = inside
              opaque;
  xaxis labelattrs = (size = 16)
        valueattrs = (size = 14);
  yaxis grid gridattrs = (color = gray25 thickness = 3)
        values = (0 to 45 by 5)
        offsetmax = 0.04
        label = 'Region Percentage within Pollutant'
        labelattrs = (size = 16)
        valueattrs = (size = 12)
        valuesformat = comma6.1;
  format Date quarter.;
  ods output SGPlot = HW4.HW4KopanskiGraph2;
run;

ods listing close;
ods pdf close;

proc compare base = inputds.hw4dugginsgraph2 compare = HW4.HW4KopanskiGraph2
  method = absolute;
run;

quit;
