* 5_extra_pieces.do

clear all

*cd "\bigdata\mbateslab\dford013\coding\01_PRISON_PHONE_paper"
cd "~\coding\01_PRISON_PHONE_paper"

********************************************************************************

capture log close 
log using "3000_code\SMCL_logs\5_extra_pieces", smcl replace



use "2000_data\500_working\labeled_prison_dta", replace
sort state year
save "2000_data\500_working\extra_pieces_dta", replace

**********

* scatterplot of all phone rates across time 
use "2000_data\500_working\extra_pieces_dta", replace
keep if year>=2008 & year<=2018
twoway scatter oos_coll_15m year, ms(X) xline(2013.5, lstyle(dot)) yline(3.75, lstyle(dot)) subtitle() ytitle("15-Minute Interstate Collect Call Cost") xtitle("Year") saving("5000_figures\Scatterplot All Rates.gph", replace)
*graph export "~\coding\03_figures\pdfs\Scatterplot All Rates.pdf", as(pdf) name("Graph") replace
graph export "6000_LaTeX\rates_scatterplot.eps", replace
graph export "6000_LaTeX\rates_scatterplot.pdf", replace

STOP

*** phone rate variance and serrbar graphs
* dropping potential defiers and states with missing rate observations
use "2000_data\500_working\extra_pieces_dta", replace
keep if year>=2008 & year<=2018
drop if potential_defier==1 | rates_incomplete==1  

* creating limited dataset variables, calling them 'adj'
bysort year: egen adj_avg_oos_coll_15m = mean(oos_coll_15m)
bysort year: egen adj_max_oos_coll_15m = max(oos_coll_15m)
bysort year: egen adj_min_oos_coll_15m = min(oos_coll_15m)
bysort year: egen adj_sd_oos_coll_15m = sd(oos_coll_15m)
gen adj_var_oos_coll_15m = adj_sd_oos_coll_15m^2
* constrained states / treatment group
bysort year: egen adj_treat_avg_oos_coll_15m = mean(oos_coll_15m) if treat_base==1
bysort year: egen adj_treat_max_oos_coll_15m = max(oos_coll_15m) if treat_base==1
bysort year: egen adj_treat_min_oos_coll_15m = min(oos_coll_15m) if treat_base==1
bysort year: egen adj_treat_sd_oos_coll_15m = sd(oos_coll_15m) if treat_base==1
gen adj_treat_var_oos_coll_15m = adj_treat_sd_oos_coll_15m^2 if treat_base==1
* unconstrained states / control group
bysort year: egen adj_control_avg_oos_coll_15m = mean(oos_coll_15m) if treat_base==0
bysort year: egen adj_control_max_oos_coll_15m = max(oos_coll_15m) if treat_base==0
bysort year: egen adj_control_min_oos_coll_15m = min(oos_coll_15m) if treat_base==0
bysort year: egen adj_control_sd_oos_coll_15m = sd(oos_coll_15m) if treat_base==0
gen adj_control_var_oos_coll_15m = adj_control_sd_oos_coll_15m^2 if treat_base==0

* scatterplot of variance by year
twoway scatter adj_var_oos_coll_15m year, xline(2014, lstyle(dot)) title("Interstate 15m Collect Call Cost Variance") subtitle() note("Defiers/missing rates dropped") ytitle("Interstate Collect Rate Variance") xtitle("Year") name(ScatterplotRateVarianceSimple)

* scatterplot of variance by year, broken down by treatment status
twoway scatter adj_treat_var_oos_coll_15m year, ms(X) || scatter adj_control_var_oos_coll_15m year, ms(Oh) xline(2014, lstyle(dot)) title("15m Call Cost Variance by Treatment") subtitle() note("Defiers/missing rates dropped, treat_base==1 if (2013 rate>cap)") ytitle("Interstate Collect Call Cost Variance") xtitle("Year") legend(label(1 Treatment Variance) label(2 Control Variance) position(0) bplacement(neast)) name(ScatterplotRateVarbyTreat)

* graph of mean phone rates by year, with std dev bands
serrbar adj_avg_oos_coll_15m adj_sd_oos_coll_15m year, xline(2014, lstyle(dot)) title("15m Call Cost Means with S.D. Bands") subtitle() note("Defiers/missing rates dropped") ytitle("Interstate Collect Call 15m Cost") xtitle("Year") name(RateMeanswithStdDevBands)

