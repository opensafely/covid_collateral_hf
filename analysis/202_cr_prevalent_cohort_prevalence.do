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
*2.  GRAPH AND TABULATE THE PROPORTION OF PATIENTS ON DRUGS BY COVARIATES
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
		
		
		export delimited using "$tabfigdir/prevalent_prevalences_summary_`hftype'_redacted_rounded.csv", replace
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2018.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2019.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2020.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2021.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2022.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2023.dta"

		/*
	***************************************************************************
	*OVERALL PRESCRIPTION BY YEAR
	***************************************************************************
	***************************************************************************
	*GRAPHS BY COVARIATES
	***************************************************************************
	*Label variables for graph
	noi display "labelling variables"
		replace variable="Age group" if variable=="agegroup"
		replace variable="Sex" if variable=="male"
		replace variable="Ethnicity" if variable=="ethnicity"
		replace variable="IMD" if variable=="imd"
		replace variable="Region" if variable=="region_9"
		replace variable="Duration HF" if variable=="duration_hf_yrs"
		replace variable="Diabetes" if variable=="previous_diabetes"
		replace variable="Frailty" if variable=="efi_cat"
		replace variable="CKD" if variable=="ckd"
		replace variable="CLD" if variable=="cld"
		
		gen order=. 
		replace order=1 if variable=="Overall"
		replace order=2 if variable=="Age group"
		replace order=3 if variable=="Sex"
		replace order=4 if variable=="Ethnicity"
		replace order=5 if variable=="IMD"
		replace order=6 if variable=="Region"
		replace order=7 if variable=="Duration HF"
		replace order=8 if variable=="Diabetes"
		replace order=9 if variable=="CKD"
		replace order=10 if variable=="CLD"
		gen cat=""
		
		replace cat="All" if variable=="Overall"
		
		replace cat="18-29" if variable=="Age group" & category==1
		replace cat="30-39" if variable=="Age group" & category==2
		replace cat="40-49" if variable=="Age group" & category==3
		replace cat="50-59" if variable=="Age group" & category==4
		replace cat="60-69" if variable=="Age group" & category==5
		replace cat="70-79" if variable=="Age group" & category==6
		replace cat="80+" if variable=="Age group" & category==7
		
		replace cat="Female" if variable=="Sex" & category==0
		replace cat="Male" if variable=="Sex" & category==1
		
		replace cat="White" if variable=="Ethnicity" & category==1
		replace cat="Mixed" if variable=="Ethnicity" & category==2
		replace cat="Asian or Asian British" if variable=="Ethnicity" & category==3
		replace cat="Black" if variable=="Ethnicity" & category==4
		replace cat="Other" if variable=="Ethnicity" & category==5
		replace cat="Unknown" if variable=="Ethnicity" & category==6

		replace cat="1 least deprived" if variable=="IMD" & category==1
		replace cat="2" if variable=="IMD" & category==2
		replace cat="3" if variable=="IMD" & category==3
		replace cat="4" if variable=="IMD" & category==4
		replace cat="5 most deprived" if variable=="IMD" & category==5
	
		replace cat="East Midlands" if variable=="Region" & category==1				
		replace cat="East" if variable=="Region" & category==2
		replace cat="London" if variable=="Region" & category==3							
		replace cat="North East"  if variable=="Region" & category==4						
		replace cat="North West" if variable=="Region" & category==5						
		replace cat="South East" if variable=="Region" & category==6 						
		replace cat="South West" if variable=="Region" & category==7						
		replace cat="West Midlands" if variable=="Region" & category==8 	
		replace cat="Yorkshire and The Humber" if variable=="Region" & category==9

		replace cat="0-1 years" if variable=="Duration HF" & category==0								
		replace cat="1-2 years" if variable=="Duration HF" & category==1
		replace cat="2-5 years" if variable=="Duration HF" & category==2 
		replace cat=">5 years" if variable=="Duration HF" & category==3
	
		replace cat="No diabetes"  if variable=="Diabetes" & category==0						
		replace cat="Diabetes"  if variable=="Diabetes" & category==1						

		replace cat="No CKD"  if variable=="CKD" & category==1				
		replace cat="CKD stage 3, eGFR 30-60"  if variable=="CKD" & category==2			
		replace cat="CKD stage 4/5, eGFR <30"  if variable=="CKD" & category==3						

		*replace cat="No CLD"  if variable=="CLD" & category==0						
		*replace cat="CLD"  if variable=="CLD" & category==1						
*/


		***************************************************************************
		*OVERALL PRESCRIPTION, BY CALENDAR YEAR
		***************************************************************************
		/*
		*GRAPH POST OUTPUT CHECK
		preserve
		noi display "make overall graph"
			keep if variable=="Overall"
			twoway bar proportion year, by(drugpresc, ///
			rows(2) ///
			legend(off) ///
			graphregion(color(white))) ///
			xlabel(2018 2019 2020 2021 2022 2023, labsize(small) angle(45) notick) ///
			ytitle(Percentage of patients treated (95% CI)) ///
			yscale(range (0 100)) ///
			ylabel(0(20)70) ///
			xtitle("") ///
			barwidth(0.8) ///
			|| rcap uci lci year, 
			* 
			
		graph export "$tabfigdir/prevalent_prevalences_by_`hftype'.svg", as(svg) replace	
		restore	
		*/
		*TABLE
				
	/*
	*GRAPH STRATIFIED
	local years " "2023" "
	*"2018" "2019" "2020" "2021" "2022"
	foreach year in `years' {
	foreach drug in aa betablockers mra arni sglt2i two_pillars three_pillars four_pillars {	
			
			preserve	
				keep if year==`year'
				keep if drug=="`drug'"
				/*
				graph bar proportion, over(cat, gap(5)) ///
				legend(label(1 "Overall") label(2 "Age group") label(3 "Sex") label(4 "Ethnicity")) ///
				ytitle("Proportion") ///
				title("Proportions by Category") ///
				|| rcap ul ll cat
				*/
				graph bar proportion, ///
				over(cat, sort(order) label(angle(45) labsize(vsmall))) ///
				graphregion(color(white)) ///
				ytitle(% patients treated with `drug' in `year' (95% CI)) ///
				bargap(40) 
				*need to add confidence intervals
				graph save "$tabfigdir/prevalent_prevalences_by_covar_`hftype'_`year'_`drug'.gph", replace	
			restore	
				}
				*/
}
				
		
log close		
