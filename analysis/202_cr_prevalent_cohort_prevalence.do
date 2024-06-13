********************************************************************************
*
*	Do-file:		102_cr_prevalent_cohort_prevalence.do
*
*	Programmed by:	Emily Herrett (based on John & Alex)
*
*	Data used:		"$outdir/prevalent_cohort_hfref_`year'.dta"
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
log using "$logdir/102_cr_prevalent_cohort_prevalence.log", replace

local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

********************************************************************************
*1.  CREATE TABLE OF PROPORTIONS FOR EACH DRUG, EACH COVARIATE AND EACH YEAR
********************************************************************************

local years "  "2022" "2023" "
*"2018" "2019" "2020" "2021"
foreach year in `years' {

	use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear 
	*use "$outdir/prevalent_cohort_hfref_2018.dta", clear 

	global stratifiers "agegroup male ethnicity imd duration_hf_yrs previous_diabetes ckd"
	*efi_cat region_9
	*tempfile for the postfile command
	tempname measures
*float(year)																	 	
	postfile `measures' float(year)  str20(drug) str20(variable) float(category) float(total) float(ondrug) float(proportion) float(ll) float(ul) using "$tabfigdir/prevalent_prevalences_summary_`hftype'_`year'", replace

	*need to add contraindications to this loop
	*need to add automatic redaction to this loop
foreach drug in aa betablockers mra arni sglt2i two_pillars three_pillars four_pillars {	

	*unstratified
		count 
		local total=r(N)
		count if `drug'==1
		local ondrug=r(N)
		proportion `drug'
		// Loop through the results and post them to the temporary file
	matrix list r(table)
	*local i = 1
	*while `i' <= colsof(r(table)) {
		local category = .
		local proportion = r(table)[1, 2]
		local ll = r(table)[5,2]
		local ul = r(table)[6,2]
		
			if (`ondrug' == 0 | `ondrug' > 5) & (`total' == 0 | `total' >5) {
			post `measures' (`year') ("`drug'") ("Overall") (`category') (`total') (`ondrug') (`proportion') (`ll') (`ul')
			}

			else {
			post `measures' (`year') ("`drug'") ("Overall") (`category') (`total') (.) (.) (.) (.)
					}
				

		
	*stratified
		foreach c of global stratifiers {		
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "Calculate proportion for variable `c' and level `l'" 
				count if `c'==`l'
				local total=r(N)
				count if `c' ==`l' & `drug'==1
				local ondrug =r(N)
				proportion `drug' if `c'==`l'
				// Loop through the results and post them to the temporary file
				matrix list r(table)
				local category = `l'
				local proportion = r(table)[1, 2]
				local ll = r(table)[5, 2]
				local ul = r(table)[6, 2]
				
			if `ondrug' == 0 | `ondrug' > 5 {
			post `measures' (`year') ("`drug'") ("`c'") (`category') (`total') (`ondrug') (`proportion') (`ll') (`ul')
			}

			else {
			post `measures' (`year') ("`drug'") ("`c'") (`category') (`total') (.) (.) (.) (.)
				}
				
			}
		}
		
	}	
	// Close the postfile
	postclose `measures'

}
********************************************************************************
*2.  GRAPH AND TABULATE THE PROPORTION OF PATIENTS ON DRUGS BY COVARIATES
********************************************************************************
	use "$tabfigdir/prevalent_prevalences_summary_`hftype'_2022", clear
	
	local years 2023 
*2019 2020 2021 2022
	foreach year in `years' {
	append using "$tabfigdir/prevalent_prevalences_summary_`hftype'_`year'"
	}

	*TURN PROPORTIONS INTO PERCENTAGES
		replace proportion=proportion*100
		replace ll=ll*100
		replace ul=ul*100

	*DESTRING THE DRUGS AND LABEL	
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

	***************************************************************************
	*OVERALL PRESCRIPTION BY YEAR
	***************************************************************************
	***************************************************************************
	*GRAPHS BY COVARIATES
	***************************************************************************
	*Label variables for graph
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
		replace cat="East of England" if variable=="Region" & category==2
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

		replace cat="No CKD"  if variable=="CKD" & category==0						
		replace cat="CKD stage 3, eGFR 30-60"  if variable=="CKD" & category==1						
		replace cat="CKD stage 4/5, eGFR <30"  if variable=="CKD" & category==2						

		*replace cat="No CLD"  if variable=="CLD" & category==0						
		*replace cat="CLD"  if variable=="CLD" & category==1						


		***************************************************************************
		*OVERALL PRESCRIPTION, BY CALENDAR YEAR
		***************************************************************************
		
		preserve	
			keep if variable=="Overall"
			twoway bar proportion year, by(drugpresc, ///
			rows(2) ///
			legend(off) ///
			graphregion(color(white))) ///
			xlabel( 2022 2023, labsize(small) angle(45) notick) ///
			ytitle(Percentage of patients treated (95% CI)) ///
			yscale(range (0 100)) ///
			ylabel(0(20)70) ///
			xtitle("") ///
			barwidth(0.8) ///
			|| rcap ul ll year, 
		graph save "$tabfigdir/prevalent_prevalences_by_`hftype'.gph", replace	
		restore	
		*2018 2019 2020 2021
		*TABLE
		order year drugpresc variable cat category total ondrug proportion ll ul
		export delimited using "$tabfigdir/prevalent_prevalences_summary_`hftype'.csv", replace
		*erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2018.dta"
		*erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2019.dta"
		*erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2020.dta"
		*erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2021.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2022.dta"
		erase "$tabfigdir/prevalent_prevalences_summary_`hftype'_2023.dta"

		}			
