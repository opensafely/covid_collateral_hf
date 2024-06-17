********************************************************************************
*
*	Do-file:		204_cr_prevalent_cohort_table.do
*
*	Programmed by:	Emily Herrett (based on John & Alex)
*
*	Data used:		
*
*	Data created:   "$tabfigdir/"
*
*	Other output:	Table summary
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			
********************************************************************************
do "`c(pwd)'/analysis/global.do"
capture log close
log using "$logdir/204_cr_prevalent_cohort_table.log", replace

label define new 0 "0" 1 "1" 2 "2+"

	local years "  "2023" "
	foreach year in `years' {
*"2018" "2019" "2020" "2021" "2022"
local heartfailtype " "hfref" "hf" "
foreach hftype in `heartfailtype' {

	use "$outdir/prevalent_cohort_`hftype'_`year'.dta", clear
	*use "$outdir/prevalent_cohort_hfref_2023.dta", clear
		stset enddate, id(patient_id) failure(allcause_mortality1yr) enter(master_index_date)origin(master_index_date) scale(365.25)
		label variable _t "Mean follow-up, years (SD)"

		preserve		
		gen total=1

		*recode outcomes to 0, 1, 2+
		foreach var of varlist ///
		n_outhf_emerg1yr n_outhf_secondary1yr n_emerg_hosp1yr n_admitted_hosp1yr ///
		n_cvd_admissions1yr n_dka_hosps1yr {
			replace `var'=2 if `var'>2 & `var'!=.
			label values `var' new
			}
		*how to do redaction and rounding here?
		* Create baseline table
		table1_mc, vars(total bin\ _t contn \ agegroup cate \ male cate \ ethnicity cate \ region_9 cate \ ///
		imd cate \ duration_hf_yrs cate \ ///
		previous_diabetes bin \ ckd cate \ cld bin \  ///
		af bin \ hypertension bin \ copd bin \  ///
		arb_contraindications bin \ acei_contraindications bin \ bb_contraindications bin \ ///
		mra_contraindications bin \ ///
		betablockers bin \ aa bin \ arni bin \ mra bin \ sglt2i bin \ two_pillars bin \  ///
		three_pillars bin \ four_pillars bin \ ///
		allcause_mortality1yr bin \ cvd_mortality1yr bin \ hf_mortality1yr bin \ ///
		all_hosp_fup1yr bin \ outhf_hosp1yr bin \ all_cvd_fup1yr bin \ ///
		hyperkalaemia1yr bin \ hyponatraemia1yr bin \ dka_hosp1yr bin \ ///
		aki1yr bin \ fractures1yr bin \ ///
		n_emerg_hosp1yr cate \ n_admitted_hosp1yr cate \ ///
		n_outhf_emerg1yr cate \ n_outhf_secondary1yr cate \ ///
		n_cvd_admissions1yr cate \  n_dka_hosps1yr cate ) clear
		export delimited using "$tabfigdir/prevalent_table1_`hftype'_`year'", replace

		*redact non zero numbers <7 and round to nearest 5
		import delimited using "$tabfigdir/prevalent_table1_`hftype'_`year'", clear
		drop v3 v4 v5
		drop in 1/3
		destring v6, gen(n) ignore(",") force
		replace n=. if n>0 & n<=7
		replace v7="." if n==.
		gen round_n=round(n,5) 
		drop v6
		export delimited using "$tabfigdir/prevalent_table1_`hftype'_`year'_redacted_rounded", replace

	restore
 
	}
}

* Close log file 
log close

		

 