/*******************************************************************************
Program:    	1f_merge_LSMS_waves_HH.do
Note:			This file appends household-level variables from Waves 1 and 2 of LSMS 
Author:     	Yihan Chen
*******************************************************************************/


use "$OUT/hh_data_LSMS1", clear
append using "$OUT/hh_data_LSMS2"

order HHID wave y2_hhid case_id ea_id hhsize rural stratum region consHH consPC poorLine2010 ePoorLine2010 poor2010 ePoor2010 poorLine2013 ePoorLine2013 poor2013 ePoor2013

*Label variables
lab data "Household-level variables from Malawi LSMS1 and LSMS2, 2010-2013"

lab var wave "Wave: 1=2010, 2=2013"
lab var region "Region: North/Central/South"
lab var consPC "Total real annual consumption per capita- 2013 Prices, Spatially & Tempo"
lab var foodConsPC "Food/Bev, real annual consumption per Capita"
lab var borrowCredit "Over the past 12 months, did anyone in this household borrowed on Credit?"
lab var houseOwned "Do you own this house, or is it other kinds of ownership?"
lab var nonAgriBiz "Household engagement in non-agricultural business in the past 12 months"
lab var valuePlots "Cumulative cash value equivalent of all the land owned by the household if sold today"

save "$OUT/LSMS_all_households", replace
