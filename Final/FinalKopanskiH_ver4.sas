*Author = Halid Kopanski;
*Class  = ST555;
*Project= Final;
*Purpose = To analyze movie data.;
*Date Created = 23APR2020;
*Date Modified = 27APR2020;
*v1: New file;
*v2: Tested on VTL, added comments, and justified headers and columns in proc reports.;
*v3: Fixed indents, replaced < with lt, removed a comment, fixed additional instances of justification.;
*v4: Changed font color from default to white in studio rating, changed over 90% background from f1eef6 to d4b9da;

x 'cd L:\st555\Data';
filename RawData '.';
x 'cd L:\st555\Results';
libname inputds '.';

x 'cd S:\Documents\hk_user\Final_Results';
libname fp '.';

ods _all_ close;

*Create main dataset;
data fp.kopanskifinalmovies;
  infile RawData("movies.dat") DSD TRUNCOVER firstobs = 7;
  attrib 
    Title     format = $68.     label = "Movie Title"
    Studio    format = $25.     label = "Lead Studio Name"
    Rotten    format = BEST12.  label = "Rotten Tomatoes Score"
    Audience  format = BEST12.  label = "Audience Score"
    ScoreDiff format = BEST12.  label = "Score Difference (Rotten - Audience)"
    Theme     format = $18.     label = "Movie Theme"
    Genre     format = $9.      label = "Movie Genre";
  input _title $char250. / _score $char10. /  _genthem $char100. / _studio $char250.;
  Title = compbl(_title);
  Studio = compbl(_studio);
  Genre = compress(scan(_genthem,1,'--'));
  Theme = scan(_genthem,-1,'--');
  Rotten = input(scan(_score,1,'--'),BEST12.);
  Audience = input(scan(_score,-1,'--'),BEST12.);
  _negAud = -1 * Audience;
  ScoreDiff = sum(Rotten, _negAud);
  if Theme in ('Adventure') then Theme = '';
  drop _:;
run;

*Validation of main dataset and attributes;
proc contents data = fp.kopanskifinalmovies VARNUM;
  ods select position;
  ods output position = fp.kopanskifinalmoviesdesc(drop = member);
run;

proc compare base = inputds.dugginsfinalmoviesdesc 
  compare = fp.kopanskifinalmoviesdesc
  out = fp.desc_comp outbase outcompare outdiff outnoequal
  method = absolute criterion = 1E-10;
run;

proc compare base = inputds.dugginsfinalmovies 
  compare = fp.kopanskifinalmovies
  out = fp.ds_comp outbase outcompare outdiff outnoequal
  method = absolute criterion = 1E-10;
run;

*Running and creating frequency dataset;
proc freq data = fp.kopanskifinalmovies;
  table Studio*Genre / nopercent norow nocol nocum;
  Where Genre not in ('Adventure');
  ods output CrossTabFreqs = fp.kopanskimovies_freq(drop = Table _TYPE_ _TABLE_ Missing);
run;

*Running and creating means dataset;
proc means data = fp.kopanskifinalmovies nonobs nolabels min max mean maxdec = 2;
  var Rotten Audience;
  class studio;
  ods output summary = fp.kopanskimovies_means;
run;

*Preparing freq dataset for merging;
proc sort data = fp.kopanskimovies_freq out = fp.kopanskimovies_freq_s;
  by studio;
run;

proc transpose data = fp.kopanskimovies_freq_s out = fp.kopanskimovies_fT
  (rename = (COL1 = Action
             COL2 = Animation
             COL3 = Comedy
             COL4 = Drama
             COL5 = Fantasy
             COL6 = Horror
             COL7 = Romance
             COL8 = Thriller
             COL9 = Total)
             drop = _:);
  by studio;
run;

*Merging freq and means datasets;
data fp.kopanski_means_freq;
  attrib 
    studio label = 'Studio'
    score_stat format = $10.;
  merge fp.kopanskimovies_fT(in = inFreq)
    fp.kopanskimovies_means(in = inMeans);
  by Studio;
  if missing(Studio) then delete;
  
  cat_rot = CAT("(",Rotten_Min,","," ",Rotten_Max,")");
  cat_aud = CAT("(",Audience_Min,","," ",Audience_Max,")");
  
  array _cat[2] cat_rot cat_aud;
  array _means[2] Rotten_Mean Audience_Mean;
  array var1[2] $;
  
  do i = 1 to 2;
    var1[i] = _cat[i];
    score_stat = "(Min, Max)";
  end;
  output;
  do j = 1 to 2;
    var1[j] = put(_means[j],4.1);
    score_stat = "Mean";
  end;
  output;
  
  rename var11 = RTscore var12 = ADscore;
  drop i j VName: Total Rotten_Min Rotten_Max Audience_Min Audience_Max Audience_Mean cat_rot cat_aud;
