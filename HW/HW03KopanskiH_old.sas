/* Author = Halid Kopanski   */
/* Class  = ST555            */
/* Project= HW3              */
/* Purpose = To complete HW3 */
/* Date Created = 01FEB2020  */
/* Date Modified = 01FEB2020 */

options FMTSEARCH = (outputds)ps = 100 ls = 90 nodate;
ods noproctitle;
ods _all_ close;

x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW3\HW3_Data";
libname inputds "Base_Data";
filename raw_data "Raw_Data";

x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW3\HW3_Results";
libname outputds "Data_Library";
filename reports "Reports";

proc format library = outputds;
value sbp low - 129  = "Acceptable"
          130 - high = "High";
value dbp low - 79   = "Acceptable"
          80  - high = "High";
run;

data outputds.hw3kopanskisite1;
  attrib Subj          label = "Subject Number"
         sfReas        label = "Screen Failure Reason"               length = $ 50
         sfStatus      label = "Screen Failure Status (0 = Failed)"  length = $ 1
         BioSex        label = "Biological Sex"                      length = $ 1
         VisitDate     label = "Visit Date"                          length = $ 9
         failDate      label = "Failure Notification Date"           length = $ 9
         sbp           label = "Systolic Blood Pressure"
         dbp           label = "Diastolic Blood Pressure"
         bpUnits       label = "Units (BP)"                          length = $ 5
         pulse         label = "Pulse"
         pulseUnits    label = "Units (Pulse)"                       length = $ 9
         position      label = "Position"                            length = $ 9
         temp          label = "Temperature"                                         format = 5.1
         tempUnits     label = "Units (Temp)"                        length = $ 1
         weight        label = "Weight"
         weightUnits   label = "Units (Weight)"                      length = $ 2
         pain          label = "Pain Score";
  infile raw_data('Site 1, Baselilne Visit.txt') dlm = '09'x dsd;
  input  Subj sfReas $ sfStatus $ BioSex $ VisitDate $ failDate $ sbp dbp bpUnits $ pulse pulseUnits $ 
         position $ temp tempUnits $ weight weightUnits $ pain;
run;

data outputds.hw3kopanskisite2;
  attrib Subj          label = "Subject Number"
         sfReas        label = "Screen Failure Reason"               length = $ 50
         sfStatus      label = "Screen Failure Status (0 = Failed)"  length = $ 1
         BioSex        label = "Biological Sex"                      length = $ 1
         VisitDate     label = "Visit Date"                          length = $ 9
         failDate      label = "Failure Notification Date"           length = $ 9
         sbp           label = "Systolic Blood Pressure"
         dbp           label = "Diastolic Blood Pressure"
         bpUnits       label = "Units (BP)"                          length = $ 5
         pulse         label = "Pulse"
         pulseUnits    label = "Units (Pulse)"                       length = $ 9
         position      label = "Position"                            length = $ 9
         temp          label = "Temperature"                                         format = 3.1
         tempUnits     label = "Units (Temp)"                        length = $ 1
         weight        label = "Weight"
         weightUnits   label = "Units (Weight)"                      length = $ 2
         pain          label = "Pain Score";
  infile raw_data('Site 2, Baseline Visit.csv') dlm = '2C'x dsd;
  input  Subj sfReas $ sfStatus $ BioSex $ VisitDate $ failDate $ sbp dbp bpUnits $ pulse pulseUnits $ 
         position $ temp tempUnits $ weight weightUnits $ pain;
run;

