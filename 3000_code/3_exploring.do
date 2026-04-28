* 3_exploring.do

clear all

*cd "\bigdata\mbateslab\dford013\coding\01_PRISON_PHONE_paper"
cd "~\coding\01_PRISON_PHONE_paper"

********************************************************************************

capture log close
log using "3000_code\SMCL_logs\3_exploring", smcl replace

*ssc install estout

use "2000_data\500_working\labeled_prison_dta", replace
sort state year
save "2000_data\500_working\exploring_dta", replace

* 8/20/22
* Common Entry Date: Supposed T=2, balanced, X time-invariant
* Di, Ft, Wit
* first, supposing there is a single entry date, some basic inference

* regressions using continuous treatment: 
use "2000_data\500_working\exploring_dta", replace
eststo clear
foreach outcome of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips year
	eststo: qui xtreg `outcome' c.oos_coll_15m##caps_enact i.year , fe vce(cluster state_fips)
}
esttab, star(* 0.10 ** 0.05 *** 0.01) drop(*.year 0.*) se
* highest and lowest pct variables were just returning zeroes, not sure why 


**********


* looking into regression pretrends

* classic way of checking pretrends: 
* check pre-treatment means, if they are different it may be suspicious 
* add leads to the regression
* pick control groups that have similar pre-treatment trends

*** FIGURED OUT HOW TO USE NAME() OPTION TO AVOID FILE SAVE CLUTTER ***
* without controls: 
use "2000_data\500_working\exploring_dta", replace
foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips year
	keep if year<2014
	xtreg `o' treat_base##caps_enact i.year if treat_base==0, fe vce(cluster state_fips)
	predict yhat_`o'_cont
	xtreg `o' treat_base##caps_enact i.year if treat_base==1, fe vce(cluster state_fips)
	predict yhat_`o'_treat
	tw lfit yhat_`o'_cont year || lfit yhat_`o'_treat year , legend(label(1 Control) label(2 Treatment)) title("`o' Regression Pretrends") subtitle() note() ytitle() xtitle() name(g1_`o')
	}
	
graph combine g1_inmate_noncon_all g1_inmate_noncon_subs g1_inmate_contact_all g1_inmate_contact_subs, row(2) title("Regression Pretrends IoI, No Controls") subtitle() note("xtreg `o' treat##post i.year if treat=={0,1}, fe vce(cluster state_fips)") iscale(*0.8)
graph export "5000_figures\jpgs\Regression Pretrends IoI, No Controls.jpg", as(jpg) name("Graph") replace

graph combine g1_staff_miscond_all g1_staff_miscond_subs g1_staff_harassment_all g1_staff_harassment_subs, row(2) title("Regression Pretrends SoI, No Controls") subtitle() note("xtreg `o' treat##post i.year if treat=={0,1}, fe vce(cluster state_fips)") iscale(*0.8)
graph export "5000_figures\jpgs\Regression Pretrends SoI, No Controls.jpg", as(jpg) name("Graph") replace


*** RESUMING NOW WITH NAME() OPTION ***
* with pop controls:
use "2000_data\500_working\exploring_dta", replace

foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips year
	keep if year<2014
	xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop if treat_base==0, fe vce(cluster state_fips)
	predict yhat_`o'_cont
	xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop if treat_base==1, fe vce(cluster state_fips)
	predict yhat_`o'_treat
	tw lfit yhat_`o'_cont year || lfit yhat_`o'_treat year , legend(label(1 Control) label(2 Treatment)) title("`o' Regression Pretrends") subtitle() note() ytitle() xtitle() name(g2_`o')
	}
	
graph combine g2_inmate_noncon_all g2_inmate_noncon_subs g2_inmate_contact_all g2_inmate_contact_subs, row(2) title("Regression Pretrends IoI, With Pop Controls") subtitle() note("xtreg `o' treat##post i.year `controls' if treat=={0,1}, fe vce(cluster state_fips)") iscale(*0.8)
graph export "5000_figures\jpgs\Regression Pretrends IoI, With Pop Controls.jpg", as(jpg) name("Graph") replace

