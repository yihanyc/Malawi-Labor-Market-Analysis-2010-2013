/*******************************************************************************
Program:    00_master.do
Note:		This file runs all the do files necessary for processing LSMS data for Malawi
Author:     Yihan Chen
*******************************************************************************/

*** Setup
	cls
	clear
	macro drop _all
	version 18
	set more off
	set linesize 255
	
*** Define global macros
	global ROOT "/Users/amazingruan/Downloads/GHDP7048/Malawi/LSMS"
	global IN "$ROOT/1_input"
	global Extra "$IN/MWI_2010_IHS-III_v01_M_STATA8"
	global Main "$IN/MWI_2010-2013_IHPS_v01_M_Stata"
	global DO "$ROOT/2_Code"
	global OUT "$ROOT/3_Output"

*** Create log file
	capture log close //close any log file, if open
	log using "$OUT/LSMS_log_file", smcl replace
	
*** Merge data
	do "$DO/1a_merge_LSMS1_IND.do"
	do "$DO/1b_merge_LSMS2_IND.do"
	do "$DO/1c_merge_LSMS1_HH.do"
	do "$DO/1d_merge_LSMS2_HH.do"
	do "$DO/1e_merge_LSMS_waves_IND.do"
	do "$DO/1f_merge_LSMS_waves_HH.do"


*** Generate descriptive statistics	
	do "$DO/2_descriptive_statistics.do"

*** Conduct analysis
	do "$DO/3_analysis.do"
	
*** Erase intermediate data files created earlier
	 erase "$OUT/individual_data_LSMS1.dta"
	 erase "$OUT/individual_data_LSMS2.dta"
	 erase "$OUT/hh_data_LSMS1.dta"
	 erase "$OUT/hh_data_LSMS2.dta"
	 
