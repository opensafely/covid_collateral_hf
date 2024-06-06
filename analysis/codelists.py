# Remember to update codelists.txt with new codelists prior to import
from cohortextractor import codelist_from_csv, codelist

# Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    system="snomed",
    column="snomedcode",
    category_column="Grouping_6",
)

# Primary care
# CTV3 LISTS
sleep_apnoea_codes = codelist_from_csv(
    "codelists/user-emilyherrett-sleep-apnoea.csv",
    system="ctv3",
    column="code",)

hf_codes = codelist_from_csv(
    "codelists/user-emilyherrett-heart-failure-ctv3.csv",
    system="ctv3",
    column="code",)

hfref_codes = codelist_from_csv(
    "codelists/user-emilyherrett-hfref.csv",
    system="ctv3",
    column="code",)

hfpef_codes = codelist_from_csv(
    "codelists/user-emilyherrett-hfpef.csv",
    system="ctv3",
    column="code",)


hypokal_codes = codelist_from_csv(
    "codelists/user-emilyherrett-hypokalaemia.csv",
    system="ctv3",
    column="code",)

hyponat_codes = codelist_from_csv(
    "codelists/user-emilyherrett-hyponatraemia.csv",
    system="ctv3",
    column="code",)

amputation_codes = codelist_from_csv(
    "codelists/opensafely-amputation-of-lower-limb.csv",
    system="ctv3",
    column="CTV3Code",)

carehome_codes = codelist_from_csv(
    "codelists/opensafely-nhs-england-care-homes-residential-status-ctv3.csv",
    system="ctv3",
    column="code",)

dka_codes = codelist_from_csv(
    "codelists/opensafely-diabetes-ketoacidosis-ctv3-dka-unspecific.csv",
    system="ctv3",
    column="ctv3_id",)

dialysis_codes = codelist_from_csv(
    "codelists/opensafely-dialysis.csv",
    system="ctv3",
    column="CTV3ID",)

kidney_transplant_codes = codelist_from_csv(
    "codelists/opensafely-kidney-transplant.csv",
    system="ctv3",
    column="CTV3ID",)

falls_codes = codelist_from_csv(
    "codelists/opensafely-falls.csv",
    system="ctv3",
    column="CTV3Code",)

cld_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv",
    system="ctv3",
    column="CTV3ID",)

af_codes = codelist_from_csv(
    "codelists/opensafely-atrial-fibrillation-clinical-finding.csv",
    system="ctv3",
    column="CTV3Code",)

clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",)

bb_contra_codes = codelist_from_csv(
    "codelists/user-emilyherrett-beta-blocker-contraind.csv",
    system="snomed",
    column="code", )

mra_contra_codes = codelist_from_csv(
    "codelists/user-emilyherrett-mra-contraind.csv",
    system="snomed",
    column="code", )

efi_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-efi_cod.csv",
    system="snomed",
    column="code", )

falls_codes_snomed = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-falls_cod.csv",
    system="snomed",
    column="code", )

arb_contra2_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-xaii_cod.csv",
    system="snomed",
    column="code", )

arb_contra_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-txaii_cod.csv",
    system="snomed",
    column="code", )

arb_declined_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-aiidec_cod.csv",
    system="snomed",
    column="code", )

ace_declined_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-acedec_cod.csv",
    system="snomed",
    column="code", )


ace_contra2_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-xace_cod.csv",
    system="snomed",
    column="code", )

ace_contra_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-txace_cod.csv",
    system="snomed",
    column="code", )

hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension-snomed.csv",
    system="snomed",
    column="id", )

language_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-preflang_cod.csv",
    system="snomed",
    column="code", )

ckd_12_codes=codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ckd1and2_cod.csv",
    system="snomed",
    column="code", )

ckd_35_codes=codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-ckd_cod.csv",
    system="snomed",
    column="code", )

creatinine_codes = codelist_from_csv(
    "codelists/user-bangzheng-creatinine-value.csv",
    system="snomed",
    column="code", )

