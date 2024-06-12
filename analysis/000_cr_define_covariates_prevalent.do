********************************************************************************
*
*	Do-file:		000_cr_define_covariates_prevalent.do
*
*	Programmed by:	Emily Herrett (based on Alex & John (Based on Fizz & Krishnan))
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
clear
capture log close
do "`c(pwd)'/analysis/global.do"
log using "$logdir/000_cr_define_covariates_prevalent.log", replace

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
import delimited "$outdir/input_prevalent_`year'.csv", clear
*import delimited "$outdir/input_prevalent_2018.csv", clear


	di "STARTING COUNT FROM IMPORT:"
	count 

* check that no HFpEF patients are included
	drop if hfpef==1
	count
	
* master indexdate for prevalent populations - mid year 
	gen master_index = "`year'-05-01"
	*gen index = "2018-05-01"

do "$projectdir/analysis/002_cr_covariates.do"

	*Duration of heart failure
	gen duration_hf=(master_index_date-patient_index_date)/365.25
	replace duration_hf=. if duration_hf<0
	assert duration_hf>=0
	gen duration_hf_yrs=.
	replace duration_hf_yrs=0 if duration_hf<1
	replace duration_hf_yrs=1 if duration_hf>=1 & duration_hf<2
	replace duration_hf_yrs=2 if duration_hf>=2 & duration_hf<5
	replace duration_hf_yrs=3 if duration_hf>=5 & duration_hf!=.
	label define duration 0 "0-1 years" 1 "1-2 years" 2 "2-5 years" 3 ">5 years"
	label values duration_hf_yrs duration 
	tab duration_hf_yrs

*keep HFrEF patients identified in primary care AND unknown patients identified in primary care but with two pillars
	keep if hfref==1 | (first_hf_primary!=. & two_pillars==1)
	count
save "$outdir/prevalent_cohort_hf_`year'.dta", replace 

*keep HFrEF patients identified in primary care
	keep if hfref==1
	count 

save "$outdir/prevalent_cohort_hfref_`year'.dta", replace 

}
log close