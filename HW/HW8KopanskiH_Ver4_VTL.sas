/*
 Author = Halid Kopanski      
 Class  = ST555               
 Project= HW08                
 Purpose = To create blood work reports from recorded patient data.
 Date Created = 12APR2020     
 Date Modified = 13APR2020 v4
 v1: New file
 v2: Tested on VTL
 v3: Code overhaul,
     Removed second data step from Section 1 
     Renamed proc means output dataset and replaced OUT=  with ODS OUTPUT statement.
     Added data step to Section 4 to reshape dataset output from Section 3.
     Edited Section 5 to match changes from all other sections where applicable.
 v4: Tested on VTL.
*/

/*Location of raw and validation files*/
x 'cd L:\st555\Data';
filename RawData ".";
libname inputds ".";

x 'cd S:\Documents\hk_user\HW8_Results';
filename HW8 ".";
libname HW8 ".";

ods _all_ close;

/*Section 1: 
Read in, clean, and sort collected blood work data from raw file. This the Main Dataset*/
data HW8.blood_raw;
  infile Rawdata('blood.txt') dlm = '0920'x TRUNCOVER firstobs = 2;
  format Review $7.;
  input Subject BloodGroup : $2. AgeGroup : $5.  WBC RBC Chol;
  BloodGroup = upcase(BloodGroup);
  if (missing(WBC) or missing(RBC) or missing(Chol)) then Review = 'M';
      else if RBC > 6.1 
           or RBC < 4.0 
           or Chol < 0 
           or WBC > 11000
           or WBC < 4000 then Review = 'Y';
        else Review = 'Missing';
run;
/* End of Section 1 */

/* Section 2: 
Create first report from main dataset */
options;

footnote 'Header (n=5) of bloodwork data set.';
footnote2 'Only using records in need of a review.';

ods rtf file = 'HW8 Kopanski Report 1.rtf';

proc report data = HW8.blood_raw(obs = 5) nowd
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=11pt
                   backgroundcolor = cxC0C0C0
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=10pt];
  columns Subject WBC RBC Chol Review;
  define subject / display 'Subject Number';
  define WBC / display 'White Blood Cells' format = comma8.;
  define RBC / display 'Red Blood Cells' format = comma3.1;
  define Chol / display 'Cholesterol Level';
  define Review / 'Review Code';
run;

ods rtf close;
/* End of Section 2 */

/* Section 3: 
Create second report using dataset generated from proc means ods output.*/
proc means data =  HW8.blood_raw nonobs mean median min max;
  class BloodGroup;
  var WBC Chol;
  ods output summary = HW8.blood_R2out;
run;

ods rtf file = 'HW8 Kopanski Report 2.rtf';

title 'WBC and Cholesterol Summarized by Blood Group';
title2 '(Ignoring Rhesus Factor)';
footnote;
footnote2;

proc report data = HW8.blood_R2out
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=11pt
                   backgroundcolor = cxC0C0C0
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=10pt];
  columns BloodGroup WBC_Mean -- WBC_Max Chol_Mean -- Chol_Max;
  define BloodGroup / group order = internal 'Blood Group (Ignoring Rhesus Factor)';
  define WBC_Mean / analysis mean 'Mean White Blood Cell Count' format = 8.2;
  define WBC_Median / analysis median 'Median White Blood Cell Count' format = 8.1;
  define WBC_Min / analysis min 'Minimum White Blood Cell Count';
  define WBC_Max / analysis max 'Maximum White Blood Cell Count';
  define Chol_Mean / analysis mean 'Mean Cholesterol Level' format = 8.2;
  define Chol_Median / analysis median 'Median Cholesterol Level' format = 8.1;
  define Chol_Min / analysis min 'Minimum Cholesterol Cell Count';
  define Chol_Max / analysis max 'Maximum Cholesterol Cell Count';
run;

ods rtf close;
/* End of Section 3 */

/* Section 4: 
Create Reshape dataset from Report2 dataset and generate Report 3. */

options nodate;

