%macro getquantile(out,type,dataset,ql,qu);
	proc iml;
		use &dataset.;
		read all var {estimate} into x;
		close &dataset.;
		call qntl(myq, x, {&ql., &qu.});
		quantiles = myq`;
		
		varnames = {'lower','upper'} ;   * Create  a 1 x 2 array of labels ...;
   	    create &out. from quantiles [colname = varnames];  * V is an  n x 2 array ...;
   	    append from quantiles;  
   	    
	quit;
	
	data &out.;
   	       set &out.;
   	       type = &type.;
   	run;
%mend;
