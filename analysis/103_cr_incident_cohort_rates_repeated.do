********************************************************************************
*
*	Do-file:		103_cr_incident_cohort_rates_repeated.do
*
*	Programmed by:	Emily Herrett (based on John & Alex)
*
*	Data used:		None
*
*	Data created:   None
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
capture log close
log using "$logdir/103_cr_incident_cohort_rates_repeated.log", replace

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
	use "$outdir/incident_cohort_`hftype'.dta", clear 
		keep if year==`year'	

	global stratifiers "agegroup male ethnicity imd region_9 previous_diabetes ckd aa arni betablocker mra sglt2i two_pillars three_pillars four_pillars"
	*efi_cat
		tempname measures																	 
		postfile `measures' float(year) str25(outcome) str20(variable) category float(rate) float(ll) float(ul) using "$tabfigdir/incident_rates_repeated_`hftype'_`year'", replace
		local d " "1yr" "5yr" "
		foreach x in `d' {
			foreach v in n_admitted_hosp ///
			n_emerg_hosp n_outhf_emerg  ///
			n_outhf_secondary ///
			n_cvd_admissions ///
			n_dka_hosps {
				preserve
				local failure="`v'`x'"
				display "`failure'"
				replace `failure'=0 if `failure'<1 /// return expectations has led to some numbers below zero so fix here for dummy data
				
				local enddatenow= "enddate`x'"
				stset `enddatenow', id(patient_id) failure(`failure') enter(patient_index_date) exit(time .) scale(365.25)
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
					noi di "Calculate rate in `year' for variable `c' and level `l'" 
					count if `c'==`l' & _d==1 & timefup!=.
						local n_events=r(N)
						/*
					*count number of people in subgroup
						count if `c' ==`l'
						local n_people=r(N)
						
					*count number of people with outcomes in subgroup, if they have follow-up
						count if `c'==`l' & `failure'>0 & timefup!=.
						local n_outcomes=r(N)
					*proceed with rate calc if there are sufficient people in the group and they have follow-up time
						if `n_people' > 0 & `n_events' > 0 & timefup!=. {
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
						/*
						else {
							post `measures' (`year') ("`v'`x'")  ("`c'") (`l') (.) (.) (.) 	
						
						}
						}
						*/
						else {
							post `measures' (`year') ("`v'`x'")  ("`c'") (`l') (.) (.) (.) 	
						}

				
				}
				}
				*/
				restore
				
			}
			}
		
postclose `measures'

* Change postfiles to csv
}
use "$tabfigdir/incident_rates_repeated_`hftype'_2018", clear
append using "$tabfigdir/incident_rates_repeated_`hftype'_2019"
append using "$tabfigdir/incident_rates_repeated_`hftype'_2020"
append using "$tabfigdir/incident_rates_repeated_`hftype'_2021"
append using "$tabfigdir/incident_rates_repeated_`hftype'_2022"
append using "$tabfigdir/incident_rates_repeated_`hftype'_2023"

export delimited using "$tabfigdir/incident_rates_repeated_`hftype'_summary.csv", replace

*erase files for each year
local years " "2018" "2019" "2020" "2021" "2022" "2023" "
foreach year in `years' {
capture erase "$tabfigdir/incident_rates_repeated_`hftype'_`year'.csv"
capture erase "$tabfigdir/incident_rates_repeated_`hftype'_`year'.dta"
}


}
log close