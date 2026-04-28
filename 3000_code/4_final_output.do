* 4_final_output.do

clear all

*cd "\bigdata\mbateslab\dford013\coding\01_PRISON_PHONE_paper"
cd "~\coding\01_PRISON_PHONE_paper"

********************************************************************************

capture log close 
log using "3000_code\SMCL_logs\4_final_output", smcl replace

*ssc install outreg2

use "2000_data/500_working/labeled_prison_dta", replace
sort state year

* no PREA data before 2004 or after 2018
drop if (year < 2004) | (year > 2018)
* year_1 = 2004

* no rate data before 2008 or after 2018
drop if (year<2008) | (year>2018)
*drop year_1 

* playing around trying to balance full set -- imputing IL & NV missing values with surrounding year means
*egen IL_inmate_noncon_all_mean1 = mean(inmate_noncon_all) if state=="ILLINOIS" & year<2007
*egen IL_inmate_noncon_all_mean2 = mean(inmate_noncon_all) if state=="ILLINOIS" & year>2011 & year<2015
*replace inmate_noncon_all = IL_inmate_noncon_all_mean1 if state=="ILLINOIS" & year==2005
*replace inmate_noncon_all = IL_inmate_noncon_all_mean2 if state=="ILLINOIS" & year==2013
*egen NV_inmate_noncon_all_mean1 = mean(inmate_noncon_all) if state=="NEVADA" & year==2016
*replace inmate_noncon_all = NV_inmate_noncon_all_mean1 if state=="NEVADA" & year==2016

* playing around imputing basic early phone rate years
*bysort state: gen early_rate_imputes = oos_coll_15m if year==2008
*bysort state: egen early_imputes = max(early_rate_imputes)
*replace oos_coll_15m = early_imputes if year<2008

* identifying balanced panel
* missing inmate_noncon_all: IL*1, NV*1
* missing staff_miscond_all: NONE
gen balanced = (state!="ILLINOIS" & state!="NEVADA")

bysort state: egen pre_rate = mean(oos_coll_15m) if year==2013

la var oos_coll_15m "Treatment"
la var total_pop "Prison Pop."
la var total_pop2 "Pop. Squared"
la var total_pop3 "Pop. Cubed"
la var treat_base "Treatment Status"
la var inmate_noncon_all "Inmate Sexual Acts"
la var staff_miscond_all "Staff Misconduct"
la var pre_rate "Pre-Period Cost ($)"

* Labeling Values for Table: 
label define treatment_status 0 "Control" 1 "Treated" 
label values treat_base treatment_status

collect clear

dtable inmate_noncon_all staff_miscond_all pre_rate total_pop, by(treat_base) ///
	name(dstats) nosample title("Raw Differences") 
collect style cell result[mean sd]#var[inmate_noncon_all], nformat(%3.2fc)
collect style cell result[mean sd]#var[staff_miscond_all], nformat(%3.2fc)
collect style cell result[mean sd]#var[pre_rate], nformat(%3.2fc)
collect style cell result[mean sd]#var[total_pop], nformat(%5.0fc)
collect export "6000_LaTeX\prison_phone_dstats.tex", replace tableonly

save "2000_data/500_working/final_output_dta", replace

**********

/*
* Preliminary Unbalanced TWFE, Adding Controls 

use "2000_data/500_working/final_output_dta", replace

drop if balanced==0

local yit "inmate_noncon_all staff_miscond_all"

local xit0 "c.oos_coll_15m c.total_pop i.state_fips i.year"
local xit1 "c.oos_coll_15m c.total_pop i.state_fips i.year c.age_* i.nined_age_*"
local xit2 "c.oos_coll_15m c.total_pop i.state_fips i.year c.educ_* i.nined_educ_*"
local xit3 "c.oos_coll_15m c.total_pop i.state_fips i.year"
local xit4 "c.oos_coll_15m c.total_pop i.state_fips i.year"
local xit5 "c.oos_coll_15m c.total_pop i.state_fips i.year"

* xit0
foreach y in `yit' {
	reg `y' `xit0', vce(cl state_fips)
	outreg2 using "4000_outputs/unb_TWFE_`y'1.0.tex", dec(3) replace ctitle(Xit0) nocons keep(oos_coll_15m total_pop) title(TWFE: "`: var label `y''")
}

* xit1
foreach y in `yit' {
	reg `y' `xit1', vce(cl state_fips)
	outreg2 using "4000_outputs/unb_TWFE_`y'1.0.tex", dec(3) append ctitle(Xit1) nocons keep(oos_coll_15m total_pop age_*) title(TWFE: "`: var label `y''")
}

* xit2
foreach y in `yit' {
	reg `y' `xit2', vce(cl state_fips)
	outreg2 using "4000_outputs/unb_TWFE_`y'1.0.tex", dec(3) append ctitle(Xit2) nocons keep(oos_coll_15m total_pop educ_*) title("`: var label `y''")
}

* xit3
foreach y in `yit' {
	reg `y' `xit3', vce(cl state_fips)
	outreg2 using "4000_outputs/unb_TWFE_`y'1.0.tex", dec(3) append ctitle(Xit3) nocons keep(oos_coll_15m total_pop) title("`: var label `y''")
}

* xit4
foreach y in `yit' {
	reg `y' `xit4', vce(cl state_fips)
	outreg2 using "4000_outputs/unb_TWFE_`y'1.0.tex", dec(3) append ctitle(Xit4) nocons keep(oos_coll_15m total_pop) title("`: var label `y''")
}

* xit5
foreach y in `yit' {
	reg `y' `xit5', vce(cl state_fips)
	outreg2 using "4000_outputs/unb_TWFE_`y'1.0.tex", dec(3) append ctitle(Xit5) nocons keep(oos_coll_15m total_pop) title("`: var label `y''")
}

* total_pop strict improvement, seems mandatory
* design_cap makes intuitive sense, but doesn't seem very useful (0.95 corr with total_pop)
* total_pop2 seems pretty negligible
* rated_cap and operational_cap even more correlated with total_pop, thinking design_cap if any
* age_* seem to drive estimates negative, which seems odd. Why could this be? 
* educ_* seem to strengthen the estimates somewhat?
*/

