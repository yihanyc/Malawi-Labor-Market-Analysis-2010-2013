/*******************************************************************************
Program:    	3_analysis.do
Note:			This file conducts analysis of Malawi's Labor Force Participation
Author:     	Yihan Chen
*******************************************************************************/

*** Summary statistics at the individual level
	use "$OUT/LSMS_all_individuals", clear
	xtset indid wave //Describe the panel structure of dataset
	xtdescribe //Summarize how frequently observations appear over the panel
	
***********************************************************************************
* Drop unrelated variables for this model
***********************************************************************************
*** Drop variables with little observations	
	drop tempHealth~p  economicHa~p reasonNoWork employerType jobseek 

*** Drop variables only in wave 2
	drop econActivityPrim econActivitySec econ12mo agriWork12m

*** Other outcome variables for reminder
	drop wageEmploy12m apprentice12m ganyu12m farm12m nonAgriBiz labor12m
	drop SecEmployed12m work7days hoursWage7d hAgriculture7d 
	rename labor12mnew labor12m
	
*** Drop age <= 14 and age >64
*	drop if age <= 14 | age >64 
*	compare full sample (1) and age group (2) in the FE model
	drop under15

***********************************************************************************
* Test for Models and Find Variables Cannot Be Used
***********************************************************************************	

* Variables Cannot Be Used:
*** poor2010, ePoor2010, poor2013, ePoor2013 (T = 1 → No within-group variation) 
*** comBank microFinance mpVisit roadDistance
	drop poor2010 ePoor2010 poor2013 ePoor2013 comBank microFinance mpVisit roadDistance
	
***********************************************************************************
* Modify Models: quadratic and log forms, interaction terms
***********************************************************************************	
	* Consider a quadratic form and interaction terms
*	twoway (scatter labor12m age, jitter(5)) ///
		   (lowess labor12m age, bw(0.3) lcolor(red)), ///
		   title("Age vs. Labor Force Participation") ///
		   xtitle("Age") ytitle("Labor Force Participation")

	gen age2 = age^2  
*	reg labor12m age age2
*	predict yhat
*	twoway (scatter labor12m age, jitter(5)) ///
		   (line yhat age, lcolor(blue)), ///
		   title("Quadratic Fit of Age and Labor Force Participation") ///
		   xtitle("Age") ytitle("Predicted Labor Force Participation")

*	gen age_female = age*female
*	gen age2_female = age2*female
*	gen age_rural = age * rural

	* Try to consider a log form
*	hist consHH, bin(50) normal
*	hist foodConsPC, bin(50) normal
*	gen log_consHH = log(consHH)
*	gen log_foodConsPC = log(foodConsPC)
	
	* Add time/econ/policy consideration
	gen econcrisis = .
	replace econcrisis = 1 if wave ==2
	replace econcrisis = 0 if wave ==1
	label variable econcrisis "Yes if year is 2013; No if year is 2010."
	* Surprisingly, econcrisis has a positive coefficient, so I want to examine interaction terms:
	gen econcrisis_rural = econcrisis * rural
*	gen econcrisis_female = econcrisis * female
	gen econcrisis_age = econcrisis * age
	gen econcrisis_age2 = econcrisis * age2
	
	pwcorr labor12m econcrisis econcrisis_rural econcrisis_age econcrisis_age2, sig
	
***********************************************************************************
* Adopt Lasso to select important variables
** Model selection techniques in Machine Learning
***********************************************************************************	
*** （1）Install necessary commands
*	ssc install esttab, replace
*	ssc install vselect, replace
*	ssc install estout, replace
*	ssc install lassopack, replace

*** （2）Shrinkage methods (lasso)
	gl rhsVars "age age2 rural i.region i.maritalStatus i.relToHHH i.highestEdu readChichewa readEnglish illness2weeks chronicIllness borrowCredit econcrisis econcrisis_rural econcrisis_age econcrisis_age2" //All candidate variables
	gl vars "age age2 rural i.region i.maritalStatus i.relToHHH i.highestEdu readChichewa readEnglish illness2weeks chronicIllness borrowCredit econcrisis econcrisis_rural econcrisis_age econcrisis_age2" //Variables we want to plot

