********************************************************************************
*
*	Do-file:		101_cr_simple_rates_prevalent.do
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
*	Note:			
********************************************************************************
do "`c(pwd)'/analysis/global.do"

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear 

global stratifiers "agegroup male ethnicity imd region_9 duration_hf_yrs previous_diabetes ckd cld"
*efi_cat
tempname measures
																	 
	postfile `measures' float(year) str25(outcome) str20(variable) category personTime numEvents rate lc uc using "$tabfigdir/rates_summary_`hftype'_`year'", replace

foreach v in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
				cvd_mortality hf_mortality hyperkalaemia ///
				hyponatraemia dka_hosp aki fractures{

	preserve
	cap drop time	
	local out  `v'
	local end_date `v'_enddate
	
		stset `end_date', id(patient_id) failure(`out') enter(index_date)  origin(index_date) scale(365.25)
		
		* Overall rate 
		stptime, per(1000)  
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' (`year') ("`out'") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
		
		* Stratified	
		foreach c of global stratifiers {		
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "$group: Calculate rate for variable `c' and level `l'" 
				qui  count if `c' ==`l'
				if `r(N)' > 0 {
				stptime if `c'==`l'
				* Save measures
				local events .
				if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
				post `measures' (`year') ("`out'") ("`c'") (`l') (`r(ptime)')	///
								(`events') (`r(rate)') 							///
								(`r(lb)') (`r(ub)')
				}

				else {
				post `measures' ("$group") ("`out'") ("`c'") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
					
			}
		}
  
restore  
		
}

postclose `measures'

* Change postfiles to csv
use "$tabfigdir/rates_summary_`hftype'_`year'", replace

export delimited using "$tabfigdir/rates_summary_`hftype'`year'.csv", replace

}
}