**********

* MAKING 1ST SET OF TABLES: 

* Specification #1, unbalanced TWFE, Baseline: 
* yit = alpha + xit*beta + si*gamma + ft*delta + eit
use "2000_data/500_working/final_output_dta", replace

local yit "inmate_noncon_all staff_miscond_all"
local xit "c.oos_coll_15m c.total_pop i.state_fips i.year"

* SPECIFICATION #1 REGRESSION LOOP:
foreach y in `yit' {
	reg `y' `xit', vce(cluster state_fips)
	outreg2 using "6000_LaTeX/table_`y'_1.1.tex", dec(3) replace ctitle(TWFE) nocons keep(oos_coll_15m total_pop) label tex(frag) nonotes 
}

**********

* testing equivalency in my setting: using i.state_fips and i.year vs xi_bar and xt_bar 
/* 
* evidently, 2K vs (N-1) + (T-1) controls, or 
* for Mundlak vs TWFE tables, coef same, F-Stat only appearing on Mundlak specification, TWFE likely too many DoF issue
use "2000_data/500_working/final_output_dta", replace

*drop if balanced==0

local yit "inmate_noncon_all staff_miscond_all"
local xit "oos_coll_15m total_pop design_cap crime_violent off_rapesa nined_design_cap nined_crime_violent nined_off_rapesa"

foreach x in `xit' {
	bysort state: egen `x'_i_bar = mean(`x')
}
local xi_bar "*_i_bar"

foreach x in `xit' {
	bysort year: egen `x'_t_bar = mean(`x')
}
local xt_bar "*_t_bar"

local xit "c.oos_coll_15m c.total_pop c.design_cap c.crime_violent c.off_rapesa i.nined_design_cap i.nined_crime_violent i.nined_off_rapesa"

* Bm Regressions: 
reg inmate_noncon_all `xit' `xi_bar' `xt_bar', vce(cluster state_fips)
outreg2 using "4000_outputs/mundlak_vs_twfe_test2.tex", dec(3) replace ctitle(Mundlak) nocons keep(oos_coll_15m total_pop design_cap crime_violent off_rapesa) addstat("F Test", e(F)) title(More Controls Odd: inmate_noncon_all, Even: staff_miscond_all) nonotes 

reg staff_miscond_all `xit' `xi_bar' `xt_bar', vce(cluster state_fips)
outreg2 using "4000_outputs/mundlak_vs_twfe_test2.tex", dec(3) append ctitle(Mundlak) nocons keep(oos_coll_15m total_pop design_cap crime_violent off_rapesa) addstat("F Test", e(F))


foreach y in `yit' {
	reg `y' `xit' i.state_fips i.year, vce(cluster state_fips)
	outreg2 using "4000_outputs/mundlak_vs_twfe_test2.tex", dec(3) append ctitle(TWFE) nocons keep(oos_coll_15m total_pop design_cap crime_violent off_rapesa)
}

*/ 

* for balanced panel, TWFE vs Mundlak appear to give equivalent estimates

**********

* Specification #2, unbalanced TWFE, adding total_pop2 & total_pop3: 
* yit = alpha + xit*beta + si*gamma + ft*delta + eit
use "2000_data/500_working/final_output_dta", replace

