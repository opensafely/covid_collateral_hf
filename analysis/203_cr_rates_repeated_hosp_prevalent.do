********************************************************************************
*
*	Do-file:		203_cr_rates_repeated_hosp_prevalent.do
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

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
	use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear 
	*use "$outdir/prevalent_cohort_`hftype'_2018.dta", clear 

	global stratifiers "agegroup male ethnicity imd region_9 duration_hf_yrs previous_diabetes ckd cld"
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
			
			stset `enddatenow', id(patient_id) failure(`failure') enter(index_date) exit(time .) scale(365.25)
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
				noi di "Calculate rate for variable `c' and level `l'" 
				qui  count if `c' ==`l'
				if `r(N)' > 0 {
				poisson `failure' if `c'==`l', cluster(patient_id) exposure(timefup)
				poisson, irr
				matrix list r(table)
				local rate = r(table)[1, 1]
				local ll = r(table)[5, 1]
				local ul = r(table)[6, 1]
				post `measures' (`year') ("`v'`x'") ("`c'") (`l') (`rate') (`ll') (`ul')
			}
			}
			}
			restore
		}
		}
		
postclose `measures'

* Change postfiles to csv
use "$tabfigdir/prevalent_rates_repeated_`hftype'_`year'", clear
export delimited using "$tabfigdir/prevalent_rates_repeated_`hftype'_`year'.csv", replace
erase "$tabfigdir/prevalent_rates_repeated_`hftype'_`year'.dta"
}
}