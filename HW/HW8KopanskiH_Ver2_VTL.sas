/*
 Author = Halid Kopanski      
 Class  = ST555               
 Project= HW08                
 Purpose = To create blood work reports from recorded patient data.
 Date Created = 12APR2020     
 Date Modified = 12APR2020 v2
 v1: New file
 v2: Tested on VTL 
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
Read in, clean, and sort collected blood work data from raw files. */
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

data HW8.blood_reshape;
  format T_Code $4.;
  set HW8.Blood_raw;
  by Subject;
  
  array b_stats[*] WBC -- Chol;
  
  do i = 1 to dim(b_stats);
    R_Value = b_stats[i];
    if i eq 1 then T_Code = 'WBC';
      else if i eq 2 then T_Code = 'RBC';
        else if i eq 3 then T_Code = 'CHOL';
    output;
  end;
  drop i WBC RBC Chol;
run;

/* End of Section 1 */

/* Section 2: 
Create first report from main dataset */
options nodate;

title;
title2;
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
Create second report using dataset generated from proc means output.*/
proc means data =  HW8.blood_raw nonobs mean median min max;
  class BloodGroup;
  var WBC Chol;
  ods output summary = HW8.blood_means;
run;

ods rtf file = 'HW8 Kopanski Report 2.rtf';

title 'WBC and Cholesterol Summarized by Blood Group';
title2 '(Ignoring Rhesus Factor)';
footnote;
footnote2;

proc report data = HW8.blood_means
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
Create third report using reshaped dataset. */
ods rtf file = 'HW8 Kopanski Report 3.rtf';

title 'WBC and Cholesterol Summarized by Blood Group';
title2;
footnote 'Note: Rhesus factor was not considered';
footnote2;

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
  columns BloodGroup T_Code R_Value = R_mean R_Value = R_median R_Value = R_min R_Value = R_max;
  where T_Code in ('WBC' 'CHOL');
  define BloodGroup / group 'Blood Group (Ignoring Rhesus Factor)';
  define T_Code / group descending 'Test Code';
  define R_mean / analysis mean 'Mean' format = 8.2;
  define R_median / analysis median 'Median' format = 8.1;
  define R_min / analysis min 'Minimum' format = 8.1;
  define R_max / analysis max 'Maximum' format = 8.1;
run;

ods rtf close;
/* End of Section 4 */

/* Section 5: 
Create fourth report from main, means, and reshaped datasets. Fourth report lists all records that require review.
This includes both subjects with out of spec results and incomplete records. */
ods pdf file = 'HW8 Kopanski Report 4.pdf' columns = 4;

title 'Selected Summaries of WBC and Cholestorol';
title2;
footnote;
footnote2;

proc report data = HW8.blood_raw nowd
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=8pt
                   backgroundcolor = cxFFFFFF
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=8pt];
  columns Subject WBC Chol;
  where Review in ('Y' 'M');
  define subject / display 'Subject Number';
  define WBC / display 'White Blood Cells' format = comma8.;
  define Chol / display 'Cholesterol Level';
run;

options pageno = 1;
ods pdf columns = 1;

proc report data = HW8.blood_means
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=8pt
                   backgroundcolor = cxFFFFFF
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=8pt];
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

options pageno = 1;

proc report data = HW8.blood_reshape
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=8pt
                   backgroundcolor = cxFFFFFF
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=8pt];
  columns BloodGroup T_Code R_Value = R_mean R_Value = R_median R_Value = R_min R_Value = R_max;
  where T_Code in ('WBC' 'CHOL');
  define BloodGroup / group 'Blood Group (Ignoring Rhesus Factor)';
  define T_Code / group descending 'Test Code';
  define R_mean / analysis mean 'Mean' format = 8.2;
  define R_median / analysis median 'Median' format = 8.1;
  define R_min / analysis min 'Minimum' format = 8.1;
  define R_max / analysis max 'Maximum' format = 8.1;
run;

ods pdf close;
/* End of Section 5 */

quit;
/* End of Script */