local yit "inmate_noncon_all staff_miscond_all"
local xit "c.oos_coll_15m c.total_pop c.total_pop2 i.state_fips i.year"

* SPECIFICATION #2 REGRESSION LOOP:
foreach y in `yit' {
	reg `y' `xit', vce(cluster state_fips)
	outreg2 using "6000_LaTeX/table_`y'_1.1.tex", dec(3) append ctitle(TWFE) nocons keep(oos_coll_15m total_pop total_pop2 total_pop3) label tex(frag) nonotes 
}

**********

* Specification #3, Balanced Mundlak: 
* yit = alpha + xit*beta + xi_bar*zeta + xt_bar*eta + eit
use "2000_data/500_working/final_output_dta", replace

drop if (balanced == 0)

local yit "inmate_noncon_all staff_miscond_all"
local xit "oos_coll_15m total_pop"

foreach x in `xit' {
	bysort state: egen `x'_i_bar = mean(`x')
}
local xi_bar "*_i_bar"

foreach x in `xit' {
	bysort year: egen `x'_t_bar = mean(`x') 
}
local xt_bar "*_t_bar"

local xit "c.oos_coll_15m c.total_pop"

* SPECIFICATION #3 REGRESSION LOOP:
foreach y in `yit' {
	reg `y' `xit' `xi_bar' `xt_bar', vce(cluster state_fips)
	outreg2 using "6000_LaTeX/table_`y'_1.1.tex", dec(3) append ctitle(TWM) nocons keep(oos_coll_15m total_pop) label tex(frag) nonotes 
	*addstat("F-Statistic", e(F))
}

**********

* Specification #4, Balanced Mundlak, adding xi_bar & xt_bar interaction: 
* yit = alpha + xit*beta + xi_bar*zeta + xt_bar*eta + (xi_bar#xt_bar)*pi + eit
use "2000_data/500_working/final_output_dta", replace

*balancing dataset
drop if (balanced==0)

local yit "inmate_noncon_all staff_miscond_all"
local xit "oos_coll_15m total_pop"

foreach x in `xit' {
	bysort state: egen `x'_i_bar = mean(`x') 
}
local xi_bar "c.*_i_bar"

foreach x in `xit' {
	bysort year: egen `x'_t_bar = mean(`x') 
}
local xt_bar "c.*_t_bar"

local xit "c.oos_coll_15m c.total_pop"

reg inmate_noncon_all `xit' `xi_bar'##`xt_bar', vce(cl state_fips)

* SPECIFICATION #4 REGRESSION LOOP:
foreach y in `yit' {
	reg `y' `xit' `xi_bar'##`xt_bar', vce(cl state_fips)
	outreg2 using "6000_LaTeX/table_`y'_1.1.tex", dec(3) append ctitle(TWM+Int) nocons keep(oos_coll_15m total_pop) label tex(frag) nonotes 
	*addstat("F-Statistic", e(F))
}

**********

* Specification #5, balanced Mundlak, full interactions: 
* yit = alpha + xit*beta + xi_bar*zeta + xt_bar*eta + (xi_bar#xt_bar)*pi + xit#(xi_bar - x_bar)*omicron + xit#(xt_bar - x_bar)*rho + eit
use "2000_data/500_working/final_output_dta", replace

drop if balanced==0

local yit "inmate_noncon_all staff_miscond_all"
local xit "oos_coll_15m total_pop"

foreach x in `xit' {
	bysort state: egen `x'_i_bar = mean(`x') 
}
local xi_bar "*_i_bar"

foreach x in `xit' {
	bysort year: egen `x'_t_bar = mean(`x') 
}
local xt_bar "*_t_bar"

foreach x in `xit' {
	egen `x'_bar = mean(`x') 
}

* need to change this manually if xit changes!
local x_bar "oos_coll_15m_bar total_pop_bar"

foreach x in `xit' {
	gen `x'i_less_x = `x'_i_bar - `x'_bar
	gen `x't_less_x = `x'_t_bar - `x'_bar
}
local xilessx "*i_less_x"
local xtlessx "*t_less_x"

local xit "c.oos_coll_15m c.total_pop"
local xi_bar "c.*_i_bar"
local xt_bar "c.*_t_bar"
local xilessx "c.*i_less_x"
local xtlessx "c.*t_less_x"

* SPECIFICATION #5 REGRESSION LOOP:
foreach y in `yit' {
	reg `y' `xit' `xi_bar' `xt_bar' (`xi_bar')#(`xt_bar') (`xit')#(`xilessx') (`xit')#(`xtlessx'), vce(cl state_fips)
	*outreg2 using "6000_LaTeX/table_`y'_1.1.tex", dec(2) append ctitle(Unb Mundlak, ++Int) nocons keep(oos_coll_15m total_pop) 
}

