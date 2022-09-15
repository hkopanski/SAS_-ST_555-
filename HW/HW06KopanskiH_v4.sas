/*
 Author = Halid Kopanski      
 Class  = ST555               
 Project= HW06                
 Purpose = To create a report on housing status in various Regions
 Date Created = 11MAR2020     
 Date Modified = 20MAR2020 v4  
 v2 :Reduced number of proc sorts and renamed all datasets for clarity. 
 v3 :Added novarname to sgpanel in Section 9 
 v4 :Corrected typo in Section 6 comments and fixed conditional logic in Section 4 
*/

/*Location of raw and validation files*/
x 'cd L:\st555\Results';
libname inputds ".";
x 'cd L:\st555\Data';
filename RawData ".";
libname RawData ".";

/*Location of all output files*/
x 'cd S:\Documents\hk_user\HW06_Results';
libname HW6 ".";
filename HW6 ".";

options nodate;
ods _all_ close;

/*Section 1: 
Read in, clean, sort, and combine state and city raw data into a single SAS datas set.*/

data HW6.State_raw;
  infile RawData('States.txt') dlm = '09'x DSD firstobs = 2 TRUNCOVER;
  attrib  Serial      length = 8.         label = 'Household Serial Number'
          State       length = $20.       label = 'State, District, or Territory'
          City        length = $40.       label = 'City Name';
  input Serial State $char20. City ~ $40.;
run;

data HW6.Cities_raw;
  infile RawData('Cities.txt') dlm = '09'x firstobs = 2 TRUNCOVER;
  attrib  City       length = $40.        label = 'City Name'
          CityPop    length = 8.          label = 'City Population (in 100s)'  format = comma6.;
  input City : $ CityPop comma6.;
  City = tranwrd(City, '/', '-');
run;

proc sort data = HW6.State_raw
  out  = HW6.State_sorted;
  by City;
run;

proc sort data = HW6.Cities_raw
  out  = HW6.Cities_sorted;
   by City;
run;

data HW6.StateCity(where = (Serial ^= .));
  merge HW6.State_sorted
        HW6.Cities_sorted;
  by City;
run;

proc sort data = HW6.StateCity
  out = HW6.StateCity_Serial;
  by Serial;
run;
/* End of Section 1 */

/* Section 2: 
Read in and clean morgage and contract raw data into individual SAS data sets.*/

data HW6.Mortgage_raw;
  infile RawData('Mortgaged.txt') dlm = '09'x firstobs = 2 TRUNCOVER;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3.        label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          MortStat     length = $45.       label = 'Mortgage Status'
          Ownership    length = $6.        label = 'Ownership Status';
  input Serial : Metro : CountyFIPS : $ MortPay : dollar6. HHI : dollar10. HomeVal : dollar10.;
  MortStat = 'Yes, mortgaged/ deed of trust or similar debt';
  Ownership = 'Owned';
run;

data HW6.Contract_raw;
  infile RawData('Contract.txt') dlm = '09'x firstobs = 2 TRUNCOVER;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3         label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          MortStat     length = $45.       label = 'Mortgage Status'
          Ownership    length = $6.        label = 'Ownership Status';
  input Serial : Metro : CountyFIPS : $ MortPay : dollar6. HHI : dollar10. HomeVal : dollar10.;
  MortStat = 'Yes, contract to purchase';
  Ownership = 'Owned';
run;
/* End of Section 2 */

/* Section 3:
Read in, clean, and combine Mortgage, Contract, Free&Clear, and Renters datasets into a single SAS data set.
New data set is then sorted by Serial number. */
data HW6.No_stcit;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3.        label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          MortStat     length = $45.       label = 'Mortgage Status'
          Ownership    length = $6.        label = 'Ownership Status';
  set RawData.FreeClear(in = freein)
      RawData.Renters(in = rentin rename = (FIPS = CountyFIPS))
      HW6.Mortgage_raw(in = Mortin)
      HW6.Contract_raw(in = Conin);
  if rentin eq 1 then do;
     Ownership = 'Rented';
     MortStat = 'N/A';
  end;
  else if freein eq 1 then do;
    Ownership = 'Owned';
    MortStat = 'No, owned free and clear';
  end;
run;

proc sort data = HW6.No_stcit
  out = HW6.No_stcit_sort;
  by Serial;
run;
/* End of Section 3 */

/*Section 4: 
Merge all data sets into a single SAS data set for analysis. 
All future analysis will be done using this data set.*/

