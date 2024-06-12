********************************************************************************
*
*	Do-file:		203_cr_prevalent_cohort_rates_repeated.do
*
*	Programmed by:	Emily Herrett (based on John & Alex)
*
*	Data used:		"$outdir/prevalent_cohort_`hftype'_`year'.dta"
*
*	Data created:   "$tabfigdir/rates_repeated_`hftype'_`year'"
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			need to add automatic redaction	
********************************************************************************
do "`c(pwd)'/analysis/global.do"
log using "$logdir/203_cr_prevalent_cohort_rates_repeated.log", replace

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
	use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear 
	*use "$outdir/prevalent_cohort_`hftype'_2018.dta", clear 

	global stratifiers "agegroup male ethnicity imd region_9 duration_hf_yrs previous_diabetes ckd aa arni betablocker mra sglt2i two_pillars three_pillars four_pillars"
	*efi_cat
	tempname measures																	 
	postfile `measures' float(year) str25(outcome) str20(variable) category float(rate) float(ll) float(ul) using "$tabfigdir/prevalent_rates_repeated_`hftype'_`year'", replace
	local d " "1yr" "2yr" "5yr" "
	foreach x in `d' {
		local enddatenow= "enddate`x'"
		foreach v in n_admitted_hosp ///
		n_emerg_hosp n_outhf_emerg  ///
		n_outhf_secondary ///
		n_cvd_admissions ///
		n_dka_hosps {
			preserve
			local failure="`v'`x'"
			display "`failure'"
			replace `failure'=0 if `failure'<1 /// return expectations has led to some numbers below zero so fix here for dummy data
			
			stset `enddatenow', id(patient_id) failure(`failure') enter(master_index_date) exit(time .) scale(365.25)
			gen timefup=_t-_t0
			local events . 
			count if _d==1
			if (`r(N)' == 0 | `r(N)' > 5) {
			local events = `r(N)' 
			}
			display "`events'"
			
			*Overall
			poisson `failure', cluster(patient_id) exposure(timefup)
			poisson, irr
			matrix list r(table)
			local rate = r(table)[1, 1]
			local ll = r(table)[5, 1]
			local ul = r(table)[6, 1]
			if (`events' == 0 | `events' > 5) {
			post `measures' (`year') ("`v'`x'") ("Overall") (0) (`rate') (`ll') (`ul')
			}
			else {
			post `measures' (`year') ("`v'`x'") ("Overall") (0) (.) (.) (.)
			}
			
			
			*Stratified	
			foreach c of global stratifiers {		
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "Calculate rate for variable `c' and level `l'"
				count if `c'==`l' & _d==1 & timefup!=.
				local n_events=r(N)
			/*
				*count number of people in subgroup
				count if `c' ==`l'
				local n_people=r(N)
				*count number of people with outcomes in subgroup, if they have follow-up
				count if `c'==`l' & `failure'>0 & timefup!=.
				local n_outcomes=r(N)
				if `n_people' > 0 & `n_outcomes'>0 & timefup!=. {
				*/
				capture poisson `failure' if `c'==`l', cluster(patient_id) exposure(timefup)
				poisson, irr
				if (`n_events' == 0 | `n_events' > 5) {
				matrix list r(table)
				local rate = r(table)[1, 1]
				local ll = r(table)[5, 1]
				local ul = r(table)[6, 1]
				post `measures' (`year') ("`v'`x'") ("`c'") (`l') (`rate') (`ll') (`ul')
				}
				else {
				post `measures' (`year') ("`v'`x'")  ("`c'") (`l') (.) (.) (.) 	
					}

			}
			}
			restore
		}
		}
		
postclose `measures'

}
* Change postfiles to csv
use "$tabfigdir/prevalent_rates_repeated_`hftype'_2018", clear
local years " "2019" "2020" "2021" "2022" "2023" "
foreach year in `years' {
append using "$tabfigdir/prevalent_rates_repeated_`hftype'_`year'"
}
export delimited using "$tabfigdir/prevalent_rates_repeated_`hftype'.csv", replace

local years " "2018" "2019" "2020" "2021" "2022" "2023" "
foreach year in `years' {
erase "$tabfigdir/prevalent_rates_repeated_`hftype'_`year'.dta"
}


}
log close