log close		

	/*
	*GRAPH
	local years " "2018" "2019" "2020" "2021" "2022" "2023" "
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
	*TABLE
	*export delimited using "$tabfigdir/prevalences_covar_`hftype'_`year'_`drug'.csv", replace
			
			restore	
				}
				}
*/

			
	/*
			///
			*(rcap ul ll cat)
			/*
			twoway (bar proportion number), 
			///
				barwidth(0.8) sort(order) ///
				label(angle(45) labsize(vsmall)) ///
				graphregion(color(white)) ///
				ytitle("Percentage of patients treated (95% CI)") ///
				bargap(40) lcolor(none)) ///
				(rcap lower upper number), ///
				graphregion(color(white))
				
				
			twoway (bar proportion cat, ///
			sort(order) label(angle(45) labsize(vsmall))) ///
			graphregion(color(white)) ///
			ytitle(Percentage of patients treated (95% CI)) ///
			bargap(40)) (rcap ul ll, over(cat))
			
			|| rcap ul ll proportion
			
				*/		
			
		

		
		
		
		
		
/*		
*BY AGE GROUP
local vars ageband sex eth5 townsend_quint	
foreach name in `vars' {
	keep if `name'!=.
	twoway bar proportion year, by(`name', rows(1) legend(off) graphregion(color(white)))  xlabel(2019 2020 2021, notick) yscale(range (0 100)) ylabel(0(20)100) ytitle(Proportion of eligible patients treated) xtitle("Year") barwidth(0.8) || rcap upperci lowerci year, 
*/
	/*
	gen agegroup=.
	replace agegroup=category if variable=="Age group"
	label define agegrp 1 "18-39" 2 "40-59" 3 "60-79" 4 "80+"
	label values agegroup agegrp

	gen male=.
	replace male=category if variable=="Sex"
	*label define sexLab 1 "male" 0 "female"
	label values male sexLab

	gen ethnicity=.
	replace ethnicity=category if variable=="Ethnicity"
	label define ethnicity_lab 	1 "White"  							///
							2 "Mixed" 								///
							3 "Asian or Asian British"				///
							4 "Black"  								///
							5 "Other"								///
							6 "Unknown"
	label values ethnicity ethnicity_lab
	
	gen region=.
	replace region=category if variable=="Region"
	label define region_9 	1 "East Midlands" 					///
							2 "East of England"   				///
							3 "London" 							///
							4 "North East" 						///
							5 "North West" 						///
							6 "South East" 						///
							7 "South West"						///
							8 "West Midlands" 					///
							9 "Yorkshire and The Humber"
	label values region region_9

	gen imd=.
	replace imd=category if variable=="IMD"
	label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" 
	label values imd imd 

	gen duration_hf_yrs=.
	replace duration_hf_yrs=category if variable=="Duration HF"
	label define duration 0 "0-1 years" 1 "1-2 years" 2 "2-5 years" 3 ">5 years"
	label values duration_hf_yrs duration 
	
	gen diabetes=.
	replace diabetes=category if variable=="Diabetes"
	label define yndiab 0 "No diabetes" 1 "Diabetes"
	label values diabetes yndiab 
	
	gen ckd=.
	replace ckd=category if variable=="CKD"
	label define ynckd 0 "No CKD" 1 "CKD stage 3, eGFR 30-60" 2 "CKD stage 4/5, eGFR<30"
	label values ckd ynckd 

	gen cld=.
	replace cld=category if variable=="CLD"
	label define yncld 0 "No CLD" 1 "CLD"
	label values cld yncld 
*/	
	*Label categories for graph
	/*
		gen cat=""
		
		replace cat="All" if variable=="Overall"
		
		replace cat="18-39" if variable=="Age group" & category==1
		replace cat="40-59" if variable=="Age group" & category==2
		replace cat="60-79" if variable=="Age group" & category==3
		replace cat="80+" if variable=="Age group" & category==4
		
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
		replace cat="East of England" if variable=="Region" & category==2
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

		replace cat="No CKD"  if variable=="CKD" & category==0						
		replace cat="CKD stage 3, eGFR 30-60"  if variable=="CKD" & category==1						
		replace cat="CKD stage 4/5, eGFR <30"  if variable=="CKD" & category==2						

		replace cat="No CLD"  if variable=="CLD" & category==0						
		replace cat="CLD"  if variable=="CLD" & category==1						

		*/
	/*	
		gen number=_n
		label define labels 1 "All" 2 "18-39" 3 "40-59" 4 "60-79" 5 "80+" 6 "Female" 7 "Male" 8 "White" ///
9 "Asian or Asian British" 10 "Other" 11 "Unknown" 12 "1 least deprived" 13 "2" ///
14 "3" 15 "4" 16 "5 most deprived" 17 "East Midlands" 18 "East of England" ///
19 "London" 20 "North East" 21 "North West" 22 "South East" 23 "South West" ///
24 "West Midlands" 25 "Yorkshire and The Humber" 26 "0-1 years" 27 "1-2 years" ///
28 "2-5 years"  29 ">5 years" 30 "No diabetes" 31 "Diabetes" 32 "No CKD" ///
33 "CKD" 34 "No CLD" 35 "CLD"
	label values number labels
		*/
