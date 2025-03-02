/*******************************************************************************
Program:    	1c_merge_LSMS1_HH.do
Note:			This file merges all household variables in LSMS wave 1, Malawi
Author:     	Yihan Chen
*******************************************************************************/

***************Household demographics: urban/rural, region (north/center/south)
use "$Main/HH_MOD_A_FILT_10.dta", clear

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

*ii. Variable: stratum, we will keep it as it is, but we will generate a region variable
codebook stratum
tab stratum

gen region = .
replace region = 1 if stratum == 1 | stratum == 2
replace region = 2 if stratum == 3 | stratum == 4
replace region = 3 if stratum == 5 | stratum == 6

label define reg1_lbl 1 "North" 2 "Central" 3 "South"
label value region reg1_lbl
tab region

keep HHID case_id ea_id rural region stratum
tempfile lsms1hh
save `lsms1hh', replace
***************************************************


***************Household consumption/consumption per capita in wave 1
use "$Extra/Panel/Round 1 (2010) Consumption Aggregate.dta", clear 

**rename variable: consumption per household/consumption per capita
codebook rexpagg pcrexpagg
*For consumption per household, the maximum value is 18304290, might be a problem? 
*For consumption per capita, the maximum value is 6101430...?
*After checking that specific maximum number (which is the same household), it may be just a normal rich household that becomes an outlier, so we will keep it. 
rename (rexpagg pcrexpagg) (consHH consPC)

**rename variable: food/beverage per household/per capita
rename (rexp_cat01 pcrexp_cat01)(foodConsHH foodConsPC)

**rename variable: poor/extreme poor threshold
rename (absolute_povline extreme_povline)(poorLine2010 ePoorLine2010)

**rename variable: poor/extreme poor dummy variables
codebook poor epoor
label define p_lbl 0 "No" 1 "Yes"
label values poor p_lbl
label values epoor p_lbl

rename (poor epoor) (poor2010 ePoor2010)

keep HHID case_id ea_id consHH consPC foodConsHH foodConsPC poorLine2010 ePoorLine2010 poor2010 ePoor2010
tempfile consWave1
save `consWave1', replace
***************************************************


***************Household: borrowed on credit?
use "$Main/HH_MOD_A_FILT_10.dta", clear

**rename variable: borrow on credit in the past 12 months?
codebook hh_s01
tab hh_s01
*original: 2 = no, 1 = yes

rename hh_s01 borrowCredit
recode borrowCredit (2=0) (1=1)
label define r_lbl 0 "No" 1 "Yes"
label value borrowCredit r_lbl
tab borrowCredit

keep HHID case_id ea_id borrowCredit
tempfile borrowed
save `borrowed', replace
***************************************************


***************Household: house owned?
use "$Main/HH_MOD_F_10.dta", clear

**rename variable: do you own this house/or are purchasing it/granted by employer/etc.?
codebook hh_f01
tab hh_f01
*original: 1 = owned; 2 = buying in progress; 3 = employer provides; 4 = free and authorised; 5 = free but not authorised; 6 = rented
*Hence, we do not change the method of original value labels. 

rename (HHID case_id ea_id hh_f01)(HHID case_id ea_id houseOwned)
tab houseOwned

keep HHID case_id ea_id houseOwned
tempfile house
save `house', replace
***************************************************


***************Household: non-agricultural business?
use "$Main/HH_MOD_N1_10.dta", clear

**rename variable: summary of previous questions - has any household member engaged in non-agricultural business/activities in the past 12 months?
codebook hh_n0b
tab hh_n0b
*original: 1 = yes 2= no

rename (HHID case_id ea_id hh_n0b)(HHID case_id ea_id nonAgriBiz)
recode nonAgriBiz (2=0) (1=1)
label define a_lbl 0 "No" 1 "Yes"
label value nonAgriBiz a_lbl
tab nonAgriBiz 