graph combine g2_staff_miscond_all g2_staff_miscond_subs g2_staff_harassment_all g2_staff_harassment_subs, row(2) title("Regression Pretrends SoI, With Pop Controls") subtitle() note("xtreg `o' treat##post i.year `controls' if treat=={0,1}, fe vce(cluster state_fips)") iscale(*0.8)
graph export "5000_figures\jpgs\Regression Pretrends SoI, With Pop Controls.jpg", as(jpg) name("Graph") replace


* with pop/cap controls:
use "2000_data\500_working\exploring_dta", replace

foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips year
	keep if year<2014
	xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct if treat_base==0, fe vce(cluster state_fips)
	predict yhat_`o'_cont
	xtreg `o' treat_base##caps_enact i.year total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct if treat_base==1, fe vce(cluster state_fips)
	predict yhat_`o'_treat
	tw lfit yhat_`o'_cont year || lfit yhat_`o'_treat year , legend(label(1 Control) label(2 Treatment)) title("`o' Regression Pretrends") subtitle() note() ytitle() xtitle() name(g3_`o')
	}
	
graph combine g3_inmate_noncon_all g3_inmate_noncon_subs g3_inmate_contact_all g3_inmate_contact_subs, row(2) title("Regression Pretrends IoI, With Pop & Cap Controls") subtitle() note("xtreg `o' treat##post i.year `controls' if treat=={0,1}, fe vce(cluster state_fips)") iscale(*0.8)
graph export "5000_figures\jpgs\Regression Pretrends IoI, With Pop & Cap Controls.jpg", as(jpg) name("Graph") replace

graph combine g3_staff_miscond_all g3_staff_miscond_subs g3_staff_harassment_all g3_staff_harassment_subs, row(2) title("Regression Pretrends SoI, With Pop & Cap Controls") subtitle() note("xtreg `o' treat##post i.year `controls' if treat=={0,1}, fe vce(cluster state_fips)") iscale(*0.8)
graph export "5000_figures\jpgs\Regression Pretrends SoI, With Pop & Cap Controls.jpg", as(jpg) name("Graph") replace


***** now with T_coll (T_coll_pos=16 when T_coll=0)
* without controls: 
use "2000_data\500_working\exploring_dta", replace

foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips T_coll_pos
	keep if T_coll_pos<16
	xtreg `o' treat_base##caps_enact i.T_coll_pos if treat_base==0, fe vce(cluster state_fips)
	predict yhat_`o'_cont
	xtreg `o' treat_base##caps_enact i.T_coll_pos if treat_base==1, fe vce(cluster state_fips)
	predict yhat_`o'_treat
	tw lfit yhat_`o'_cont T_coll_pos || lfit yhat_`o'_treat T_coll_pos, legend(label(1 Control) label(2 Treatment)) title("T_coll `o' Reg Pretrends") subtitle() note() ytitle() xtitle(T_coll_pos) name(g4_`o')
	}
	
graph combine g4_inmate_noncon_all g4_inmate_noncon_subs g4_inmate_contact_all g4_inmate_contact_subs, row(2) title("T_coll Regression Pretrends IoI, No Controls") subtitle("T_coll_pos = T_coll + 18, forcing positivity") note("xtreg `o' treat##post i.T_coll_pos if treat=={0,1}, fe vce(cluster state_fips), restricted to T_coll<0") iscale(*0.8)
graph export "5000_figures\jpgs\T_coll Regression Pretrends IoI, No Controls.jpg", as(jpg) name("Graph") replace

graph combine g4_staff_miscond_all g4_staff_miscond_subs g4_staff_harassment_all g4_staff_harassment_subs, row(2) title("T_coll Regression Pretrends SoI, No Controls") subtitle("T_coll_pos = T_coll + 18, forcing positivity") note("xtreg `o' treat##post i.T_coll_pos if treat=={0,1}, fe vce(cluster state_fips), restricted to T_coll<0") iscale(*0.8)
graph export "5000_figures\jpgs\T_coll Regression Pretrends SoI, No Controls.jpg", as(jpg) name("Graph") replace


* with pop controls:
use "2000_data\500_working\exploring_dta", replace

foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips T_coll_pos
	keep if T_coll_pos<16
	xtreg `o' treat_base##caps_enact i.T_coll_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop if treat_base==0, fe vce(cluster state_fips)
	predict yhat_`o'_cont
	xtreg `o' treat_base##caps_enact i.T_coll_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop if treat_base==1, fe vce(cluster state_fips)
	predict yhat_`o'_treat
	tw lfit yhat_`o'_cont T_coll_pos || lfit yhat_`o'_treat T_coll_pos, legend(label(1 Control) label(2 Treatment)) title("T_coll `o' Reg Pretrends") subtitle() note() ytitle() xtitle(T_coll_pos) name(g5_`o')
	}
	
graph combine g5_inmate_noncon_all g5_inmate_noncon_subs g5_inmate_contact_all g5_inmate_contact_subs, row(2) title("T_coll Regression Pretrends IoI, With Pop Controls") subtitle("T_coll_pos = T_coll + 18, forcing positivity") note("xtreg `o' treat##post i.T_coll_pos `controls' if treat=={0,1}, fe vce(cluster state_fips), restricted to T_coll<0") iscale(*0.8)
graph export "5000_figures\jpgs\T_coll Regression Pretrends IoI, With Pop Controls.jpg", as(jpg) name("Graph") replace

graph combine g5_staff_miscond_all g5_staff_miscond_subs g5_staff_harassment_all g5_staff_harassment_subs, row(2) title("T_coll Regression Pretrends SoI, With Pop Controls") subtitle("T_coll_pos = T_coll + 18, forcing positivity") note("xtreg `o' treat##post i.T_coll_pos `controls' if treat=={0,1}, fe vce(cluster state_fips), restricted to T_coll<0") iscale(*0.8)
graph export "5000_figures\jpgs\T_coll Regression Pretrends SoI, With Pop Controls.jpg", as(jpg) name("Graph") replace

* with pop/cap controls:
use "2000_data\500_working\exploring_dta", replace

foreach o of varlist inmate_noncon_all inmate_noncon_subs inmate_contact_all inmate_contact_subs staff_miscond_all staff_miscond_subs staff_harassment_all staff_harassment_subs {
	xtset state_fips T_coll_pos
	keep if T_coll_pos<16
	xtreg `o' treat_base##caps_enact i.T_coll_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct if treat_base==0, fe vce(cluster state_fips)
	predict yhat_`o'_cont
	xtreg `o' treat_base##caps_enact i.T_coll_pos total_m_pop total_f_pop oneplus_m_pop oneplus_f_pop oneminus_m_pop oneminus_f_pop operational_cap design_cap custody_pop lowest_cap_pct highest_cap_pct if treat_base==1, fe vce(cluster state_fips)
	predict yhat_`o'_treat
	tw lfit yhat_`o'_cont T_coll_pos || lfit yhat_`o'_treat T_coll_pos, legend(label(1 Control) label(2 Treatment)) title("T_coll `o' Reg Pretrends") subtitle() note() ytitle() xtitle(T_coll_pos) name(g6_`o')
	}
	
graph combine g6_inmate_noncon_all g6_inmate_noncon_subs g6_inmate_contact_all g6_inmate_contact_subs, row(2) title("T_coll Regression Pretrends IoI, With Pop & Cap Controls") subtitle() note("xtreg `o' treat##post i.year `controls' if treat=={0,1}, fe vce(cluster state_fips), restricted to T_coll<0") iscale(*0.8)
graph export "5000_figures\jpgs\T_coll Regression Pretrends IoI, With Pop & Cap Controls.jpg", as(jpg) name("Graph") replace

graph combine g6_staff_miscond_all g6_staff_miscond_subs g6_staff_harassment_all g6_staff_harassment_subs, row(2) title("T_coll Regression Pretrends SoI, With Pop & Cap Controls") subtitle() note("xtreg `o' treat##post i.year `controls' if treat=={0,1}, fe vce(cluster state_fips), restricted to T_coll<0") iscale(*0.8)
graph export "5000_figures\jpgs\T_coll Regression Pretrends SoI, With Pop & Cap Controls.jpg", as(jpg) name("Graph") replace

use "2000_data\500_working\exploring_dta", replace

log close
