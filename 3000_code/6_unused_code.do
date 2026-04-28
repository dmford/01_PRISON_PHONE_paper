* 6_unused_code.do

clear all

*cd "\bigdata\mbateslab\dford013\coding\01_PRISON_PHONE_paper"
cd "~\coding\01_PRISON_PHONE_paper"

********************************************************************************

capture log close 
log using "3000_code\SMCL_logs\4_final_output", smcl replace



use "2000_data\500_working\labeled_prison_dta", replace
sort state year
save "2000_data\500_working\unused_code_dta", replace

******************************************************************************

* generating treatment = (min_FD_abs <= 1.6585)
* THIS THRESHOLD IS HARD CODED, NEED TO UPDATE MANUALLY IF DATASET CHANGES *
*bysort state: egen temp_min_FD_abs = min(fd_oos_coll_15m) if year>=2007 & year<=2018
*bysort state: gen temp_treatment = (abs(temp_min_FD_abs) >=1.6585 & temp_min_FD_abs!=.)
*bysort state: egen avg_temp_treatment = mean(temp_treatment)
*gen treatment = (avg_temp_treatment>0)
*drop temp_*

* graph depicting how I made the choice: 
*bysort state: egen temp_min_FD_abs = min(fd_oos_coll_15m) if year>=2007 & year<=2018
*sort temp_min_FD_abs
*drop if year!=2014
*gen n=_n
*gen temp_min_FD_abs_diff = temp_min_FD_abs[_n] - temp_min_FD_abs[_n-1]
*egen temp_max_min_FD_abs_diff_qtl = max(temp_min_FD_abs_diff) if n!=35
*order state year temp_*
*tw scatter temp_min_FD_abs_diff n, xline()

******************************************************************************


* can try both where treatment is defined as law passed and above, meaning single entry date, and where treatment is when they go below the value

* 8/20/22
* Common Entry Date: Supposed T=2, balanced, X time-invariant
* Di, Ft, Wit
* first, supposing there is a single entry date, some basic inference

* dropping years without PREA data
drop if year<2004 | year>2018

* no rate data before 2008 or after 2018
drop if year<2008 | year>2018
drop year_1 

* two states with missing observation data for inmate_noncon_all and staff_miscond_all
gen balanced = (state!="ILLINOIS" & state!="NEVADA")

* should be strongly balanced now 
xtset state_fips year
drop year_7 /// this is 2014, omitting as is standard

gen w=treat_base*caps_enact

*** demeaning control variables 
foreach control in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs total_pop oneplus_tot_pop oneminus_tot_pop unsen_tot_pop unsen_m_pop unsen_f_pop total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap rated_cap lowest_cap_pct highest_cap_pct age_1824 age_2534 age_3544 age_4554 age_55p educ_anycoll educ_hs educ_nohs sent_1m sent_1_2 sent_2_5 sent_5_10 sent_10_25 sent_25p sent_life sent_miss off_manslaughter off_assault off_drugs off_fraud off_larceny off_cartheft off_murder off_burglary off_publicorder off_rapesa off_robbery off_othprop off_othviolent off_other off_missing crime_violent crime_public crime_property crime_drugs crime_other crime_missing {
	sum `control' if treat_base
	gen `control'_dm = `control' - r(mean)
	la var `control'_dm "`control' Covariate De-Meaned"
}