keep HHID case_id ea_id nonAgriBiz
tempfile nonAgri
save `nonAgri', replace
***************************************************



***************Household: well-being self-assessment 
use "$Main/HH_MOD_T_10.dta", clear

**rename variable: well-being self-assessment on food consumption (t01), housing (t02), clothing (t03), health care (t04)
codebook hh_t01
*All 4 variables coded as following: 1 = less then adequate, 2 = just adequate, 3 = more than adequate. Hence, we are not changing it. 
rename (HHID case_id ea_id hh_t01 hh_t02 hh_t03 hh_t04) (HHID case_id ea_id selfFood selfHouse selfCloth selfHealth)

keep HHID case_id ea_id selfFood selfHouse selfCloth selfHealth
tempfile selfAssess
save `selfAssess', replace
***************************************************


***************Household: value of plot owned?
use "$Main/AG_MOD_D_10.dta", clear

**regenerate variable: value of plot owned if sold today
*Because one household may have multiple plots owned, so we generate a sum instead
codebook HHID //we verified the thoughts above. 

collapse (sum) ag_d05, by(HHID case_id ea_id)
rename ag_d05 valuePlots

keep HHID case_id ea_id valuePlots
tempfile vPlots
save `vPlots', replace
***************************************************


***************Household: community infrastructure?
**Note: this module is not found in the 2013 wave
use "$Main/COM_CD_10.dta", clear

**Note: this module only has ea_id, no HHID/case_id

**regenerate variable: distance to the nearest road
codebook com_cd02a com_cd02b
*02a is the distance, and 02b is the unit, so we need to convert into a universal unit
gen roadDistance = .
replace roadDistance = com_cd02a //would keep original km in the end
replace roadDistance = com_cd02a * 0.001 if com_cd02b == 1 //meter to km
replace roadDistance = com_cd02a * 1.60934 if com_cd02b == 3 //mile to km
list com_cd02a com_cd02b roadDistance //check successful conversion
label variable roadDistance "Distance to the nearest road (in KM)"


**rename variable: nearest public primary school electrified
codebook com_cd35
*original: 1 = yes, 2 = no

rename (ea_id com_cd35)(ea_id schoolElectrified)
recode schoolElectrified (2=0) (1=1)
label define e_lbl 0 "No" 1 "Yes"
label value schoolElectrified e_lbl
tab schoolElectrified

**rename variable: is there a commercial bank in this community? 
codebook com_cd66
*original: 1 = yes, 2 = no

rename com_cd66 comBank
recode comBank (2=0) (1=1)
label define c_lbl 0 "No" 1 "Yes"
label value comBank c_lbl
tab comBank 

**rename variable: is there a microfinance in this community?
codebook com_cd68
*original: 1 = yes, 2 = no

rename com_cd68 microFinance
recode microFinance (2=0) (1=1)
label define m_lbl 0 "No" 1 "Yes"
label value microFinance m_lbl
tab microFinance

**rename variable: did MP of this area visit the community in past 3 months to speak/listen to people?
codebook com_cd71
*original: 1 = yes, 2 = no, .=missing

rename com_cd71 mpVisit
recode mpVisit (2=0) (1=1) (.=0)
label define p_lbl 0 "No" 1 "Yes"
label value mpVisit p_lbl
tab mpVisit

keep ea_id roadDistance schoolElectrified comBank microFinance mpVisit
tempfile commAccess
save `commAccess', replace
***************************************************


****************Merge all data and clean up
use `lsms1hh', clear
merge 1:1 HHID case_id ea_id using `consWave1', nogen
merge 1:1 HHID case_id ea_id using `borrowed', nogen
merge 1:1 HHID case_id ea_id using `house', nogen
merge 1:1 HHID case_id ea_id using `nonAgri', nogen
merge 1:1 HHID case_id ea_id using `selfAssess', nogen
merge 1:1 HHID case_id ea_id using `vPlots', nogen
merge m:1 ea_id using `commAccess', nogen

save `lsms1hh', replace
generate wave = 1
label variable wave "1 = wave 2010"
des

save "$OUT/hh_data_LSMS1", replace
