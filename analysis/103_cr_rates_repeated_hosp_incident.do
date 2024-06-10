********************************************************************************
*
*	Do-file:		102_cr_rates_repeated_hosp_prevalent.do
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

/*	foreach out in all_hosp_fup outhf_hosp all_cvd_fup  dka_hosp s{

				*/

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
	use "$outdir/incident_cohort_`hftype'.dta", clear 
		keep if year==`year'	

	global stratifiers "agegroup male ethnicity imd region_9 previous_diabetes ckd cld"
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
				
				*Overall
				poisson `failure', cluster(patient_id) exposure(timefup)
				poisson, irr
				matrix list r(table)
				local rate = r(table)[1, 1]
				local ll = r(table)[5, 1]
				local ul = r(table)[6, 1]
				post `measures' (`year') ("`v'`x'") ("Overall") (0) (`rate') (`ll') (`ul')
				
				*Stratified	
				foreach c of global stratifiers {		
				qui levelsof `c' , local(cats) 
				di `cats'
				foreach l of local cats {
					noi di "Calculate rate in `year' for variable `c' and level `l'" 
					*count number of people in subgroup
					count if `c' ==`l'
					local n_people=r(N)
					*count number of people with outcomes in subgroup, if they have follow-up
					count if `c'==`l' & `failure'>0 & timefup!=.
					local n_outcomes=r(N)
					if `n_people' > 0 & `n_outcomes'>0 {
					poisson `failure' if `c'==`l', cluster(patient_id) exposure(timefup)
					poisson, irr
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
				*/
				restore
				
			}
			}
		
postclose `measures'

* Change postfiles to csv
use "$tabfigdir/incident_rates_repeated_`hftype'_`year'", clear
export delimited using "$tabfigdir/incident_rates_repeated_`hftype'_`year'.csv", replace

}
}