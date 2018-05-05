%macro analysis1(subjid, labels, fuzzy_ci, pdf, clear = 1);

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

    %if &clear. = 1 %then %do;
	    proc genmod data=merge;
			class true_id true_label;
			model logy = true_label / type3;
			repeated  subject = true_id / type = ar(1);
			lsmeans true_label / cl ; *adjust=tukey;
			ods output lsmeans=clear_ci&subjid;
	    run;
	    data clear_ci&subjid; 
	      set clear_ci&subjid;
	      act_n = true_label;
	      act_c = put(true_label, actfmt.);
	      mae = exp(estimate); 
	      lcl = exp(lower); ucl = exp(upper); 
	      keep act_n act_c mae lcl ucl;
	    run; 
	    
	    ods pdf file = "&pdf";
        title "Confusion matrix and 95% confidence interval for subject &subjid";
	    proc freq data=subset;
	   		tables pred_act * true_act / nopercent nofreq nocol;
	    run;
	    
	    ods escapechar="^";
	    ods pdf text="^{newline 5}";
	    ods startpage=no;
	    
	    proc sql; select a.act_c, a.mae as clear_mae, a.lcl as clear_lcl,
	    a.ucl as clear_ucl, b.mae as fuzzy_mae, b.lcl as fuzzy_lcl,
	    b.ucl as fuzzy_ucl from clear_ci&subjid as a 
	    join &fuzzy_ci as b on a.act_c = b.act_c order by a.mae asc; quit;
	    
	    %plothr(data1, &subjid.);
	    
	    ods pdf close;
	%end;
    
    proc datasets nolist;
  		delete subset confusion confusion1 merge temp plot sub;
    quit;
    
%mend;