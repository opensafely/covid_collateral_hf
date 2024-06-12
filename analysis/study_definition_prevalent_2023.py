# STUDY DEFINITION FOR BASELINE CHARACTERISTICS - PREVALENT HEART FAILURE POPULATION

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
common_variables = generate_common_variables(index_date_variable="index_date")

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
    
    # define the study index date - this is mid year for prevalent cohorts
    index_date="2023-05-01",    

    # INCLUDE: age 18+ on date of study, male or female, registered with TPP at index date, with 3 months complete registration, a valid address and postcode
    # EXCLUDE:missing age, missing sex, missing region, missing IMD, 

    population=patients.satisfying(
        # first argument is a string defining the population of interest using elementary logic syntax (= != < <= >= > AND OR NOT + - * /)
        """
        (age >= 18 AND age < 120) AND 
        is_registered_with_tpp AND 
        (NOT died) AND
        heart_failure_index = "1" AND
        (NOT hfpef) AND
        (sex = "M" OR sex = "F") AND 
        has_follow_up AND
        (region != "") AND
        (imd != "0")
        """,         
    ),

    # define the study variables

    # HEART FAILURE STUDY POPULATION 
        hf_primary_case=patients.with_these_clinical_events(
            codelist=hf_codes,    
            on_or_before="index_date - 1 day",
            returning="binary_flag",
            return_expectations={"incidence": 0.90, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 
   
        hf_secondary_case=patients.admitted_to_hospital(
            with_these_diagnoses=heart_failure_icd_codes,
            returning="binary_flag",
            on_or_before="index_date - 1 day",
            return_expectations={"incidence": 0.50, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 

        hf_emerg_case=patients.attended_emergency_care(
            on_or_before="index_date - 1 day",
            with_these_diagnoses=hf_emerg_codes,
            returning="binary_flag",
            return_expectations={
                "incidence": 0.4,
            }, 
        ),
 
        heart_failure_index=patients.satisfying(
            "hf_primary_case OR hf_secondary_case OR hf_emerg_case",
        ),

    # HEART FAILURE DATES 
        first_hf_primary=patients.with_these_clinical_events(
            codelist=hf_codes,    
            on_or_before="index_date - 1 day",
            returning="date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"incidence": 0.90, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 
   
        first_hf_secondary=patients.admitted_to_hospital(
            with_these_diagnoses=heart_failure_icd_codes,
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            on_or_before="index_date - 1 day",
            find_first_match_in_period=True,
            return_expectations={"incidence": 0.50, "date": {"earliest" : "2000-01-01", "latest": "today"}},
        ), 

        first_hf_emerg=patients.attended_emergency_care(
            on_or_before="index_date - 1 day",
            with_these_diagnoses=hf_emerg_codes,
            returning="date_arrived",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.4,
            }, 
            ),
        
        patient_index_date=patients.minimum_of(
            "first_hf_primary", "first_hf_secondary", "first_hf_emerg"
        ),

   

**common_variables
)