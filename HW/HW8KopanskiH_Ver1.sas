filename RawData "HW8";
libname inputds "HW8";
filename HW8 "HW8_Results";
libname HW8 "HW8_Results";

data HW8.blood_raw 
     HW8.blood_WBS(keep = Subject BloodGroup AgeGroup WBC rename = (WBC = R_Value)) 
     HW8.blood_Chol(keep = Subject BloodGroup AgeGroup Chol rename = (Chol = R_Value));
  infile Rawdata('blood.txt') dlm = '0920'x TRUNCOVER firstobs = 2;
  input Subject BloodGroup : $2. AgeGroup : $5.  WBC RBC Chol;
  BloodGroup = upcase(BloodGroup);
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

proc format;
  value Review
    0 = 'M'
    1 = 'Y'
    2 = 'missing';
run;

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
  define Review / computed format = Review. 'Review Code';
  compute Review;
    if (missing(WBC) or missing(RBC) or missing(Chol)) then Review = '0';
      else if RBC > 6.1 
           or RBC < 4.0 
           or Chol < 0 
           or WBC > 11000
           or WBC < 4000 then Review = '1';
      else Review = '2';
  endcomp;
run;

ods rtf close;

ods rtf file = 'HW8 Kopanski Report 2.rtf';

title 'WBC and Cholesterol Summarized by Blood Group';
title2 '(Ignoring Rhesus Factor)';
footnote;
footnote2;

proc report data = HW8.blood_raw nowd
  style(header) = [fontfamily = 'Times New Roman'
                   fontsize=11pt
                   backgroundcolor = cxC0C0C0
                   color = cx000000]
  style(summary) = [fontfamily = 'Times New Roman'
                    backgroundcolor = cx00009F
                    color = cxFFFFFF]
  style(column)  = [fontfamily = 'Times New Roman'
                    fontsize=10pt];
  columns BloodGroup 
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

ods rtf close;

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

title;
title2;
footnote;
footnote2;