********************************************************************************
*
*	Do-file:		000_cr_define_covariates.do
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
do "`c(pwd)'/analysis/global.do"

local years " "2018" "2019" "2020" "2021" "2022" "2023" "

foreach year in `years' {
import delimited "$outdir/input_prevalent_`year'.csv", clear
*import delimited "$outdir/input_prevalent_2018.csv", clear


	di "STARTING COUNT FROM IMPORT:"

	count 

* check that no HFpEF patients are included
	drop if hfpef==1
	count
*run on all patients

* Indexdate - mid year 
	gen index = "`year'-07-01"
	*gen index = "2018-07-01"

	rename patient_index_date patient_index 
*Rename variables that are too long	

******************************
*  Convert strings to dates  *
******************************
* To be added: dates related to outcomes
foreach var of varlist 	  index		///
						  date_deregistered	///
						  patient_index ///
						  first_hf_emerg ///
						  first_hf_secondary ///
						  first_hf_primary ///
						  outhf_emerg	///
						  outhf_secondary	///
						  outhf_hosp	///
						  allcause_mortality ///
						  cvd_mortality ///
						  hf_mortality ///
						  falls_primary_care ///
						  falls_emerg ///
						  all_hosp_fup	///
						  all_cvd_fup	///
						  fracture_icd_10 ///
						  amputation_primary_care ///
						  amputation_opcs4 ///
						  admitted_hosp	///
						  mace_emerg ///
						  cvd_primary_admission ///
						  hyperkalaemia ///
						  hyponatraemia ///
						  dka_hosp ///
						  aki            ///   
							{

capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		rename `var' `var'_dstr
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
	gen `var'=1 if `var'_date!=.
}

**********************
*Recode covariates
**********************
*Duration of heart failure
	gen duration_hf=(index_date-patient_index_date)/365.25
	replace duration_hf=. if duration_hf<0
	gen duration_hf_yrs=.
	replace duration_hf_yrs=0 if duration_hf<1
	replace duration_hf_yrs=1 if duration_hf>=1 & duration_hf<2
	replace duration_hf_yrs=2 if duration_hf>=2 & duration_hf<5
	replace duration_hf_yrs=3 if duration_hf>=5 & duration_hf!=.
	label define duration 0 "0-1 years" 1 "1-2 years" 2 "2-5 years" 3 ">5 years"
	label values duration_hf_yrs duration 
	tab duration_hf_yrs

* Sex
	assert inlist(sex, "M", "F")
	gen male = (sex=="M")
	drop sex
	label define sexLab 1 "male" 0 "female"
	label values male sexLab
	label var male "sex = 0 F, 1 M"

*IMD
	* Group into 5 groups
	rename imd imd_o
	egen imd = cut(imd_o), group(5) icodes
	replace imd = imd + 1
	replace imd = . if imd_o==-1
	drop imd_o

	* Reverse the order (so high is more deprived)
	recode imd 5=1 4=2 3=3 2=4 1=5 .=.

	label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" 
	label values imd imd 

	noi di "DROPPING IF NO IMD" 
	drop if imd>=.

* Smoking
	label define smoke 1 "Never" 2 "Former" 3 "Current" 
	gen     smoke = 1  if smoking_status=="N"
	replace smoke = 2  if smoking_status=="E"
	replace smoke = 3  if smoking_status=="S"
	replace smoke = . if smoking_status=="M"
	label values smoke smoke
	drop smoking_status

*Ethnicity (5 category)
	tab ethnicity 
	replace ethnicity = 6 if ethnicity==.
	label define ethnicity_lab 	1 "White"  							///
							2 "Mixed" 								///
							3 "Asian or Asian British"				///
							4 "Black"  								///
							5 "Other"								///
							6 "Unknown"
	label values ethnicity ethnicity_lab