data HW8.blood_reshape;
  format TCode $4.;
  set HW8.blood_R2out;
   array _Blood[2,4] WBC_Mean -- WBC_Max Chol_Mean -- Chol_Max;
   array B_Stat[4];
   do j = 1 to dim(_Blood);
     do i = 1 to dim(_Blood,2);
       B_Stat[i] = _Blood[j,i];
       if j = 1 then TCode = 'WBC';
         else if j = 2 then TCode = 'CHOL';
     end;
   output;
   end;
  drop i j _BREAK_ WBC_Mean -- Chol_Max;
  rename B_Stat1 = Mean B_Stat2 = Median B_Stat3 = Minimum B_Stat4 = Maximum;
run;

title 'WBC and Cholesterol Summarized by Blood Group';
title2;
footnote 'Note: Rhesus factor was not considered';
footnote2;

ods rtf file = 'HW8 Kopanski Report 3.rtf';

proc report data = HW8.blood_reshape
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=11pt
                   backgroundcolor = cxC0C0C0
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=10pt];
  columns BloodGroup TCode Mean -- Maximum;
  define BloodGroup / group 'Blood Group (Ignoring Rhesus Factor)';
  define TCode / group descending 'Test Code';
  define Mean / analysis mean 'Mean' format = 8.2;
  define Median / analysis median 'Median' format = 8.1;
  define Minimum / analysis min 'Minimum' format = 8.1;
  define Maximum / analysis max 'Maximum' format = 8.1;
run;

ods rtf close;
/* End of Section 4 */

/* Section 5: 
Create fourth report from main, report2, and reshaped datasets. Fourth report lists all records that require review.
This includes both subjects with out of spec results and incomplete records. */

title 'Selected Summaries of WBC and Cholesterol';
title2;
footnote;
footnote2;

ods pdf file = 'HW8 Kopanski Report 4.pdf' columns = 4;

proc report data = HW8.blood_raw nowd
  style(header) = [fontsize=8pt
                   backgroundcolor = cxFFFFFF
                   color = cx000000]
  style(summary) = [backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontsize=8pt];
  columns Subject WBC Chol;
  where Review in ('Y' 'M');
  define subject / display 'Subject Number';
  define WBC / display 'White Blood Cells' format = comma8.;
  define Chol / display 'Cholesterol Level';
run;

options pageno = 1;
ods pdf columns = 1;

proc report data = HW8.blood_raw
  style(header) = [fontsize=8pt
                   backgroundcolor = cxFFFFFF
                   color = cx000000]
  style(summary) = [backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontsize=8pt];
  columns 
    BloodGroup 
    WBC  = WBC_Mean  WBC  = WBC_Median  WBC  = WBC_Min  WBC  = WBC_Max  
    Chol = Chol_Mean Chol = Chol_Median Chol = Chol_Min Chol = Chol_Max;
  define BloodGroup / group order = internal 'Blood Group (Ignoring Rhesus Factor)';
  define WBC_Mean / analysis mean 'Mean White Blood Cell Count' format = 8.2;
  define WBC_Median / analysis median 'Median White Blood Cell Count' format = 8.1;
  define WBC_Min / analysis min 'Minimum White Blood Cell Count';
  define WBC_Max / analysis max 'Maximum White Blood Cell Count';
  define Chol_Mean / analysis mean 'Mean Cholesterol Level' format = 8.2;
  define Chol_Median / analysis median 'Median Cholesterol Level' format = 8.1;
  define Chol_Min / analysis min 'Minimum Cholesterol Cell Count';
  define Chol_Max / analysis max 'Maximum Cholesterol Cell Count';
run;

options pageno = 1;

proc report data = HW8.blood_reshape
  style(header) = [fontsize=8pt
                   backgroundcolor = cxFFFFFF
                   color = cx000000]
  style(summary) = [backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontsize=8pt];
  columns BloodGroup TCode Mean -- Maximum;
  define BloodGroup / group 'Blood Group (Ignoring Rhesus Factor)';
  define TCode / group descending 'Test Code';
  define Mean / analysis mean 'Mean' format = 8.2;
  define Median / analysis median 'Median' format = 8.1;
  define Minimum / analysis min 'Minimum' format = 8.1;
  define Maximum / analysis max 'Maximum' format = 8.1;
run;

ods pdf close;
/* End of Section 5 */

quit;
/* End of Script */
