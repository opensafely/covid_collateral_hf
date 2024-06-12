********************************************************************************
*
*	Do-file:		001_cr_define_covariates_incident.do
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
log using "$logdir/001_cr_define_covariates_incident.log", replace


import delimited "$outdir/input_incident.csv", clear

	di "STARTING COUNT FROM IMPORT:"

	count 

* check that no HFpEF patients are included
	drop if hfpef==1
	count

* master index date for incident populations - date of first heart failure (patient_index_date)
	gen master_index=patient_index_date
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

gen year=year(patient_index_date)
tab year

*keep patients whose incident heart failure was on or after 2018
	drop if year<2018

*keep HFrEF patients identified in primary care AND unknown patients identified in primary care but with two pillars
	keep if hfref==1 | (  first_hf_primary!=. & two_pillars==1)
	count
	
*save dataset 
save "$outdir/incident_cohort_hf.dta", replace 

*save dataset of HFrEF patients identified in primary care 
	keep if hfref==1
	count 
save "$outdir/incident_cohort_hfref.dta", replace 

log close