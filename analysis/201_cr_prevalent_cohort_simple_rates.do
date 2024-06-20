********************************************************************************
*
*	Do-file:		201_cr_prevalent_simple_rates.do
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
log using "$logdir/201_cr_prevalent_simple_rates.log", replace

local heartfailtype " "hf" "hfref"  "
foreach hftype in `heartfailtype' {

	local years "  "2023" "
	* "2018" "2019" "2020" "2021" "2022"
	foreach year in `years' {
	use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear 

	global stratifiers "agegroup male ethnicity imd region_9 duration_hf_yrs previous_diabetes ckd aa arni betablocker mra sglt2i two_pillars three_pillars four_pillars"
	*efi_cat

	tempname measures
																		 
		postfile `measures'  float(year) str20(time) str25(outcome) str20(variable) category personTime numEvents rate lc uc using "$tabfigdir/prevalent_rates_summary_`hftype'_`year'", replace

	foreach v in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
					cvd_mortality  hyperkalaemia ///
					hyponatraemia dka_hosp aki fractures{
	preserve
	cap drop time	
	local out  `v'
	local d " "1yr"  "
	*"5yr"
	foreach x in `d' {
		local enddatenow= "`v'_enddate`x'"
		local start1yr=master_index_date
		*local start2yr=master_index_date+365.25
		local start5yr=master_index_date
	
		stset `enddatenow', id(patient_id) failure(`out'`x') enter(master_index_date) origin(master_index_date) scale(365.25)
		
		
		
		
		* Overall rate 
		stptime, per(1000)  
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 7 {
			local events = `r(failures)'
			}
		post `measures' (`year') ("`x'") ("`out'") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
		
		
		
		
		* Stratified	
		foreach c of global stratifiers {		
			levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "$group: Calculate rate for variable `c' and level `l'" 
				count if `c' ==`l'
				*if `r(N)' > 0 {
				capture stptime  if `c'==`l', per(1000)
				* Save measures
					local events .
					local persontime .
					local rate .
					local lower .
					local upper .
					display `events' `persontime' `rate' `lower' `upper'
				if (`r(failures)' == 0 | `r(failures)' > 7) {
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
				
		}
		}
restore  
		

}

postclose `measures'


export delimited using "$tabfigdir/prevalent_rates_summary_`hftype'_`year'.csv", replace
*erase "$tabfigdir/prevalent_rates_summary_`hftype'_`year'.dta"
}

* Change postfiles to csv
use "$tabfigdir/prevalent_rates_summary_`hftype'_2023", clear
		/*
		local years " "2019" "2020" "2021" "2022" "2023" "
		* 
		foreach year in `years' {
			append using "$tabfigdir/prevalent_rates_summary_`hftype'_`year'"
			}
			*/
	** Redact and round rates
	foreach var of varlist numEvents personTime  {
	gen `var'_midpoint = (ceil(`var'/6)*6) - (floor(6/2) * (`var'!=0))
	}
	gen rate_midpoint = (numEvents_midpoint/personTime_midpoint)*1000
	gen lci_midpoint = exp( ln(rate_midpoint) - invnormal(0.975)/sqrt(numEvents_midpoint) )
	gen uci_midpoint = exp( ln(rate_midpoint) + invnormal(0.975)/sqrt(numEvents_midpoint) )
	drop personTime numEvents rate lc uc
	replace lci_midpoint=. if rate_midpoint==0
	replace uci_midpoint=. if rate_midpoint==0
	
		export delimited using "$tabfigdir/prevalent_rates_summary_`hftype'_redacted_rounded.csv", replace

		local years " "2023" "
*		"2018" "2019" "2020" "2021" "2022" 
		foreach year in `years' {
			capture erase "$tabfigdir/prevalent_rates_summary_`hftype'_`year'.dta"
			capture erase "$tabfigdir/prevalent_rates_summary_`hftype'_`year'.csv"
			}

}

log close