*** (3) Implement lasso regressions using diffrent values of lambda
	lasso2 labor12m $rhsVars,  alpha(1) //Alpha=1 corresponds to the lasso regression
	lasso2, lic(ebic) //Optimal lasso model selected using EBIC
	* Lasso tells you what variables should be included in the model.

*** (4) Choose optimal lambda for lasso through cross-validation
	cvlasso labor12m $rhsVars, seed(123) lopt alpha(1) postest
	gl lassoVars=e(selected) //Save variables selected by lasso

	* Post-lasso estimation
	eststo clear //Clear any saved estimates
*	eststo ols: reg labor12m $rhsVars
*	eststo lasso: reg labor12m $lassoVars
	eststo fe: xtreg labor12m $rhsVars if age >= 15 & age <= 64, fe vce(cluster indid)
	eststo fe_lasso: xtreg labor12m $lassoVars if age >= 15 & age <= 64, fe vce(cluster indid)

	* Tabluate saved estimates
*		esttab ols lasso /*using "test.rtf"*/, ///
			not mti(OLS Lasso) ///
			stats(r2 r2_a N df_m, labels("R-squared" "Adjusted R-squared" "Number of observations" "Number of covariates")) 
		esttab fe fe_lasso /*using "test.rtf"*/, ///
			not mti(FixedEffect Lasso) ///
			stats(r2 r2_a N df_m, labels("R-squared" "Adjusted R-squared" "Number of observations" "Number of covariates")) 
			
*** (5) Reflection
* Variables deleted by lasso:
	* region == Central
	* maritalStatus == Separated/Divorced
	* religion == Islam
	* highestEdu == Primary
	* relToHHH == Spouse

*** (6) Final Decision
* use lasso result
	drop female religion consPC consHH foodConsPC selfFood selfHouse selfCloth selfHealth
	
***********************************************************************************
* Finalize Models：Full sample
***********************************************************************************
	
*** (1) Pooled OLS
*	regress labor12m age age2 female age_female age2_female rural i.region i.maritalStatus i.religion i.relToHHH i.highestEdu readChichewa readEnglish illness2weeks chronicIllness borrowCredit selfFood selfHouse selfCloth selfHealth econcrisis econcrisis_rural econcrisis_female econcrisis_age econcrisis_age2, robust

	regress labor12m $lassoVars, robust
	est store ols_full
	vif
	
*** (2) Random Effect Testing
	xtreg labor12m $lassoVars, fe i(indid)
	est store fe_1

	xtreg labor12m $lassoVars, re i(indid)
	est store re_1

	hausman fe_1 re_1, sigmamore

	* Failing to pass hausman test
	* Use Fixed Effect instead!
	
*** (3) Fixed Effect: Final Decision
*	xtreg labor12m age age2 female age_female age2_female rural i.region i.maritalStatus i.religion i.relToHHH i.highestEdu readChichewa readEnglish illness2weeks chronicIllness borrowCredit selfFood selfHouse selfCloth selfHealth econcrisis econcrisis_rural econcrisis_female econcrisis_age econcrisis_age2, fe vce(cluster indid)
	* drop log_consHH log_foodConsPC selfFood selfHouse selfCloth selfHealth  from the model
	
	xtreg labor12m $lassoVars, fe vce(cluster indid)
	est store fe_full
	vif, uncentered
	
** Check which variables were dropped due to collinearity **
	estat vce, corr

***********************************************************************************
* Finalize Models：Age [15,64]
***********************************************************************************
	
*** (1) Pooled OLS
*	regress labor12m age age2 female age_female age2_female rural i.region i.maritalStatus i.religion i.relToHHH i.highestEdu readChichewa readEnglish illness2weeks chronicIllness borrowCredit selfFood selfHouse selfCloth selfHealth econcrisis econcrisis_rural econcrisis_female econcrisis_age econcrisis_age2, robust

	regress labor12m $lassoVars if age >= 15 & age <= 64, robust
	est store ols_1564
	vif
	