copd_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-copd_cod.csv",
    system="snomed",
    column="code",)

diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", 
    system="ctv3", 
    column="CTV3ID", )

diabetes_t1_codes = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes.csv", 
    system="ctv3", 
    column="CTV3ID", )
diabetes_t2_codes = codelist_from_csv(
    "codelists/opensafely-type-2-diabetes.csv", 
    system="ctv3", 
    column="CTV3ID",)

diabetes_unknown_codes = codelist_from_csv(
    "codelists/opensafely-diabetes-unknown-type.csv", 
    system="ctv3", 
    column="CTV3ID", )

# ICD codes for hospitalisations and deaths
heart_failure_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-heart-failure.csv",
    system="icd10",
    column="code",)

dm_keto_icd_codes = codelist_from_csv(
    "codelists/opensafely-diabetic-ketoacidosis-secondary-care.csv",
    system="icd10",
    column="icd10_code",)

fracture_icd_codes = codelist_from_csv(
    "codelists/bristol-fractures.csv",
    system="icd10",
    column="code",)

aki_icd_codes = codelist_from_csv(
    "codelists/user-viyaasan-acute-kidney-injury.csv",
    system="icd10",
    column="code",)

dialysis_icd_codes = codelist_from_csv(
    "codelists/user-viyaasan-dialysis.csv",
    system="icd10",
    column="code",)

krt_icd_codes = codelist_from_csv(
    "codelists/user-viyaasan-kidney-replacement-therapy.csv",
    system="icd10",
    column="code",)

cvd_icd_codes = codelist_from_csv(
    "codelists/opensafely-cardiovascular-secondary-care.csv",
    system="icd10",
    column="icd",)

    # OPCS-4    
kidney_replacement_therapy_opcs_4_codes = codelist_from_csv(
    "codelists/user-viyaasan-kidney-replacement-therapy-opcs-4.csv",
    system="opcs4",
    column="code",)

haemofiltration_opcs_4_codes = codelist_from_csv(
    "codelists/user-viyaasan-haemofiltration.csv",
    system="opcs4",
    column="code",)

dialysis_opcs_4_codes = codelist_from_csv(
    "codelists/user-viyaasan-dialysis-opcs-4.csv",
    system="opcs4",
    column="code",)

kidney_transplant_opcs_4_codes = codelist_from_csv(
    "codelists/user-viyaasan-kidney-transplant-opcs-4.csv",
    system="opcs4",
    column="code",)

amputation_opcs_4_codes = codelist_from_csv(
    "codelists/opensafely-amputation-opcs-4-procedure-codes.csv",
    system="opcs4",
    column="Code",)

# Snomed codes for emergency care outcomes
# CVD
mace_emerg_codes = codelist_from_csv(
    "codelists/user-alwynkotze-mace-snomed.csv",
    system="snomed",
    column="code",)

hf_emerg_codes = codelist_from_csv(
    "codelists/pincer-hf.csv",
    system="snomed",
    column="code",)

# MEDICATION CODES
betablocker_codes = codelist_from_csv(
    "codelists/opensafely-beta-blocker-medications.csv",
    system="snomed",
    column="id",)

arni_codes = codelist_from_csv(
    "codelists/user-emilyherrett-arni.csv",
    system="snomed",
    column="code",)

mra_codes = codelist_from_csv(
    "codelists/user-emilyherrett-mras.csv",
    system="snomed",
    column="code",)

sglt2i_codes = codelist_from_csv(
    "codelists/user-john-tazare-sglt2-inhibitors-dmd.csv",
    system="snomed",
    column="code",)

acei_codes = codelist_from_csv(
    "codelists/opensafely-ace-inhibitor-medications.csv",
    system="snomed",
    column="id",)

arb_codes = codelist_from_csv(
    "codelists/opensafely-angiotensin-ii-receptor-blockers-arbs.csv",
    system="snomed",
    column="id",)

diuretic_codes = codelist_from_csv(
    "codelists/pincer-diur.csv",
    system="snomed",
    column="id",)

