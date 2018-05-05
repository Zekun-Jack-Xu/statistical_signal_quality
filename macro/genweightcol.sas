%macro genweightcol(data, weight, labels, outdata);

   proc sql; select count(distinct true_label) 
       into: dim from &weight.; quit;
       
   %do i = 1 %to &dim.;
   		%let x=%scan(&labels.,&i.);
   		/*%put &x;*/
   		/*only full comment allowed in macro*/
   		%if &i. = 1 %then %do;
   		    proc sql; create table &outdata. as  
    			select a.*, b.weight as weight&x from &data. as a
    			left join &weight. (where=(true_label = &x)) as b 
    			on a.pred_label = b.pred_label; quit;
    		/*proc freq data=merge; tables weight1; run;*/
   		%end;
   		%else %do;
   			proc sql; create table &outdata. as
   			   select a.*, b.weight as weight&x from &outdata. as a
   			   left join &weight. (where=(true_label = &x)) as b 
   			   on a.pred_label = b.pred_label; quit;
   		%end;
   
   %end;
%mend;