* MAKING 2ND SET OF TABLES NOW:
* (AND GRAPHS)

* #6: TWFE + total_pop + largest_reduc*T_3 + largest_reduc*T_2 + ... + largest_reduc*T2 + largest_reduc*T3
* yit = alpha + si*gamma + ft*delta + largest_reduc*T_3*beta1 + largest_reduc*T_2*beta2 + ... + largest*reduc3*beta6 + eit
use "2000_data/500_working/final_output_dta", replace

local yit "inmate_noncon_all staff_miscond_all"

bysort state: egen temp_max_reduc = min(fd_oos_coll_15m)
gen max_reduc = abs(temp_max_reduc) 
bysort state: gen temp_reduc_year_id = max_reduc + fd_oos_coll_15m 
bysort state: egen temp_reduc_year = min(year) if temp_reduc_year_id==0 & state!="FLORIDA"
bysort state: egen reduc_year = max(temp_reduc_year) if state!="FLORIDA"
drop temp_max_reduc temp_reduc_year_id temp_reduc_year

* FL increased rate in 2012
*replace reduc_year = 2012 if state=="FLORIDA"
*replace max_reduc = -0.3 if state=="FLORIDA"

la var max_reduc "Largest Observed Out-of-State 15m Collect Call Cost Reduction"
la var reduc_year "Year of Largest Observed Out-of-State 15m Collect Call Cost Reduction"

* NOTE: FLORIDA HAS NO REDUCTIONS, BUT IN FACT, AN INCREASE! RATES UP BY $0.30 IN 2012

gen eventT_3 = (year==reduc_year-3)
gen eventT_2 = (year==reduc_year-2)
gen eventT0 = (year==reduc_year)
gen eventT1 = (year==reduc_year+1)
gen eventT2 = (year==reduc_year+2)
gen eventT3 = (year==reduc_year+3)

foreach T in eventT_3 eventT_2 eventT0 eventT1 eventT2 eventT3 {
	gen max_reduc_`T' = max_reduc*`T'
}

local xit "c.total_pop"
local max_reduc_eventT "c.max_reduc_*"

* include:  c.crime_violent i.nined_crime_violent c.off_rapesa ? 

foreach y in `yit' {
	reg `y' `max_reduc_eventT' `xit' i.state_fips i.year, vce(cl state_fips)
	gen etime_T_3_`y' = _b[max_reduc_eventT_3]
	gen etime_T_3_`y'_se = _se[max_reduc_eventT_3]
	gen etime_T_2_`y' = _b[max_reduc_eventT_2]
	gen etime_T_2_`y'_se = _se[max_reduc_eventT_2]
	gen etime_T0_`y' = _b[max_reduc_eventT0]
	gen etime_T0_`y'_se = _se[max_reduc_eventT0]
	gen etime_T1_`y' = _b[max_reduc_eventT1]
	gen etime_T1_`y'_se = _se[max_reduc_eventT1]
	gen etime_T2_`y' = _b[max_reduc_eventT2]
	gen etime_T2_`y'_se = _se[max_reduc_eventT2]
	gen etime_T3_`y' = _b[max_reduc_eventT3]
	gen etime_T3_`y'_se = _se[max_reduc_eventT3]
	*outreg2 using "4000_outputs/table_`y'2.1.tex", dec(3) replace ctitle(Event Study, Unbalanced) nocons drop(i.state_fips i.year) title("`: var label `y''") label tex(frag) 
}

* constructing event study graphs
gen event_time = -3 if year==reduc_year-3
replace event_time = -2 if year==reduc_year-2
*replace event_time = -1 if year==reduc_year-1 
replace event_time = 0 if year==reduc_year
replace event_time = 1 if year==reduc_year + 1
replace event_time = 2 if year==reduc_year + 2
replace event_time = 3 if year==reduc_year + 3
drop if event_time==.

foreach y in `yit' {
gen reduc_etime_`y' = 0
replace reduc_etime_`y' = etime_T_3_`y' if event_time==-3
replace reduc_etime_`y' = etime_T_2_`y' if event_time==-2
replace reduc_etime_`y' = etime_T0_`y' if event_time==0
replace reduc_etime_`y' = etime_T1_`y' if event_time==1
replace reduc_etime_`y' = etime_T2_`y' if event_time==2
replace reduc_etime_`y' = etime_T3_`y' if event_time==3

gen reduc_etime_`y'_u = reduc_etime_`y'
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T_3_`y'_se*1.96 if event_time==-3
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T_2_`y'_se*1.96 if event_time==-2
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T0_`y'_se*1.96 if event_time==0
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T1_`y'_se*1.96 if event_time==1
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T2_`y'_se*1.96 if event_time==2
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T3_`y'_se*1.96 if event_time==3

