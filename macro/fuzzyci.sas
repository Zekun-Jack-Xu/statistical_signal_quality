%macro fuzzyci(data, labels, times, outdata);
	
    %do i = 1 %to &times.;
       %let x=%scan(&labels.,&i.);
       
       %if &i = 1 %then %do;
       
         proc genmod data=&data.;
			class pred_id;
			model logy =  / type3;
			weight weight&x;
			repeated  subject = pred_id / type = ar(1);
			ods output GEEEmpPEst = &outdata.;
	     run;
	     
	     data &outdata.; 
	         set &outdata.; act_n = &x; 
	         act_c = put(act_n, actfmt.);
	         lcl = exp(lowercl); ucl = exp(uppercl); 
	         mae = exp(estimate);       
	         keep act_n act_c mae lcl ucl; 
	     run;
	     
	    %end;
	    %else %do;
	    
	    	proc genmod data=&data.;
			  class pred_id ;
			  model logy =  / type3;
			  weight weight&x;
			  repeated  subject = pred_id / type = ar(1);
			  ods output GEEEmpPEst = temp;
	        run;
	        
	        data temp; 
	         set temp; act_n = &x; 
	         act_c = put(act_n, actfmt.);
	         lcl = exp(lowercl); ucl = exp(uppercl); 
	         mae = exp(estimate);       
	         keep act_n act_c mae lcl ucl; 
	        run;
	        
	        data &outdata.; set &outdata. temp; run;
	        
	    %end;
    
    %end;
%mend;