data outputds.hw3kopanskisite3;
  attrib Subj          label = "Subject Number"
         sfReas        label = "Screen Failure Reason"               length = $ 50
         sfStatus      label = "Screen Failure Status (0 = Failed)"  length = $ 1
         BioSex        label = "Biological Sex"                      length = $ 1
         VisitDate     label = "Visit Date"                          length = $ 9
         failDate      label = "Failure Notification Date"           length = $ 9
         sbp           label = "Systolic Blood Pressure"
         dbp           label = "Diastolic Blood Pressure"
         bpUnits       label = "Units (BP)"                          length = $ 5
         pulse         label = "Pulse"
         pulseUnits    label = "Units (Pulse)"                       length = $ 9
         position      label = "Position"                            length = $ 9
         temp          label = "Temperature"                                         format = 3.1
         tempUnits     label = "Units (Temp)"                        length = $ 1
         weight        label = "Weight"
         weightUnits   label = "Units (Weight)"                      length = $ 2
         pain          label = "Pain Score";
  infile raw_data('Site 3, Baseline Visit.dat') dlm = "2E"x dsd;
  input  Subj 1-7 sfReas $ 8-58 sfStatus $ 59-61 BioSex $ 62 VisitDate $ 63-72 failDate $ 73-82 sbp 83-85 dbp 86-88 bpUnits $ 89-95 pulse 95-97 
         pulseUnits $ 98-107 position $ 108-120 temp 121-123 tempUnits $ 124 weight 125-127 weightUnits $ 128-131 pain 132;
  putlog "Pulse";
run;

proc sort data = outputds.hw3kopanskisite1
          out  = outputds.hw3kopanskisite1s;
          by DESCENDING sfStatus sfReas DESCENDING VisitDate DESCENDING failDate Subj;
run;

proc sort data = outputds.hw3kopanskisite2
          out  = outputds.hw3kopanskisite2s;
          by DESCENDING sfStatus sfReas DESCENDING VisitDate DESCENDING failDate Subj;
run;

proc sort data = outputds.hw3kopanskisite3
          out  = outputds.hw3kopanskisite3s;
          by DESCENDING sfStatus sfReas DESCENDING VisitDate DESCENDING failDate Subj;
run;

proc compare  base = inputds.hw3dugginssite1 compare = outputds.hw3kopanskisite1s;
run;

proc compare  base = inputds.hw3dugginssite2 compare = outputds.hw3kopanskisite2s;
run;

proc compare  base = inputds.hw3dugginssite3 compare = outputds.hw3kopanskisite3s;
run;

ods rtf file   = 'HW03 Kopanski.Clinical Report.rtf' style = sapphire;
ods pdf file   = 'HW03 Kopanski.Clinical Report.pdf';
ods powerpoint file  = 'HW03 Kopanski.Clinical Report.pptx' style = PowerPointDark;

ods powerpoint exclude all;

title "Variable-level Attributes and Sort Information: Site 1";
proc contents data = outputds.hw3kopanskisite1s varnum;
  ods select position;
  ods select sortedby;
run;

title "Variable-level Attributes and Sort Information: Site 2";
proc contents data = outputds.hw3kopanskisite2s varnum;
  ods select position;
  ods select sortedby;
run;

title "Variable-level Attributes and Sort Information: Site 3";
proc contents data = outputds.hw3kopanskisite3s varnum;
  ods select position;
  ods select sortedby;
run;

title;

ods powerpoint exclude none;

title "Selected Summary Statistics on Baseline Measurements";
title2 "for Patients from Site 1";
footnote h = 8pt j = left "Statistic and SAS keyword: Sample size (n), Mean (mean), Standard Deviation (stddev), Median (median), IQR (qrange)";

proc means data = outputds.hw3kopanskisite1s NONOBS N MEAN STD MEDIAN QRANGE MAXDEC = 1;
  class pain;
  var weight temp pulse dbp sbp;
run;

ods pdf columns = 2;

title "Frequency Analysis of Baseline Positions and Pain Measurements by Blood Pressure Status";
title2 "for Patients from Site 2";
footnote j = left "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";

proc freq data = outputds.hw3kopanskisite2s;
  table position;
  table pain * dbp * sbp / norow nocol;
  format dbp dbp. sbp sbp.;
run;

ods powerpoint exclude all;
ods pdf columns = 1;

title "Selected Listing of Patients with a Screen Failure and Hypertension";
title2 "for patients from Site 3";
footnote2 j = left "Only patients with a screen failure are included.";

proc print data = outputds.hw3kopanskisite3s label noobs;
  id Subj pain;
  var VisitDate sfStatus sfReas failDate BioSex sbp 
      dbp bpUnits weight weightUnits;
  where sfReas in ('High Blood Pressure', 'LOW BASELINE PAIN') and dbp >= 80;
run;

title;
title2;
footnote;
footnote2;
ods pdf close;
ods rtf close;
ods powerpoint close;

quit;
