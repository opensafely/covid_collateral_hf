# STUDY DEFINITION FOR BASELINE CHARACTERISTICS - INCIDENT HEART FAILURE POPULATION

# Import necessary functions
from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
    Measure,
)     

# Import all codelists
from codelists import *
from common_variables import generate_common_variables
dummy_data_date= "2020-02-01"
common_variables = generate_common_variables(index_date_variable="patient_index_date", admission_variable="hf_icd_10")


# Specify study definition
study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "2024-04-30"},
        "rate": "uniform",
        "incidence": 0.5,
    },

    # define the study population 
    # all the study definitions have to have a study population definition - this selects all the patients for whom you want information
    # use the "patients.satisfying()" function to combine information from multiple different variables
    
    # define the study index date - this is earliest heart failure date
    # index_date="earliest_hf",    
    # index_date="2018-07-01",    

    # INCLUDE: age 18+ on date of study, male or female, registered with TPP at index date, with 3 months complete registration, a valid address and postcode
    # EXCLUDE:missing age, missing sex, missing region, missing IMD, 

    population=patients.satisfying(
        # first argument is a string defining the population of interest using elementary logic syntax (= != < <= >= > AND OR NOT + - * /)
        """
        (hf_primary_care OR
        hf_icd_10 OR
        ever_hf_emerg) AND
        (age >= 18 AND age < 120) AND 
        is_registered_with_tpp AND 
        (NOT hfpef) AND
        (NOT died) AND
        (sex = "M" OR sex = "F") AND 
        has_follow_up AND
        (region != "") AND
        (imd != "0")
        """,         
    ),

    index_date="2000-01-01",
    # define the study variables

    # HEART FAILURE STUDY POPULATION 
        hf_primary_care=patients.with_these_clinical_events(
            codelist=hf_codes,    
            on_or_after="2000-01-01",
            returning="binary_flag",
            return_expectations={"incidence": 0.10, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 
   
        hf_icd_10=patients.admitted_to_hospital(
            with_these_diagnoses=heart_failure_icd_codes,
            returning="binary_flag",
            on_or_after="2000-01-01",
            return_expectations={"incidence": 0.10, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 

        ever_hf_emerg=patients.attended_emergency_care(
            on_or_after="2000-01-01",
            with_these_diagnoses=hf_emerg_codes,
            returning="binary_flag",
            return_expectations={
                "incidence": 0.1,
            }, 
            ),
 
        heart_failure=patients.satisfying(
            "hf_primary_care OR hf_icd_10 OR ever_hf_emerg",
        ),

        # HEART FAILURE DATES 
        hf_primary_date=patients.with_these_clinical_events(
                    codelist=hf_codes,    
                    on_or_after="2000-01-01",
                    returning="date",
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={"incidence": 0.10, "date": {"earliest" : "2000-01-01", "latest": "today"}}, 
        ), 
        
        hf_icd_date=patients.admitted_to_hospital(
                    with_these_diagnoses=heart_failure_icd_codes,
                    returning="date_admitted",
                    date_format="YYYY-MM-DD",
                    on_or_after="2000-01-01",
                    find_first_match_in_period=True,
                    return_expectations={"incidence": 0.10, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 

        hf_emerg_date=patients.attended_emergency_care(
                    on_or_after="2000-01-01",
                    with_these_diagnoses=hf_emerg_codes,
                    returning="date_arrived",
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "incidence": 0.1,
                    }, 
        ),

        patient_index_date=patients.minimum_of(
            "hf_primary_date", "hf_icd_date", "hf_emerg_date"
            ),
        

    **common_variables
)