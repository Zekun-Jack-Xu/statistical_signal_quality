/*analyze the anomaly count data*/

/*change to the corresponding macro folder*/
options implmac mautosource mrecall 
	sasautos = ('/folders/myfolders/ece/macro');


proc import out = data1 datafile = "/folders/myfolders/ece/anomaly.csv" dbms =csv replace;
  getnames = yes;
  datarow = 2;
run;


proc format;
  invalue backx 'rowing' = 1 'typing' = 2 'laying' = 3 
           'rest' = 4 'bicycle' = 5  'walk' = 6 
           'drinking' = 7 'Cleaning up' = 8 'Setting dinner' = 9 
           'carrying the box' = 10; 
  value tickxx 1 = 'rowing' 2 = 'typing' 3 = 'laying'
       4 = 'rest' 5 = 'bicycle' 6 = 'walk'
       7 = 'drinking' 8 = 'Cleaning up' 9 = 'Setting dinner'
       10 = 'carring the box';
run;


data data2; 
    set data1;
    *where anomaly_freq > 0;
	where Label ^= 'sync';
    seconds = minutes * 60;
    logtime = log(seconds);
    label subject = "Subject ID"
    	  anomaly_freq = "# of Anomalies"
    	  seconds = "Duration (sec)"
    	  label = "Activity";
run;

proc sort data=data2; by subject label; run;

/*aggregate the same activities together*/
data data3;
  set data2(keep=subject label anomaly_freq seconds);
  by subject label;
  retain sum_anomaly sum_second 0;
  if first.label then do;
     sum_anomaly = anomaly_freq;
     sum_second = seconds;
  end;
  else;
  	 sum_anomaly = sum_anomaly + anomaly_freq;
  	 sum_second = sum_second + seconds;
  
  intensity = sum_anomaly / sum_second;
  if last.label then output;
  
  label subject = "Subject ID"
  		  intensity = "Anomaly/sec"
    	  sum_anomaly = "#Anomalies"
    	  sum_second = "Duration(sec)"
    	  label = "Activity";
run;

/*print the anomaly counts*/
/*change the output pdf file name*/
ods pdf file='/folders/myfolders/ece/anomaly.pdf';
proc sort data=data3;/*(where=(subject not in (292, 390)))*/
   by subject intensity descending sum_second; 
run;
proc print data=data3 noobs label;
    by subject; 
    var subject label sum_second sum_anomaly intensity;
run;
ods pdf close;

/*plot the confidence interval for the mean number of anomalies per minute*/
%anomaly_plot(15,data2);
%anomaly_plot(59,data2);
%anomaly_plot(274,data2);
%anomaly_plot(292,data2);
%anomaly_plot(380,data2);
%anomaly_plot(390,data2);
%anomaly_plot(454,data2);
%anomaly_plot(503,data2);
%anomaly_plot(805,data2);
%anomaly_plot(875,data2);