* reg OUTCOME i.w i.w#c.X_dm i.d i.f2 X i.d#X i.f2#c.X, vce(cl cid)
eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	eststo: qui reg `outcome' i.w i.treat_base i.year_* i.w#c.total_m_pop_dm i.w#c.total_f_pop_dm total_m_pop_dm total_f_pop_dm 
}

* reg D.OUTCOME w i.w#c.X_dm x, vce(robust)
* xtreg OUTCOME i.w i.w#c.X_dm i.f2 i.f2#X, fe vce(cl cid)
* xtreg OUTCOME i.w i.w#X_dm i.d i.f2 X i.d#c.X i.f2#c.X, re vce(cl cid)
* gen dOUTCOME = D.y

* Regression Adjustment 
* est ATET of (w) on dOUTCOME controlling for X
* teffects ra (dOUTCOME X) (w), atet
* provides se that adjusts for sample averages of covariates
* alt, could forego centering with margins command

* xtreg OUTCOME i.w i.w#c.X i.f2 i.f2#c.X, fe vce(cl cid)

* margins, dydx(w) vce(uncond) subpop(if d==1)
* marginal means, predictive margins, marginal effects
* dydx(w) estimates marginal effect of w 
* vce(uncon) estimates SEs allowing for sampling of covariates
* subpop(a) estimates margins for subpop a

* where post is binary indicator for post period, equivalent estimations:
* reg OUTCOME i.w i.w#c.X_dm i.d i.post X i.d#c.X i.post#c.X, vce(cl cid)
* outcomes: 8x PREA outcome variables
* controls: total_m_pop, oneplus_m_pop, oneminus_m_pop, total_f_pop, oneplus_f_pop, oneminus_f_pop, operational_cap + nined_versions

drop if year==2013
eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	eststo: qui reg `outcome' i.w i.treat_base i.caps_enact i.w#c.total_m_pop_dm i.w#c.total_f_pop_dm i.treat_base#c.total_m_pop_dm i.treat_base#c.total_f_pop_dm i.caps_enact#c.total_m_pop_dm i.caps_enact#c.total_f_pop_dm total_m_pop_dm total_f_pop_dm nined_total_m_pop nined_total_f_pop off_rapesa_dm i.w#c.off_rapesa_dm i.treat_base#c.off_rapesa_dm i.caps_enact#c.off_rapesa_dm, vce(cl state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop() 
* one 10% significant, one insignificantly negative, rest insignificant but positive

* NOW ADD
* same controls, but adding allegations 
foreach outcome in inmate_noncon inmate_contact staff_miscond staff_harassment {
	reg `outcome'_subs i.w i.w#c.`outcome'_all_dm i.w#c.total_m_pop_dm i.w#c.oneplus_m_pop_dm i.w#c.oneminus_m_pop_dm i.w#c.total_f_pop_dm i.w#c.oneplus_f_pop_dm i.w#c.oneminus_f_pop_dm i.w#c.operational_cap_dm i.treat_base i.caps_enact `outcome'_all_dm total_m_pop oneplus_m_pop oneminus_m_pop total_f_pop oneplus_f_pop oneminus_f_pop operational_cap i.treat_base#c.`outcome'_subs i.treat_base#c.total_m_pop i.treat_base#c.oneplus_m_pop i.treat_base#c.oneminus_m_pop i.treat_base#c.total_f_pop i.treat_base#c.oneplus_f_pop i.treat_base#c.oneminus_f_pop i.treat_base#c.operational_cap i.caps_enact#c.`outcome'_subs i.caps_enact#c.total_m_pop i.caps_enact#c.oneplus_m_pop i.caps_enact#c.oneminus_m_pop i.caps_enact#c.total_f_pop i.caps_enact#c.oneplus_f_pop i.caps_enact#c.oneminus_f_pop i.caps_enact#c.operational_cap, vce(cl state_fips)
}
* all positive, three 5% significant, other has t=0.47

