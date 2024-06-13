********************************************************************************
*
*	Do-file:		101_cr_incident_simple_rates.do
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
capture log close
log using "$logdir/101_cr_incident_simple_rates.log", replace

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

local years " "2022" "2023" "
foreach year in `years' {
use "$outdir/incident_cohort_`hftype'.dta", clear 
keep if year==`year'

	*list stratifiers
		global stratifiers "agegroup male ethnicity imd region_9 previous_diabetes ckd aa arni betablocker mra sglt2i two_pillars three_pillars four_pillars"
		*efi_cat
	*create a file to post results	
		tempname measures
		display "make postfile"
		postfile `measures' float(year) str20(time) str25(outcome) str20(variable) category personTime numEvents rate lc uc using "$tabfigdir/incident_rates_summary_`hftype'_`year'", replace

foreach v in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
				cvd_mortality  hyperkalaemia ///
				hyponatraemia dka_hosp aki fractures{
				*hf_mortality
	display "preserve data"			
	preserve	
	local out  `v'
	local d " "1yr" "5yr" "
	foreach x in `d' {
		display "set end date for outcome"
		local enddatenow= "`v'_enddate`x'"
		local start1yr=patient_index_date
		*local start2yr=patient_index_date+365.25
		local start5yr=patient_index_date
		
		display "stset the data"
		stset `enddatenow', id(patient_id) failure(`out'`x') enter(patient_index_date)  scale(365.25)
		
		display "calculate rate"
		* Overall rate 
		stptime, per(1000)  
		* Save measure
		local events . // create a local macro called events and set to missing
		if `r(failures)' == 0 | `r(failures)' > 5 {
		local events = `r(failures)' 
		}
		* if the number of failures is zero or more than 5, set the local macro to the number of events 
		post `measures' (`year') ("`x'") ("`out'") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
		
		* Stratified	
		foreach c of global stratifiers {		
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "$group: Calculate rate for variable `c' and level `l'" 
				count if `c'==`l' & _d==1 
				if `r(N)' > 0  {
				stptime if `c'==`l'
				* Save measures
				local events .
				local persontime .
				local rate .
				local lower .
				local upper .
				display `events' `persontime' `rate' `lower' `upper'
				if (`r(failures)' == 0 | `r(failures)' > 5) {
					local events =`r(failures)'
					local persontime = `r(ptime)'
					local rate = `r(rate)'
					local lower = `r(lb)'
					local upper = `r(ub)'				
				}
				post `measures' (`year') ("`x'") ("`out'") ("`c'") (`l') (`persontime')	///
								(`events') (`rate') 							///
								(`lower') (`upper')
				}

				else { 					
				post `measures' (`year') ("`x'") ("`out'") ("`c'") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
					
			}
		}
		}
  
restore  
		
}
}
postclose `measures'


local years " "2022" "2023" "
foreach year in `years' {
* Change postfiles to csv
use "$tabfigdir/incident_rates_summary_`hftype'_`year'", replace
export delimited using "$tabfigdir/incident_rates_summary_`hftype'_`year'.csv", replace
erase "$tabfigdir/incident_rates_summary_`hftype'_`year'.dta"
}
}

log close