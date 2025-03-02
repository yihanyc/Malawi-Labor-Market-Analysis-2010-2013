/*******************************************************************************
Program:    	1d_merge_LSMS2_HH.do
Note:			This file merges all household variables in LSMS wave 2, Malawi
Author:     	Yihan Chen
*******************************************************************************/


***************Household demographics: urban/rural, region (north/center/south)
use "$Main/HH_MOD_A_FILT_13.dta", clear

**Note: for the HHID, there are duplicates, but potentially because of they have moved to different region (or other reasons), i.e. the duplicated HHIDs do not contain repeated info. 

*i. Variable: urban or rural
codebook reside
tab reside
*original: 1= urban, 2 = rural
*rename urban/rural variable
rename reside rural
recode rural (2=1) (1=0)
label define reg_lbl 0 "urban" 1 "rural"
label values rural reg_lbl
tab rural

*ii. Variable: region, 1= North, 2= Central, 3= South, no need to edit

*iii. Variable: hhsize (not mentioned in 2010, but we will keep it)

*iv. Variable: borrow on credit in the past 12 months?
codebook hh_s01
tab hh_s01
*original: 2 = no, 1 = yes, . = missing, and we will categorize them as no. 

rename hh_s01 borrowCredit
recode borrowCredit (2=0) (1=1) (.=0)
label define r_lbl 0 "No" 1 "Yes"
label value borrowCredit r_lbl
tab borrowCredit

keep HHID y2_hhid case_id ea_id rural stratum region hhsize borrowCredit
tempfile lsms2hh
save `lsms2hh', replace
*****************************************************************


*Household consumption/consumption per capita in wave 2
use "$Main/Round 2 (2013) Consumption Aggregate.dta", clear 

**rename variable: consumption per household/consumption per capita
codebook rexpagg pcrexpagg
*For consumption per household, the maximum value is 15668025, but it is a household of 8; 
*For consumption per capita, the maximum value is 3716532.5, and it is a one-person household, so both are just regular outliers (not excessive), and we will keep the data as it is. 
rename (rexpagg pcrexpagg) (consHH consPC)

**rename variable: food/beverage per household/per capita
rename (rexp_cat01 pcrexp_cat01)(foodConsHH foodConsPC)

**rename variable: poor/extreme poor threshold
rename (absolute_povline extreme_povline)(poorLine2013 ePoorLine2013)

**rename variable: poor/extreme poor dummy variables
codebook poor epoor
label define p_lbl 0 "No" 1 "Yes"
label values poor p_lbl
label values epoor p_lbl

rename (poor epoor) (poor2013 ePoor2013)

keep HHID case_id y2_hhid ea_id consHH consPC foodConsHH foodConsPC poorLine2013 ePoorLine2013 poor2013 ePoor2013
tempfile consWave2
save `consWave2', replace
***************************************************


***************Household: house owned?
use "$Main/HH_MOD_F_13.dta", clear
**Note: This module only uses y2_hhid, no case_id, ea_id, etc. 

**rename variable: do you own this house/or are purchasing it/granted by employer/etc.?
codebook hh_f01
*original: 1 = owned; 2 = buying in progress; 3 = employer provides; 4 = free and authorised; 5 = free but not authorised; 6 = rented
*Hence, we do not change the method of original value labels. 

rename hh_f01 houseOwned
tab houseOwned

keep y2_hhid houseOwned
tempfile house
save `house', replace
***************************************************


***************Household: non-agricultural business?
use "$Main/HH_MOD_N1_13.dta", clear
**Note: This module only uses y2_hhid, no case_id, ea_id, etc. 

**rename variable: summary of previous questions - has any household member engaged in non-agricultural business/activities in the past 12 months?
codebook hh_n0b
*original: 1 = yes 2= no

rename hh_n0b nonAgriBiz
recode nonAgriBiz (2=0) (1=1)
label define a_lbl 0 "No" 1 "Yes"
label value nonAgriBiz a_lbl
tab nonAgriBiz 

keep y2_hhid nonAgriBiz 
tempfile nonAgri
save `nonAgri', replace
***************************************************


***************Household: well-being self-assessment 
use "$Main/HH_MOD_T_13.dta", clear
**Note: This module only uses y2_hhid, no case_id, ea_id, etc. 

**rename variable: well-being self-assessment on food consumption (t01), housing (t02), clothing (t03), health care (t04)
codebook hh_t01
*All 4 variables coded as following: 1 = less then adequate, 2 = just adequate, 3 = more than adequate. Hence, we are not changing it. 
*One missing value in t04, healthcare, but because of the specific nature of the question, we will not change it. 
rename (hh_t01 hh_t02 hh_t03 hh_t04) (selfFood selfHouse selfCloth selfHealth)

keep y2_hhid selfFood selfHouse selfCloth selfHealth
tempfile selfAssess
save `selfAssess', replace
***************************************************


***************Household: value of plot owned?
use "$Main/AG_MOD_D_13.dta", clear
**Note: This module only uses y2_hhid, no case_id, ea_id, etc. 

**regenerate variable: value of plot owned if sold today
*Because one household may have multiple plots owned, so we generate a sum instead
codebook y2_hhid //we verified the thoughts above. 

collapse (sum) ag_d05, by(y2_hhid)
rename ag_d05 valuePlots

keep y2_hhid valuePlots
tempfile vPlots
save `vPlots', replace
***************************************************
**Note: unlike the 2010 module, the 2013 questionnaire does not contain the community infrastructure section (i.e., the section that asks about distance to nearest road, cloest public primary school, bank, microfinance institution, etc.), so we move on to merging directly. 


****************Merge all data and clean up
use `lsms2hh', clear
merge 1:1 HHID case_id ea_id y2_hhid using `consWave2', nogen
merge m:1 y2_hhid using `house', nogen
merge m:1 y2_hhid using `nonAgri', nogen
merge m:1 y2_hhid using `selfAssess', nogen
merge m:1 y2_hhid using `vPlots', nogen

save `lsms2hh', replace
generate wave = 2
label variable wave "2 = wave 2013"
des

save "$OUT/hh_data_LSMS2", replace