* what if I drop 2013, the "anticipation" year? 
* I believe this would remove anticipation concerns 
* drop 2013, same controls as above regression
drop if year==2013
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	reg `outcome' i.w i.w#c.total_m_pop_dm i.w#c.oneplus_m_pop_dm i.w#c.oneminus_m_pop_dm i.w#c.total_f_pop_dm i.w#c.oneplus_f_pop_dm i.w#c.oneminus_f_pop_dm i.w#c.operational_cap_dm i.treat_base i.caps_enact total_m_pop oneplus_m_pop oneminus_m_pop total_f_pop oneplus_f_pop oneminus_f_pop operational_cap i.treat_base#c.total_m_pop i.treat_base#c.oneplus_m_pop i.treat_base#c.oneminus_m_pop i.treat_base#c.total_f_pop i.treat_base#c.oneplus_f_pop i.treat_base#c.oneminus_f_pop i.treat_base#c.operational_cap i.caps_enact#c.total_m_pop i.caps_enact#c.oneplus_m_pop i.caps_enact#c.oneminus_m_pop i.caps_enact#c.total_f_pop i.caps_enact#c.oneplus_f_pop i.caps_enact#c.oneminus_f_pop i.caps_enact#c.operational_cap, vce(cl state_fips)
}
* all positive, seeing 3-4 5% significant

* drop 2013, using _rates as outcomes
foreach outcome in inmate_noncon_rate inmate_contact_rate staff_miscond_rate staff_harassment_rate {
	reg `outcome' i.w i.w#c.total_m_pop_dm i.w#c.oneplus_m_pop_dm i.w#c.oneminus_m_pop_dm i.w#c.total_f_pop_dm i.w#c.oneplus_f_pop_dm i.w#c.oneminus_f_pop_dm i.w#c.operational_cap_dm i.treat_base i.caps_enact total_m_pop oneplus_m_pop oneminus_m_pop total_f_pop oneplus_f_pop oneminus_f_pop operational_cap i.treat_base#c.total_m_pop i.treat_base#c.oneplus_m_pop i.treat_base#c.oneminus_m_pop i.treat_base#c.total_f_pop i.treat_base#c.oneplus_f_pop i.treat_base#c.oneminus_f_pop i.treat_base#c.operational_cap i.caps_enact#c.total_m_pop i.caps_enact#c.oneplus_m_pop i.caps_enact#c.oneminus_m_pop i.caps_enact#c.total_f_pop i.caps_enact#c.oneplus_f_pop i.caps_enact#c.oneminus_f_pop i.caps_enact#c.operational_cap, vce(cl state_fips)
}
* again, all positive, seeing 5% significance in 3/4


* xtreg OUTCOME i.w i.w#i.c.X_dm i.post i.post#c.X, fe vce(cl cid)
* xtreg OUTCOME i.w i.w#i.c.X_dm i.tid i.tid#c.X, fe vce(cl cid)
* xtreg OUTCOME i.w i.w#i.c.X i.post i.post#c.X, fe vce(cl cid)
* margins, dydx(w) vce(uncond) subpop(if d==1)
* I believe above specifications are all equivalent 
* (see did_4.dta, .do) 

* STAGGERED ENTRY DATE: first treated at t=q, cohort dummies defined dq dqp1, ..., dT, single covariate.
* showing fe version where X demeaned

* will need to create indicator variables for dq, dqp1, dqp2, dqp3, etc. 
* how to define treatment: when observed under, when observed GOING under? when observed reducing by >X%? 
* would I be keeping the same 7-year span to have a balanced panel? 
* need to: 
** define t=q, the earliest year of treatment 
** define dq dummy, 1 if treated in t=q
** define dqp1, ..., dqpT dummies
** define fq timeline dummy, will interact year group is treated with years since first group treated
** similarly with fqp1, ..., fqpT dummies

** need to de-mean covariates by dq, dqp1, ..., dqpT status
xtset state_fips year
*for each dq, dqp1, etc. - will need a loop for each dqpX value!
*sum X if dq
*gen X_dmq = x-r(mean)

* ..., generate all of these for time periods
* in below line, be careful with ... parts
*xtreg OUTCOME c.dq#c.fq ... c.dq#c.fT ///
*c.dqp1#c.fqp1 ... c.dqp1#c.fT ... c.dT#c.fT ///
*c.dq#c.fq#c.q_dmq ... c.dq#c.fT#c.X_dmT /// 
*c.dqpt#c.fqp1#c.X_dmqp1 ... dqp1#c.fT#c.x_dmqp1 ... dT#c.fT#c.X_dmT ///
*i.tid i.tid#c.x, fe vce(cl cid)

* see staggered_6.dta and .do for example