* Region
	tab region
	rename region region_string
	assert inlist(region_string, 								///
						"East Midlands", 						///
						"East of England",  					///
						"London", 								///
						"North East", 							///
						"North West", 							///
						"South East", 							///
						"South West",							///
						"West Midlands", 						///
						"Yorkshire and the Humber") 
	gen     region_9 = 1 if region_string=="East Midlands"
	replace region_9 = 2 if region_string=="East of England"
	replace region_9 = 3 if region_string=="London"
	replace region_9 = 4 if region_string=="North East"
	replace region_9 = 5 if region_string=="North West"
	replace region_9 = 6 if region_string=="South East"
	replace region_9 = 7 if region_string=="South West"
	replace region_9 = 8 if region_string=="West Midlands"
	replace region_9 = 9 if region_string=="Yorkshire and the Humber"

	label define region_9 	1 "East Midlands" 					///
							2 "East of England"   				///
							3 "London" 							///
							4 "North East" 						///
							5 "North West" 						///
							6 "South East" 						///
							7 "South West"						///
							8 "West Midlands" 					///
							9 "Yorkshire and The Humber"
	label values region_9 region_9
	label var region_9 "Region of England (9 regions)"

	
*Age
	* Check there are no missing ages
	assert age<.
	assert ageband_broad!=""
	gen agegroup=.
	replace agegroup=1 if ageband_broad=="18-39"
	replace agegroup=2 if ageband_broad=="40-59"
	replace agegroup=3 if ageband_broad=="60-79"
	replace agegroup=4 if ageband_broad=="80+"
	
	label define agegrp 1 "18-39" 2 "40-59" 3 "60-79" 4 "80+"
	label values agegroup agegrp

*eGFR  
	* Set implausible creatinine values to missing (Note: zero changed to missing)
	replace creatinine = . if !inrange(creatinine, 20, 3000) 
		
	* Divide by 88.4 (to convert umol/l to mg/dl)
	gen SCr_adj = creatinine/88.4

	gen min=.
	replace min = SCr_adj/0.7 if male==0
	replace min = SCr_adj/0.9 if male==1
	replace min = min^-0.329  if male==0
	replace min = min^-0.411  if male==1
	replace min = 1 if min<1

	gen max=.
	replace max=SCr_adj/0.7 if male==0
	replace max=SCr_adj/0.9 if male==1
	replace max=max^-1.209
	replace max=1 if max>1

	gen egfr=min*max*141
	replace egfr=egfr*(0.993^age)
	replace egfr=egfr*1.018 if male==0
	label var egfr "egfr calculated using CKD-EPI formula with no eth"


	* Categorise into ckd stages
	egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
	recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
	* 0 = "No CKD" 	2 "stage 3a" 3 "stage 3b" 4 "stage 4" 5 "stage 5"
	label define ckd 0 "No CKD" 1 "CKD"
	label values ckd ckd
	label var ckd "CKD stage calc without eth"

	* Convert into CKD group
	*recode ckd 2/5=1, gen(chronic_kidney_disease)
	*replace chronic_kidney_disease = 0 if creatinine==. 

	recode ckd 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
	replace reduced_kidney_function_cat = 1 if creatinine==. 
	label define reduced_kidney_function_catlab ///
		1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4/5 egfr<30"
	label values reduced_kidney_function_cat reduced_kidney_function_catlab 
	replace reduced_kidney_function_cat=3 if ckd_stage45==1
	replace reduced_kidney_function_cat=2 if ckd_stage35==1 & ckd_stage45!=1
	
	*More detailed version incorporating stage 5 or dialysis as a separate category	
	*recode ckd 0=1 2/3=2 4=3 5=4, gen(reduced_kidney_function_cat2)
	*replace reduced_kidney_function_cat2 = 1 if creatinine==. 
	*label define reduced_kidney_function_cat2lab ///
	*	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4 egfr 15-<30" 4 "Stage 5 egfr <15 or dialysis"
	*label values reduced_kidney_function_cat2 reduced_kidney_function_cat2lab 
	drop SCr_adj min max egfr egfr_cat ckd 
	rename reduced_kidney_function_cat ckd 
*Diabetes
	tab previous_diabetes
	
*EFI
	gen efi_cat=.
	replace efi_cat=1 if efi<=0.12
	replace efi_cat=2 if efi>0.12 & efi<=0.24
	replace efi_cat=3 if efi>0.24 & efi<=0.36
	replace efi_cat=4 if efi>0.36 & efi!=.

	label define eficat 1 "fit" 2 "mild frailty" 3 "moderate frailty" 4 "severely frail"
	label values efi_cat eficat 

