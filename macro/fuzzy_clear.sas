%macro fuzzy_clear(ciname, powername, seed, ntimes, nsample, lb, ub, lambda,
         mu1, sd1, phi1, mu2, sd2, phi2);
      
      /*proc datasets lib=work nolist kill;
	  run; quit;*/

      proc iml;

		call randseed(&seed.);
	
   		*function to generate a single cluster of mixed ar(1) series;
   		start gen_level1(out, id, lb, ub, lambda,
   				mu1, sd1, phi1, mu2, sd2, phi2);
		
			*generate the length and weight;
			L = j(1,1);
			U1 = j(1,1);
			call randgen(L, "POISSON", lambda);
			call randgen(U1, "UNIFORM", lb, ub);
			labels = j(L, 1);
		
			*clusterid can only 1 or 2;
			if id = 1 then do;
				weight = U1; *prob of 1 against 0;
			    call randgen(labels, "BERN", weight); *dimension;
			end;
			else do;
			    weight = 1 - U1;
			    call randgen(labels, "BERN", weight);
			end;
		
			weight1 = j(L, 1, weight);
			weight2 = j(L, 1, 1-weight);
		
			clusterid = j(L, 1, id);
			temp = j(1,1);
			y = j(L, 1);
		
			*start generating the switching AR(1);
			do i = 1 to L;
			    if i = 1 then do;
			        if labels[i] = 1 then do;
			            call randgen(temp, "NORMAL", mu1, sd1);
			        end;
			        else do;
			            call randgen(temp, "NORMAL", mu2, sd2);
		 	       end;
		 	       y[i] = temp;
		 	   end;
		    
		 	   else do;
		  		  	if labels[i] = 1 then do;
		  		  	   if labels[i-1] = 1 then do;
		   		 	      call randgen(temp, "NORMAL", 0, sd1);
		    	 		  y[i] = mu1 + phi1*(y[i-1]-mu1) + temp;
		    	  	 end;
		    	  	 else do;
		    	  	    call randgen(temp, "NORMAL", mu1, sd1);
		    	  	    y[i] = temp;
		    	  	 end;
		    		end;
		    	
		    		else do;
		    			if labels[i-1] = 1 then do;
		    			    call randgen(temp, "NORMAL", mu2, sd2);
		    			    y[i] = temp;
		    			end;
		    			else do;
		    			    call randgen(temp,"NORMAL",0,sd2);
		    			    y[i] = mu2 + phi2 * (y[i-1]-mu2) + temp;
		    			end;
		    		end;
		    
		    	end;
		    
			end;            
			out = clusterid || labels || weight1 || weight2 || y;

   	finish;
   
  

   	*generate one simulation of alternating cluster series;
   	start gen_level2(dat, nsample, lb, ub, lambda,
   						mu1, sd1, phi1, mu2, sd2, phi2);
   
     	    do j = 1 to nsample;
      	       call gen_level1(dat1, 1, lb, ub, lambda,
      	            mu1, sd1, phi1, mu2, sd2, phi2);
          	   seriesid = j(nrow(dat1), 1, 2*j-1);
           	   dat1 = seriesid || dat1;
             
            	 call gen_level1(dat2, 2, lb, ub, lambda,
            	      mu1, sd1, phi1, mu2, sd2, phi2);
            	 seriesid = j(nrow(dat2), 1, 2*j);
            	 dat2 = seriesid || dat2;
             
             
             	if j = 1 then dat = dat1 // dat2;
             	else dat = dat // dat1 // dat2;
         	end;
   	finish;
   
 
   	*generate ntimes simulations;
		start gen_level3(cbind, ntimes, nsample, lb, ub, lambda,
   					mu1, sd1, phi1, mu2, sd2, phi2);
        	do i = 1 to ntimes;
           	call gen_level2(temp, nsample, lb, ub, lambda,
           	         mu1, sd1, phi1, mu2, sd2, phi2);
           	dim1 = nrow(temp);
           	temp_simid = repeat(i, dim1, 1); *one column of i;
           
           	if i = 1 then cbind = temp_simid || temp;
           	else do;
           	    temp_cbind = temp_simid || temp;
           	    cbind = cbind // temp_cbind;
           	end;
        	end;
   	finish;
   
   	call gen_level3(final, &ntimes., &nsample., &lb.,&ub., &lambda.,
         &mu1.,&sd1.,&phi1.,&mu2.,&sd2.,&phi2.);
   	varnames = {'simid' 'seriesid' 'cluster'
     	          'activity' 'weight1' 'weight2' 'y'} ;   * Create  a 1 x 2 array of labels ...;
   	create simdata from final [colname = varnames];  * V is an  n x 2 array ...;
   	append from final ;   
   	
	quit;

    /*end of proc iml, begin proc genmod*/
    /*power first*/
    *fuzzy comparison;
    proc genmod data=simdata;
 		by simid;
  		class seriesid;
  		model y =  / type3 alpha=0.05;
  	    weight weight1;
  		repeated  subject = seriesid / type = ar(1);
  		ods output GEEEmpPEst = parmest1;
	run;
 
	proc genmod data=simdata ;
 		 by simid;
  		class seriesid;
  		model y =  / type3 alpha=0.05;
  		weight weight2;
  		repeated  subject = seriesid / type = ar(1);
  		ods output GEEEmpPEst = parmest2;
		run;
 
		proc sql; create table fuzzy_compare as 
 			select a.simid, a.lowercl as lower1, a.uppercl as upper1,
        	b.lowercl as lower2, b.uppercl as upper2 from parmest1 as a
        	join parmest2 as b on a.simid = b.simid; quit;

		data fuzzy_compare;
 			set fuzzy_compare;
 			if lower1 > upper2 or lower2 > upper1 then reject = 1;
 			else reject = 0 ;
		run;
		
		proc freq data=fuzzy_compare; table reject / out=fuzzypower;  run;
		data fuzzypower; set fuzzypower; where reject = 1; type = 'fuzzy'; run;

        *clear comparison;
         proc genmod data=simdata ;
  			by simid;
  			class seriesid activity;
  			model y = activity / type3 noint alpha=0.05;
  			repeated  subject = seriesid / type = ar(1);
  			ods output GEEEmpPEst = parmest_both;
			run;
			
		data parmest_both1 parmest_both2;
 			set parmest_both;
 			if level1 = '0' then output parmest_both1;
 			if level1 = '1' then output parmest_both2;
		run;
		
		proc sql; create table clear_compare as  
   			select a.simid, a.lowercl as lower1, a.uppercl as upper1,
        		b.lowercl as lower2, b.uppercl as upper2 
        		from parmest_both (where= (level1='0')) as a
        		join parmest_both (where=(level1='1')) as b
        	on a.simid = b.simid; quit;
    
		data clear_compare;
 			set clear_compare;
 			if lower1 > upper2 or lower2 > upper1 then reject = 1;
 			else reject = 0 ;
			run;
		proc freq data=clear_compare; table reject / out=clearpower; run;
		data clearpower; set clearpower; where reject = 1; type = 'clear'; run;
        
        
		data &powername.;
		  set fuzzypower clearpower;
		run;
		
		/*confidence interval next*/
		%getquantile(a1, "fuzzy1", parmest1, 0.025, 0.975);
	    %getquantile(a2, "fuzzy2", parmest2, 0.025, 0.975);
        %getquantile(a3, "clear1", parmest_both2, 0.025, 0.975);
        %getquantile(a4, "clear2", parmest_both1, 0.025, 0.975);
        data &ciname.; set a1 a2 a3 a4; run;
        
        proc datasets nolist;
  		    delete a1 a2 a3 a4 clear_compare clearpower fuzzy_compare
  		    fuzzypower parmest_both parmest_both1 parmest_both2
  		    parmest1 parmest2 simdata;
        quit;
%mend;
