libname inputds "HW4";
filename RawData "HW4";

libname HW4 "HW4_J";
filename HW4 "HW4_J";

libname HW5 "HW5";
filename HW5 "HW5";

libname pol_data "SAS_Data";
filename pol_data "SAS_Data";

options nodate FMTSEARCH = (HW4);

data HW5.HW5KopanskiO3_raw (DROP = _:);
  infile RawData('O3Projects.txt') dlm = '2C'x DSD firstobs = 2 TRUNCOVER;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          PolType     length = $4                           label = 'Pollutant Name'
          PolCode     length = $8                           label = 'Pollutant Code'
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.
          JobTotal                      format = dollar11.;
  input StName : $ _JobID : $ _DatReg : $char25. _CodType : $ Equipment : dollar11. Personnel : dollar11.;
  StName = upcase(StName);
  _JobID = tranwrd(tranwrd(_JobID,'O','0'), 'l','1');
  JobID = abs(input(_JobID, 8.));
  Date = compress(_DatReg,,'KD');
  Region = propcase(compress(_DatReg,,'d'));
  PolCode = substr(_CodType,1,1);
  PolType = substr(_CodType,2);
  JobTotal = Equipment + Personnel;
run;

data HW5.HW5KopanskiCO_raw (DROP = _:);
  infile RawData('COProjects.txt') dlm = '2C'x DSD firstobs = 2 TRUNCOVER;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          PolType     length = $4                           label = 'Pollutant Name'
          PolCode     length = $8                           label = 'Pollutant Code'
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.
          JobTotal                      format = dollar11.;
  input StName : $ _JobID : $ _DatReg : $char25. _CodType : $ Equipment : dollar11. Personnel : dollar11.;
  StName = upcase(StName);
  _JobID = tranwrd(tranwrd(_JobID,'O','0'), 'l','1');
  JobID = abs(input(_JobID, 8.));
  Date = compress(_DatReg,,'KD');
  Region = propcase(compress(_DatReg,,'d'));
  PolCode = compress(_CodType,,'KD');
  PolType = compress(_CodType,,'d');
  JobTotal = Equipment + Personnel;
run;

data hw5.hw5kopanskitsp_raw (drop = _st _job _dateRegion);
  set pol_data.tspprojects;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          PolType     length = $4                           label = 'Pollutant Name'
          PolCode     length = $8                           label = 'Pollutant Code'
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.
          JobTotal                      format = dollar11.; 
  StName = upcase(_st);
  Region = propcase(compress(_dateRegion,,'d'));
  JobID  = _job;
  Date = compress(_dateRegion,,'KD');
  PolType = 'TSP';
  PolCode = '4';
  Equipment = Equipment;
  Personnel = Personnel;
  JobTotal = Equipment + Personnel;
run;

data hw5.hw5kopanskiso2_raw (drop = _st _job _dateRegion);
  set pol_data.so2projects;
  attrib  StName      length = $2                           label = 'State Name'
          Region      length = $9
          JobID       length = 8
          Date                          format = date9.
          PolType     length = $4                           label = 'Pollutant Name'
          PolCode     length = $8                           label = 'Pollutant Code'
          Equipment                     format = dollar11.
          Personnel                     format = dollar11.
          JobTotal                      format = dollar11.; 
  StName = upcase(_st);
  Region = propcase(compress(_dateRegion,,'d'));
  JobID  = _job;
  Date = compress(_dateRegion,,'KD');
  PolType = 'SO2';
  PolCode = '1';
  Equipment = Equipment;
  Personnel = Personnel;
  JobTotal = Equipment + Personnel;
run;

proc report data = hw4.hw4kopanskilead_raw(obs = 10) nowd;
  columns StName -- Jobtotal;
run;

proc report data = hw5.hw5kopanskio3_raw(obs = 10) nowd;
  columns StName -- Jobtotal;
run;

proc report data = hw5.hw5kopanskiCO_raw(obs = 10) nowd;
  columns StName -- Jobtotal;
run;

proc sort data = hw5.hw5kopanskio3_raw out hw5.hw5kopanskio3;
  by StName descending JobTotal;
run;

proc sort data = hw5.hw5kopanskico_raw out hw5.hw5kopanskico;
  by StName descending JobTotal;
run;


select(PolCode);
    when(2) PolType = 'Lead';
    when(3)  PolType = 'CO';
    when(4)  PolType = 'SO2';
    when(5)  PolType = 'O3';

if PolCode eq 1 then PolType = 'TSP';
  else if PolCode eq 2 then PolType = 'Lead';
  else if PolCode eq 3 then PolType = 'CO';
  else if PolCode eq 4 then PolType = 'SO2';
  else if PolCode eq 5 then PolType = 'O3';