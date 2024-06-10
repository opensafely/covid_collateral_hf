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

use "$outdir/incident_cohort_`hftype'.dta", clear 

	*list stratifiers
		global stratifiers "agegroup male ethnicity imd region_9 previous_diabetes ckd cld year"
		*efi_cat
	*create a file to post results	
		tempname measures
		postfile `measures' str20(time) str25(outcome) str20(variable) category personTime numEvents rate lc uc using "$tabfigdir/incident_rates_summary_`hftype'", replace

foreach v in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
				cvd_mortality hf_mortality hyperkalaemia ///
				hyponatraemia dka_hosp aki fractures{

	preserve	
	local out  `v'
	local d " "1yr" "5yr" "
	foreach x in `d' {
		local enddatenow= "`v'_enddate`x'"
		local start1yr=patient_index_date
		*local start2yr=patient_index_date+365.25
		local start5yr=patient_index_date
	
		stset `enddatenow', id(patient_id) failure(`out'`x') enter(`start`x'')  origin(`start`x'') scale(365.25)
		
		* Overall rate 
		stptime, per(1000)  
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' ("`x'") ("`out'") ("Overall") (0) (`r(ptime)') 	///
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
				post `measures' ("`x'") ("`out'") ("`c'") (`l') (`r(ptime)')	///
								(`events') (`r(rate)') 							///
								(`r(lb)') (`r(ub)')
				}

				else {
				post `measures' ("`x'") ("`out'") ("`c'") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
					
			}
		}
		}
  
restore  
		
}

postclose `measures'

* Change postfiles to csv
use "$tabfigdir/incident_rates_summary_`hftype'", replace

export delimited using "$tabfigdir/incident_rates_summary_`hftype'.csv", replace
erase "$tabfigdir/incident_rates_summary_`hftype'.dta"
}
