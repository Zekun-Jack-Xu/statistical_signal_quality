%macro plothr(data, subjid);
	data plot;
	  set &data.(where=(subj=&subjid.));
	  keep Timesync_min hr truehr act ecgvx ecgllra ecgllla ecglara;
	run;
	
	proc sql noprint; select count(distinct act) into : ntimes
	   from plot ; quit;
	
	proc sql noprint; select distinct act into : actlabel
	   separated by ',' from plot ; quit;
	
	/*%put &actlabel;*/
	
	%do i = 1 %to &ntimes.;
	/*need to mask the space in the actlabel*/
		%let x=%scan(%bquote(&actlabel.),&i.,%str(,));
		
		data sub; 
		  set plot;
		  where act = "&x";
		  sec = _N_;
		 run;
		
		proc sgplot data=sub;
  			title "Subject &subjid : &x";
  			series x = sec y = hr / 
     			name = "bioharness" legendlabel = "BH" 
     			lineattrs=(pattern=solid color=red) ;
  			series x = sec y = truehr / 
     			name = "shimmer" legendlabel="True" 
     			lineattrs=(pattern=solid color=blue);
   			series x = sec y = ecgvx / 
     			name = "ecgvx" legendlabel="SH_VX" 
     			lineattrs=(pattern=shortdash color=green);
   			series x = sec y = ecglara / 
     			name = "ecglara" legendlabel="SH_LARA" 
     			lineattrs=(pattern=shortdash color=black);
   			series x = sec y = ecgllla / 
     			name = "ecgllla" legendlabel="SH_LLLA" 
     			lineattrs=(pattern=shortdash color=orange);
   			series x = sec y = ecgllra / 
     			name = "ecgllra" legendlabel="SH_LLRA" 
     			lineattrs=(pattern=shortdash color=purple);
  			xaxis label = "sec";
  			yaxis label = "bpm";
  			keylegend "bioharness" "shimmer" "ecgvx" "ecglara"
             "ecgllla" "ecgllra";
		run;
	%end;
	
%mend;