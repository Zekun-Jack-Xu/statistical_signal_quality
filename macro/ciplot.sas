%macro ciplot(subjid, labels, fuzzy_ci);
	 
       data subset;
         set data1 (where=(subj=&subjid.));
  		 true_act = put(true_label, actfmt.);
  		 pred_act = put(pred_label, actfmt.);
  		 keep true_label pred_label true_act pred_act 
       		 subj logy true_id pred_id;
	   run;

    
    proc freq data=subset;
   		tables pred_label * true_label / nopercent nofreq nocol;
  	    ods output crosstabfreqs = confusion;
    run;
    
    proc sql; create table confusion1 as 
   		select pred_label, true_label, rowpercent/100 as weight from confusion
   		where rowpercent is not null; quit;

    %genweightcol(subset,confusion1,&labels,merge);
    
    %fuzzyci(merge, &labels, 7, &fuzzy_ci);

	  proc genmod data=merge;
			class true_id true_label;
			model logy = true_label / type3;
			repeated  subject = true_id / type = ar(1);
			lsmeans true_label / cl ; *adjust=tukey;
			ods output lsmeans=lsmeans;
	  run;
       
	
	data clear;
   		set lsmeans;
   		act_n = true_label;
   		act_c = put(true_label, actfmt.);
   		lcl = exp(lower);
   		ucl = exp(upper);
   		mae = exp(estimate);
   		typelab = "Activity known";
   		keep act_n act_c lcl ucl mae typelab;
	run;

	data fuzzy; set &fuzzy_ci.; typelab = "Activity unknown"; run;
	

	data cidata; 		
		set fuzzy clear;
		temp = input(act_c, back.);
		if typelab = 'Activity unknown' then x = temp - 0.1;
		else x = temp + 0.1;
	run;    
	
	ods graphics on / ATTRPRIORITY=NONE; 
	title "The 95% confidence intervals of Bioharness heart rate quality for Subject &subjid.";
	proc sgplot data=cidata;
		styleattrs  
     		datacontrastcolors=(green red) 
     		datalinepatterns=(dot solid)
     		datasymbols = (diamondfilled circlefilled);
   		scatter x=x y=mae / yerrorlower = lcl yerrorupper = ucl
       		group=typelab  name = "typelab" legendlabel="Scenario";
   		xaxis display=(nolabel) labelattrs=(size=18) 
         	valueattrs=(size=13) values=(1 to 7 by 1) 
         	offsetmax=0.08  offsetmin=0.08 fitpolicy=rotate
         	tickvalueformat=tick2x.;
   		yaxis label = "Absolute error" labelattrs=(size=18) 
         	valueattrs=(size=13);
   		keylegend "typelab" / position=bottom 
                         down=1 noborder titleattrs=(size=13)
                         valueattrs=(size=13);
	run;
	
	proc datasets nolist;
  		delete cidata clear confusion confusion1 fuzzy fuzzyout lsmeans 
  		temp subset merge;
    quit;
%mend;