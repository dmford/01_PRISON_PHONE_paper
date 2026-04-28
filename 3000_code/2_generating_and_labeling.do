* 2_generating_and_labeling.do

clear all

*cd "\bigdata\mbateslab\dford013\coding\01_PRISON_PHONE_paper"
cd "~\coding\01_PRISON_PHONE_paper"

********************************************************************************

capture log close
log using "3000_code\SMCL_logs\2_generating_and_labeling", smcl replace



use "2000_data\500_working\merged_prison_dta", replace
save "2000_data\500_working\labeled_prison_dta", replace


********** GENERATING VARIABLES **********

* proposed Nov 2012, passed Nov 2013, enacted Feb 2014
gen caps_proposed = (year>=2013)
gen caps_enact = (year>=2014)

* per-minute phone rate caps: 
gen coll_cap = 0.25
gen pre_cap = 0.21
gen debit_cap = 0.21

* converting to 15m caps: 
gen coll_cap_15m = coll_cap*15
gen pre_cap_15m = pre_cap*15
gen debit_cap_15m = debit_cap*15

* POPULATION TOTALS
* taking 1+, 1-, unsentenced population figures and adding them together, maintaining M/F divide
gen total_pop = oneplus_tot_pop + oneminus_tot_pop + unsen_tot_pop if (oneplus_tot_pop != .) & (oneminus_tot_pop != .) & (unsen_tot_pop != .)
gen total_m_pop = oneplus_m_pop + oneminus_m_pop + unsen_m_pop if (oneplus_m_pop != .) & (oneminus_m_pop != .) & (unsen_m_pop != .)
gen total_f_pop = oneplus_f_pop + oneminus_f_pop + unsen_f_pop if (oneplus_f_pop != .) & (oneminus_f_pop != .) & (unsen_m_pop != .)

* pop^2 and pop^3
gen total_pop2 = total_pop*total_pop
gen total_pop3 = total_pop*total_pop*total_pop

* Constructing 15 MINUTE CALL COSTS
* first, use "flat" rate if given
gen is_coll_15m_total = is_coll_15m_flat
gen is_pre_15m_total = is_pre_15m_flat
gen is_debit_15m_total = is_debit_15m_flat
gen oos_coll_15m_total = oos_coll_15m_flat
gen oos_pre_15m_total = oos_pre_15m_flat
gen oos_debit_15m_total = oos_debit_15m_flat

* otherwise, replace missing values with fee + 15*rate
replace is_coll_15m_total = is_coll_fee + 15*is_coll_rate if is_coll_15m_total==.
replace is_pre_15m_total = is_pre_fee + 15*is_pre_rate if is_pre_15m_total==.
replace is_debit_15m_total = is_debit_fee + 15*is_debit_rate if is_debit_15m_total==.
replace oos_coll_15m_total = oos_coll_fee + 15*oos_coll_rate if oos_coll_15m_total==.
replace oos_pre_15m_total = oos_pre_fee + 15*oos_pre_rate if oos_pre_15m_total==.
replace oos_debit_15m_total = oos_debit_fee + 15*oos_debit_rate if oos_debit_15m_total==.


*** using old rate dataset to fill missing observations in new rate dataset ***

* creating placeholder variables 
*** collect rate data points are main ones ***
gen oos_coll_15m = oos_coll_15m_total
gen is_coll_15m = is_coll_15m_total
* (only really use the above two)
gen is_pre_15m = is_pre_15m_total
gen is_debit_15m = is_debit_15m_total
gen oos_pre_15m = oos_pre_15m_total
gen oos_debit_15m = oos_debit_15m_total

* first, making the most-valid combinations
* 2013: imposing old prepaid rates onto new prepaid dataset
replace is_pre_15m = is_avg_rate if (year == 2013) & (is_pre_15m == .)
replace oos_pre_15m = oos_avg_rate if (year == 2013) & (oos_pre_15m == .)

* 2014: un-reducing "prepaid" rates by 15% to re-capture underlying collect rates, no changes made
replace is_coll_15m = is_avg_rate/.85 if (year == 2014) & (is_coll_15m == .)

* 2014 oos_coll rates not viable, they assumed states over cap exactly matched cap 

* 2015: un-reducing "prepaid" rates by 15%, impose onto coll rates, no changes made
replace is_coll_15m = is_avg_rate/.85 if (year == 2015) & (is_coll_15m == .)

