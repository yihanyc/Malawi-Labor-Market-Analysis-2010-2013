/*******************************************************************************
Program:    	1e_merge_LSMS_waves_IND.do
Note:			This file appends individual-level variables from Waves 1 and 2 of LSMS 
Author:     	Yihan Chen
*******************************************************************************/
	use "$OUT/individual_data_LSMS1", clear
	append using "$OUT/individual_data_LSMS2"
	
	* Label variables

	lab data "Individual-level variables from LSMS1 and LSMS1"
	lab var wave "Wave: 1=2010, 2=2013"
	destring indid, replace
	order hhid indid wave 
	save "$OUT/LSMS_all_individuals", replace
	

