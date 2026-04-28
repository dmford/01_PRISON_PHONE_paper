* 1_conversions_and_merging.do

clear all

*cd "\bigdata\mbateslab\dford013\coding\01_PRISON_PHONE_paper"
cd "~\coding\01_PRISON_PHONE_paper"

********************************************************************************

capture log close
log using "3000_code\SMCL_logs\1_conversions_and_merging", smcl replace

*ssc install statastates

* outcomes: inmate_noncon_, inmate_contact_, staff_miscond_, staff_harassment_
	* both all(egations) and subs(tantiations), for 2004-2018
import delimited "2000_data\200_raw\prea_data.csv", encoding(UTF-8)
save "2000_data\400_base\prea_dta", replace

* my phone rates: is_coll_, is_pre, is_debit, oos_coll, oos_pre, oos_debit
	* _fee, _rate, and _flat, for 2005-2018
import delimited "2000_data\200_raw\phone_rate_new_data.csv", encoding(UTF-8) clear
destring oos_coll_rate, replace
save "2000_data\400_base\phone_rate_new_dta", replace

* website phone rates: oos_avg_rate and is_avg_rate, for 2008 + 2013-2019
import delimited "2000_data\200_raw\phone_rate_old_data.csv", encoding(UTF-8) clear
save "2000_data\400_base\phone_rate_old_dta", replace

* population data by sentence length (+ gender); 1+, 1-, unsen, for 2000-2019
import delimited "2000_data\200_raw\population_data.csv", encoding(UTF-8) clear
save "2000_data\400_base\population_dta", replace

* capacity data, rated_, operational_, design_, custody_pop, 
	* plus lowest_cap_pct, highest_cap_pct, for 2011-2019
import delimited "2000_data\200_raw\capacity_data.csv", encoding(UTF-8) clear
order state year
save "2000_data\400_base\capacity_dta", replace

* blocked suicide data: in blocked-years, for 2001-2019
import delimited "2000_data\200_raw\suicide_blocked_data.csv", encoding(ISO-8859-2) clear
sort state year
save "2000_data\400_base\suicide_blocked_dta.dta", replace

* supplemental: counts for age bins, education levels, sentence lengths, offense types, for 2004-2019 
import delimited "2000_data\200_raw\states_2004_2019_ages_plus.csv", encoding(UTF-8) clear
save "2000_data\400_base\states_2004_2019_ages_plus_dta", replace

* unconditional deaths: raw_death_count, deaths_fed_total, deaths_state_total, for 2001-2019
import delimited "2000_data\200_raw\raw_death_counts_2001_2019.csv", encoding(UTF-8) clear
save "2000_data\400_base\raw_death_counts_2001_2019_dta", replace

* merging above into single DTA file
use "2000_data\400_base\prea_dta", replace
merge 1:m state year using "2000_data\400_base\phone_rate_new_dta.dta", nogen
merge m:m state year using "2000_data\400_base\phone_rate_old_dta.dta", nogen
merge m:1 state year using "2000_data\400_base\capacity_dta.dta", nogen
merge m:1 state year using "2000_data\400_base\population_dta.dta", nogen
merge m:1 state year using "2000_data\400_base\suicide_blocked_dta.dta", nogen
merge m:1 state year using "2000_data\400_base\states_2004_2019_ages_plus_dta.dta", nogen
merge m:1 state year using "2000_data\400_base\raw_death_counts_2001_2019_dta.dta", nogen

statastates, name(state)
drop _merge

* dropping DC and Hawaii
drop if (state_fips==11) 
drop if (state_fips==15) 
sort state year

save "2000_data\500_working\merged_prison_dta", replace

log close
