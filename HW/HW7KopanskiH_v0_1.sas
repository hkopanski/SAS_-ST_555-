filename RawData "SAS_Data";
libname inputds "SAS_Data";
filename outputds "HW7_Results";
libname outputds "HW7_Results";

proc format;
  value aqidesc
    low - <0  = 'Missing'
    0   - 50  = 'Good'
    50  <- 100 = 'Moderate'
    100 <- 150 = 'Unhealthy for Sensative Groups'
    150 <- 200 = 'Unhealthy'
    200 <- 300 = 'Very Unhealthy'
    300 <- 500 = 'Hazardous'
    500 <- high = 'Beyond the AQI';
run;

data HW7.EPA01(drop = _:);
  infile RawData("EPA Data.csv") DSD firstobs = 7 TRUNCOVER;
  attrib     
    date      format = YYMMDD10.
    siteid    length = 8.
    poc       length = 8.
    aqscode   length = 8.
    aqsabb    length = $4.
    aqs       length = 8.
    aqi       length = 8.
    count     length = 8.;
  input SiteID :  aqscode :  poc : / _Day_ $char10. / _MaxC_ $char10. / _AQI_ $char5. / _MeasNo_ $char10.;
  date = scan(_Day_, 1,,'lu') + 21549;
  aqi = input(scan(_AQI_,1,,'lu'), comma8.);
  count = input(scan(_MeasNo_,1,,'lu'),comma2.);
  aqs = input(compress(_MaxC_,'Max'), comma8.);
  aqsabb = 'SO2';
run;

data HW7.EPA02;
  infile RawData("EPA Data (1).csv") DSD firstobs = 2 TRUNCOVER;
  attrib 
    date      format = YYMMDD10.
    siteid    length = 8.
    poc       length = 8.
    aqscode   length = 8.
    aqsabb    length = $4.
    aqs       length = 8.
    aqi       length = 8.
    count     length = 8.;
  input date : $mmddyy. siteid : poc : aqs : aqi : count : aqscode : ;
  aqsabb = 'O3';
run;

data HW7.EPA03(drop = i);
  infile RawData("EPA Data (2).csv") DSD firstobs = 6 TRUNCOVER;
  attrib 
    date      format = YYMMDD10.
    siteid    length = 8.
    poc       length = 8.
    aqscode   length = 8.
    aqsabb    length = $4.
    aqs       length = 8.
    aqi       length = 8.
    count     length = 8.;
  date = 21550;
  aqsabb = 'CO';
  input siteid aqscode poc aqs aqi count @;
  do i = 1 to 244;
    output;
    date = date + 1;
    input aqs aqi count @;
  end;
run;

proc transpose data = inputds.pm10 out = HW7.pm10_T(rename = (_NAME_ = _DAY COL1 = aqs COL2 = aqi COL3 = count));
  attrib _DAY label = 'Day #';
  by siteID aqscode poc;
run;

data HW7.HW7Collected_Data(drop = _:);
  set HW7.EPA01(in = inSO2)
      HW7.EPA02(in = inO3)
      HW7.pm10_T(in = inPM10)
      HW7.EPA03(in = inCO);
  if inPM10 eq 1 then do;
    date = scan(_Day, 1,,'lu') + 21549;
    aqsabb = 'PM10';
  end;
  length aqsdesc $40.;
  if inSO2 eq 1 then aqsdesc = 'Daily Max 1-hour SO2 Concentration';
    else if inO3 eq 1 then aqsdesc = 'Daily Max 8-hour Ozone Concentration';
      else if inCO eq 1 then aqsdesc = 'Daily Max 8-hour CO Concentration';
        else if inPM10 eq 1 then aqsdesc = 'Daily Mean PM10 Concentration';
  percent = round(100*count/24,1);
  aqidesc = put(aqi, aqidesc.);
  StCode = input(substr(put(siteid, $9.),1,2), comma8.);
  CountyCode = input(substr(put(siteid, $9.),3,3), comma8.);
  SiteNum = input(substr(put(siteid, $9.),6,4), comma8.);
  if (missing(aqs) and missing(aqi) and missing(count)) then delete;
run;

data HW7.HW7Coll_Sites;
  merge HW7.HW7Collected_Data(in = inColl)
        inputds.aqssites(in = inSites);
  by StCode CountyCode SiteNum;
  stabbrev = scan(CBSAName, -1, ',');
  cityname = scan(CBSAName, 1, ',');
  if inColl eq 1 and inSites eq 1 then output;
  drop StCode CountyCode SiteNum CBSAName;
run;

proc sort data = HW7.HW7Coll_Sites
  out  = HW7.HW7Coll_Sites_sorted;
  by aqscode;
run;

proc sort data = inputds.methods
  out  = HW7.methods_2;
  by aqscode;
run;

data HW7.HW7FinalKopanski;
  attrib 
    date         label = "Observation Date"    format = YYMMDD10.
    siteid       label = "Site ID"
    poc          label = "Parameter Occurance Code (Instrument Number within Site and Parameter)"
    aqscode      label = "AQS Parameter Code"
    parameter    label = "AQS Parameter Name"
    aqsabb       label = "AQS Parameter Abbreviation"
    aqsdesc      label = "AQS Measurement Description"
    aqs          label = "AQS Observed Value"
    aqi          label = "Daily Air Quality Index Value"
    aqidesc      label = "Daily AQI Category"
    count        label = "Daily AQS Observations"
    percent      label = "Percent of AQS Observations (100*Observed/24)"
    mode         label = "Measurement Mode"
    collectdescr label = "Description of Collection Process"
    analysis     label = "Analysis Technique"
    mdl          label = "Federal Method Detection Limit"
    localName    label = "Site Name"
    lat          label = "Site Latitude"
    long         label = "Site Longitude"
    stabbrev     label = "State Abbreviation"
    countyname   label = "County Name"
    cityname     label = "City Name"
    estabdate    label = "Site Established Date"  format = YYMMDD10.
    closedate    label = "Site Closed Date"       format = YYMMDD10.;
  merge HW7.HW7Coll_Sites_sorted(in = inCollSites)
        HW7.methods_2(in = inMet);
  by aqscode;
  collectdescr = propcase(collectdescr);
  analysis = propcase(analysis);
  if inCollSites eq 1 and inMet eq 1 then output;
run;

proc contents data = HW7.HW7FinalKopanski varnum;
  ods output position = HW7.HW7Kopanskidesc (drop = member);
run;

proc compare base = inputds.hw7dugginsdesc
  compare = HW7.HW7Kopanskidesc
  out = HW7.desc_comp
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;

proc compare base    = inputds.HW7finalduggins
             compare = HW7.HW7FinalKopanski
             out     = HW7.comp
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;

data HW7.HW7FinalKopanski100;
  set HW7.HW7FinalKopanski;
  if percent ne 100 then delete;
  output;
run;

proc compare base    = inputds.HW7finalduggins100
             compare = HW7.HW7FinalKopanski100
             out     = HW7.comp100
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;