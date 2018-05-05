/*settings:
2 activities: running, walking
2 clusters

U1 ~ U(lb, ub)
confusion matrix for running and walking:
			{U1 1-U1, 
			 1-U1 U1}
			 
length of each cluster: L ~ POISSON(lambda)

repetition: nsample

simulation: ntimes

ARMA parameters: phi(ar), theta(ma), mu, sigma (sd)

%let ciname=ci25;
%let powername=power25;
%let  seed=13;
%let  ntimes=500;
%let nsample=25;
%let lb=0.7;
%let ub=0.9;
%let lambda=10;
%let mu1=-0.5;
%let sd1=1;
%let phi1=0.2;
%let mu2=0.5;
%let sd2=1.5;
%let phi2=0.1;
*/

/*change to the corresponding macro folder*/
options implmac mautosource mrecall 
	sasautos = ('/folders/myfolders/ece/macro');

/*****************************************************/
*1000 simulations break for nsample >= 25...;
%fuzzy_clear(ciname=ci5, powername=power5, seed=13, 
     ntimes=500, nsample=5, lb=0.7, ub=0.9, lambda=10,
         mu1=-0.5, sd1=1, phi1=0.2, mu2=0.5, sd2=1.5, phi2=0.1);
*power (f/c): 0.064, 0.85;
*ci (f12/c12):
-0.465588586	0.1640497559
-0.153810527	0.551992452	
-0.796689852	-0.105766457		
0.0508016082	0.9127550248	
; 
%fuzzy_clear(ciname=ci10, powername=power10, seed=13, 
     ntimes=500, nsample=10, lb=0.7, ub=0.9, lambda=10,
         mu1=-0.5, sd1=1, phi1=0.2, mu2=0.5, sd2=1.5, phi2=0.1);
*power (f/c): 0.214, 0.99;
*ci (f12/c12):
-0.396208808	0.0453726363
-0.072451682	0.4527915475	
-0.701573521	-0.269887804		
0.1883751035	0.8329576293	
; 
%fuzzy_clear(ciname=ci15, powername=power15, seed=13, 
     ntimes=500, nsample=15, lb=0.7, ub=0.9, lambda=10,
         mu1=-0.5, sd1=1, phi1=0.2, mu2=0.5, sd2=1.5, phi2=0.1);
*power: 0.442, 0.998;
*ci: -0.354264291	0.0003754352
     -0.014763885	0.3928935285	
     -0.662382286	-0.30134417
     0.2684373187	0.7487675124	
;         
%fuzzy_clear(ciname=ci20, powername=power20, seed=13, 
     ntimes=500, nsample=20, lb=0.7, ub=0.9, lambda=10,
         mu1=-0.5, sd1=1, phi1=0.2, mu2=0.5, sd2=1.5, phi2=0.1);
 *power: 0.638, 1;
*ci: -0.326209528	-0.027546131
     0.006607133	0.362632977
     -0.65364138	-0.324755243
     0.2936913089	0.7078310316
 ;            
%fuzzy_clear(ciname=ci25, powername=power25, seed=13, 
         ntimes=500, nsample=25, lb=0.7, ub=0.9, lambda=10,
         mu1=-0.5, sd1=1, phi1=0.2, mu2=0.5, sd2=1.5, phi2=0.1);
   *power: 0.778, 1;
*ci: -0.320434725	-0.04439942
     0.0390740995	0.3540049022
     -0.632512253	-0.338261533
     0.2926877216	0.6931839788;  
%fuzzy_clear(ciname=ci30, powername=power30, seed=13, 
     ntimes=500, nsample=30, lb=0.7, ub=0.9, lambda=10,
        mu1=-0.5, sd1=1, phi1=0.2, mu2=0.5, sd2=1.5, phi2=0.1);
 *power:  0.892, 1      
 *ci: -0.304372499	-0.051517892
	  0.056047341	0.3348661826
	  -0.606421301	-0.354833944	
	  0.3262871482	0.6764526545
	  ;
	  
/*plot those power and confidence interval*/
data power5; set power5; n=5; run;
data power10; set power10; n=10; run;
data power15; set power15; n=15; run;
data power20; set power20; n=20; run;
data power25; set power25; n=25; run;
data power30; set power30; n=30; run;

libname this "/folders/myfolders/ece";
data this.power; 
	set power5 power10 power15 power20 power25 power30; 
	if type = "fuzzy" then typelab = "Activity unknown";
	else typelab = "Activity known";
run;


ods graphics on / ATTRPRIORITY=NONE; 
proc sgplot data=this.power;
	styleattrs  
     	datacontrastcolors=(green red) 
     	datalinepatterns=(dot solid)
     	datasymbols = (diamondfilled circlefilled);
   scatter x=n y=percent / group=typelab;
   series x=n y=percent / group=typelab 
             name = "typelab" legendlabel="Scenario";
   xaxis label = "Sample size" labelattrs=(size=24) 
         valueattrs=(size=13);
   yaxis label = "Power" labelattrs=(size=24) 
         valueattrs=(size=13);
   keylegend "typelab" / location = inside position=bottom 
                         down=1 noborder titleattrs=(size=13)
                         valueattrs=(size=13);
run;


data ci5; set ci5; n=5; run;
data ci10; set ci10; n=10; run;
data ci15; set ci15; n=15; run;
data ci20; set ci20; n=20; run;
data ci25; set ci25; n=25; run;
data ci30; set ci30; n=30; run;

libname this "/folders/myfolders/ece";
data this.ci; 
	set ci5 ci10 ci15 ci20 ci25 ci30; 
	temp = substr(type, length(type),1);
	est = (lower + upper) / 2;
	length act $15.;
	if temp = '1' then do ;
	        x = n-0.5;
	        act = "Low intensity";
	end;
	if temp = '2' then do;
	        x = n+0.5;
	        act = "High intensity";
	end;
	if substr(type, 1, 1) = "f" then typelab = "Activity unknown";
	else typelab = "Activity known";
	
	drop temp;
run;



proc format; 
    value tickx 5 = "5" 10 = "10" 15 = "15" 20 = "20"
          25 = "25" 30 = "30";
run;




ods graphics on / ATTRPRIORITY=NONE; 
proc sgpanel data=this.ci;
	panelby typelab / columns=1 novarname spacing=1;
	styleattrs  
     	datacontrastcolors=(green red) 
     	datalinepatterns=(dot solid)
     	datasymbols = (diamondfilled circlefilled);
   scatter x=x y=est / yerrorlower = lower yerrorupper = upper
       group=act  name = "act" legendlabel="Activity";
   colaxis label = "Sample size" labelattrs=(size=18) 
         valueattrs=(size=13) values=(5 to 30 by 5) 
         offsetmax=0.08  offsetmin=0.08
         tickvalueformat=tickx.;
   rowaxis label = "Log absolute error" labelattrs=(size=18) 
         valueattrs=(size=13);
   keylegend "act" / position=bottom 
                         down=1 noborder titleattrs=(size=13)
                         valueattrs=(size=13);
run;
