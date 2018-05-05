/*macro to plot confidence intervals from poisson regression*/
%macro anomaly_plot(subjid, inputdat);
	proc genmod data=&inputdat.(where=(subject=&subjid.));
	  class label;
	  model anomaly_freq = label / dist   = poisson 
	         noint  link   = log   offset = logtime  type3;
	  ods output parameterestimates = parm;
	run;


	data parm1;
	 set parm(keep = level1 estimate lowerwaldcl upperwaldcl);
	 where not missing(level1);
	 est = exp(estimate) * 60;
	 lower = exp(lowerwaldcl) * 60;
	 upper = exp(upperwaldcl) * 60;
	 x = input(level1, backx.);
	 keep x level1 est lower upper;
	run;

	title "The 95% confidence intervals of mean anomalies per minute for Subject &subjid.";
	proc sgplot data=parm1;
		styleattrs  
     		datacontrastcolors=(green red) 
     		datalinepatterns=(dot solid)
     		datasymbols = (diamondfilled circlefilled);
   		scatter x=x y=est / yerrorlower = lower yerrorupper = upper;
       		/*name = "typelab" legendlabel="Activity";*/
   		xaxis display=(nolabel) labelattrs=(size=18) 
         	valueattrs=(size=13) values=(1 to 10 by 1) 
         	offsetmax=0.08  offsetmin=0.08 fitpolicy=rotate
         	tickvalueformat=tickxx.;
   		yaxis label = "Anomalies per minute" labelattrs=(size=18) 
         	valueattrs=(size=13);
   		/*keylegend "typelab" / position=bottom 
                         down=1 noborder titleattrs=(size=13)
                         valueattrs=(size=13);*/
	run;
	
	proc datasets nolist; delete parm parm1; run;
%mend;