* further, easy to allow for heterogeneous trends. Assuming linear time trend defined, fe version of command is: 
*xtreg OUTCOME c.dq#c.fq ... c.dq#c.fT /// 
*c.dqp1#c.fqp1 ... c.dqp1#c.fT ... c.dT#c.fT ///
*c.dq#c.fq#c.X_dmq ... c.dq#c.fT#c.X_dmT ///
*c.dqp1#c.fqp1#c.X_dmqp1 ... dqp1#c.fT#c.X_dmqp1 ... dT#c.fT#c.X_dmT ///
*i.tid i.tid#c.x i.dq#c.t ... i.dT#c.t, fe vce(cl cid)

******************************************************************************



***** RUNNING REGRESSIONS *****

* BASELINE, NO CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
eststo clear
foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
	xtset state_fips year
	eststo: qui xtreg `o' i.year treat_base##caps_enact, fe cluster(state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year)
* t-stats: some positive, some negative, none significant
* N=650-730


* WITH POP CONTROLS
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
eststo clear
foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
	xtset state_fips year
	eststo: qui xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop, fe vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year)
* t-stats: some positive, some negative, none significant
* N=650-730


* WITH POP/CAP CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
eststo clear
foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
	xtset state_fips year
	eststo: qui xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct, fe vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year)
* t-stats: all positive, (3) at 1%, (4) at 5%, (7) at 5%
* N=210-230


* SUBSTANTIATION RATES, NO CONTROLS:
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
eststo clear
foreach o of varlist inmate_contact_rate inmate_noncon_rate staff_harassment_rate staff_miscond_rate {
xtset state_fips year
eststo: qui xtreg `o' i.year treat_base##caps_enact, fe cluster(state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year)
* t-stats: some positive, some negative, none significant
* N=570-710


* SUBSTANTIATION RATES, WITH POP CONTROLS:
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
eststo clear
foreach o of varlist inmate_contact_rate inmate_noncon_rate staff_harassment_rate staff_miscond_rate {
xtset state_fips year
eststo: qui xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop, fe vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year)
* t-stats: all positive, none significant
* N=570-710


* SUBSTANTIATION RATES, WITH POP/CAP CONTROLS:
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
eststo clear
foreach o of varlist inmate_contact_rate inmate_noncon_rate staff_harassment_rate staff_miscond_rate {
xtset state_fips year
eststo: qui xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct, fe vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year)
* t-stats: some positive, some negative, none significant
* N=190-210


***** BALANCED REGRESSIONS *****

* FULL LOOP, T_* BALANCED, NO CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist T_coll T_alt {
	use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
				drop if drop_bal_`time'==1 | abs(`time') > bal_mag_`time'
				xtset state_fips `time'_pos
				eststo: qui xtreg `o' `treat'##`post' i.`time'_pos, fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time'_pos)
		}
	}
}


* FULL LOOP, T_* BALANCED, WITH POP CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist T_coll T_alt {
	use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
				drop if drop_bal_`time'==1 | abs(`time') > bal_mag_`time'
				xtset state_fips `time'_pos
				eststo: qui xtreg `o' `treat'##`post' i.`time'_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop, fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time'_pos)
		}
	}
}


* FULL LOOP, T_* BALANCED, WITH POP/CAP CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist T_coll T_alt {
	use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
				drop if drop_bal_`time'==1 | abs(`time') > bal_mag_`time'
				xtset state_fips `time'_pos
				eststo: qui xtreg `o' `treat'##`post' i.`time'_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct, fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time'_pos)
		}
	}
}


* FULL LOOP, T_* BALANCED SUBSTANTIATION RATES, NO CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist T_coll T_alt {
	use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_rate inmate_noncon_rate staff_harassment_rate staff_miscond_rate {
				drop if drop_bal_`time'==1 | abs(`time') > bal_mag_`time'
				xtset state_fips `time'_pos
				eststo: qui xtreg `o' `treat'##`post' i.`time'_pos, fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time'_pos)
		}
	}
}