**************
*  Outcomes  *
**************	
*drugs
	*betablockers 
	*sglt2i 
	*acei 
	*arb 
	*arni 
	*mra 
	*diuretics
	*create a variable combining ACEI, ARB
	gen aa=max(acei, arb)

	*count the pillars
	gen aaa=max(acei, arb, arni)
	gen npillars = aaa+betablockers+mra+sglt2i 
	tab npillars
	
	*two pillars
	gen two_pillars=0
	replace two_pillars=1 if npillars==2
	
	*three pillars
	gen three_pillars=0
	replace three_pillars=1 if npillars==3
	
	*four pillars 
	gen four_pillars=0
	replace four_pillars=1 if npillars==4
	
	
	*Hospitalisations
	*All cause
		*all_hosps_date
			*n_admitted_hosp
			*n_admitted_hosp_1yr
			*n_admitted_hosp_2yr
			*n_emerg_hosp
			*n_emerg_hosp1yr
			*n_emerg_hosp2yr
	*Heart failure - includes emergency and admissions
		* outhf_hosp
		*n_outhf_emerg
		*n_outhf_emerg1yr
		*n_outhf_emerg2yr
		
		*n_outhf_secondary
		*n_outhf_secondary1yr
		*n_outhf_secondary2yr
	*CVD hospitalisations
		* all_cvd_hosps_date
		*n_cvd_admissions
		*n_cvd_admissions1yr
		*n_cvd_admissions2yr

*Mortality outcomes 
	*allcause_mortality_date 
	* cvd_mortality_date 
	* hf_mortality_date 

*Other outcomes	
	*HYPERKALAEMIA AND HYPONATRAEMIA
		*hyperkalaemia_date -  
		*hyponatraemia_date -  
	*DKA - exclude primary care outcomes duie to repeated/prevalent coding
		*dka_hosp_date 

	*AKI - only measured in secondary care
		*aki_date  

	*FALLS AND FRACTURES
		*fractures in secondary care, and falls in primary care ()excluding those with a recent history of falls in primary care?? - person who has had a fall more likely to have another fall - so excluding history of falls might introduce bias?  Therefore main outcome will be secondary care fractures - sens analysis including falls in primary care)
		*falls_primary_care_date 
		*falls_emerg_date 
		*fracture_icd_10_date
		gen fractures_date=min(falls_emerg_date, fracture_icd_10_date)
		gen fractures=0
		replace fractures=1 if fractures_date!=.

		
*Define end date - end of study (currently set to 1st June 2024), end of registration, death, 
display d(01june2024)
local end_date=23528

	rename date_deregistered_date deregistered_date
	gen enddate=min(allcause_mortality_date, deregistered_date, `end_date')
	format enddate %td

*Define end dates for outcome variables
	foreach out in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
				cvd_mortality hf_mortality hyperkalaemia ///
				hyponatraemia dka_hosp aki fractures{

	*replace outcome as missing if it occurs after the enddate
	replace `out'_date=. if `out'_date>enddate
	replace `out'=0 if `out'_date>enddate

	*generate a variable to show the end date including the outcome 
	gen `out'_enddate = min(`out'_date, enddate)
	replace `out'_enddate= `out'_enddate + 1
	format `out'_enddate %td
	}
	
*Define end dates when looking at outcomes in the first and second years after index date
	gen end1yr=index_date+365.25
	gen end2yr=index_date+365.25+365.25
	gen enddate1yr=min(enddate, end1yr)
	gen enddate2yr=min(enddate, end2yr)

*/

*keep HFrEF patients identified in primary care AND unknown patients identified in primary care but with two pillars
	keep if hfref==1 | (first_hf_primary!=. & two_pillars==1)
	count
save "$outdir/prevalent_cohort_hf_`year'.dta", replace 

*keep HFrEF patients
	keep if hfref==1
	count 

save "$outdir/prevalent_cohort_hfref_`year'.dta", replace 

}