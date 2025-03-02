/*******************************************************************************
Program:    	2_descriptive_statistics.do
Note:			This file generates descriptive statistics for LSMS Waves 1 and 2
Author:     	Yihan Chen and Angela He
*******************************************************************************/

******** Create A Unique Identifer for Household Level ***********
	use "$OUT/LSMS_all_households", clear
	rename HHID hhid
**Note: for the sub-households (or the split households) in Wave 2 that shares the same HHID, I instead construct a new wave in order to make xtset function work. In this case, the newwaves (starting from 3) would represent the split households, while the 2s are the original households in wave 2. 
	sort hhid wave
	gen newwave = wave
	bysort hhid (wave): replace newwave = _n if wave == 2
	rename wave oldwave
	rename newwave wave
	drop if wave >2

*** Collapse: from household to individual level ***********	
*	use "$OUT/LSMS_all_households", clear
*	duplicates report hhid wave  // Check how many duplicates exist
*	duplicates list hhid wave 
***********************************************************************************
* Economic Status & Poverty Indicators
***********************************************************************************
******* consHH consPC foodConsPC borrowCredit poor2010 ePoor2010 poor2013 ePoor2013 
***********************************************************************************
* Outcome variable for non-agriculture business: nonAgriBiz
***********************************************************************************
***********************************************************************************
* Location: rural region
***********************************************************************************
***********************************************************************************
* Household Satisfaction: selfFood selfHouse selfCloth selfHealth 
***********************************************************************************
***********************************************************************************
* Other Facilities: comBank microFinance mpVisit roadDistance
***********************************************************************************
	keep hhid wave consHH consPC foodConsPC borrowCredit poor2010 ePoor2010 poor2013 ePoor2013 nonAgriBiz rural region selfFood selfHouse selfCloth selfHealth comBank microFinance mpVisit roadDistance
	tempfile fromhousehold
	save `fromhousehold', replace  
***********************************************************************************
* Merge those from the household level
***********************************************************************************
	use "$OUT/LSMS_all_individuals", clear
	merge m:1 hhid wave using `fromhousehold'
	drop _merge
	
	gen labor12mnew = 0  
	replace labor12mnew = 1 if labor12m == 1 | nonAgriBiz == 1
	replace labor12m = . if missing(labor12m) & missing(nonAgriBiz)
	label variable labor12mnew "Employed in the last 12 months (wage, apprentice, ganyu, other unpaid, non-agri business)"
	label values labor12mnew yesno


	save "$OUT/LSMS_all_individuals", replace
	
	
	
	
*** Summary statistics at the individual level
	use "$OUT/LSMS_all_individuals", clear
	isid indid wave
	***	Panel Data
	xtset indid wave //Describe the panel structure of dataset
	xtdescribe //Summarize how frequently observations appear over the panel

*** Generate summary statistics (alternative methods)
	summarize
	describe
	describe, short
	
* Summary table by year	for non-categorical variables in both waves
	forvalues i =1/2{
		di "Wave = " `i'
		su female age tempHealthStop  hoursWage7d        if wave== `i'
	}
	
* Summary table by variable for non-categorical variables in both waves
	foreach i of varlist female age tempHealthStop  hoursWage7d {
		di "Variable = " "`i'" ", Wave=1"
		su `i' if wave== 1
		
		di "Variable = " "`i'" ", Wave=2"
		su `i' if wave== 2
	}

** Summary table by variable for categorical variables in both waves
****** Demographics & Education & Health & Economics *****
	foreach i of varlist maritalStatus religion under15 relToHHH highestEdu illness2weeks chronicIllness economicHardship {
		di "Variable = " "`i'" ", Wave=1"
		tab `i' if wave==1, missing
		
		di "Variable = " "`i'" ", Wave=2"
		tab `i' if wave==2, missing
	}

****** Time Use & Labor ******
		foreach i of varlist work7days jobseek reasonNoWork SecEmployed12m employerType {
		di "Variable = " "`i'" ", Wave=1"
		tab `i' if wave==1, missing
		
		di "Variable = " "`i'" ", Wave=2"
		tab `i' if wave==2, missing
	}

****** Variables only recorded in wave 2 ******
		foreach i of varlist econ12mo agriWork12m econActivityPrim econActivitySec {
		di "Variable = " "`i'" ", Wave=1"
		tab `i' if wave==1, missing
		
		di "Variable = " "`i'" ", Wave=2"
		tab `i' if wave==2, missing
	}	

*** Compare Literacy
	ssc install tab3way
	tab3way readChichewa readEnglish wave
	
	
	
	

*Descriptive data for household data in LSMS Waves 1 and 2.


	use "$OUT/LSMS_all_households", clear
	rename HHID hhid
**Note: for the sub-households (or the split households) in Wave 2 that shares the same HHID, I instead construct a new wave in order to make xtset function work. In this case, the newwaves (starting from 3) would represent the split households, while the 2s are the original households in wave 2. 
	sort hhid wave
	gen newwave = wave
	bysort hhid (wave): replace newwave = _n if wave == 2
	
xtset hhid newwave

xtdescribe


**Other summary statistics at the household level (between wave 1 and 2): 
codebook rural region consPC foodConsPC borrowCredit houseOwned nonAgriBiz selfFood selfHouse selfCloth selfHealth valuePlots schoolElectrified comBank microFinance mpVisit roadDistance poor2010 ePoor2010 if wave==1, c
codebook rural region hhsize consPC foodConsPC borrowCredit houseOwned nonAgriBiz selfFood selfHouse selfCloth selfHealth valuePlots poor2013 ePoor2013 if wave==2, c
