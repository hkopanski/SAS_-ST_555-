/* Author = Halid Kopanski   */
/* Class  = ST555            */
/* Project= HW2              */
/* Purpose = To complete HW2 */
/* Date Created = 26JAN2020  */
/* Date Modified = 27JAN2020 */

x "cd C:\Users\halid\Documents\SAS\Data\HW2"; /* This is the location of the raw data.*/
filename rawdata ".";

x "cd C:\Users\halid\Documents\SAS\Data\HW2\Results"; /*All reports and new datasets are saved here*/
libname inputds ".";

/* The data step imports the baseball dataset and uses comma (2C) and tabs (09) as delimiters for LName FName and Team variables*/
/* all numeric data variables are captured through column designation in the data file.*/
/* Variables are assigned new labels in this step.*/

data inputds.bb_data_3;
  infile rawdata('Baseball.dat') dlm = '2C09'x firstobs = 13;
  length LName $ 9 FName $ 11 Team $ 13;
  input LName $ FName $ Team $ nAtBat 50-54 nHits 55-58 nHome 59-61 nRuns 62-66 nRBI 67-70 
        nBB 71-74 YrMajor 75-77 CrAtBat 78-82 CrHits 83-87 CrHome 88-91 CrRuns 92-95 CrRbi 96-98 
        CrBB 99-102 League $ 103-111 Division $ 112-115 Position $ 117-118 nOuts 132-136 
        nAssts 137-140 nError 141-144 Salary 145-152;
  format Salary dollar10.3;
  attrib FName    label = "First Name"
         LName    label = "Last Name"
         Team     label = "Team at the end of 1986" 
         nAtBat   label = "# of At Bats in 1986"
         nHits    label = "# of Hits in 1986"
         nHome    label = "# of Home Runs in 1986" 
         nRuns    label = "# of Runs in 1986"
         nRBI     label = "# of RBIs in 1986"
         nBB      label = "# of Walks in 1986"
         YrMajor  label = "# of Years in the Major Leagues"
         CrAtBat  label = "# of At Bats in Career"
         CrHits   label = "# of Hits in Career"
         CrHome   label = "# of Home Runs in Career"
         CrRuns   label = "# of Runs in Career"
         CrRbi    label = "# of RBIs in Career"
         CrBB     label = "# of Walks in Career"
         League   label = "League at the end of 1986"
         Division label = "Division at the end of 1986"
         Position label = "Position(s) Played"
         nOuts    label = "# of Put Outs in 1986"
         nAssts   label = "# of Assists in 1986"
         nError   label = "# of Errors in 1986"
         Salary   label = "Salary (Thousands of Dollars)";
run;

options FMTSEARCH = (Inputds) nodate;

/* Two reports are to be generated in rtf and pdf formats. No other output is generated.*/

ods _all_ close;
ods rtf file = 'HW02 Kopanski Baseball Report.rtf' style = Sapphire;
ods pdf file = 'HW02 Kopanski Baseball Report.pdf' style = Journal;

/* Exclude some elements from the pdf report.*/

ods pdf exclude all;

/* Print out of variable table.Provides variable name, length, format, and label.*/

title "Variable-Level Metadata (Descriptor) Information";
proc contents data = inputds.bb_data_3 varnum;
  ods select position;
  ods noproctitle;
run;
title;

/* Create a format used specifically for the salary information found in the raw data.*/

title "Salary Format Details";
proc format fmtlib;
  value salary (fuzz = 0)   .           = 'Missing'
                           0            = 'None'
                           0   <- 190   = 'First Quartile'
                           190 <- 425   = 'Second Quartile'
                           425 <- 750   = 'Third Quartile'
                           750 <- 2460  = 'Fourth Quartile'
                           other        = 'Unclassified';
run;

title;

/*Create a new sorted data set from the imported data. This set is sorted by ascending League Division and Team. Salary*/
/* is sorted by descending order.*/ 

proc sort data = inputds.bb_data_3
          out  = inputds.bb_data_s3;
          by League Division Team descending Salary;
run;

/*Allow the following elements to be included in the pdf version of the report.*/
ods pdf exclude none;

title "Five Number Summaries of Selected Batting Statistics";
title2 h = 10pt "Grouped by League (1986), Division (1986), and Salary Category (1987)";

/* Prints out table of basic dataset statistics. */

proc means data = inputds.bb_data_s3 min p25 p50 p75 max nolabels missing maxdec = 2;
  class League Division Salary;
  var nHits nHome nRuns nRBI nBB;
  format Salary salary.;
run;

title;

/* Prints out frequency tables based on position and position vs salary.*/

title "Breakdown of Players by Position and Position by Salary";

proc freq data = inputds.bb_data_s3;
  table Position;
  table Position*Salary / missing;
  format Salary salary.;
run;

footnote h=8pt j=left 'Included: Players with Salaries of at least $1,000,000 or who played for the Chicago Cubs';

title 'Listing of Selected 1986 Players';

/* Prints out information summary on all players whom earned at least $1,000,000 or were on the Chicago Cubs Team.*/

proc print data = inputds.bb_data_s3 label noobs;
  id LName FName Position;
  var League Division Team Salary nHits nHome nRuns nRBI nBB;
  format Salary DOLLAR13.3 nHits COMMA6.0 nHome COMMA6.0 nRuns COMMA6.0 nRBI COMMA6.0 nBB COMMA6.0;
  where Salary >= 1000 or Team in ('Chicago') and Division in ('East');
  sum Salary nHits nHome nRuns nRBI nBB;
run;

title;
footnote;
ods rtf close;
ods pdf close;
