/* Author = Halid Kopanski   */
/* Class  = ST555            */
/* Project= HW05             */
/* Purpose = To create a     */
/* comprehensive report on Pollution in various Regions */
/* Date Created = 01MAR2020  */
/* Date Modified = 02Mar2020*/
/* Added comments and modified graph attributes */

/*Location of raw data files*/
x "cd L:\st555\Data";
libname inputds ".";
filename RawData ".";

/*Location of validation data files*/
x "cd L:\st555\Results";
libname pol_data ".";
filename pol_data ".";

/*Location of data files and formats generated from HW4*/
x "cd S:\Documents\hk_user\HW4\Results";
libname HW4 ".";
filename HW4 ".";

/*Location of all output data files, reports, and graphs. */
x "cd S:\Documents\hk_user\HW5";
libname HW5 ".";
filename HW5 ".";

options nodate FMTSEARCH = (HW4);
ods _all_ close;

/* Read in of O3 raw data and creation of O3 SAS data file */
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

/* Read in of CO raw data and creation of CO SAS data file */
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


/* Combining and cleaning of O3, SO2, Lead, TSP, and CO datasets */
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
  set inputds.tspprojects(in = inTSP)
      hw4.hw4kopanskilead(in = inLead)
      HW5.HW5KopanskiCO_raw(in = inCO)
      inputds.so2projects(in = inSO2)
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
  Equipment = tranwrd(Equipment,99999,.);
  Personnel = tranwrd(Personnel,99999,.);
  JobTotal = sum(Equipment, Personnel);
  putlog _all_;
run;


/* Creation of contents data file for combined data set. */
proc contents data = HW5.HW5kopanski_all varnum;
  ods output position = hw5.hw5kopanskidesc (drop = member); 
run;

/* Validation of contents data file for combined data set. */
proc compare base = pol_data.hw5dugginsprojectsdesc compare = HW5.HW5kopanskidesc
  out = hw4.desc_comp outbase outcompare outdif outnoequal
  method = absolute criterion = 1E-15;
run;

/* Validation of combined data. */
proc compare 
  base = pol_data.hw5dugginsprojects 
  compare = hw5.hw5kopanski_all 
  out = hw5.ds_comp_1 
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;

/* Mean statistics and output */
proc means data = hw5.hw5kopanski_all p90 missing;
  class PolCode Region Date;
  var JobTotal;
  format Date myqtr.;
  ods output summary = HW5.all_mean;
run;

/* Frequency statistics and output */
proc freq data = HW5.HW5KOPANSKI_ALL;
  table PolCode*Region*Date / nocol nopercent missing;
  format Date myqtr.;
  ods output CrossTabFreqs = HW5.all_freq (drop = _TYPE_ Table _TABLE_ Frequency);
run;

/* Opening of Report Files */
ods pdf file = 'HW5 Kopanski Projects Report.pdf' DPI = 300;
ods rtf file = 'HW5 Kopanski Projects Report.rtf' DPI = 300;
ods noproctitle;

/* Creation and attribute settings of 90 percentile graphs saved as png files. */
ods listing image_dpi = 300;
ods graphics / reset = index imagename = 'Kopanski90PctPlot' height = 4.5in width = 6in;

title '90th Percentile of Total Job Cost By Region';
title2 'Including Records where Region was Unknown (Missing)';
footnote j = l 'Bars are labeled with the number of jobs contributing to each bar';

/* Horizontal bar plot creation using 90th percentile data. */
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
        grid gridattrs = (thickness = 1 color = grayCC)
        offsetmax = 0.05;
  format Date myqtr. JobTotal_P90 dollar10.;
  by PolCode;
run;

/* Creation and attribute settings of Frequency graphs saved as png files. */
ods listing image_dpi = 300;
ods graphics / reset = index imagename = 'KopanskiFreqPlot' height = 4.5in width = 6in;

title;
title2;
footnote;


/* Vertical bar plot creation using frequency data. */
proc sgplot data = HW5.all_freq;
  styleattrs datacolors = (cx1b9e77 cxd95f02 cx7570b3 cxe7298a cx66a61e cxe6ab02);
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
  yaxis grid gridattrs = (thickness = 3 color = grayCC)
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

/* Closing of all outputs */
ods listing close;
ods pdf close;
ods rtf close;

/* GPP requirement */
quit;
