********************************************************************************
*
*	Do-file:		202_cr_prevalent_cohort_prevalence.do
*
*	Programmed by:	Emily Herrett (based on John & Alex)
*
*	Data used:		"$outdir/prevalent_cohort_`hftype'_`year'.dta"
*
*	Data created:   "$tabfigdir/prevalences_summary_`year'"
*
*	Other output:	Graphs describing prevalence of drug use
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			
********************************************************************************
do "`c(pwd)'/analysis/global.do"
capture log close
log using "$logdir/202_cr_prevalent_cohort_prevalence.log", replace

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

********************************************************************************
*1.  CREATE TABLE OF PROPORTIONS FOR EACH DRUG, EACH COVARIATE AND EACH YEAR
********************************************************************************

local years " "2018" "2019" "2020" "2021" "2022" "2023" "
* 
foreach year in `years' {

	use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear 

	global stratifiers "agegroup male ethnicity imd duration_hf_yrs previous_diabetes ckd"
	*efi_cat region_9
	*tempfile for the postfile command
	tempname measures
*float(year)																	 	
	postfile `measures' float(year)  str20(drug) str20(variable) float(category) float(total) float(ondrug) using "$tabfigdir/prevalent_prevalences_summary_`hftype'_`year'", replace

	*need to add contraindications to this loop
foreach drug in aa betablockers mra arni sglt2i two_pillars three_pillars four_pillars {	
	display `drug'
	*unstratified
		preserve
		*drop if patient has contraindications to the drug 
		capture drop if population_`drug'!=1
		count 
		local total=r(N)
		count if `drug'==1
		local ondrug=r(N)
		local category=.
		// Loop through the results and post them to the temporary file		
			if (`ondrug' == 0 | `ondrug' > 7) & (`total' == 0 | `total' >7) {
			post `measures' (`year') ("`drug'") ("Overall") (`category') (`total') (`ondrug')
			}

			else {
			post `measures' (`year') ("`drug'") ("Overall") (`category') (`total') (.) 
					}
				

		
	*stratified
		foreach c of global stratifiers {		
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "Calculate proportion on `drug' for variable `c' and level `l'" 
				noi display "number of people in category"
				count if `c'==`l'
				local total=r(N)
				noisily display "number of people in variable `c' and level `l' and on `drug'"
				count if `c' ==`l' & `drug'==1
				local ondrug =r(N)
				// Loop through the results and post them to the temporary file
				local category = `l'
				if `ondrug' == 0 | `ondrug' > 7 {
				post `measures' (`year') ("`drug'") ("`c'") (`category') (`total') (`ondrug') 
				}

				else {
				post `measures' (`year') ("`drug'") ("`c'") (`category') (`total') (.)
					}
					
				}
			}
		restore	
		}	
	// Close the postfile
	postclose `measures'

}

********************************************************************************
*2.  TABULATE THE PROPORTION OF PATIENTS ON DRUGS BY COVARIATES
********************************************************************************
	noi display "combine the summaries from each year for a graph"
	use "$tabfigdir/prevalent_prevalences_summary_`hftype'_2018", clear
	*
	local years 2019 2020 2021 2022 2023 
	foreach year in `years' {
	append using "$tabfigdir/prevalent_prevalences_summary_`hftype'_`year'"
	}

	* Redact numbers less than 7
	foreach var in total ondrug {
	replace `var'=. if `var'<=7
	}	
	
	* Rounding numbers in table to nearest 5
	noi display "round numbers to the nearest 5"
	foreach var in total ondrug {
	gen rounded_`var' = round(`var', 5)
	drop `var'
	rename rounded_`var' `var'
	}
	* Calculate the proportion
	gen proportion=(ondrug/total)

	* Calculate the confidence intervals for each proportion
	noi display "make confidence intervals for each proportion"
	gen lci = .
	gen uci = .
	count
	local count=r(N)
	forvalues i = 1/`count' {
		local ondrug = ondrug[`i']
		local total = total[`i']
		display `i'
		capture cii proportions `total' `ondrug'
		display r(lb)
		display r(ub)
		replace lci = r(lb) in `i'
		replace uci = r(ub) in `i'
	}
	
	*TURN PROPORTIONS INTO PERCENTAGES
	noi display "make proportions into percentages"
		replace proportion=proportion*100
		replace lci=lci*100
		replace uci=uci*100

	*DESTRING THE DRUGS AND LABEL
	noi display "destring drug names and label"
		gen drugpresc=.
		replace drugpresc=1 if drug=="aa"
		replace drugpresc=2 if drug=="betablockers"
		replace drugpresc=3 if drug=="mra"
		replace drugpresc=4 if drug=="arni"
		replace drugpresc=5 if drug=="sglt2i"
		replace drugpresc=6 if drug=="two_pillars"
		replace drugpresc=7 if drug=="three_pillars"
		replace drugpresc=8 if drug=="four_pillars"
		
		label define drugs 1 "ACEi/ARB" 2 "Beta blocker" 3 "MRA" 4 "ARNi" 5 "SGLT2i" 6 "Two pillars" 7 "Three pillars" 8 "Four pillars"
		label values drugpresc drugs

		order year drugpresc variable cat category total ondrug proportion lci uci
		rename total total_rounded
		rename ondrug ondrug_rounded
		rename proportion proportion_rounded
		
		export delimited using "$tabfigdir/prevalent_prevalences_summary_`hftype'_redacted_rounded.csv", replace
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2018.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2019.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2020.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2021.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2022.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2023.dta"

}
				
		
log close		