data HW6.KopanskiIPUMS2005;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3.        label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MetroDesc    length = $32.       label = 'Metro Status Description'
          CityPop      length = 8.         label = 'City Population (in 100s)' format = comma6.
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          State        length = $20.       label = 'State, District, or Territory'
          City         length = $40.       label = 'City Name'
          MortStat     length = $45.       label = 'Mortgage Status'
          Ownership    length = $6.        label = 'Ownership Status';
  merge HW6.StateCity_Serial
        HW6.No_stcit_sort;
  if HomeVal eq 9999999 then HomeVal = .R;
    else if HomeVal eq . then HomeVal = .M;
  MetroDesc = input(metro, $32.);
  MetroDesc = tranwrd(MetroDesc, '0', 'Indeterminable');
  MetroDesc = tranwrd(MetroDesc, '1', 'Not in a Metro Area');
  MetroDesc = tranwrd(MetroDesc, '2', 'In Central/Principal City');
  MetroDesc = tranwrd(MetroDesc, '3', 'Not in Central/Principal City');
  MetroDesc = tranwrd(MetroDesc, '4', 'Central/Principal Indeterminable');
  by Serial;
run;
/* End of Section 4 */

/*Section 5: 
Data validation final merged data set prior to analysis.*/

proc contents data = HW6.KopanskiIPUMS2005 varnum;
  ods output position = HW6.Kopanskidesc (drop = member);
run;

proc compare base = inputds.hw6dugginsdesc
  compare = HW6.Kopanskidesc
  out = HW6.desc_comp
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;

proc compare base = inputds.hw6dugginsipums2005
  compare = HW6.KopanskiIPUMS2005
  out = hw6.ds_comp
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;
/* End of Section 5 */

/*The remainder of the script is for data analysis and report generation.*/

/* PDF report output setup */
ods pdf file = 'HW6 Kopanski IPUMS Report.pdf' startpage = never;

ods listing image_dpi = 300;
ods graphics / width = 5.5in;

title 'Listing of Households in NC with Incomes Over $500,000';

ods exclude _all_;

/* Section 6: 
Summary list of all North Carolina households with income over half a million. */

proc report data = HW6.KopanskiIPUMS2005;
  columns City Metro MortStat HHI HomeVal;
  where State in ('North Carolina') and HHI > 500000;
run;

title;
/* End of Section 6 */

/* Section 7: 
Proc univariate step for statistical analysis of merged data.
Only City Population, Mortgage Payment, House Hold income, and Homevalue
are analyzed here. No other variable analysis was requested. */

proc univariate data = HW6.KopanskiIPUMS2005;
  var CityPop MortPay HHI HomeVal;
  histogram CityPop / kernel(c = 0.79);
  ods select CityPop.BasicMeasures;
  ods select CityPop.Quantiles;
  ods select CityPop.Histogram.Histogram;
  ods select MortPay.Quantiles;
  ods select HHI.BasicMeasures;
  ods select HHI.ExtremeObs;
  ods select HomeVal.BasicMeasures;
  ods select HomeVal.ExtremeObs;
  ods select HomeVal.MissingValues;
run;

/* End of Section 7 */

ods pdf startpage = now;

/* Section 8: 
Histogram and density plots generated for city population in named cities only.
Graph is output to pdf report. */
title 'Distribution of City Population';
title2 '(For Households in a Recognized City)';
footnote j = l 'Recognized cities have a non-zero value for City Population.';

proc sgplot data = HW6.KopanskiIPUMS2005;
  histogram CityPop / binstart = 500
                      binwidth = 1000
                      scale = proportion;
  density CityPop / type = kernel (weight = quadratic)
                    lineattrs = (color = red thickness = 3);
  keylegend / position = ne
              location = inside;
  yaxis display = (nolabel) valuesformat = percent7.;
  xaxis values = (0 to 80000 by 20000);
  where city not in ('Not in identifiable city (or size group)');
run;

/* End of Section 8 */

/* Section 9: Histogram and density plots of households by mortgage status */

title 'Distribution of Household Income Stratified by Mortgage Status';
title2;
footnote "Kernel estimate parameters were determined automatically.";

proc sgpanel data = HW6.KopanskiIPUMS2005 noautolegend;
  panelby MortStat / columns = 2
                     rows = 2
                     novarname;
  histogram HHI / scale = proportion;
  density HHI / scale = proportion
                type = kernel (weight = quadratic)
                lineattrs = (color = red thickness = 2);
  rowaxis display = (nolabel) valuesformat = percent7.;
  colaxis values = (0, 1500000);
run;

title;
footnote;
/* End of Section 9 */

ods listing close;
ods pdf close;

quit;
/* End of Script */