gen reduc_etime_`y'_l = reduc_etime_`y'
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T_3_`y'_se*1.96 if event_time==-3
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T_2_`y'_se*1.96 if event_time==-2
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T0_`y'_se*1.96 if event_time==0
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T1_`y'_se*1.96 if event_time==1
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T2_`y'_se*1.96 if event_time==2
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T3_`y'_se*1.96 if event_time==3
}

* (cleaned-up for oral exam, sept 2024)
twoway (rspike reduc_etime_inmate_noncon_all_u reduc_etime_inmate_noncon_all_l event_time, mcolor(stc1)) || (scatter reduc_etime_inmate_noncon_all event_time, mcolor(stc1)), ///
	legend(off) name("inmate_noncon_all", replace) xtitle("0 = Year of Biggest Rate Reduction") ytitle(Counts of Allegations) ///
	xline(-0.5, lcolor(red) lwidth(0.1pt)) yline(0, lcolor(red) lwidth(0.1pt)) ///
	xlab(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3", nogrid) 
graph export "6000_LaTeX\inmate_noncon_all.eps", replace
graph export "6000_LaTeX\inmate_noncon_all.pdf", replace

twoway (rspike reduc_etime_staff_miscond_all_u reduc_etime_staff_miscond_all_l event_time, mcolor(stc1)) || (scatter reduc_etime_staff_miscond_all event_time, mcolor(stc1)), ///
	legend(off) name("staff_miscond_all", replace) xtitle("0 = Year of Biggest Rate Reduction") ytitle(Counts of Allegations) ///
	xline(-0.5, lcolor(red) lwidth(0.1pt)) yline(0, lcolor(red) lwidth(0.1pt)) ///
	xlab(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3", nogrid) 
graph export "6000_LaTeX\staff_miscond_all.eps", replace
graph export "6000_LaTeX\staff_miscond_all.pdf", replace

**********

* #7: same, but drop states that don't have PREA data for T_3 to T3 
* yit = alpha + si*gamma + ft*delta + largest_reduc*T_3*beta1 + largest_reduc*T_2*beta2 + ... + largest*reduc3*beta6 + eit

use "2000_data/500_working/final_output_dta", replace

local yit "inmate_noncon_all staff_miscond_all"

bysort state: egen temp_max_reduc = min(fd_oos_coll_15m)
gen max_reduc = abs(temp_max_reduc) 
bysort state: gen temp_reduc_year_id = max_reduc + fd_oos_coll_15m 
bysort state: egen temp_reduc_year = min(year) if temp_reduc_year_id==0 & state!="FLORIDA"
bysort state: egen reduc_year = max(temp_reduc_year) if state!="FLORIDA"
drop temp_max_reduc temp_reduc_year_id temp_reduc_year

la var max_reduc "Largest Observed Out-of-State 15m Collect Call Cost Reduction"
la var reduc_year "Year of Largest Observed Out-of-State 15m Collect Call Cost Reduction"

* NOTE: FLORIDA HAS NO REDUCTIONS, BUT IN FACT, AN INCREASE! RATES UP BY $0.30 IN 2012

gen eventT_3 = (year==reduc_year-3)
gen eventT_2 = (year==reduc_year-2)
gen eventT0 = (year==reduc_year)
gen eventT1 = (year==reduc_year+1)
gen eventT2 = (year==reduc_year+2)
gen eventT3 = (year==reduc_year+3)

foreach T in eventT_3 eventT_2 eventT0 eventT1 eventT2 eventT3 {
	gen max_reduc_`T' = max_reduc*`T'
}

local xit "c.total_pop"
local max_reduc_eventT "c.max_reduc_*"

bysort state: egen temp_timeline_check_1 = max(eventT_3) 
bysort state: egen temp_timeline_check_2 = max(eventT3)
bysort state: gen timeline_check = temp_timeline_check_1 + temp_timeline_check_2
gen fulltimeline = (timeline_check==2)
keep if fulltimeline==0 | state=="FLORIDA"

foreach y in `yit' {
	reg `y' `max_reduc_eventT' `xit' i.state_fips i.year, vce(cl state_fips)
	gen etime_T_3_`y' = _b[max_reduc_eventT_3]
	gen etime_T_3_`y'_se = _se[max_reduc_eventT_3]
	gen etime_T_2_`y' = _b[max_reduc_eventT_2]
	gen etime_T_2_`y'_se = _se[max_reduc_eventT_2]
	gen etime_T0_`y' = _b[max_reduc_eventT0]
	gen etime_T0_`y'_se = _se[max_reduc_eventT0]
	gen etime_T1_`y' = _b[max_reduc_eventT1]
	gen etime_T1_`y'_se = _se[max_reduc_eventT1]
	gen etime_T2_`y' = _b[max_reduc_eventT2]
	gen etime_T2_`y'_se = _se[max_reduc_eventT2]
	gen etime_T3_`y' = _b[max_reduc_eventT3]
	gen etime_T3_`y'_se = _se[max_reduc_eventT3]
	*outreg2 using "6000_LaTeX/table_`y'2.1.tex", dec(3) append ctitle(Event Study, Balanced) nocons drop(i.state_fips i.year) label tex(frag) 
}

* constructing event study graphs
gen event_time = -3 if year==reduc_year-3
replace event_time = -2 if year==reduc_year-2
*replace event_time = -1 if year==reduc_year-1
replace event_time = 0 if year==reduc_year
replace event_time = 1 if year==reduc_year + 1
replace event_time = 2 if year==reduc_year + 2
replace event_time = 3 if year==reduc_year + 3
drop if event_time==.

foreach y in `yit' {
gen reduc_etime_`y' = 0
replace reduc_etime_`y' = etime_T_3_`y' if event_time==-3
replace reduc_etime_`y' = etime_T_2_`y' if event_time==-2
replace reduc_etime_`y' = etime_T0_`y' if event_time==0
replace reduc_etime_`y' = etime_T1_`y' if event_time==1
replace reduc_etime_`y' = etime_T2_`y' if event_time==2
replace reduc_etime_`y' = etime_T3_`y' if event_time==3

gen reduc_etime_`y'_u = reduc_etime_`y'
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T_3_`y'_se*1.96 if event_time==-3
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T_2_`y'_se*1.96 if event_time==-2
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T0_`y'_se*1.96 if event_time==0
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T1_`y'_se*1.96 if event_time==1
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T2_`y'_se*1.96 if event_time==2
replace reduc_etime_`y'_u = reduc_etime_`y'_u + etime_T3_`y'_se*1.96 if event_time==3

gen reduc_etime_`y'_l = reduc_etime_`y'
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T_3_`y'_se*1.96 if event_time==-3
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T_2_`y'_se*1.96 if event_time==-2
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T0_`y'_se*1.96 if event_time==0
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T1_`y'_se*1.96 if event_time==1
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T2_`y'_se*1.96 if event_time==2
replace reduc_etime_`y'_l = reduc_etime_`y'_l - etime_T3_`y'_se*1.96 if event_time==3
}

twoway (rspike reduc_etime_inmate_noncon_all_u reduc_etime_inmate_noncon_all_l event_time, mcolor(stc1)) || (scatter reduc_etime_inmate_noncon_all event_time, mcolor(stc1)), ///
	legend(off) name("inmate_noncon_all_balanced", replace) xtitle("0 = Year of Biggest Rate Reduction") ytitle(Counts of Allegations) ///
	xline(-0.5, lcolor(red) lwidth(0.1pt)) yline(0, lcolor(red) lwidth(0.1pt)) ///
	xlab(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3", nogrid) 
graph export "6000_LaTeX\inmate_noncon_all_balanced.eps", replace
graph export "6000_LaTeX\inmate_noncon_all_balanced.pdf", replace

twoway (rspike reduc_etime_staff_miscond_all_u reduc_etime_staff_miscond_all_l event_time, mcolor(stc1)) || (scatter reduc_etime_staff_miscond_all event_time, mcolor(stc1)), ///
	legend(off) name("staff_miscond_all_balanced", replace) xtitle("0 = Year of Biggest Rate Reduction") ytitle(Counts of Allegations) ///
	xline(-0.5, lcolor(red) lwidth(0.1pt)) yline(0, lcolor(red) lwidth(0.1pt)) ///
	xlab(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3", nogrid) 
graph export "6000_LaTeX\staff_miscond_all_balanced.eps", replace
graph export "6000_LaTeX\staff_miscond_all_balanced.pdf", replace

**********

* not sure why I left this here??
*STOP

/*

**********

use "2000_data/500_working/final_output_dta", replace

* original DiD variable, focus of DiD regressions
gen d1 = treat_base
gen post1 = caps_enact
gen w1 = d1*post1

* Basic DID regression:
* reg Y w1 d1 time, vce(cluster id)
* worried about "anticipation" in 2013 --> dropping that year's observations
drop if year==2013
drop year_10

eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	eststo: qui reg `outcome' w1 d1 year_*, vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop(year_5 year_6 year_7 year_8 year_9) 

**********

* Allow a separate effect in each of the treated time periods:
* Can show it is the ATT for each t.

eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	eststo: qui reg `outcome' c.w1#c.year_* d1 year_*, vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop(year_5 year_6 year_7 year_8 year_9 c.w1#c.year_5 c.w1#c.year_6 c.w1#c.year_7 c.w1#c.year_8 c.w1#c.year_9) 

**********

* Add a covariate to the general equation with homogeneous time effects: 

*** demeaning control variables 
foreach control in total_pop oneplus_tot_pop oneminus_tot_pop unsen_tot_pop unsen_m_pop unsen_f_pop total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap rated_cap lowest_cap_pct highest_cap_pct age_1824 age_2534 age_3544 age_4554 age_55p educ_anycoll educ_hs educ_nohs sent_1m sent_1_2 sent_2_5 sent_5_10 sent_10_25 sent_25p sent_life sent_miss off_manslaughter off_assault off_drugs off_fraud off_larceny off_cartheft off_murder off_burglary off_publicorder off_rapesa off_robbery off_othprop off_othviolent off_other off_missing crime_violent crime_public crime_property crime_drugs crime_other crime_missing {
	sum `control' if treat_base
	gen `control'_dm = `control' - r(mean)
	la var `control'_dm "`control' Covariate De-Meaned"
}

