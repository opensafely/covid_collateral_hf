********************************************************************************
*
*	Do-file:		002_cr_covariates.do
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
*	Purpose:	defines common covariates for incident and prevalent cohorts
*
*	Note:			
********************************************************************************
	*Rename variables that are too long	
	rename patient_index_date patient_index 

******************************
*  Convert strings to dates  *
******************************
* To be added: dates related to outcomes
foreach var of varlist 	  master_index ///
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
						  fracture_icd10 ///
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
* Sex
	assert inlist(sex, "M", "F")
	gen male = (sex=="M")
	drop sex
	label define sexLab 1 "male" 0 "female"
	label values male sexLab
	label var male "sex = 0 F, 1 M"

*IMD
	* Group into 5 groups
	tab imd, m 
	drop if imd==.
	drop if imd==0
	/*
	rename imd imd_o
	egen imd = cut(imd_o), group(5) icodes
	tab imd
	replace imd = imd + 1
	tab imd
	replace imd = . if imd_o==-1
	tab imd
	drop imd_o
	tab imd
	*/
	* Reverse the order (so high is more deprived)
	recode imd 5=1 4=2 3=3 2=4 1=5 .=.

	label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" 
	label values imd imd 

	noi di "DROPPING IF NO IMD" 
	drop if imd>=.
	tab imd

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
	tab ethnicity

* Region
	tab region
	rename region region_string
	gen     region_9 = 1 if region_string=="East Midlands"
	replace region_9 = 2 if region_string=="East"
	replace region_9 = 3 if region_string=="London"
	replace region_9 = 4 if region_string=="North East"
	replace region_9 = 5 if region_string=="North West"
	replace region_9 = 6 if region_string=="South East"
	replace region_9 = 7 if region_string=="South West"
	replace region_9 = 8 if region_string=="West Midlands"
	replace region_9 = 9 if region_string=="Yorkshire and The Humber"

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
	tab region_9
	
*Age
	* Check there are no missing ages
	assert age<.
	assert ageband_broad!=""
	gen agegroup=.
	replace agegroup=0 if ageband_broad=="0"
	replace agegroup=1 if ageband_broad=="18-29"
	replace agegroup=2 if ageband_broad=="30-39"
	replace agegroup=3 if ageband_broad=="40-49"
	replace agegroup=4 if ageband_broad=="50-59"
	replace agegroup=5 if ageband_broad=="60-69"
	replace agegroup=6 if ageband_broad=="70-79"
	replace agegroup=7 if ageband_broad=="80+"
	
	label define agegrp 1 "18-29" 2 "30-39" 3 "40-49" 4 "50-59" 5 "60-69" 6 "70-79" 7 "80+"
	label values agegroup agegrp
	tab agegroup
	bysort agegroup: summ age 
	count
	drop if age<18
	count

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
		1 "None" 2 "Stage 3a/3b egfr 30-60" 3 "Stage 4/5 egfr<30"
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
	label variable ckd ""
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
	tab arni, m 
	tab mra, m
	tab sglt2i, m 
	
	
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
	
	*populations for drug prevalence calculations
	tab bb_contraindications
	gen population_betablockers=1
	replace population_betablockers=0 if bb_contraindications==1
	
	tab mra_contraindications
	gen population_mra=1
	replace population_mra=0 if mra_contraindications==1
	
	tab acei_contraindications
	tab arb_contraindications
	gen population_aa=1
	replace population_aa=0 if acei_contraindications==1 & arb_contraindications==1
	
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
		*fractures in secondary care, falls in emergency care, and falls in primary care ()excluding those with a recent history of falls in primary care?? - person who has had a fall more likely to have another fall - so excluding history of falls might introduce bias?  Therefore main outcome will be secondary care fractures and emergency care falls - sens analysis including falls in primary care??)
		*falls_primary_care_date 
		*falls_emerg_date 
		*fracture_icd10_date
		gen fractures_date=min(falls_emerg_date, fracture_icd10_date)
		gen fractures=0
		replace fractures=1 if fractures_date!=.

		