* graph of mean phone rates by year, broken down by treatment states, with std dev bands
gen upper_treat = adj_treat_avg_oos_coll_15m + adj_treat_sd_oos_coll_15m
gen upper_control = adj_control_avg_oos_coll_15m + adj_control_sd_oos_coll_15m
gen lower_treat = adj_treat_avg_oos_coll_15m - adj_treat_sd_oos_coll_15m
gen lower_control = adj_control_avg_oos_coll_15m - adj_control_sd_oos_coll_15m
gen yearp = year+0.1
gen yearm = year-0.1

twoway scatter adj_treat_avg_oos_coll_15m yearp, mc(red) || rcap upper_treat lower_treat yearp, lc(red) || scatter adj_control_avg_oos_coll_15m yearm, mc(blue) || rcap upper_control lower_control yearm, lc(blue) xline(2014, lstyle(dot)) title("15m Call Cost Means with Bands by Treatment") subtitle() note("Defiers/missing rates dropped, treat_base==1 if (2013 rate>cap)") ytitle("Interstate Collect Call 15m Cost") xtitle("Year") legend(label(1 "Treatment Means") label(2 "+/- 1 Std Dev") label(3 "Control Means") label(4 "+/- 1 Std Dev") size(*0.9) position(0) bplacement(neast)) name(RateMeanswithStdDevBandsbyTreat)
drop yearp yearm

* combining variance scatterplots
graph combine ScatterplotRateVarianceSimple ScatterplotRateVarbyTreat, row(1) title("Scatterplot Rate Variance Combined") subtitle() note() iscale(*0.75) ycommon
graph export "6000_LaTeX\Scatterplot Rate Variance Combined.jpg", as(jpg) name("Graph") replace

* combining means with std dev Bands
graph combine RateMeanswithStdDevBands RateMeanswithStdDevBandsbyTreat, row(1) title("Rate Means with Std Dev Bands Combined") subtitle() note() iscale(*0.85) ycommon
graph export "6000_LaTeX\Rate Means with Std Dev Bands Combined.jpg", as(jpg) name("Graph") replace


**********


clear all
local prea_outcomes inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs

foreach o of local prea_outcomes {
    use "2000_data\500_working\extra_pieces_dta", replace
	drop if early_adopt==1 | year<2004 | year>2018
	local mytitle "`:variable label `o''"
	local savetitle "PREA Simple Outcome Means `o'"
	separate `o', by(treat_base) generate()
	collapse(mean) `o'?, by(treat_base year)
	graph twoway (line `o'? year, sort), xline(2014, lstyle(dot)) title(`"`mytitle'"', size(*0.9)) subtitle() note() ytitle(`"`mytitle'"', size(*0.9)) xtitle("Year", size(*1)) legend(size(*0.9) label(1 "Treatment") label(2 "Control")) name(g1_`o')
}

* Inmate on Inmate Outcomes
graph combine g1_inmate_noncon_all g1_inmate_noncon_subs g1_inmate_contact_all g1_inmate_contact_subs, row(2) title("PREA Simple Outcome Means IoI Outcomes") note("Unbalanced panel, dropped early adopters, treatment if (2013 rate>cap)") iscale(*0.75)
graph export "6000_LaTeX\PREA Simple Outcome Means IoI Combined.jpg", as(jpg) name("Graph") replace

* Staff on Inmate Outcomes
graph combine g1_staff_miscond_all g1_staff_miscond_subs g1_staff_harassment_all g1_staff_harassment_subs, row(2) title("PREA Simple Outcome Means SoI Outcomes") note("Unbalanced panel, dropped early adopters, treatment if (2013 rate>cap)") iscale(*0.75)
graph export "6000_LaTeX\PREA Simple Outcome Means SoI Combined.jpg", as(jpg) name("Graph") replace


**********


*** FD PCT GRAPHS ***
* full scatterplot
clear all

use "2000_data\500_working\extra_pieces_dta", replace

* NOTICE: for below, dropping years without full rate data, dropping defying states, dropping states without full rate data
keep if year>=2008 & year<=2018 & potential_defier==0 & rates_incomplete==0

twoway scatter fd_pct_coll_15m year, ms(X) xline(2014, lstyle(dot)) title("Percent Change in Cost") subtitle() note("Defiers/missing rates dropped") ytitle("Change in Cost (%)", size(*0.9)) xtitle("Year") name(g2_RateFDScatter)

* treatment/control full scatterplot 
gen yearp = year+0.1
gen yearm = year-0.1
twoway scatter fd_pct_coll_15m yearp if treat_base==1, mc(red) ms(X) || scatter fd_pct_coll_15m yearm if treat_base==0, mc(blue) ms(Oh) xline(2014, lstyle(dot)) title("Percent Change in Cost by Treatment") subtitle() note("Defiers/missing rates dropped, treatment if (2013 rate>cap)") ytitle("Change in Cost (%)", size(*0.9)) legend(label(1 "Treatment FD's") label(2 "Control FD's") position(0) bplacement(nwest)) name(g2_RateFDScatterbyTreat)

* means with error bars
bysort year: egen fd_pct_mean = mean(fd_pct_coll_15m) 
bysort year: egen fd_pct_sd = sd(fd_pct_coll_15m)
serrbar fd_pct_mean fd_pct_sd year, title("Percent Change in Cost Means with Bands") subtitle() note("Defiers/missing rates dropped") ytitle("Change in Cost (%)", size(*0.9)) xtitle("Year") name(g2_RateFDMeanswithStdDev)

* treatment/control means with error bars 
bysort year: egen fd_pct_mean_treat = mean(fd_pct_coll_15m) if treat_base==1
bysort year: egen fd_pct_sd_treat = sd(fd_pct_coll_15m) if treat_base==1
bysort year: egen fd_pct_mean_contr = mean(fd_pct_coll_15m) if treat_base==0
bysort year: egen fd_pct_sd_contr = sd(fd_pct_coll_15m) if treat_base==0
gen upper_fd_pct_treat = fd_pct_mean_treat + fd_pct_sd_treat 
gen lower_fd_pct_treat = fd_pct_mean_treat - fd_pct_sd_treat 
gen upper_fd_pct_contr = fd_pct_mean_contr + fd_pct_sd_contr
gen lower_fd_pct_contr = fd_pct_mean_contr - fd_pct_sd_contr 
twoway scatter fd_pct_mean_treat yearp, mc(red) || rcap upper_fd_pct_treat lower_fd_pct_treat yearp, lc(red) || scatter fd_pct_mean_contr yearm, mc(blue) || rcap upper_fd_pct_contr lower_fd_pct_contr yearm, lc(blue) xline(2014, lstyle(dot)) title("Mean Percent Change with Bands by Treatment") subtitle() note("Defiers/missing rates dropped, treatment if (2013 rate>cap)") ytitle("Change in Cost (%)", size(*0.9)) xtitle("Year") legend(label(1 "Treatment Means") label(2 "+/- 1 Std. Dev.") label(3 "Control Means") label(4 "+/- 1 Std. Dev.") size(*0.4) position(0) bplacement(nwest)) name(g2_RateFDMeanswithStdDevbyTreat)

* combining these four FD graphs
graph combine g2_RateFDScatter g2_RateFDScatterbyTreat g2_RateFDMeanswithStdDev g2_RateFDMeanswithStdDevbyTreat, title("Rate First Differences Combined") subtitle() note() iscale(*0.75)
graph export "6000_LaTeX\Rate First Differences Combined.jpg", as(jpg) name("Graph") replace


**********


* histograms
* no longer dropping missing/defying! *
clear all
use "2000_data\500_working\extra_pieces_dta", replace
label define contr_treat 0 "Control" 1 "Treatment"
label values treat_base contr_treat
hist fd_pct_coll_15m, freq addl gap(10) title("15m Rate First Differences, 2009-2018") subtitle() note() ytitle() xtitle("Rate Change from Previous Year (%)") name(g3_HistFD)

* histogram for only 2013-2014
hist fd_pct_coll_15m if year>=2013 & year<=2014, freq addl gap(10) title("15m Rate First Differences, 2013-2014") subtitle() note() ytitle() xtitle("Rate Change from Previous Year (%)") name(g3_HistFD20132014)

* histogram by treatment status
hist fd_pct_coll_15m, freq addl gap(10) by(treat_base, title("Rate FD % by Treatment Histogram, 2008-2018") subtitle() note("Treatment if (2013 rate>cap)") legend(off)) name(g3_HistFDbyTreat)

* histogram for only 2013-2014 by treatment status
hist fd_pct_coll_15m if year>=2013 & year<=2014, freq addl gap(10) by(treat_base, title("Rate FD % by Treatment Histogram, 2013-2014") note("Treatment if (2013 rate>cap)") legend(off)) name(g3_HistFDbyTreat20132014)

* simple histograms
graph combine g3_HistFD g3_HistFD20132014, row(1) title("Histogram First Differences Combined") subtitle() note() iscale(*0.8)
graph export "6000_LaTeX\Histogram First Differences Combined.jpg", as(jpg) name("Graph") replace
* now the histograms by treatment status
graph combine g3_HistFDbyTreat g3_HistFDbyTreat20132014, row(2) title("Histogram First Differences by Treatment Combined") subtitle() note() iscale(*0.8)
graph export "6000_LaTeX\Histogram First Differences by Treatment Combined.jpg", as(jpg) name("Graph") replace


**********


*** EVENT STUDY GRAPHS ***
clear all
local prea_outcomes inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs
* note: dropping early adopters here
foreach o of local prea_outcomes {
    use "2000_data\500_working\extra_pieces_dta", replace
	drop if early_adopt==1 | T_coll<-6 | T_coll>5
	local mytitle "`:variable label `o''"
	local savetitle "PREA Event Study Means `o'"
	separate `o', by(treat_base) generate()
	collapse(mean) `o'?, by(treat_base T_coll)
	graph twoway (line `o'? T_coll, sort), title(`"`mytitle'"', size(*0.9)) subtitle() note() ytitle(`"`mytitle'"', size(*0.9)) xtitle("Years Before/After Obs'd Under Cap", size(*1)) xlabel(-6(1)5) legend(size(*0.9) label(1 "Treatment") label(2 "Control")) xline(0, lstyle(dot)) name(g4_`o')
}

* combining Inmate on Inmate outcomes
graph combine g4_inmate_noncon_all g4_inmate_noncon_subs g4_inmate_contact_all g4_inmate_contact_subs, row(2) title("PREA Event Study Means IoI Combined") subtitle() note("Unbalanced panel, dropped early adopters, treatment if (2013 rate>cap)") iscale(0.75)
graph export "6000_LaTeX\PREA Event Study Means IoI Combined.jpg", as(jpg) name("Graph") replace
* combining Staff on Inmate outcomes
graph combine g4_staff_miscond_all g4_staff_miscond_subs g4_staff_harassment_all g4_staff_harassment_subs, row(2) title("PREA Event Study Means SoI Combined") subtitle() note("Unbalanced panel, dropped early adopters, treatment if (2013 rate>cap)") iscale(0.75)
graph export "6000_LaTeX\PREA Event Study Means SoI Combined.jpg", as(jpg) name("Graph") replace


*** GRAPHS FROM 5/12 MEETING ***

*** balanced panel, simple mean graphs
* using treat_base and T_coll
clear all
local prea_outcomes inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs
foreach o of local prea_outcomes {
    use "2000_data\500_working\extra_pieces_dta", replace
	drop if drop_bal_T_coll==1 | abs(T_coll)>3
	local mytitle "`:variable label `o''"
	local savetitle "PREA Balanced Event Study Means `o'"
	separate `o', by(treat_base) generate()
	collapse(mean) `o'?, by(treat_base T_coll)
	graph twoway (line `o'? T_coll, sort), xline(0, lstyle(dot)) title(`"`mytitle'"', size(*0.9)) subtitle() note() ytitle(`"`mytitle'"', size(*0.9)) xtitle("Years Before/After Obs'd Under Cap", size(*1)) xlabel(-3(1)3) legend(size(*0.9) label(1 "Treatment") label(2 "Control")) name(g5_`o')
}

* Combining Inmate on Inmate outcomes
graph combine g5_inmate_noncon_all g5_inmate_noncon_subs g5_inmate_contact_all g5_inmate_contact_subs, row(2) iscale(*0.8) title("PREA Balanced Event Study Means IoI Combined") subtitle() note("Balanced panel, treatment if (2013 rate>cap)") 
graph export "6000_LaTeX\PREA Balanced Event Study Means IoI Combined.jpg", as(jpg) name("Graph") replace

* Combining Staff on Inmate outcomes
graph combine g5_staff_miscond_all g5_staff_miscond_subs g5_staff_harassment_all g5_staff_harassment_subs, row(2) iscale(*0.8) title("PREA Balanced Event Study Means SoI Combined") subtitle() note("Balanced panel, treatment if (2013 rate>cap)")
graph export "6000_LaTeX\PREA Balanced Event Study Means SoI Combined.jpg", as(jpg) name("Graph") replace

* T_alt outcome simple means
clear all
local prea_outcomes inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs
* note: dropping early adopters here
foreach o of local prea_outcomes {
    use "2000_data\500_working\extra_pieces_dta", replace
	drop if early_adopt==1 | T_coll<-6 | T_coll>5
	local mytitle "`:variable label `o''"
	local savetitle "PREA Alt Event Study Means `o'"
	separate `o', by(treat_base) generate()
	collapse(mean) `o'?, by(treat_base T_alt)
	graph twoway (line `o'? T_alt, sort), title(`"`mytitle'"', size(*0.9)) subtitle() note() ytitle(`"`mytitle'"', size(*0.9)) xtitle("Years Before/After Largest Rate Reduction", size(*1)) xlabel(-6(1)5) legend(size(*0.9) label(1 "Treatment") label(2 "Control")) xline(0, lstyle(dot)) name(g6_`o')
}

* combining Inmate on Inmate outcomes
graph combine g6_inmate_noncon_all g6_inmate_noncon_subs g6_inmate_contact_all g6_inmate_contact_subs, row(2) title("PREA Alt Event Study Means IoI Combined") subtitle() note("Unbalanced panel, dropped early adopters, treatment if (2013 rate>cap)") iscale(0.75)
graph export "6000_LaTeX\PREA Alt Event Study Means IoI Combined.jpg", as(jpg) name("Graph") replace

* combining Staff on Inmate outcomes
graph combine g6_staff_miscond_all g6_staff_miscond_subs g6_staff_harassment_all g6_staff_harassment_subs, row(2) title("PREA Alt Event Study Means SoI Combined") subtitle() note("Unbalanced panel, dropped early adopters, treatment if (2013 rate>cap)") iscale(0.75)
graph export "6000_LaTeX\PREA Alt Event Study Means SoI Combined.jpg", as(jpg) name("Graph") replace


* T_alt balanced outcome simple means
clear all
local prea_outcomes inmate_contact_all inmate_contact_subs inmate_noncon_all inmate_noncon_subs staff_harassment_all staff_harassment_subs staff_miscond_all staff_miscond_subs
foreach o of local prea_outcomes {
    use "2000_data\500_working\extra_pieces_dta", replace
	drop if drop_bal_T_alt==1 | abs(T_alt)>3
	local mytitle "`:variable label `o''"
	local savetitle "PREA Alt Balanced Event Study Means `o'"
	separate `o', by(treat_base) generate()
	collapse(mean) `o'?, by(treat_base T_alt)
	graph twoway (line `o'? T_alt, sort), xline(0, lstyle(dot)) title(`"`mytitle'"', size(*0.9)) subtitle() note() ytitle(`"`mytitle'"', size(*0.9)) xtitle("Years Before/After Largest Rate Reduction", size(*1)) xlabel(-3(1)3) legend(size(*0.9) label(1 "Treatment") label(2 "Control")) name(g7_`o')
}

* Combining Inmate on Inmate outcomes
graph combine g7_inmate_noncon_all g7_inmate_noncon_subs g7_inmate_contact_all g7_inmate_contact_subs, row(2) iscale(*0.8) title("PREA Alt Balanced Event Study Means IoI Combined") subtitle() note("Balanced panel, treatment if (2013 rate>cap)") 
graph export "6000_LaTeX\PREA Alt Balanced Event Study Means IoI Combined.jpg", as(jpg) name("Graph") replace

* Combining Staff on Inmate outcomes
graph combine g7_staff_miscond_all g7_staff_miscond_subs g7_staff_harassment_all g7_staff_harassment_subs, row(2) iscale(*0.8) title("PREA Alt Balanced Event Study Means SoI Combined") subtitle() note("Balanced panel, treatment if (2013 rate>cap)")
graph export "6000_LaTeX\PREA Alt Balanced Event Study Means SoI Combined.jpg", as(jpg) name("Graph") replace

use "2000_data\500_working\extra_pieces_dta", replace


* next using treat_early_base, treat_base + early_adopt (?)


* eventually, use treat_alt, which will use largest observed rate drop (?)


* similarly, use T_coll_alt, where T=0 in year with min(FD) (?)

log close