* reg Y w1 d1 i.year_* w1#controls_dm i.year_*#controls controls c.d1#controls nined_controls, vce(cl state_fips)
/*
eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	eststo: qui reg `outcome' w1 d1 i.year_* c.w1#c.`controls'_dm i.year_*#c.`controls' `controls' c.d1#c.`controls' nined_`controls', vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop() 
*/
*** not entirely sure if this is correctly-done, removed the interaction with 

**********

* Add a covariate to the general equation with heterogeneous time effects:

* de-meaned and nined controls already created 
* sum x1 if d
* gen x1_dm_1 = x1 - r(mean)

* believe all are equivalent 
* xtreg logy c.w#c.f2014 c.w#c.f2015 c.w#c.f2014#c.x1_dm_1 c.w#c.f2015#c.x1_dm_1 i.year c.f2014#c.x1 c.f2015#c.x1,  fe vce(cluster id)
* reg logy c.w#c.f2014 c.w#c.f2015 c.w#c.f2014#c.x1_dm_1 c.w#c.f2015#c.x1_dm_1 i.year c.f2014#c.x1 c.f2015#c.x1 d x1 c.d#c.x1, vce(cluster id)
* reg logy c.w#c.f2014 c.w#c.f2015 c.w#c.f2014#c.x1_dm_1 c.w#c.f2015#c.x1_dm_1 i.year i.year#c.x1 d x1 c.d#c.x1, vce(cluster id)