********************
*END DATES**
********************		
	*Define last collection date - based on TPP reports online for primary care, APC, Emergency care and ONS mortality
		display d(01may2024)
		local lcd=23497

	*generate end date overall - minimum of all cause death, deregistration, and 1st May 2024
		rename date_deregistered_date deregistered_date
		gen enddate=min(allcause_mortality_date, deregistered_date, `lcd')
		format enddate %td

	*Define end dates for outcome variables where follow-up ends at failure
			foreach out in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
						cvd_mortality hf_mortality hyperkalaemia ///
						hyponatraemia dka_hosp aki fractures{

			*replace outcome and outcome date as missing if it occurs after the enddate
			replace `out'_date=. if `out'_date>enddate
			replace `out'=0 if `out'_date>enddate

			*generate a variable to show the end date including the date of the outcome 
			gen `out'_enddate = min(`out'_date, enddate)
			format `out'_enddate %td
			}
			
	*Define end dates when looking at outcomes in the first and second years after index date
		gen end1yr=master_index_date+365.25
		gen end2yr=master_index_date+365.25+365.25
		gen end5yr=master_index_date+(365.25*5)
		
		gen enddate1yr=min(enddate, end1yr)
		gen enddate2yr=min(enddate, end2yr)
		gen enddate5yr=min(enddate, end5yr)
		format enddate5yr enddate1yr enddate2yr %td

	*Define outcomes and end dates for rates at 0-1 years, 1-2 years, and 0-5 years - have not done 1-2 yet
	local d " "1yr"  "5yr" "
	*"2yr"
	foreach x in `d' {
	*Define end dates for outcome variables
	foreach out in all_hosp_fup outhf_hosp all_cvd_fup allcause_mortality ///
				cvd_mortality hf_mortality hyperkalaemia ///
				hyponatraemia dka_hosp aki fractures{

	*replace outcome and outcome date as missing if it occurs after the enddate
	*use these variables in the stset command.
	replace `out'_date=. if `out'_date>enddate`x'
	gen `out'`x'=`out'  // this is the failure variable
	replace `out'`x'=0 if `out'_date>enddate`x'

	*generate a variable to show the end date including the outcome for simple rates
	gen `out'_enddate`x' = min(`out'_date, enddate`x')
	replace `out'_enddate`x'= `out'_enddate`x' + 1
	format `out'_enddate`x' %td  // this is the end date for stset in simple rates calculation
	}
	}
						
				
*label variables 
	label variable agegroup "Age group"
	label variable male "Sex"
	label variable region_9 "Region"
	label variable imd "IMD quintile"
	label variable previous_diabetes "Diabetes"
	label variable ckd "CKD, coded and eGFR"
	label variable cld "Chronic liver disease"
	label variable af "Atrial fibrillation"
	label variable hypertension "Hypertension"
	label variable copd "COPD"
	label variable arb_contraindications "ARB contraindication"
	label variable acei_contraindications "ACEi contraindication"
	label variable bb_contraindications "Betablocker contraindication"
	label variable mra_contraindications "MRA contraindication"
	label variable aa "ACEi/ARB*"
	label variable arni "ARNi*"
	label variable mra "MRA*"
	label variable sglt2i "SGLT2 inhibitor*"
	label variable two_pillars "Two pillars of treatment*"
	label variable three_pillars "Three pillars of treatment*"
	label variable four_pillars "Four pillars of treatment*"
	label variable n_outhf_emerg1yr "N HF emergency attendances 1 year"
	label variable n_outhf_secondary1yr "N HF admissions 1 year"
	label variable n_emerg_hosp1yr "N emergency attendances 1 year"
	label variable n_admitted_hosp1yr "N hospital admissions 1 year"
	label variable n_cvd_admissions1yr "N CVD admissions 1 year"
	label variable n_dka_hosps1yr "N DKA admissions 1 year"
	label variable n_fracture_icd101yr "N falls 1 year"
	label variable n_falls_emerg1yr "N falls 1 year"
	label variable n_falls_emerg5yr "N falls 5 years"
	label variable n_dka_hosps1yr "N DKA admissions 1 year"
	label variable allcause_mortality1yr "One year all-cause mortality"
	label variable cvd_mortality1yr "One year CVD mortality"
	label variable hf_mortality1yr "One year heart failure mortality"
	label variable hyperkalaemia1yr "One year hyperkalaemia"
	label variable hyponatraemia1yr "One year hyponatraemia"
	label variable dka_hosp1yr "One year DKA"
	label variable aki1yr "One year acute kidney injury"
	label variable fractures1yr "One year fractures"
	label variable all_hosp_fup1yr "One year all cause hospitalisation"
	label variable outhf_hosp1yr  "One year heart failure hospitalisation"
	label variable all_cvd_fup1yr "One year CVD hospitalisation"