*** (2) Random Effect Testing

* unrobust hausman test 

	xtreg labor12m $lassoVars if age >= 15 & age <= 64, fe i(indid)
	est store fe_2

	xtreg labor12m $lassoVars if age >= 15 & age <= 64, re i(indid)
	est store re_2

	hausman fe_2 re_2, sigmamore
	* p-value（0.0003)
	
*** (3) Fixed Effect

	xtreg labor12m $lassoVars if age >= 15 & age <= 64, fe vce(cluster indid)
	est store fe_1564
	vif, uncentered
	
** Check which variables were dropped due to collinearity **
	estat vce, corr
	
***********************************************************************************
* Create tables to compare models
***********************************************************************************

*** (1) Comparison of Full Sample (OLS vs FE)

	esttab ols_full fe_full, se stats(r2 N df_m) title("Full Sample: OLS vs FE") mtitle("OLS" "FE")

*** (2) Comparison of Age Group [15, 64] (OLS vs FE)

	esttab ols_1564 fe_1564, se stats(r2 N df_m) title("Age [15,64]: OLS vs FE") mtitle("OLS" "FE")

*** (3) Comparison of FE across Two Age Groups (Full Sample vs Age [15, 64])

	esttab fe_full fe_1564, se stats(r2 N df_m) title("FE Comparison: Full Sample vs Age [15, 64]") mtitle("Full Sample" "Age 15-64")

*** (4) Comparison of four models

	esttab ols_full ols_1564 fe_full fe_1564, se stats(r2 N df_m) ///
		   title("Comparison of OLS and FE Models: Full Sample vs Age 15-64") ///
		   mtitle("OLS (Full Sample)" "OLS (15-64)" "FE (Full Sample)" "FE (15-64)")

***********************************************************************************
* Six OLS assumptions for my main FE model (Age 15-64)
***********************************************************************************		 
	xtreg labor12m $lassoVars if age >= 15 & age <= 64, fe vce(cluster indid)
	predict fitted, xb
	predict residuals, e
*	scatter residuals fitted if age >= 15 & age <= 64, yline(0)
	
*** MLR.1 (Linear in parameters)
	* Beta is assumed linear.
	* Nonlinear specification: quadratic function is used (age2).
	* Interaction terms rule, that if X1X2 is included in the model, make sure X1 and X2 are also included, is satisfied.
	* The plot does not exhibit a funnel shape, which suggests that the model does not violate the assumption of linearity.


*** MLR.2 (Random sampling)
	* We have a large sample (N = 15821)。
	* There are some moderate missing values, but they do not appear to introduce systematic bias.
	* We limits our sample to age (15-64).
	* The residuals appear to be randomly scattered around the zero line, which is a positive sign. It suggests that the model captures the linear relationship between the dependent and independent variables reasonably well.

*** MLR.3 (No perfect collinearity)
	* Checked by vif. Variables with 10+ score except for the interaction terms were dropped.


*** MLR.4 (Zero conditional mean)

	* The residual plot shows a three-layer pattern, indicating possible violations of the zero conditional mean assumption, though I have tried quadratic form and interaction terms.
	* (1) Unobserved Heterogeneity: There may be unobserved group-level effects.
	* (2) Group-Level Clustering: There might be hidden characteristics.
	
*** MLR.5 (Homoskedasticity)
	* I have clustered standard errors (vce(cluster indid)), which helps address heteroskedasticity issues.
	* However, the residuals appear to have a consistent spread across fitted values, suggesting no clear signs of increasing or decreasing variance (heteroskedasticity). However, the distinct banding pattern may indicate a form of heteroskedasticity related to subgroups in the data.

*** MLR.6 (Normality of error terms)
	* We have a large sample size. With a large sample size, normality is likely achieved.
	
	
***********************************************************************************
* Final .dta file with only the variables used in analysis
***********************************************************************************
	des age rural maritalStatus highestEdu readChichewa readEnglish illness2weeks chronicIllness borrowCredit econcrisis
	save "$OUT/LSMS_final_individuals", replace
	
	
	
	
	