* 2016: imposing old in-state prepaid rates onto new prepaid dataset
replace is_pre_15m = is_avg_rate if (year == 2016) & (is_pre_15m == .)

* 2017, 2018: imposing old prepaid rates onto new dataset
replace is_pre_15m = is_avg_rate if (year == 2017) & (is_pre_15m == .)
replace oos_pre_15m = oos_avg_rate if (year == 2017) & (oos_pre_15m == .)
replace is_pre_15m = is_avg_rate if (year == 2018) & (is_pre_15m == .)
replace oos_pre_15m = oos_avg_rate if (year == 2018) & (oos_pre_15m == .)

* 2019: imposing prepaid rates onto new dataset
replace is_pre_15m = is_avg_rate if year==2019 & is_pre_15m==.

* identifying missing rates after data combination, noting missing obs counts between 2008-2018 
gen missing_oos_coll_15m = (oos_coll_15m==.)
gen missing_oos_pre_15m = (oos_pre_15m==.)
gen missing_oos_debit_15m = (oos_debit_15m==.)
gen missing_is_coll_15m = (is_coll_15m==.)
gen missing_is_pre_15m = (is_pre_15m==.)
gen missing_is_debit_15m = (is_debit_15m==.)


***************************************************************************************************************************


* generating incomplete rate binary identifier
gen rates_incomplete = (oos_coll_15m==. & year>=2008 & year<=2018)

* generating potential defying rate binary identifier
	* meaning: contract or phone data implies they don't obey the cap on time 
gen potential_defier = (oos_coll_15m > coll_cap_15m) & (oos_coll_15m != .) & (year >= 2014) & (year <= 2018)

* generating FIRST DIFFERENCE RATE VARIABLE, and PCT CHANGE
set varabbrev off

* absolute FD's first
bysort state: gen fd_oos_coll_15m = oos_coll_15m[_n]-oos_coll_15m[_n-1] if (year >= 2008) & (year <= 2018)
* as percents now
bysort state: gen fd_pct_coll_15m = (oos_coll_15m[_n]-oos_coll_15m[_n-1])/(oos_coll_15m[_n-1])*100 if (year >= 2008) & (year <= 2018)

set varabbrev on

* identifying early adopters: 11/2012 notice, 11/2013 passed, 2/2014 effected
* identifying states over cap in early year (early==2013 gives compliers)
* generating (OVER IN YEAR=EARLY) BINARY IDENTIFIER
gen early = 1
gen over_early = (year == 2013 - early) & (oos_coll_15m > coll_cap_15m)
bysort state: egen temp_over_early_avg = mean(over_early)
replace over_early=0
replace over_early=1 if (temp_over_early_avg > 0)
drop (temp_over_early_avg)

* generating (UNDER IN YEAR=EARLY+1) BINARY IDENTIFIER
gen under_earlyp1 = 0
replace under_earlyp1 = 1 if (year == 2014 - early) & (oos_coll_15m <= coll_cap_15m)
bysort state: egen temp_under_earlyp1_avg = mean(under_earlyp1)
replace under_earlyp1 = 0
replace under_earlyp1 = 1 if (temp_under_earlyp1_avg > 0)
drop (temp_under_earlyp1_avg)

* generating (OVER IN YEAR=EARLY & UNDER IN YEAR=EARLY+1) = EARLY ADOPTER BINARY IDENTIFIER
gen early_adopt=0
replace early_adopt=1 if (year == 2013 + early) & (over_early == 1) & (under_earlyp1 == 1)
drop (over_early under_earlyp1)
tab state if (early_adopt == 1)

* generating TREATMENT BINARY IDENTIFIERS
* generating treat_base = over caps in 2013
gen treat_base = (year == 2013) & (oos_coll_15m > coll_cap_15m)
bysort state: egen temp_treat_base = mean(treat_base)
replace treat_base = (temp_treat_base > 0)
drop (temp_treat_base)

* generating treat_early_base = treat_base + early_adopt
gen treat_early_base = (treat_base == 1) | (early_adopt == 1)
bysort state: egen temp_treat_early_base = mean(treat_early_base)
replace treat_early_base = 1 if (temp_treat_early_base > 0)
drop (temp_treat_early_base)

* generating substantiation rate variables
bysort state year: gen inmate_contact_rate = inmate_contact_subs/inmate_contact_all
bysort state year: gen inmate_noncon_rate = inmate_noncon_subs/inmate_noncon_all
bysort state year: gen staff_harassment_rate = staff_harassment_subs/staff_harassment_all
bysort state year: gen staff_miscond_rate= staff_miscond_subs/staff_miscond_all

