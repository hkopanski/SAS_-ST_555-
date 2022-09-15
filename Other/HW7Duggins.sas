/*
Authored By: Jonathan W. Duggins
Authored On: 2019-11-11
Authored To: Provide solution for HW 7 in Intro SAS

Change Logs: 

Updated By: Jonathan W. Duggins
Updated on: 2020-04-08
Updated to: Use updated data sets, add more comments, add in the GPP-mandated QUIT I had forgotten!
*/

*Set libraries and options;
x "cd L:\ST555";
filename RawData "Data";
libname InputDS "Data";
libname Results "Results";

x "cd S:\Documents\TEACHING\NCSU COURSES\ST 555 v3.0\Assignments";
libname HW7 "HW7";

options nodate fmtsearch = (InputDS);
ods listing close;

*Read in SO2 data and use arrays to clean it since it's all the same process;
data HW7.So2Duggins(drop = _: i);
  infile RawData("EPA Data.csv") dsd truncover firstobs = 7;
  input #1 siteid aqscode poc 
        #2 _day $ 
        #3 _max $
        #4 _aqi $
        #5 _count $;
  array tbc[*] $ _day -- _count;
  array cleaned[*] day max aqi count;

  do i = 1 to dim(tbc);
    cleaned[i] = input(compress(tbc[i],,'a'),4.);
  end;
run;

*Read in the O3 data, no cleaning needed;
data HW7.o3Duggins;
  infile RawData("EPA Data (1).csv") dsd truncover firstobs = 2;
  input date : mmddyy. siteid poc max aqi count aqscode;
run;

*Read in the CO data.;
data HW7.CoDuggins;
  infile RawData("EPA Data (2).csv") dsd truncover firstobs = 6;
  input siteid aqscode poc @;
  do day = 1 to 244;
    input max aqi count @;
    if nmiss(max,aqi,count) lt 3 then output;
  end;
/*All numeric variables, so easier to count how many*/
/*are missing than check them individually. If you do*/
/*want to see how to check them individuall, that's*/
/*included below.*/
/*    if not missing(max) and */
/*       not missing(aqi) and */
/*       not missing(count) then output;*/
run;

proc transpose data = InputDS.pm10 out = Pm10 name = _day;
  by siteid aqscode poc;
  id metric;
  var day:;
run;

data HW7.pm10Duggins;
  set pm10;
  day = input(compress(_day,,'a'),3.);
  if not missing(aqi);
run;

*Concatenate and derive new variables - it is 
 better to derive them all in one place since
 if you have to edit your derivations, you do
 not have to edit them in multiple locations in
 your code. It is generally a GPP to never
 derive variables more than once per project;
data HW7.paramsDuggins(drop = max mean);
  set HW7.O3Duggins(in = inO3)
      HW7.CoDuggins(in = inCo) 
      HW7.pm10Duggins(drop =_: in = inPM) 
      HW7.So2Duggins(in = inSo2);

  length aqsdesc $ 40;

  if not missing(count) then percent = round(100*count/24,1);
  aqidesc = put(aqi,aqicat.);
  stCode = input(substr(put(siteid,9.),1,2),2.);
  CountyCode = input(substr(put(siteid,9.),3,3),3.);
  sitenum = input(substr(put(siteid,9.),6),4.);
  if inpm eq 1 then do;
      aqs = mean;
      aqsdesc = 'Daily Mean PM10 Concentration';
      date = day + '31DEC2018'd;
      aqsabb = 'PM10';
    end;
    else if inO3 = 1 then do;
        aqs = max;
        aqsdesc = 'Daily Max 8-hour Ozone Concentration';
        aqsabb = 'O3';
      end;
      else if inSo2 eq 1 then do;
          aqs = max;
          aqsdesc = 'Daily Max 1-hour SO2 Concentration';
          aqsabb = 'SO2';
          date = day + '31DEC2018'd;
        end;
        else if inCo eq 1 then do;
            aqs = max;
            aqsdesc = 'Daily Max 8-hour CO Concentration';
            aqsabb = 'CO';
            date = day + '31DEC2018'd;
          end;
run;

*Sort to prepare for first match-merge;
proc sort data = HW7.paramsduggins;
  by stcode countycode sitenum;
run;

data work01(drop = cbsaname);
  merge hw7.paramsDuggins(in = inParam)
        InputDS.aqssites;
  by stcode CountyCode sitenum;
  if inParam eq 1;

  cityName = scan(cbsaname,1,',');
  stabbrev = scan(cbsaname,-1,',');
run;

*Sort to prepare for second match-merge;
proc sort data = work01;
  by aqscode;
run;

proc sort data = InputDS.methods out = methods;
  by aqscode;
run;

*This is my final data set, so now is the time to ATTRIB.
 Definitely no need to use this multiple times throughout!;
data hw7.FinalDuggins(drop = day sitenum stcode countycode) 
     hw7.FinalDuggins100
     Results.HW7FinalDugginsNEW(drop = day sitenum stcode countycode)
     Results.HW7FinalDuggins100NEW
    ;

  attrib date         format = yymmdd10. label = 'Observation Date' 
         siteid                          label = 'Site ID'
         poc                             label = 'Parameter Occurance Code (Instrument Number within Site and Parameter)'
         aqscode                         label = 'AQS Parameter Code'
         parameter                       label = 'AQS Parameter Name'
         aqsabb                          label = 'AQS Parameter Abbreviation'
         aqsdesc                         label = 'AQS Measurement Description'
         aqs                             label = 'AQS Observed Value'
         aqi                             label = 'Daily Air Quality Index Value'
         aqidesc                         label = 'Daily AQI Category'
         count                           label = 'Daily AQS Observations'
         percent                         label = 'Percent of AQS Observations (100*Observed/24)'
         mode                            label = 'Measurement Mode'
         collectdescr                    label = 'Description of Collection Process'
         analysis                        label = 'Analysis Technique'
         mdl                             label = 'Federal Method Detection Limit'
         localName                       label = 'Site Name'
         lat                             label = 'Site Latitude'
         long                            label = 'Site Longitude'
         stabbrev                        label = 'State Abbreviation'
         countyname                      label = 'County Name'
         cityname                        label = 'City Name'
         estabdate    format = yymmdd10. label = 'Site Established Date' 
         closedate    format = yymmdd10. label = 'Site Closed Date' 
    ;

  merge work01(in = inParam) methods;
  by aqscode;

  collectdescr = propcase(collectdescr);
  analysis = propcase(analysis);

  if inParam eq 1 then output hw7.finalduggins results.HW7FinalDugginsNEW;
  if inParam eq 1 and percent eq 100 then output hw7.finalduggins100 results.HW7FinalDuggins100NEW;
run;

*Independent validation;
ods output position = HW7.DugginsDesc(drop = member)
           position = Results.HW7DugginsDescNEW(drop = member);
proc contents data = hw7.finalduggins varnum;
run;

proc compare base = results.hw7dugginsdesc compare = hw7.dugginsdesc
             out = hw7.diffa outbase outcompare outdiff outnoequal noprint
             method = absolute criterion = 1E-10;
run;

proc compare base = results.hw7finalduggins compare = hw7.finalduggins
             out = hw7.diffb outbase outcompare outdiff outnoequal noprint
             method = absolute criterion = 1E-10;
run;

quit;
