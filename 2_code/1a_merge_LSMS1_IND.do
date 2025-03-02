/*******************************************************************************
Program:    	1a_merge_LSMS1_IND.do
Note:			This file merges all the relevant individual-level variables in LSMS Wave 1, Malawi
Author:     	Yihan Chen
*******************************************************************************/

***********************************************************************************
* Demographics
***********************************************************************************
	* Demographics
	use "$Main/HH_MOD_B_10.dta", clear
	ren (HHID PID hh_b03 hh_b05a hh_b04 hh_b23 hh_b24) (hhid pid female age relToHHH religion maritalStatus)
	des hhid pid female age relToHHH religion maritalStatus
** recode variables
	recode female (1=0)(2=1)
	recode religion (3=1)(4=2)(1 2 5=3)
	recode maritalStatus (1 2=1)(3 4=2)(5=3)(6=4)
	recode relToHHH (1=1)(2=2)(3=3)(4=4)(5 7 8 9 6 10 11 12 13 14 15 16=5)
** drop value labels
	lab val female . //Drop existing value label "." or something else
	lab val religion .
	lab val maritalStatus .
	lab val relToHHH .
** label variables
	label variable female "Sex is female"
	label variable religion "Religion practiced if any"
	label variable maritalStatus "Marital Status"
** label values
	label define genderlbl 1 "Female" 0 "Male" 
	label values female genderlbl
	label define religionlbl 1 "Christianity" 2 "Islam" 3 "Other/Minor Religions"
	label values religion religionlbl
	label define maritallbl 1 "Married" 2 "Separated/Divorced" 3 "Widowed" 4 "Never Married"
	label values maritalStatus maritallbl
	label define relToHHHlbl 1 "Household Head" ///
                          2 "Spouse" ///
                          3 "Child" ///
                          4 "Grandchild" ///
                          5 "Other Non-Core Members"
	label values relToHHH relToHHHlbl					 
** create a tempfile
	keep hhid pid female age relToHHH religion maritalStatus
	tempfile lsms1indiv
	save `lsms1indiv', replace

***********************************************************************************
* Education
***********************************************************************************
	use "$Main/HH_MOD_C_10.dta", clear
	rename (HHID PID hh_c09 hh_c05a hh_c05b) (hhid pid highestEdu readChichewa readEnglish)
	des hhid pid highestEdu readChichewa readEnglish
** recode variables
	recode highestEdu ///
    (1=0) ///        None
    (2=1) ///        PSLC (Primary School Leaving Certificate)
    (3 4=2) ///      JCE and MSCE (Junior and Malawi School Certificates)
    (5 6 7=3) ///    Non-Univ Diploma, Univer Diploma, Postgrad degree
    (.=.)                                           
	recode readChichewa (2=0)
	recode readEnglish (2=0)
** relabel values
	label define eduLbl 0 "None" 1 "Primary" 2 "Secondary" 3 "Tertiary"
	label values highestEdu eduLbl
	label define yesno 1 "Yes" 0 "No" 
	label values readChichewa yesno
	label values readEnglish yesno
	
** create a tempfile
	keep hhid pid highestEdu readChichewa readEnglish 
	tempfile education
	save `education', replace
	
***********************************************************************************
* Health
***********************************************************************************
	use "$Main/HH_MOD_D_10.dta", clear
	rename (HHID PID hh_d04 hh_d37 hh_d33 hh_d17 hh_d08) (hhid pid illness2weeks under15 chronicIllness economicHardship tempHealthStop)
	des hhid pid illness2weeks under15 chronicIllness economicHardship tempHealthStop
	recode illness2weeks (2=0)
	label define yesno 1 "Yes" 0 "No" 
	label values illness2weeks yesno
	recode under15 (2=0)
	label values under15 yesno
	recode chronicIllness (2=0)
	label values chronicIllness yesno
	recode economicHardship (2=0)
	label values economicHardship yesno
	label variable tempHealthStop "During the past 2 weeks, for how many days did you have to stop your normal activities because of this (these) illness(es)?"
	keep hhid pid illness2weeks under15 chronicIllness economicHardship tempHealthStop
	tempfile health
	save `health', replace
	
***********************************************************************************
* Time Use & Labor
***********************************************************************************
	use "$Main/HH_MOD_E_10.dta", clear
	rename (HHID PID hh_e13 hh_e16 hh_e07 hh_e11 hh_e15 hh_e21) (hhid pid work7days jobseek hAgriculture7d hoursWage7d reasonNoWork employerType)
	* Outcome variables
	rename (hh_e18 hh_e32 hh_e46 hh_e55 hh_e60) (wageEmploy12m SecEmployed12m apprentice12m ganyu12m farm12m)
	
	recode work7days (2=0)
	recode jobseek (2=0)
	recode SecEmployed12m (2=0)
	recode wageEmploy12m (2=0)
	recode apprentice12m (2=0)
	recode ganyu12m (2=0)
	recode farm12m (2=0)
	label define yesno 1 "Yes" 0 "No" 
	label values work7days yesno
	label values jobseek yesno
	label values wageEmploy12m yesno
	label values SecEmployed12m yesno
	label values apprentice12m yesno
	label values ganyu12m yesno
	label values farm12m yesno
	
	gen labor12m = 0  
	replace labor12m = 1 if wageEmploy12m == 1 | apprentice12m == 1 | ganyu12m == 1 | farm12m == 1
	replace labor12m = . if missing(wageEmploy12m) & missing(apprentice12m) & missing(ganyu12m) & missing(farm12m)
	label variable labor12m "Employed in the last 12 months (wage, apprentice, ganyu, other unpaid)"
	label values labor12m yesno
	
	keep hhid pid work7days jobseek hAgriculture7d hoursWage7d reasonNoWork employerType wageEmploy12m SecEmployed12m apprentice12m ganyu12m farm12m labor12m
	tempfile labor
	save `labor', replace
	
***********************************************************************************
* Merge all data and clean up
***********************************************************************************
	use `lsms1indiv', clear
	merge 1:1 hhid pid using `education', nogen
	merge 1:1 hhid pid using `health', nogen
	merge 1:1 hhid pid using `labor', nogen
	ren (hhid pid ) (y1_hhid indidy1) //rename variables for merging unique individual ID
	save `lsms1indiv', replace
	generate wave = 1
	rename (y1_hhid indidy1) (hhid indid)
	des

	save "$OUT/individual_data_LSMS1", replace
