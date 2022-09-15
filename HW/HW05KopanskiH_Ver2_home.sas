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
  PolCode = 1*inTSP + 2*inLead + 3*inCO + 4*inSO2 + 5*inO3;
  select(PolCode);
    when(1) PolType = 'TSP';
    when(4) PolType = 'SO2';
    otherwise PolType = PolType;
  end;
  if Equipment = 99999 then do Equipment = .;
  end;
  if Personnel = 99999 then do Personnel = .;
  end;
  JobTotal = Equipment + Personnel;
run;

proc compare 
  base = pol_data.hw5dugginsprojects 
  compare = hw5.hw5kopanski_all 
  out = hw5.ds_comp_1 
  outbase outcompare outdif outnoequal
  method = absolute
  criterion = 1E-15;
run;