local controls "total_pop design_cap"

eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	eststo: qui reg `outcome' c.w1#c.year_* i.year_* d1 c.w1#c.year_*#c.`controls'_dm i.year_*#c.`controls' `controls' c.d1#c.`controls' nined_`controls', vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop(c.w1#c.year_5 c.w1#c.year_6 c.w1#c.year_7 c.w1#c.year_8 c.w1#c.year_9) 

* counts: staff_miscond_all > staff_harassment_all > inmate_noncon_all > inmate_contact_all > *_subs

**********
	
* Now use margins to account for the sampling error in the mean of x1. It is
* important to have w defined as the time-varying treatment variable

*** don't really understand this part, what is going on????
/* local controls "total_pop design_cap"

eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	reg `outcome' c.w1#c.year_* c.w#c.year_*#c.`controls'_dm i.year_* c.year_*#c.`controls' d1 `controls' c.d1#c.`controls', vce(cluster id)
	margins, dydx(w1) at(f2014 = 1 f2015 = 0) subpop(if d == 1) vce(uncond)
	margins, dydx(w1) at(f2014 = 0 f2015 = 1) subpop(if d == 1) vce(uncond)
	
}
*/

*********************************************************************

* taking inmate facing lowered rate as exogenous
* defining treatment as state experiencing a drop > X
* need to define X across my balanced panel: 37states*12years=

* using staggered treatment and post definitions
* treatment if largest absolute decrease <= $1.6585, chosen as a natural threshold
* generating treatment = (min_FD_abs <= 1.6585)
* THIS THRESHOLD IS HARD CODED, NEED TO UPDATE MANUALLY IF DATASET CHANGES *

use "2000_data/500_working/final_output_dta", replace
local controls "total_pop"

bysort state: egen min_FD_abs = min(fd_oos_coll_15m) if year>=2007
bysort state: gen temp_treatment = (abs(min_FD_abs) >=7.99 & min_FD_abs!=.)
bysort state: egen avg_temp_treatment = mean(temp_treatment)
gen treatment = (avg_temp_treatment>0)
drop temp_*

*tab year if inmate_contact_all!=., gen(year_)


/*
* graph depicting how I made the choice: 
bysort state: egen temp_min_FD_abs = min(fd_oos_coll_15m) if year>=2007
sort temp_min_FD_abs
drop if year!=2014
gen n=_n
gen temp_min_FD_abs_diff = temp_min_FD_abs[_n] - temp_min_FD_abs[_n-1]
egen temp_max_min_FD_abs_diff_qtl = max(temp_min_FD_abs_diff) if n!=35
order state year temp_*
tw scatter temp_min_FD_abs_diff n, xline(11)
*/

* highest year is 2018
* lowest year is 2007
bysort state: gen temp_dq_column = fd_oos_coll_15m - min_FD_abs
bysort state: gen temp_dq = (temp_dq_column==0) if treatment==1

bysort state: replace temp_dq = temp_dq[_n-1] if temp_dq[_n-1] == 1
* 1 in 2009, 1 in 2010, 1 in 2011, 3 in 2012, 1 in 2013, 4 in 2014
bysort state: egen temp_calc_dq = sum(temp_dq)

* flag when gap is biggest 
* egen maybe? 
**want var with year when largest drop happens, 
**minyear=year if temp_dq==0
** egen minyear=min(temp), by(state)
** want to know current year in ref to treatment year 
** gen eventT = year-minyear
** could use minyear total and remove by(state)
** could get one minyeartotal and one minyear, by(state)

* treatment cohort variables 
gen dq = (temp_calc_dq == 10)
gen dqp1 = (temp_calc_dq == 9)
gen dqp2 = (temp_calc_dq == 8)
gen dqp3 = (temp_calc_dq == 7)
gen dqp4 = (temp_calc_dq == 6)
gen dqp5 = (temp_calc_dq == 5)
gen dqinf = (treatment==0)

**********

* should be setup now with dq through dqp5, and dqinf for treatment==0 !
foreach control in total_pop design_cap {
	foreach t in dq dqp1 dqp2 dqp3 dqp4 dqp5 dqinf { 
		sum `control' if `t' 
		gen `control'_dm_`t' = `control' - r(mean)
	}
}

/*

* year_4 = 2007, omitted
* year_15 = 2018 = T, final year
* year_6 = 2009 = NJ year, dq
eststo clear
* inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs 
foreach outcome in inmate_noncon_all { 
	xtset state_fips year
	display "test 1"
	eststo: qui xtreg `outcome' c.dq*#c.year_* c.dq*#c.year_*#c.`controls'_dm_* i.year_* i.year_*#c.`controls' nined_`controls', fe vce(cluster state_fips)
	lincom (c.dq#c.year_6 + c.dq#c.year_7 + c.dq#c.year_8 + c.dq#c.year_9 + c.dq#c.year_10 + c.dq#c.year_11 + c.dq#c.year_12 + c.dq#c.year_13 + c.dq#c.year_14 + c.dq#c.year_15)/10
	lincom (c.dqp1#c.year_7 + c.dqp1#c.year_8 + c.dqp1#c.year_9 + c.dqp1#c.year_10 + c.dqp1#c.year_11 + c.dqp1#c.year_12 + c.dqp1#c.year_13 + c.dqp1#c.year_14 + c.dqp1#c.year_15)/9
	lincom (c.dqp2#c.year_8 + c.dqp2#c.year_9 + c.dqp2#c.year_10 + c.dqp2#c.year_11 + c.dqp2#c.year_12 + c.dqp2#c.year_13 + c.dqp2#c.year_14 + c.dqp2#c.year_15)/8
	lincom (c.dqp3#c.year_9 + c.dqp3#c.year_10 + c.dqp3#c.year_11 + c.dqp3#c.year_12 + c.dqp3#c.year_13 + c.dqp3#c.year_14 + c.dqp3#c.year_15)/7
	lincom (c.dqp4#c.year_10 + c.dqp4#c.year_11 + c.dqp4#c.year_12 + c.dqp4#c.year_13 + c.dqp4#c.year_14 + c.dqp4#c.year_15)/6
	lincom (c.dqp5#c.year_11 + c.dqp5#c.year_12 + c.dqp5#c.year_13 + c.dqp5#c.year_14 + c.dqp5#c.year_15)/5
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop() 

* lincom is to compute average effect by treatment cohort, dq - dqp5 (2009-2014)

**********

xtset state_fips year

eststo clear
foreach outcome in inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs { 
	eststo: qui xtreg `outcome' c.dq*#c.year_* c.dq*#c.year_*#c.`controls'_dm_* i.year_* i.year_*#c.`controls' nined_`controls', fe vce(cluster state_fips)
	margins, dydx()
}
esttab, star(* 0.10 ** 0.05 *** 0.01) se drop() 

*/

*/

log close