* FULL LOOP, T_* BALANCED SUBSTANTIATION RATES , WITH POP CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist T_coll T_alt {
	use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_rate inmate_noncon_rate staff_harassment_rate staff_miscond_rate {
				drop if drop_bal_`time'==1 | abs(`time') > bal_mag_`time'
				xtset state_fips `time'_pos
				eststo: qui xtreg `o' `treat'##`post' i.`time'_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop, fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time'_pos)
		}
	}
}


* FULL LOOP, T_* BALANCED SUBSTANTIATION RATES, WITH POP/CAP CONTROLS: 
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist T_coll T_alt {
	use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_rate inmate_noncon_rate staff_harassment_rate staff_miscond_rate {
				drop if drop_bal_`time'==1 | abs(`time') > bal_mag_`time'
				xtset state_fips `time'_pos
				eststo: qui xtreg `o' `treat'##`post' i.`time'_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct, fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time'_pos)
		}
	}
}


* FULL LOOP, NO CONTROLS
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
foreach time of varlist year T_coll_pos T_alt_pos {
	eststo clear
	foreach treat of varlist treat_base treat_early_base {
		eststo clear
		foreach post of varlist caps_enact caps_proposed {
			eststo clear
			foreach o of varlist inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs {
				xtset state_fips `time'
				eststo: qui xtreg `o' `treat'##`post' i.`time', fe vce(cluster state_fips)
			}
		esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.`time')
		}
	}
}

STOP

***** SUICIDES WILL BE ADDED HERE EVENTUALLY *****
* but maybe not, paper is dead

* having issues here, duplicates is not correctly dropping things 

* have to deal with some weird timelines here
use "~\coding\\01_PRISON_PHONE_paper\2000_data\500_working\unused_code_dta", replace
drop nined_operational_cap operational_cap
keep state state_fips time_block suicides treat_early_base treat_base block_post block_size block_avg_* block_med_* nined_*
duplicates drop
drop if time_block==.

* baseline, no controls: 
eststo clear
xtset state_fips time_block
eststo: xtreg suicides treat_base##c.block_post i.time_block block_size, fe vce(cluster state_fips)
* t-stat: positive and insignificant

* with avg pop/cap controls: 
xtset state_fips time_block
eststo: qui xtreg suicides treat_base##c.block_post i.time_block block_size block_avg_total_m_pop block_avg_total_f_pop block_avg_oneplus_m_pop block_avg_oneplus_f_pop block_avg_oneminus_m_pop block_avg_oneminus_f_pop block_avg_design_cap block_avg_custody_pop block_avg_lowest_cap_pct block_avg_highest_cap_pct nined_block_avg_total_m_pop nined_block_avg_total_f_pop nined_block_avg_oneplus_m_pop nined_block_avg_oneplus_f_pop nined_block_avg_oneminus_m_pop nined_block_avg_oneminus_f_pop nined_block_avg_design_cap nined_block_avg_custody_pop nined_block_avg_lowest_cap_pct nined_block_avg_highest_cap_pct, fe vce(cluster state_fips)
* t-stat: positive and insignificant

* with med pop/cap controls: 
xtset state_fips time_block
eststo: qui xtreg suicides treat_base##c.block_post i.time_block block_size block_med_total_m_pop block_med_total_f_pop block_med_oneplus_m_pop block_med_oneplus_f_pop block_med_oneminus_m_pop block_med_oneminus_f_pop block_med_operational_cap block_med_design_cap block_med_custody_pop block_med_lowest_cap_pct block_med_highest_cap_pct nined_block_med_total_m_pop nined_block_med_total_f_pop nined_block_med_oneplus_m_pop nined_block_med_oneplus_f_pop nined_block_med_oneminus_m_pop nined_block_med_oneminus_f_pop nined_block_med_operational_cap nined_block_med_design_cap nined_block_med_custody_pop nined_block_med_lowest_cap_pct nined_block_med_highest_cap_pct, fe vce(cluster state_fips)
* t-stat: positive and insignificant 

esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.time_block block_avg_* block_med_* nined_*) se
* treat_early: all positive, (3) and (5) at +10%
* treat_early_base: all positive, none significant