* generating T_coll, T_pre, and T_debit timelines
	* (#years relative to first being observed under cap)
gen under_oos_coll_cap = (oos_coll_15m <= coll_cap_15m) 
gen under_oos_pre_cap = (oos_pre_15m <= pre_cap_15m) 
gen under_oos_debit_cap = (oos_debit_15m <= debit_cap_15m) 
bysort state_fips: egen temp_coll = min(year) if (under_oos_coll_cap == 1) 
bysort state_fips: egen temp_pre = min(year) if (under_oos_pre_cap == 1) 
bysort state_fips: egen temp_debit = min(year) if (under_oos_debit_cap == 1) 
bysort state_fips: egen minyear_coll = min(temp_coll) 
bysort state_fips: egen minyear_pre = min(temp_pre) 
bysort state_fips: egen minyear_debit = min(temp_debit) 
gen T_coll = (year - minyear_coll) 
gen T_pre = (year - minyear_pre)
gen T_debit = (year - minyear_debit)
drop (under_oos_coll_cap temp_coll minyear_coll) 
drop (under_oos_pre_cap temp_pre minyear_pre) 
drop (under_oos_debit_cap temp_debit minyear_debit)

* structuring T_coll so that it is non-negative
egen min_T_coll = min(T_coll)
gen T_coll_pos = T_coll + abs(min_T_coll)
sum min_T_coll
sum T_coll
sum T_coll_pos

* generating T_alt, where T=0 for biggest rate reduction year
bysort state: egen min_fd = min(fd_pct_coll_15m) 
bysort state: gen temp_T_alt = year if (min_fd == fd_pct_coll_15m)
bysort state: egen min_fd_year = min(temp_T_alt) 
gen T_alt = (year - min_fd_year)
drop (min_fd temp_T_alt min_fd_year)

* structuring T_alt so that it is non-negative
egen min_T_alt = min(T_alt)
gen T_alt_pos = (T_alt + abs(min_T_alt))

* identifying T_coll balanced panels 
gen bal_mag_T_coll = 3
bysort state: egen min_bal_T_coll = min(T_coll) if (year >= 2008) & (year <= 2018)
bysort state: egen max_bal_T_coll = max(T_coll) if (year >= 2008) & (year <= 2018)
gen drop_bal_T_coll = (abs(min_bal_T_coll) < bal_mag_T_coll) | (abs(max_bal_T_coll) < bal_mag_T_coll) | (year > 2018) | (year < 2008)
drop (min_bal_T_coll max_bal_T_coll) 

* same for T_alt
gen bal_mag_T_alt = 3
bysort state: egen min_bal_T_alt = min(T_alt) if (year >= 2008) & (year <= 2018)
bysort state: egen max_bal_T_alt = max(T_alt) if (year >= 2008) & (year <= 2018)
gen drop_bal_T_alt = (abs(min_bal_T_alt) < bal_mag_T_alt) | (abs(max_bal_T_alt) < bal_mag_T_alt) | (year > 2018) | (year < 2008)
drop (min_bal_T_alt max_bal_T_alt)



**********


* generating pieces used in graphs
* avg/max/min/sd/var of interstate collect 15m rate (the good dataset)
bysort year: egen avg_oos_coll_15m = mean(oos_coll_15m)
bysort year: egen max_oos_coll_15m = max(oos_coll_15m)
bysort year: egen min_oos_coll_15m = min(oos_coll_15m)
bysort year: egen sd_oos_coll_15m = sd(oos_coll_15m)
gen var_oos_coll_15m = sd_oos_coll_15m^2


***** WILL NEED TO FIGURE THIS OUT WITH NEW DATA AFTER PULLING FROM CONTRACTS *****

* generating out-of-state binding indicator variables
* should be 1 if rate was above cap in 2013, 0 if else
* should I be concerned here about early dropping? Non-compliance? 
foreach i in coll pre debit {
	gen oos_`i'_bind=0
	replace oos_`i'_bind=1 if (year == 2013) & (oos_`i'_rate > `i'_cap)
 	bysort state_fips: egen temp = mean(oos_`i'_bind)
	replace oos_`i'_bind=1 if (temp > 0)
	drop (temp)
}

* same but in-state now
foreach i in coll pre debit {
	gen is_`i'_bind=0
	replace is_`i'_bind=1 if (year == 2013) & (is_`i'_rate > `i'_cap)
 	bysort state_fips: egen temp = mean(is_`i'_bind)
	replace is_`i'_bind=1 if (temp > 0)
	drop (temp)
}


* generating suicide variables
foreach control of varlist total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct {
	bysort state time_block: egen block_avg_`control' = mean(`control') if (year >= 2001) & (year <= 2019)
	bysort state time_block: egen block_med_`control' = median(`control') if (year >= 2001) & (year <= 2019)
	la var block_avg_`control' "Average Value For Suicide Time Blocks"
	la var block_med_`control' "Median Value For Suicide Time Blocks"
	replace block_avg_`control'=999 if (block_avg_`control' == .)
	replace block_med_`control'=999 if (block_med_`control' == .)
	gen nined_block_avg_`control'= (block_avg_`control' == 999)
	gen nined_block_med_`control'= (block_med_`control' == 999)
}

gen block_post = (time_block == 20152019)
replace block_post = 0.2 if (time_block == 20102014)
gen block_post_proposed = block_post
replace block_post_proposed = 0.4 if (time_block == 20102014)

foreach c of varlist total_pop total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap rated_cap custody_pop lowest_cap_pct highest_cap_pct age_1824 age_2534 age_3544 age_4554 age_55p educ_anycoll educ_hs educ_nohs sent_1m sent_1_2 sent_2_5 sent_5_10 sent_10_25 sent_25p sent_life sent_miss off_manslaughter off_assault off_drugs off_fraud off_larceny off_cartheft off_murder off_burglary off_publicorder off_rapesa off_robbery off_othprop off_othviolent off_other off_missing crime_violent crime_public crime_property crime_drugs crime_other crime_missing {
	replace `c' = 999 if (`c' == .)
	gen nined_`c' = (`c' == 999)
	la var nined_`c' "Binary identifier for obs with `c'==999"
}


* dropping rows with missing outcome variables
gen missing_outcome=0
foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	replace missing_outcome = (`o'==.) if (year >= 2004) & (year <= 2018)
}


*** creating time dummy variables 
tab year if year>=2008 & year<=2018, gen(year_)
foreach timedummy in year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11 {
	la var `timedummy' "PREA dataset time dummies: year_1=2008, year_6=2013, year_11=2018"
}


********** LABELING VARIABLES **********


* general data
la var state "State name"
la var year "Year"
la var state_abbrev "Two letter state abbreviations"
la var state_fips "Federal Information Processing System (FIPS) codes"

la var caps_enact "Binary var, 0 until 2014 when FCC caps enacted"
la var caps_proposed "Binary var, 0 until 2013 after rulemaking proposed in 11/2012"

la var oos_coll_bind "Binary var, 1 if 2013 out-of-state collect rate above FCC cap, 0 if else"
la var oos_pre_bind "Binary var, 1 if 2013 out-of-state prepaid rate above FCC cap, 0 if else"
la var oos_debit_bind "Binary var, 1 if 2013 out-of-state debit rate above FCC cap, 0 if else"
la var is_coll_bind "Binary var, 1 if 2013 in-state collect rate above FCC cap, 0 if else"
la var is_pre_bind "Binary var, 1 if 2013 in-state prepaid rate above FCC cap, 0 if else"
la var is_debit_bind "Binary var, 1 if 2013 in-state debit rate above FCC cap, 0 if else"

la var early "How many years are considered for 'early adoption' and 'early treatment' groups"
la var early_adopt "Binary var, 1 if rate lowered early"

la var treat_base "Binary var, 1 if rate was above caps in 2013"
la var treat_early_base "Binary var, 1 if rate was above caps in 2013, adding 'early adopters'"

la var fd_oos_coll_15m "Change in 15m Coll Rate from Previous Year"
la var fd_pct_coll_15m "Percent Change in 15m Coll Rate from Previous Year"

la var T_coll "T=0 when state average collect call rate first observed below FCC caps"
la var T_pre "T=0 when state average prepaid call rate first observed below FCC caps" 
la var T_debit "T=0 when state average debit call rate first observed below FCC caps" 
la var T_alt "T=0 in year where 15m collect rate reduction is largest"

la var drop_bal_T_coll "Binary identifier, 1 if rate dataset is complete for T_coll=0 +/- bal_T_mag years"
la var drop_bal_T_alt "Binary identifier, 1 if rate dataset is complete for T_alt=0 +/- bal_alt_T_mag years"
la var bal_mag_T_coll "3, number of years +/- T_coll=0 yield a decent balanced panel"
la var bal_mag_T_alt "3, number of years +/- T_alt=0 yield a decent balanced panel"

la var min_T_coll "-16, Lowest observed T_coll value, T_coll-min_T_coll = T_coll_pos"
la var min_T_alt "-18, Lowest observed T_alt value, T_alt-min_T_alt = T_alt_pos"

la var T_coll_pos "Literally T_coll + abs(min(T_coll)) to force the variable to be positive, now 0=16"
la var T_alt_pos "Literally T_alt + abs(min(T_alt)) to force the variable to be positive, now 0=18"

* PREA data
la var inmate_contact_all "Alleged Inmate Abusive Sexual Contact"
la var inmate_contact_subs "Subst. Inmate Abusive Sexual Contact"
la var inmate_noncon_all "Alleged Inmate Noncons. Sexual Acts"
la var inmate_noncon_subs "Subst. Inmate Noncons. Sexual Acts"
la var staff_harassment_all "Alleged Staff Sexual Harassment"
la var staff_harassment_subs "Subst. Staff Sexual Harassment"
la var staff_miscond_all "Alleged Staff Sexual Misconduct"
la var staff_miscond_subs "Subst. Staff Sexual Misconduct"
la var inmate_contact_rate "Inmate Abusive Sexual Contact: Substantiations / Allegations"
la var inmate_noncon_rate "Inmate Noncons. Sexual Acts: Substantiations / Allegations"
la var staff_harassment_rate "Staff Sexual Harassment: Substantiations / Allegations"
la var staff_miscond_rate "Staff Sexual Misconduct: Substantiations / Allegations"

* population data
la var oneplus_tot_pop "Total pop of prisoners with sentences over one year"
la var oneplus_m_pop "Male pop of prisoners with sentences over one year"
la var oneplus_f_pop "Female pop of prisoners with sentences over one year"
la var oneminus_tot_pop "Total pop of prisoners with sentences under one year"
la var oneminus_m_pop "Male pop of prisoners with sentences under one year"
la var oneminus_f_pop "Female pop of prisoners with sentences under one year"
la var unsen_tot_pop "Total pop of unsentenced prisoners"
la var unsen_m_pop "Male pop of unsentenced prisoners"
la var unsen_f_pop "Female pop of unsentenced prisoners"
* constructed population variables 
la var total_pop "Sum of 1+, 1-, and unsen populations"
la var total_pop2 "Total population squared"
la var total_pop3 "Total population cubed"
la var total_m_pop "Sum of 1+, 1-, and unsen male populations"
la var total_f_pop "Sum of 1+, 1-, and unsen female populations"

* BJS capacity data
la var custody_pop "Reported number of prisoners in custody from BJS capacity dataset"
la var rated_cap "Number of beds/inmates assigned by rating off to institutions in jurisdiction"
la var operational_cap "Number of inmates that can be accomodated"
la var design_cap "Number of inmates planners/arch intended"
la var lowest_cap_pct "Min number of beds across three capacity measures"
la var highest_cap_pct "Max number of beds across three capacity measures"
la var prisoners_eoy "Reported number of prisoners in custody Dec 31 from PREA"
la var prisoners_moy "Reported number of prisoners in custody Jun 30 from PREA"

* FCC rate caps, announced Nov 2013, implemented Feb 2014
la var coll_cap "FCC interstate rate cap on collect calls, imposed in Feb 2014"
la var coll_cap_15m "FCC interstate rate cap on collect calls, multiplied by 15m"
la var pre_cap "FCC interstate rate cap on prepaid calls, imposed in Feb 2014"
la var pre_cap_15m "FCC interstate rate cap on prepaid calls, multiplied by 15m"
la var debit_cap "FCC interstate rate cap on debit calls, imposed in Feb 2014"
la var debit_cap_15m "FCC interstate rate cap on debit calls, multiplied by 15m"

* new in state rate data
la var is_coll_fee "Within State Long Distance Collect Call Fee"
la var is_coll_rate "Within State Long Distance Collect Call Minute Rate"
la var is_coll_15m_flat "Within State Long Distance Collect Call 15m Flat Rate"
la var is_pre_fee "Within State Long Distance Prepaid Call Fee"
la var is_pre_rate "Within State Long Distance Prepaid Call Minute Rate"
la var is_pre_15m_flat "Within State Long Distance Prepaid Call 15m Flat Rate"
la var is_debit_fee "Within State Long Distance Debit Call Fee"
la var is_debit_rate "Within State Long Distance Debit Call Minute Rate"
la var is_debit_15m_flat "Within State Long Distance Debit Call 15m Flat Rate"

* new out of state rate data
la var oos_coll_fee "Out of State Long Distance Collect Call Fee"
la var oos_coll_rate "Out of State Long Distance Collect Call Minute Rate"
la var oos_coll_15m_flat "Out of State Long Distance Collect Call 15m Flat Rate"
la var oos_pre_fee "Out of State Long Distance Prepaid Call Fee"
la var oos_pre_rate "Out of State Long Distance Prepaid Call Minute Rate"
la var oos_pre_15m_flat "Out of State Long Distance Prepaid Call 15m Flat Rate"
la var oos_debit_fee "Out of State Long Distance Debit Call Fee"
la var oos_debit_rate "Out of State Long Distance Debit Call Minute Rate"
la var oos_debit_15m_flat "Out of State Long Distance Debit Call 15m Flat Rate"
* constructed 15m totals now, before merging with "old" dataset
la var is_coll_15m_total "Within State Collect Call 15m Total Cost"
la var is_pre_15m_total "Within State Prepaid Call 15m Total Cost"
la var is_debit_15m_total "Within State Debit Call 15m Total Cost"
la var oos_coll_15m_total "Out of State State Collect Call 15m Total Cost"
la var oos_pre_15m_total "Out of State Prepaid Call 15m Total Cost"
la var oos_debit_15m_total "Out of State Debit Call 15m Total Cost"

* old oos and is rate variables
la var oos_avg_rate "Avg 15m LD interstate call rate"
la var is_avg_rate "Avg 15m LD within state call rate"
* updating missing "new" rate obs with relevant "old" rate obs
la var is_coll_15m "Within State Long Distance 15m Collect Call Cost"
la var is_pre_15m "Within State Long Distance 15m Prepaid Call Cost"
la var is_debit_15m "Within State Long Distance 15m Debit Call Cost"
la var oos_coll_15m "Out of State Long Distance 15m Collect Call Cost"
la var oos_pre_15m "Out of State Long Distance 15m Prepaid Call Cost"
la var oos_debit_15m "Out of State Long Distance 15m Debit Call Cost"

* flags for manually-updated data from DOC phone company contract lookup
la var oos_coll_flag "Binary Flag for Obs Manually Updated from Contracts"
la var oos_pre_flag "Binary Flag for Obs Manually Updated from Contracts"
la var oos_debit_flag "Binary Flag for Obs Manually Updated from Contracts"

* missing rate data identifiers
la var missing_oos_coll_15m "Binary indicator variable for state-year observations missing out-of-state collect rate data"
la var missing_oos_pre_15m "Binary indicator variable for state-year observations missing out-of-state prepaid rate data"
la var missing_oos_debit_15m "Binary indicator variable for state-year observations missing out-of-state debit rate data"
la var missing_is_coll_15m "Binary indicator variable for state-year obs missing in-state collect rate data"
la var missing_is_pre_15m "Binary indicator variable for state-year obs missing in-state prepaid rate data"
la var missing_is_debit_15m "Binary indicator variable for state-year obs missing in-state debit rate data"

* other variable labels
la var rates_incomplete "Binary identifier for states with 1+ missing rate observation"
la var potential_defier "Binary identifier for states with 1+ defying rate observation"
la var missing_outcome "Binary identifier for rows with ANY missing PREA outcomes"


* variation depiction variables
la var avg_oos_coll_15m "Average by Year of Interstate Collect Call Rates"
la var max_oos_coll_15m "Maximum by Year of Interstate Collect Call Rates"
la var min_oos_coll_15m "Minimum by Year of Interstate Collect Call Rates"
la var sd_oos_coll_15m "Std Dev by Year of Interstate Collect Call Rates"
la var var_oos_coll_15m "Variance by Year of Interstate Collect Call Rates"

* suicide data variables
la var time_block "Blocked year range for reporting suicide, to preserve anonymity"
la var suicides "Number of suicides in each time_block"
la var block_size "Number of years in each time_block"
la var block_post "Post identifier for blocked suicide data, starting with 2014 FCC cap enactment"
la var block_post_proposed "Post identifier for blocked suicide data, starting with 2013 FCC cap proposal"

* age count as of 12/31, data for 2004-2019 from NCRP
la var age_1824 "Count of inmates aged 18-24 on 12/31 of relevant year"
la var age_2534 "Count of inmates aged 25-34 on 12/31 of relevant year"
la var age_3544 "Count of inmates aged 35-44 on 12/31 of relevant year"
la var age_4554 "Count of inmates aged 45-54 on 12/31 of relevant year"
la var age_55p "Count of inmates aged 55+ on 12/31 of relevant year"

* highest education level count, data for 2004-2019 from NCRP
la var educ_anycoll "Count of inmates who have gone to some college"
la var educ_hs "Count of inmates with a HS diploma/GED"
la var educ_nohs "Count of inmates with less than a HS/diploma/GED"

* count of inmates maximum sentence lengths, data for 2004-2019 from NCRP
la var sent_1m "Count of inmates with a sentence of less than one year"
la var sent_1_2 "Count of inmates with a sentence of 1-1.9 years"
la var sent_2_5 "Count of inmates with a sentence of 2-4.9 years"
la var sent_5_10 "Count of inmates with a sentence of 5-9.9 years"
la var sent_10_25 "Count of inmates with a sentence of 10-24.9 years"
la var sent_25p "Count of inmates with a sentence of 25+ years"
la var sent_life "Count of inmates with a sentence of life, LWOP, or life+, or death"
la var sent_miss "Count of inmates with missing sentence length information"

* count of detailed categorization of most serious sentenced offense, data for 2004-2019 from NCRP
la var off_manslaughter "Count of inmates whose most serious offense was negligent manslaughter"
la var off_assault "Count of inmates whose most serious offense was aggravated or simple assault"
la var off_drugs "Count of inmates whose most serious offense was drug possession/distribution/trafficking/other"
la var off_fraud "Count of inmates whose most serious offense was fraud"
la var off_larceny "Count of inmates whose most serious offense was larceny/theft"
la var off_cartheft "Count of inmates whose most serious offense was motor vehicle theft"
la var off_murder "Count of inmates whose most serious offense was murder"
la var off_burglary "Count of inmates whose most serious offense was burglary"
la var off_publicorder "Count of inmates whose most serious offense was public order"
la var off_rapesa "Count of inmates whose most serious offense was rape/sexual assault"
la var off_robbery "Count of inmates whose most serious offense was robbery"
la var off_othprop "Count of inmates whose most serious offense was another type of property crime"
la var off_othviolent "Count of inmates whose most serious offense was another type of violent offense"
la var off_other "Count of inmates whose most serious offense was other/unspecified"
la var off_missing "Count of inmates whose most serious offense information was missing"

* count of inmates by 5-level categorization of most serious sentenced offense, data for 2004-2019 from NCRP
la var crime_violent "Count of inmates whose most serious offence was violent"
la var crime_public "Count of inmates whose most serious offence was public order"
la var crime_property "Count of inmates whose most serious offence was property crime"
la var crime_drugs "Count of inmates whose most serious offence was drug-related"
la var crime_other "Count of inmates whose most serious offence was other/unspecified"
la var crime_missing "Count of inmates whose most serious offence information was missing"

* count of inmate deaths of state and federal prisoners, data for 2001-2019 from BJS, Mortality in Correctional Institutions
la var raw_deaths "Count of all deaths in state's prisons"
la var deaths_fed_total "Count of all deaths in federal prisons"
la var deaths_state_total "Count of all deaths in state prisons for each year"

* misc additions towards end of research period:
la var is_coll_flag "Flag for if I changed the in-state collect rate from original data source"
la var collect_eliminated "Flag for if the state eliminated collect call option, in which case I imputed prepaid value"
la var is_pre_flag "Flag for if I changed the in-state prepaid rate from original data source"
la var is_debit_flag "Flag for if I changed the in-state debit rate from original data source"

sort state year
order state_fips state state_abbrev year is_coll_15m oos_coll_15m total_pop total_pop2 total_pop3 rated_cap nined_rated_cap lowest_cap_pct highest_cap_pct inmate_noncon_* inmate_contact_* staff_miscond_* staff_harassment_*

save "2000_data\500_working\labeled_prison_dta", replace

log close
