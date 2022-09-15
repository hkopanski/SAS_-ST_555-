/* Author = Halid Kopanski   */
/* Class  = ST555            */
/* Project= HW04             */
/* Purpose = To complete HW4 */
/* Date Created = 19FEB2020  */
/* Date Modified = 22FEB2020 */
/* Modification added output datasets for all compare procs */

/*Location of raw data and validation datasets*/
x 'cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW4';

libname inputds ".";
filename RawData ".";

/*Location of generated datasets. Also, reports and graphs are output to this location */
x 'cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW4_J';

libname HW4 ".";
filename HW4 ".";

/* Options information and format search pointer */
options nodate FMTSEARCH = (HW4);
ods _all_ close;

/* Input of raw data. This section also cleans and reclassifies variables, as well as assigns formats */
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

/*Sorts newly created dataset in preparation for data validation. */
proc sort data = hw4.hw4kopanskilead_raw out = HW4.hw4kopanskilead;
  by Region StName DESCENDING Jobtotal;
run;

/* Data validation step, to see results comments out close statement on line 23. */
proc compare base = inputds.hw4dugginslead compare = HW4.HW4kopanskilead
  out = hw4.ds_comp outbase outcompare outdif outnoequal
  method = absolute criterion = 1E-15; 
run;

/* Creation of descriptor dataset used to validate against known dataset. */
proc contents data = HW4.HW4kopanskilead varnum;
  ods output position = hw4.hw4kopanskidesc (drop = member); 
run;

/* Descriptor dataset validation */
proc compare base = inputds.hw4dugginsdesc compare = hw4.hw4kopanskidesc
  out = hw4.desc_comp outbase outcompare outdif outnoequal
  method = absolute criterion = 1E-15;
run;

/*Creation of datetime format */
proc format library = HW4;
  value myqtr
    '01JAN1998'd - '31MAR1998'd = 'Jan/Feb/Mar'
    '01APR1998'd - '30JUN1998'd = 'Apr/May/Jun'
    '01JUL1998'd - '30SEP1998'd = 'Jul/Aug/Sep'
    '01OCT1998'd - '31DEC1998'd = 'Oct/Nov/Dec';
run;

/* Opening of pdf report */
ods pdf file = 'HW4 Kopanski Lead Report.pdf';
ods noproctitle;

/*Statistical analysis of dataset (means) */
title '90th Percentile of Total Job Cost By Region and Quarter';
title2 'Data for 1998';

proc means data = HW4.HW4KOPANSKILEAD p90;
  class Region Date;
  var JobTotal;
  format Date myqtr.;
  ods output summary = HW4.leadmean;
run; 

title;
title2;

/* Visualisation of means statistical data in the form of a horizontal bar graph */
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
 format Date myqtr.;
run;

/*Statistical analysis of dataset (frequency) */
title 'Frequency of Cleanup by Region and Date';
title2 'Data for 1998';

ods listing close;

proc freq data = HW4.HW4KOPANSKILEAD;
  table Region*Date / nocol nopercent;
  format Date myqtr.;
  ods output CrossTabFreqs = HW4.leadfreq (drop = _TYPE_ Table _TABLE_ Frequency);
run;

title;
title2;

/* Visualisation of frequency statistical data in the form of a vertical bar graph. Additional dataset created in this procedure. */
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
  format Date myqtr.;
  ods output SGPlot = HW4.HW4KopanskiGraph2;
run;

ods listing close;
ods pdf close;

/* Dataset generated from graphic validation */
proc compare base = inputds.hw4dugginsgraph2 compare = HW4.HW4KopanskiGraph2
  out = hw4.ds_comp outbase outcompare outdif outnoequal
  method = absolute criterion = 1E-15;
run;

 /* End of program*/
quit;
