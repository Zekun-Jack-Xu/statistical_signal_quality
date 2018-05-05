/*wGEE method for clear and fuzzy comparison on hr reliability
on the test subset in ADL data for 8 subjects*/

/*change to the corresponding macro folder*/
options implmac mautosource mrecall 
	sasautos = ('/folders/myfolders/ece/macro');


/*change to the corresponding file name for reliability.csv*/
proc import out = data1 datafile = "/folders/myfolders/ece/reliability.csv" dbms =csv replace;
  getnames = yes;
  datarow = 2;
  guessingrows=32767;
run;

proc format;
  value actfmt 1 = 'walking'
               2 = 'rowing'
               4 = 'bicycling'
               7 = 'typing'
               9 = 'resting'
               10 = 'laying'
               other = 'others';
  value tick2x 1 = 'rowing' 2 = 'typing' 3 = 'laying'
                4 = 'resting' 5 = 'bicycling' 6 = 'walking' 7 = 'other';
  invalue back 'rowing' = 1 'typing' = 2 'laying' = 3 
           'resting' = 4 'bicycling' = 5  'walking' = 6 other = 7; 
run;

/******************************/
/*compute the summary file for each subject*/
/*1.confusion matrix; 2. confidence interval; 3. heart rate plot*/

/*the labels are the cluster state learned from unsupervised model
in the reliability.csv*/

/*make sure to change the pdf filenames*/
%let labels = 1 2 3 4 7 9 10;
%analysis1(subjid=15, labels=&labels., fuzzy_ci=fuzzy_ci15, 
	pdf=/folders/myfolders/ece/subj15.pdf, clear=1);
%analysis1(subjid=59, labels=&labels., fuzzy_ci=fuzzy_ci59, 
	pdf=/folders/myfolders/ece/subj59.pdf,clear=1);
%analysis1(subjid=805, labels=&labels., fuzzy_ci=fuzzy_ci805, 
	pdf=/folders/myfolders/ece/subj805.pdf, clear=1);
%analysis1(subjid=274, labels=&labels., fuzzy_ci=fuzzy_ci274, 
	pdf=/folders/myfolders/ece/subj274.pdf, clear=1);
%analysis1(subjid=380, labels=&labels., fuzzy_ci=fuzzy_ci380, 
	pdf=/folders/myfolders/ece/subj380.pdf, clear=1);
	
%analysis1(subjid=454, labels=&labels., fuzzy_ci=fuzzy_ci454, 
	pdf=/folders/myfolders/ece/subj454.pdf, clear=1);
%analysis1(subjid=503, labels=&labels., fuzzy_ci=fuzzy_ci503, 
	pdf=/folders/myfolders/ece/subj503.pdf, clear=1);
%analysis1(subjid=875, labels=&labels., fuzzy_ci=fuzzy_ci875, 
	pdf=/folders/myfolders/ece/subj875.pdf, clear=1);

%analysis1(subjid=292, labels=&labels., fuzzy_ci=fuzzy_ci292, 
	pdf=/folders/myfolders/ece/subj292.pdf, clear=1);
%analysis1(subjid=390, labels=&labels., fuzzy_ci=fuzzy_ci390, 
	pdf=/folders/myfolders/ece/subj390.pdf, clear=1);


/***********plot the confidence intervals************/
/*see the last plot in each subject's SAS output*/
%ciplot(15,&labels.,fuzzyout);
%ciplot(59,&labels.,fuzzyout);
%ciplot(805,&labels.,fuzzyout);
%ciplot(274,&labels.,fuzzyout);
%ciplot(380,&labels.,fuzzyout);
%ciplot(454,&labels.,fuzzyout);
%ciplot(503,&labels.,fuzzyout);
%ciplot(875,&labels.,fuzzyout);

