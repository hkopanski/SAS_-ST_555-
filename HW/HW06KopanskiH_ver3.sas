/* Author = Halid Kopanski   */
/* Class  = ST555            */
/* Project= HW06             */
/* Purpose = To create a report on housing status in various Regions*/
/* Date Created = 11MAR2020  */
/* Date Modified = N/A*/

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

/*Lines 23 to 58 read in, clean, sort, and combine state and city raw data into a single SAS datas set.*/
data HW6.KopanskiState_raw;
  infile RawData('States.txt') dlm = '09'x DSD firstobs = 2 TRUNCOVER;
  attrib  Serial      length = 8.         label = 'Household Serial Number'
          State       length = $20.       label = 'State, District, or Territory'
          City        length = $40        label = 'City Name';
  input Serial State $char20. City ~ $40.;
run;

data HW6.KopanskiCities_raw;
  infile RawData('Cities.txt') dlm = '09'x firstobs = 2 TRUNCOVER;
  attrib  City       length = $40         label = 'City Name'
          CityPop    length = 8.          label = 'City Population (in 100s)'  format = comma6.;
  input City : $ CityPop comma6.;
  City = tranwrd(City, '/', '-');
run;

proc sort data = HW6.KopanskiState_raw
    out  = HW6.KopanskiSt_sort;
    by City;
run;

proc sort data = HW6.KopanskiCities_raw
    out  = HW6.KopanskiCit_sort;
    by City;
run;

data hw6.KopanskiStCit_sort(where = (Serial ^= .));
  merge HW6.KopanskiSt_sort
        hw6.KopanskiCit_sort;
  by City;
run;

proc sort data = hw6.KopanskiStCit_Sort
  out = hw6.KopanskiStCit_Sort2;
  by Serial;
run;

/*Lines 61 to 89 read in and clean morgage and contract raw data into individual SAS data sets.*/
data HW6.KopanskiMort_raw;
  infile RawData('Mortgaged.txt') dlm = '09'x firstobs = 2 TRUNCOVER;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3         label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          MortStat     length = $45        label = 'Mortgage Status'
          Ownership    length = $6         label = 'Ownership Status';
  input Serial : Metro : CountyFIPS : $ MortPay : dollar6. HHI : dollar10. HomeVal : dollar10.;
  MortStat = 'Yes, mortgaged/ deed of trust or similar debt';
  Ownership = 'Owned';
run;

data HW6.Kopanskicontract_raw;
  infile RawData('Contract.txt') dlm = '09'x firstobs = 2 TRUNCOVER;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3         label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          MortStat     length = $45        label = 'Mortgage Status'
          Ownership    length = $6         label = 'Ownership Status';
  input Serial : Metro : CountyFIPS : $ MortPay : dollar6. HHI : dollar10. HomeVal : dollar10.;
  MortStat = 'Yes, contract to purchase';
  Ownership = 'Owned';
run;

/*Lines 92 to 112 read in, clean, sort, and combine free/clear and renters data into a single SAS data set.*/
data hw6.kopanski_fc_ren(drop = FIPS);
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3         label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          MortStat     length = $45        label = 'Mortgage Status'
          Ownership    length = $6         label = 'Ownership Status';
  set RawData.FreeClear(in = freein)
      RawData.Renters (in = rentin);
  if rentin eq 1 then do;
    CountyFIPS = FIPS;
    Ownership = 'Rented';
    MortStat = 'N/A';
  end;
  else if freein eq 1 then do;
    Ownership = 'Owned';
    MortStat = 'No, owned free and clear';
  end;
run;

/*Lines 115 to 128 sort data sets created in previous section by serial number.*/
proc sort data = HW6.KopanskiMort_raw
    out  = HW6.Mortgage_sort;
    by Serial;
run;

proc sort data = HW6.Kopanskicontract_raw
    out  = HW6.Contracts_sort;
    by Serial;
run;

proc sort data = HW6.kopanski_fc_ren
    out  = HW6.fc_ren_sort;
    by Serial;
run;

