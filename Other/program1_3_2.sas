options ps=100 ls=90 number pageno=1 nodate;

data work.cars;
  set sashelp.cars;
  
  mpg_combo=0.6*mpg_city+0.4*mpg_highway;
  
  select(type);
    when('Sedan','Wagon') typeB='Sedan/Wagon';
	when('SUV','Truck') typeB='SUV/Truck';
	otherwise typeB=type;
  end:
  
  label mpg_combo='Combined MPG' typeB='Simplified Type';
run;

title 'Combined MPG Means';
proc sgplot data=work.cars;
  hbar typeB / response=mpg_combo stat=mean limits=upper;
  where typeB ne 'Hybrid';
run;

title 'MPG Five-Number Summary';
title2 'Across Types';
proc means data=cars min q1 median q3 max maxdec=1;
  class typeB;
  var mpg;
run;
