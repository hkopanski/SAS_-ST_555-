/* Author = Halid Kopanski   */
/* Class  = ST555            */
/* Project= HW05             */
/* Purpose = To create a     */
/* comprehensive report on Pollution in various Regions */
/* Date Created = 01MAR2020  */
/* Date Modified = N/A */
/* New File, No modifications */

x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW4";
libname inputds ".";
filename RawData ".";

x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW4_J";
libname HW4 ".";
filename HW4 ".";

x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\HW05_ver2";
libname HW5 ".";
filename HW5 ".";

x "cd C:\Users\halid\Documents\SASUniversityEdition\myfolders\SAS_Data";
libname pol_data ".";
filename pol_data ".";

options nodate FMTSEARCH = (HW4);

data HW5.HW5KopanskiO3_raw (DROP = _:);
  infile RawData('O3Projects.txt') dlm = '2C'x DSD firstobs = 2 TRUNCOVER;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.;
  input StName : $ _JobID : $ _DatReg : $char25. Equipment : dollar11. Personnel : dollar11.;
  StName = upcase(StName);
  _JobID = tranwrd(tranwrd(_JobID,'O','0'), 'l','1');
  JobID = abs(input(_JobID, 8.));
  Date = compress(_DatReg,,'KD');
  Region = propcase(compress(_DatReg,,'d'));
run;

data HW5.HW5KopanskiCO_raw (DROP = _:);
  infile RawData('COProjects.txt') dlm = '2C'x DSD firstobs = 2 TRUNCOVER;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.;
  input StName : $ _JobID : $ _DatReg : $char25. Equipment : dollar11. Personnel : dollar11.;
  StName = upcase(StName);
  _JobID = tranwrd(tranwrd(_JobID,'O','0'), 'l','1');
  JobID = abs(input(_JobID, 8.));
  Date = compress(_DatReg,,'KD');
  Region = propcase(compress(_DatReg,,'d'));
run;

data hw5.hw5kopanski_all (drop = _st _job _dateRegion label = 'Cleaned and Combined EPA Projects Data');
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          PolType     length = $4                           label = 'Pollutant Name'
          PolCode     length = $8                           label = 'Pollutant Code'
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.
          JobTotal                      format = dollar11.; 
  set pol_data.tspprojects(in = inTSP)
      hw4.hw4kopanskilead(in = inLead)
      HW5.HW5KopanskiCO_raw(in = inCO)
      pol_data.so2projects(in = inSO2)
      HW5.HW5KopanskiO3_raw(in = inO3);
  if inTSP or inSO2 eq 1 then do; 
    StName = upcase(_st); 
    Region = propcase(compress(_dateRegion,,'d'));
    JobID  = tranwrd(tranwrd(_job,'O','0'), 'l','1');
    Date = compress(_dateRegion,,'KD');
  end;
  PolCode = compress(1*inTSP + 2*inLead + 3*inCO + 4*inSO2 + 5*inO3);
  select(PolCode);
    when(1) PolType = 'TSP';
    when(3) PolType = 'CO';
    when(4) PolType = 'SO2';
    when(5) PolType = 'O3';
    otherwise PolType = PolType;
  end;
  if Equipment = 99999 then do Equipment = .;
  end;
  if Personnel = 99999 then do Personnel = .;
  end;
  JobTotal = sum(Equipment, Personnel);
run;

proc compare 
  base = pol_data.hw5dugginsprojects 
  compare = hw5.hw5kopanski_all 
  out = hw5.ds_comp_1 
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;

proc means data = hw5.hw5kopanski_all p90 missing;
  class PolCode Region Date;
  var JobTotal;
  format Date myqtr.;
  ods output summary = HW5.all_mean;
run;

proc freq data = HW5.HW5KOPANSKI_ALL;
  table PolCode*Region*Date / nocol nopercent missing;
  format Date myqtr.;
  ods output CrossTabFreqs = HW5.all_freq (drop = _TYPE_ Table _TABLE_ Frequency);
run;

ods listing image_dpi = 300;
ods pdf file = 'HW5 Kopanski Projects Report.pdf' DPI = 300;
ods rtf file = 'HW5 Kopanski Projects Report.rtf';
ods noproctitle;

ods listing;
ods graphics / reset = index imagename= 'Kopanski90PctPlot';

title '90th Percentile of Total Job Cost By Region';
title2 'Including Records where Region was Unknown (Missing)';
footnote j = l 'Bars are labeled with the number of jobs contributing to each bar';

proc sgplot data = HW5.all_mean;
  hbar Region / response = JobTotal_P90
                group = Date
                groupdisplay = cluster
                missing
                datalabel = NObs 
                datalabelattrs=(size=7pt)
                datalabelfitpolicy = none;
  keylegend / position = top;
  yaxis display = (nolabel);
  xaxis display = (nolabel)
        grid gridattrs = (color = gray10)
        offsetmax = 0.05;
  format Date myqtr. JobTotal_P90 dollar10.;
  by PolCode;
run;

ods graphics / reset = index imagename= 'KopanskiFreqPlot';

title;
title2;
footnote;

proc sgplot data = HW5.all_freq;
  vbar Region / response = RowPercent
                group = Date
                groupdisplay = cluster
                missing;
  keylegend / position = topright
              across = 2
              location = inside
              opaque;
  xaxis labelattrs = (size = 16)
        valueattrs = (size = 14);
  yaxis grid gridattrs = (color = gray25 thickness = 3)
        values = (0 to 60 by 5)
        offsetmax = 0.05
        label = 'Percentage within Region'
        labelattrs = (size = 16)
        valueattrs = (size = 12)
        valuesformat = comma6.1;
  format Date myqtr.;
  by PolCode;
  where Date not eq .;
  ods output SGPlot = HW5.HW5KopanskiGraph_freq;
run;

ods listing close;
ods pdf close;
ods rtf close;

quit;