/*Lines 131 to 159 merge all data sets into a single SAS data set for analysis. All future analysis will be done using this data set.*/
data hw6.KopanskiIpms2005;
  attrib  Serial       length = 8.         label = 'Household Serial Number'
          CountyFIPS   length = $3         label = 'County FIPS Code'
          Metro        length = 8.         label = 'Metro Status Code'
          MetroDesc    length = $32.       label = 'Metro Status Description'
          CityPop      length = 8.         label = 'City Population (in 100s)' format = comma6.
          MortPay      length = 8.         label = 'Monthly Mortgage Payment'  format = dollar6.
          HHI          length = 8.         label = 'Household Income'          format = dollar10.
          HomeVal      length = 8.         label = 'Home Value'                format = dollar10.
          State        length = $20.       label = 'State, District, or Territory'
          City         length = $40.       label = 'City Name'
          MortStat     length = $45        label = 'Mortgage Status'
          Ownership    length = $6         label = 'Ownership Status';
  merge HW6.KopanskiStCit_Sort2
        HW6.Mortgage_sort
        HW6.Contracts_sort
        HW6.fc_ren_sort;
  if HomeVal eq 9999999 then do; HomeVal = .R;
    end;
      else if HomeVal in ('.') then do; HomeVal = .M;
  end;
  MetroDesc = input(metro, $32.);
  MetroDesc = tranwrd(MetroDesc, '0', 'Indeterminable');
  MetroDesc = tranwrd(MetroDesc, '1', 'Not in a Metro Area');
  MetroDesc = tranwrd(MetroDesc, '2', 'In Central/Principal City');
  MetroDesc = tranwrd(MetroDesc, '3', 'Not in Central/Principal City');
  MetroDesc = tranwrd(MetroDesc, '4', 'Central/Principal Indeterminable');
  by Serial;
run;

/*Lines 162 to 180 validate final merged data set prior to analysis.*/
proc contents data = hw6.KopanskiIpms2005 varnum;
  ods output position = hw6.hw6kopanskidesc (drop = member); 
run;

proc compare base = inputds.hw6dugginsdesc 
  compare = hw6.hw6kopanskidesc
  out = hw6.desc_comp 
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;;
run;

proc compare base = inputds.hw6dugginsipums2005 
  compare = hw6.KopanskiIpms2005
  out = hw6.ds_comp 
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;;
run;

/*The remainder of the script is for data analysis and report generation.*/
ods pdf file = 'HW6 Kopanski IPUMS Report.pdf' startpage = never;

ods listing image_dpi = 300;
ods graphics / width = 5.5in;

title 'Listing of Households in NC with Incomes Over $500,000';

ods exclude _all_;

/* Summary list of all North Carolina households with income over half a million. */
proc report data = hw6.KopanskiIpms2005;
  columns City Metro MortStat HHI HomeVal;
  where State in ('North Carolina') and HHI > 500000;
run;

title;

/*Proc univariate step for statistical analysis of merged data.*/
/*Only City Population, Mortgage Payment, House Hold income, and Homevalue*/
/*are analyzed here. No other variable analysis was requested. */
proc univariate data = hw6.KopanskiIpms2005;
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

ods pdf startpage = now;

title 'Distribution of City Population';
title2 '(For Households in a Recognized City)';
footnote j = l 'Recognized cities have a non-zero value for City Population.';

/*Histogram and density plots generated for city population in named cities only. */
/*Graph is output to pdf report.  */
proc sgplot data = hw6.KopanskiIpms2005;
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

title 'Distribution of Household Income Stratified by Mortgage Status';
title2;
footnote "Kernel estimate parameters were determined automatically.";

/* Histogram and density plots of households by mortgage status */
proc sgpanel data = hw6.KopanskiIpms2005 noautolegend;
  panelby MortStat / columns = 2
                     rows = 2;
  histogram HHI / scale = proportion;
  density HHI / scale = proportion
                type = kernel (weight = quadratic)
                lineattrs = (color = red thickness = 2);
  rowaxis display = (nolabel) valuesformat = percent7.;
  colaxis values = (0, 1500000);
run;

title;
footnote;

ods listing close;
ods pdf close;

quit;
