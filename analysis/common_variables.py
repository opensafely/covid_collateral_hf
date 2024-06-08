from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def generate_common_variables(index_date_variable):
    common_variables = dict(

    # DEMOGRAPHICS - sex, age, ethnicity
        ## sex 
        sex=patients.sex(
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {"M": 0.49, "F": 0.51}},
            } 
        ),

        ## age 
        age=patients.age_as_of(
            f"{index_date_variable}",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
    
        ## age groups 
        ageband_broad = patients.categorised_as(
            {   
                "0": "DEFAULT",
                "18-39": """ age >=  18 AND age < 40""",
                "40-59": """ age >=  40 AND age < 60""",
                "60-79": """ age >=  60 AND age < 80""",
                "80+": """ age >=  80 AND age < 120""",
            },
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {"18-39": 0.3, "40-59": 0.3, "60-79":0.2, "80+":0.2 }
                }
            },
        ),


        ## ethnicity in 6 categories
        ethnicity6=patients.with_these_clinical_events(
            ethnicity_codes,
            returning="category",
            find_last_match_in_period=True,
            return_expectations={
                "category": {"ratios": {"1": 0.8, "3": 0.1, "5": 0.1,}},
                "incidence": 0.75,
            },
        ),

    # HOUSEHOLD INFORMATION
        ## care home status - This creates a variable called care_home_type which contains a 2 letter string which represents a type of care home environment. 
        # If the address is not valid, it defaults to an empty string.  Shouldn't have any as am including only those with valid address.
        care_home_type=patients.care_home_status_as_of(
            f"{index_date_variable}",
            categorised_as={
                "PC": """
                IsPotentialCareHome
                AND LocationDoesNotRequireNursing='Y'
                AND LocationRequiresNursing='N'
                """,
                "PN": """
                IsPotentialCareHome
                AND LocationDoesNotRequireNursing='N'
                AND LocationRequiresNursing='Y'
                """,
                "PS": "IsPotentialCareHome",
                "PR": "NOT IsPotentialCareHome",
                "": "DEFAULT",
            },
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "PC": 0.05, 
                        "PN": 0.05, 
                        "PS": 0.05, 
                        "PR": 0.84, 
                        "": 0.01},
                },
            },
        ),
        
    # ADMINISTRATIVE INFORMATION

        ## index of multiple deprivation, estimate of SES based on patient post code 
            imd=patients.categorised_as(
                {
                    "0": "DEFAULT",
                    "1": """index_of_multiple_deprivation >=0 AND index_of_multiple_deprivation < 32800*1/5""",
                    "2": """index_of_multiple_deprivation >= 32800*1/5 AND index_of_multiple_deprivation < 32800*2/5""",
                    "3": """index_of_multiple_deprivation >= 32800*2/5 AND index_of_multiple_deprivation < 32800*3/5""",
                    "4": """index_of_multiple_deprivation >= 32800*3/5 AND index_of_multiple_deprivation < 32800*4/5""",
                    "5": """index_of_multiple_deprivation >= 32800*4/5 AND index_of_multiple_deprivation <= 32800""",
                },
                index_of_multiple_deprivation=patients.address_as_of(
                    f"{index_date_variable}",
                    returning="index_of_multiple_deprivation",
                    round_to_nearest=100,
                ),
                return_expectations={
                    "rate": "universal",
                    "category": {
                        "ratios": {
                            "0": 0.05,
                            "1": 0.19,
                            "2": 0.19,
                            "3": 0.19,
                            "4": 0.19,
                            "5": 0.19,
                        },
                    },
                },
            ),

        ## REGION     
        region=patients.registered_practice_as_of(
            f"{index_date_variable}",
            returning="nuts1_region_name",
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "North East": 0.1,
                        "North West": 0.1,
                        "Yorkshire and the Humber": 0.1,
                        "East Midlands": 0.1,
                        "West Midlands": 0.1,
                        "East of England": 0.1,
                        "London": 0.1,
                        "South West": 0.1,
                        "South East": 0.2,
                        },
                    },
                },
        ),
   
        ## URBAN/RURAL LOCATION
        urban=patients.address_as_of(
            f"{index_date_variable}",
            returning="rural_urban_classification",
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {
                    1: 0.10, 
                    2: 0.10, 
                    3: 0.10, 
                    4: 0.10, 
                    5: 0.10, 
                    6: 0.10, 
                    7: 0.10, 
                    8: 0.10, 
                    9: 0.20 
                    }
                },
            }
        ),

    # REGISTRATION DETAILS
        # died
        died=patients.died_from_any_cause(
            on_or_before=f"{index_date_variable}",
        ),

        ## registered with TPP on index date
        is_registered_with_tpp=patients.registered_as_of(
            f"{index_date_variable}",
        ),

 
       ## registered with one practice for 90 days prior to index date        
        has_follow_up=patients.registered_with_one_practice_between(
           f"{index_date_variable} - 90 days", f"{index_date_variable}",
        ),  
    
        ## date of de-registration
        date_deregistered=patients.date_deregistered_from_all_supported_practices(
            between=["2018-07-01", "2024-04-30"],
            date_format="YYYY-MM-DD",
        ),


    # HFREF AND HFPEF - EXCLUDE PATIENTS WITH HFPEF
        hfref=patients.with_these_clinical_events(
            codelist=hfref_codes,    
            on_or_before=f"{index_date_variable} - 1 day",
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
                }, 
        ), 

        hfpef=patients.with_these_clinical_events(
            codelist=hfpef_codes,    
            on_or_before=f"{index_date_variable}  - 1 day",
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
                }, 
        ), 

        # HEART FAILURE OUTCOMES
        # HF HOSPITALISATION - EMERGENCY AND NON EMERGENCY
        outhf_emerg=patients.attended_emergency_care(
            on_or_after=f"{index_date_variable}",
            with_these_diagnoses=hf_emerg_codes,
            returning="date_arrived",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.1,
                }, 
        ), 
        outhf_secondary=patients.admitted_to_hospital(
            with_these_primary_diagnoses=heart_failure_icd_codes,
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.1,
                }, 
        ), 
        outhf_hosp=patients.minimum_of(
            "outhf_emerg", "outhf_secondary"
        ),

        # N HF HOSPITALISATIONS - EMERGENCY AND NON EMERGENCY
        n_outhf_emerg=patients.attended_emergency_care(
            between=[f"{index_date_variable}", "2024-05-01"],
            with_these_diagnoses=hf_emerg_codes,
            returning="number_of_matches_in_period",
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ), 

        n_outhf_secondary=patients.admitted_to_hospital(
            with_these_primary_diagnoses=heart_failure_icd_codes,
            between=[f"{index_date_variable}", "2024-05-01"],
            returning="number_of_matches_in_period",
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),

        # N HF HOSPITALISATIONS ONE YEAR - EMERGENCY AND NON EMERGENCY
        n_outhf_emerg1yr=patients.attended_emergency_care(
            between=[f"{index_date_variable}", f"{index_date_variable} + 1 year"],
            with_these_diagnoses=hf_emerg_codes,
            returning="number_of_matches_in_period",
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ), 

        n_outhf_secondary1yr=patients.admitted_to_hospital(
            with_these_primary_diagnoses=heart_failure_icd_codes,
            between=[f"{index_date_variable}", f"{index_date_variable} + 1 year"],
            returning="number_of_matches_in_period",
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),

    # OUTCOMES - MEDICATION USE

        ## BETA BLOCKERS
        betablockers=patients.with_these_medications(
            codelist=betablocker_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
           returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ),

        ## SGLT2i
        sglt2i=patients.with_these_medications(
            codelist=sglt2i_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ), 

        ## ACEI
        acei=patients.with_these_medications(
            codelist=acei_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ), 

        ## ARB
        arb=patients.with_these_medications(
            codelist=arb_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ), 

        ## ARNi
        arni=patients.with_these_medications(
            codelist=arni_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ), 

        ## MRAs
        mra=patients.with_these_medications(
            codelist=mra_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ), 

        ## DIURETICS
        diuretics=patients.with_these_medications(
            codelist=diuretic_codes,    
            between=[f"{index_date_variable} - 90 days", f"{index_date_variable} + 90 days"],
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
        ), 





    ## OTHER OUTCOMES

    ## MORTALITY OUTCOMES
    allcause_mortality=patients.died_from_any_cause(
        on_or_after=f"{index_date_variable}",
        returning="date_of_death",
        date_format="YYYY-MM-DD",
            return_expectations={
                "incidence": 0.1,}, 
        ),

    cvd_mortality=patients.with_these_codes_on_death_certificate(
        cvd_icd_codes,
        on_or_after=f"{index_date_variable}",
        match_only_underlying_cause=True,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
            return_expectations={
                "incidence": 0.1,}, 
        ),

    hf_mortality=patients.with_these_codes_on_death_certificate(
        heart_failure_icd_codes,
        on_or_after=f"{index_date_variable}",
        match_only_underlying_cause=True,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
            return_expectations={
                "incidence": 0.1,}, 
        ),

    # FALLS AND FRACTURES - PRIMARY CARE, EMERGENCY CARE, HOSPITAL ADMISSION
        falls_primary_care=patients.with_these_clinical_events(
            codelist=falls_codes,    
        	on_or_after=f"{index_date_variable}",
            returning="date",
            date_format="YYYY-MM-DD",
            return_expectations={
                "incidence": 0.1,}, 
            ), 

        falls_emerg=patients.attended_emergency_care(
     		on_or_after=f"{index_date_variable}",
            with_these_diagnoses=falls_codes_snomed,
            returning="date_arrived",
            date_format="YYYY-MM-DD",
            return_expectations={
            "incidence": 0.1,}, 
            ),
 
        fracture_icd_10=patients.admitted_to_hospital(
            with_these_diagnoses=fracture_icd_codes,
            returning="date_admitted",
            date_format="YYYY-MM-DD",
     		on_or_after=f"{index_date_variable}",
            find_first_match_in_period=True,
            return_expectations={
            "incidence": 0.1,}, 
            ),

        falls_or_fractures=patients.minimum_of(
            "falls_primary_care", "falls_emerg", "fracture_icd_10"
        ),
        n_fracture_icd_10=patients.admitted_to_hospital(
            with_these_diagnoses=fracture_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", "2024-05-01"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ), 
        # AMPUTATION - PRIMARY CARE AND OPCS CODES
        amputation_primary_care=patients.with_these_clinical_events(
            codelist=amputation_codes,    
            on_or_after=f"{index_date_variable}",
            returning="date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"incidence": 0.1,}, 
            ), 
 
        amputation_opcs4=patients.admitted_to_hospital(
            with_these_procedures=amputation_opcs_4_codes,
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            on_or_after=f"{index_date_variable}",
            find_first_match_in_period=True,
            return_expectations={
            "incidence": 0.1,}, 
            ),

        amputation=patients.minimum_of(
            "amputation_primary_care", "amputation_opcs4"
            ),

    # ALL HOSPITALISATION - EMERGENCY AND NON EMERGENCY
        emerg_hosp=patients.attended_emergency_care(
            on_or_after=f"{index_date_variable}",
            returning="date_arrived",
             date_format="YYYY-MM-DD",
           find_first_match_in_period=True,
            return_expectations={
            "incidence": 0.1,}, 
            ),
        n_emerg_hosp=patients.attended_emergency_care(
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", "2024-05-01"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),
        n_emerg_hosp1yr=patients.attended_emergency_care(
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 1 year"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),
        n_emerg_hosp2yr=patients.attended_emergency_care(
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 2 years"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),
        admitted_hosp=patients.admitted_to_hospital(
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            find_first_match_in_period=True,
            date_format="YYYY-MM-DD",
            return_expectations={
            "incidence": 0.1,}, 
            ),
        n_admitted_hosp=patients.admitted_to_hospital(
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", "2024-05-01"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),
        n_admitted_hosp1yr=patients.admitted_to_hospital(
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 1 year"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),
        n_admitted_hosp2yr=patients.admitted_to_hospital(
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 2 years"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
        ),

        all_hosp_fup=patients.minimum_of(
            "emerg_hosp", "admitted_hosp"),



# CVD HOSPITALISATION - EMERGENCY AND NON EMERGENCY
        mace_emerg=patients.attended_emergency_care(
            on_or_after=f"{index_date_variable}",
            with_these_diagnoses=mace_emerg_codes,
            returning="date_arrived",
             date_format="YYYY-MM-DD",
           find_first_match_in_period=True,
            return_expectations={
            "incidence": 0.1,}, 
            ),

        cvd_primary_admission=patients.admitted_to_hospital(
            with_these_primary_diagnoses=cvd_icd_codes,
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            find_first_match_in_period=True,
            date_format="YYYY-MM-DD",
            return_expectations={
            "incidence": 0.1,}, 
            ),

        all_cvd_fup=patients.minimum_of(
            "mace_emerg", "cvd_primary_admission"
        ),
        n_cvd_admissions=patients.admitted_to_hospital(
            with_these_primary_diagnoses=cvd_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", "2024-05-01"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
            ),
        n_cvd_admissions1yr=patients.admitted_to_hospital(
            with_these_primary_diagnoses=cvd_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 1 year"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
            ),
        n_cvd_admissions2yr=patients.admitted_to_hospital(
            with_these_primary_diagnoses=cvd_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 2 years"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
            ),

    # HYPERKALAEMIA AND HYPONATRAEMIA
        hyperkalaemia=patients.admitted_to_hospital(
            with_these_diagnoses=hyperkal_codes,    
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"incidence": 0.1,}, 
        ), 

        hyponatraemia=patients.admitted_to_hospital(
            with_these_diagnoses=hyponat_codes,    
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"incidence": 0.1,}, 
        ), 

        # DIABETES
        previous_diabetes=patients.with_these_clinical_events(
            combine_codelists(
                diabetes_t1_codes, diabetes_t2_codes, diabetes_unknown_codes
            ),
            on_or_before= f"{index_date_variable}",
            return_expectations={"incidence": 0.05},
        ),

    # DIABETIC KETOACIDOSIS
        dka_hosp=patients.admitted_to_hospital(
            with_these_primary_diagnoses=dm_keto_icd_codes,
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            find_first_match_in_period=True,
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.1,},
        ),
        n_dka_hosps=patients.admitted_to_hospital(
            with_these_primary_diagnoses=dm_keto_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", "2024-05-01"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
            ),
        n_dka_hosps1yr=patients.admitted_to_hospital(
            with_these_primary_diagnoses=dm_keto_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable} + 1 year"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
            ),
        n_dka_hosps2yr=patients.admitted_to_hospital(
            with_these_primary_diagnoses=dm_keto_icd_codes,
            returning="number_of_matches_in_period",
            between=[f"{index_date_variable}", f"{index_date_variable}+ 2 years"],
            return_expectations={"int": {"distribution": "normal", "mean": 2, "stddev": 1}},
            ),

    # ACUTE KIDNEY INJURY
        aki=patients.admitted_to_hospital(
            with_these_primary_diagnoses=aki_icd_codes,
            on_or_after=f"{index_date_variable}",
            returning="date_admitted",
            find_first_match_in_period=True,
            date_format="YYYY-MM-DD",
            return_expectations={
            "incidence": 0.1,}, 
            ),

    # CONTRINDICATIONS TO MEDICATIONS
        arb_contraindications=patients.with_these_clinical_events(
            combine_codelists(
                arb_contra2_codes, 
                arb_contra_codes,
                arb_declined_codes 
                ),    
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 
        
        acei_contraindications=patients.with_these_clinical_events(
            combine_codelists(
                ace_declined_codes, 
                ace_contra2_codes, 
                ace_contra_codes 
                ),    
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 

        bb_contraindications=patients.with_these_clinical_events(
            codelist=bb_contra_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 

        mra_contraindications=patients.with_these_clinical_events(
            codelist=mra_contra_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 
 
    # COVARIATES
        cld=patients.with_these_clinical_events(
            codelist=cld_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 

        af=patients.with_these_clinical_events(
            codelist=af_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 
 
        efi = patients.with_these_decision_support_values(
            algorithm = "electronic_frailty_index",
            on_or_before = "2020-12-08", # hard-coded because there are no other dates available for efi
            find_last_match_in_period = True,
            returning="numeric_value",
            return_expectations={
                #"category": {"ratios": {0.1: 0.25, 0.15: 0.25, 0.30: 0.25, 0.5: 0.25}},
                "float": {"distribution": "normal", "mean": 0.15, "stddev": 0.05},
                "incidence": 0.99
            },
        ),

        hypertension=patients.with_these_clinical_events(
            codelist=hypertension_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
            ), 

        language=patients.with_these_clinical_events(
            codelist=language_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 

        sleep_ap=patients.with_these_clinical_events(
            codelist=sleep_apnoea_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 
 
        ckd_stage12=patients.with_these_clinical_events(
            codelist=ckd_12_codes, 
            on_or_before= f"{index_date_variable}",
            find_last_match_in_period=True,
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
            ), 
 
        ckd_stage35=patients.with_these_clinical_events(
            codelist=ckd_35_codes, 
            on_or_before= f"{index_date_variable}",
            find_last_match_in_period=True,
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 

        ckd_stage45=patients.with_these_clinical_events(
            codelist=ckd_45_codes, 
            on_or_before= f"{index_date_variable}",
            find_last_match_in_period=True,
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 

        copd=patients.with_these_clinical_events(
            codelist=copd_codes, 
            on_or_before= f"{index_date_variable}",
            returning="binary_flag",
            return_expectations={"incidence": 0.1,}, 
        ), 
 
        creatinine=patients.with_these_clinical_events(
            creatinine_codes,
            find_last_match_in_period=True,
            on_or_before= f"{index_date_variable}",
            returning="numeric_value",
            return_expectations={
                "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
                "date": {"earliest": "2014-01-01", "latest": "2024-05-31"},
                "incidence": 0.95,
            },
        ), 

        smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                     most_recent_smoking_code = 'E' OR (    
                       most_recent_smoking_code = 'N' AND ever_smoked   
                     )  
                """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.4, "E": 0.3, "N": 0.2, "M": 0.1}}
            },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before= f"{index_date_variable}",
            returning="category",
            ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before= f"{index_date_variable}",
            ),
        ),


)
    return common_variables        