run;

*Create color formats for reports;
proc format;
  value frqcolor(fuzz = 0)
    .           = 'cxefedf5' 
    0           = 'cxefedf5'
    1 - 3       = 'cxbcbddc'
    4 - high    = 'cx756bb1';
  value focol(fuzz = 0)
    .           = 'cx000000'
    0 -< 3      = 'cx000000'
    3 - high    = 'cxFFFFFF';
run;

*Report creation;
option orientation = landscape nodate;
ods pdf file = "Kopanski COVID Final.pdf";

title 'Genres and Movie Ratings by Studio';
title2 'Trafficlighting based on Genre';
footnote h = 10pt j = l 'The Adventure genre was excluded as it only applied to one movie';
footnote2;

proc report data = fp.kopanski_means_freq nowd
  style(header column)  = [just = center];
  columns studio score_stat RTscore ADscore Action--Thriller;
  define studio / order 'Lead Studio Name' style(column)=[just = left cellwidth=1.6in];
  define score_stat / 'Score Statistics' style(column)=[just = right cellwidth=0.8in];
  define RTscore / 'Rotten Tomatoes Score' style=[cellwidth=0.8in];
  define ADscore / 'Audience Score' style=[cellwidth=0.8in];
  define Action / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Animation / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Comedy / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Drama / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Fantasy / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Horror / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Romance / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Thriller / style(column) = [color = focol. backgroundcolor = frqcolor.];
run;

title 'Genres and Movie Ratings by Studio';
title2 'Trafficlighting based on Genre and Average Rotten Tomatoes Score';
footnote  h = 10pt j = l 'The Adventure genre was excluded as it only applied to one movie';
footnote2 h = 10pt j = l 'Studio Color Key: Below 60 (Darkest), 60-70, 70-80, 80-90, 90-100 (Lightest)';
footnote3 h = 10pt j = l 'Studio names were colored based on mean Rotten Tomatoes score using intervals that excluded the right endpoint';

proc report data = fp.kopanski_means_freq nowd 
  style(header column)  = [just = center];
  columns Studio score_stat RTscore ADscore Rotten_Mean ('Frequency By Genre' (Action--Thriller)) stu_rating;
  define Studio / order 'Lead Studio Name' style(column)=[just = left cellwidth=1.6in];
  define score_stat / 'Score Statistics' style(column)=[just = right cellwidth=0.8in];
  define RTscore / 'Rotten Tomatoes Score' style=[cellwidth=0.8in];
  define ADscore / 'Audience Score' style=[cellwidth=0.8in];
  define Rotten_Mean / display noprint;
  define stu_rating / computed noprint;
  define Action / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Animation / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Comedy / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Drama / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Fantasy / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Horror / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Romance / style(column) = [color = focol. backgroundcolor = frqcolor.];
  define Thriller / style(column) = [color = focol. backgroundcolor = frqcolor.];
  compute stu_rating;
    stu_rating = Rotten_Mean;
    if stu_rating ge 0 and stu_rating lt 60 then call define('Studio', 'Style', 'Style = [color = white backgroundcolor=cx980043]');
      else if stu_rating ge 60 and stu_rating lt 70 then call define('Studio', 'Style', 'Style = [color = white backgroundcolor=cxdd1c77]');
      else if stu_rating ge 70 and stu_rating lt 80 then call define('Studio', 'Style', 'Style = [color = white backgroundcolor=cxdf65b0]');
      else if stu_rating ge 80 and stu_rating lt 90 then call define('Studio', 'Style', 'Style = [color = white backgroundcolor=cxd7b5d8]');
      else if stu_rating ge 90 then call define('Studio', 'Style', 'Style = [color = white backgroundcolor=cxd4b9da]');
  endcomp;
run;

title;
title2;
footnote;
footnote2;
footnote3;

*Creating vertical plot from main dataset;
ods listing image_dpi = 300;
ods graphics / reset = index height = 7.5in width = 9in;

proc sgplot data = fp.kopanskifinalmovies;
  vbar Genre / Response = ScoreDiff
               stat = median
               fillattrs = (color = cx7bccc4)
               outlineattrs = (color = cx7bccc4);
  xaxis valueattrs = (size = 12pt)
        labelattrs = (size = 16pt);
  yaxis valueattrs = (size = 12pt)
        labelattrs = (size = 16pt) 
        label = 'Median Score Difference (Rotten - Audience)';
run;

ods pdf close;
*end of script;
quit;
