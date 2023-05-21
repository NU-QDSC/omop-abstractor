/************************
*************************
*************************
*************************

Primary key constraints

*************************
*************************
*************************
************************/



/************************

Standardized vocabulary

************************/



ALTER TABLE concept DROP CONSTRAINT xpk_concept CASCADE;

ALTER TABLE vocabulary DROP CONSTRAINT xpk_vocabulary CASCADE;

ALTER TABLE domain DROP CONSTRAINT xpk_domain CASCADE;

ALTER TABLE concept_class DROP CONSTRAINT xpk_concept_class CASCADE;

ALTER TABLE concept_relationship DROP CONSTRAINT xpk_concept_relationship CASCADE;

ALTER TABLE relationship DROP CONSTRAINT xpk_relationship CASCADE;

ALTER TABLE concept_ancestor DROP CONSTRAINT xpk_concept_ancestor CASCADE;

ALTER TABLE source_to_concept_map DROP CONSTRAINT xpk_source_to_concept_map CASCADE;

ALTER TABLE drug_strength DROP CONSTRAINT xpk_drug_strength CASCADE;

ALTER TABLE cohort_definition DROP CONSTRAINT xpk_cohort_definition CASCADE;

ALTER TABLE attribute_definition DROP CONSTRAINT xpk_attribute_definition CASCADE;


/**************************

Standardized meta-data

***************************/



/************************

Standardized clinical data

************************/


/**PRIMARY KEY NONCLUSTERED constraints**/

ALTER TABLE person DROP CONSTRAINT xpk_person CASCADE;

ALTER TABLE observation_period DROP CONSTRAINT xpk_observation_period CASCADE;

ALTER TABLE specimen DROP CONSTRAINT xpk_specimen CASCADE;

ALTER TABLE death DROP CONSTRAINT xpk_death CASCADE;

ALTER TABLE visit_occurrence DROP CONSTRAINT xpk_visit_occurrence CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT xpk_visit_detail CASCADE;

ALTER TABLE procedure_occurrence DROP CONSTRAINT xpk_procedure_occurrence CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT xpk_drug_exposure CASCADE;

ALTER TABLE device_exposure DROP CONSTRAINT xpk_device_exposure CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT xpk_condition_occurrence CASCADE;

ALTER TABLE measurement DROP CONSTRAINT xpk_measurement CASCADE;

ALTER TABLE note DROP CONSTRAINT xpk_note CASCADE;

ALTER TABLE note_nlp DROP CONSTRAINT xpk_note_nlp CASCADE;

ALTER TABLE observation  DROP CONSTRAINT xpk_observation CASCADE;




/************************

Standardized health system data

************************/


ALTER TABLE location DROP CONSTRAINT xpk_location CASCADE;

ALTER TABLE care_site DROP CONSTRAINT xpk_care_site CASCADE;

ALTER TABLE provider DROP CONSTRAINT xpk_provider CASCADE;



/************************

Standardized health economics

************************/


ALTER TABLE payer_plan_period DROP CONSTRAINT xpk_payer_plan_period CASCADE;

ALTER TABLE cost DROP CONSTRAINT xpk_visit_cost CASCADE;


/************************

Standardized derived elements

************************/

ALTER TABLE cohort DROP CONSTRAINT xpk_cohort CASCADE;

ALTER TABLE cohort_attribute DROP CONSTRAINT xpk_cohort_attribute CASCADE;

ALTER TABLE drug_era DROP CONSTRAINT xpk_drug_era CASCADE;

ALTER TABLE dose_era  DROP CONSTRAINT xpk_dose_era CASCADE;

ALTER TABLE condition_era DROP CONSTRAINT xpk_condition_era CASCADE;




/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License") CASCADE;
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

/************************

 ####### #     # ####### ######      #####  ######  #     #           #######      #####      #####
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #           #     #    #     #  ####  #    #  ####  ##### #####    ##   # #    # #####  ####
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #                 #    #       #    # ##   # #        #   #    #  #  #  # ##   #   #   #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######       #####     #       #    # # #  #  ####    #   #    # #    # # # #  #   #    ####
 #     # #     # #     # #          #       #     # #     #    #    #       # ###       #    #       #    # #  # #      #   #   #####  ###### # #  # #   #        #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     # ### #     #    #     # #    # #   ## #    #   #   #   #  #    # # #   ##   #   #    #
 ####### #     # ####### #           #####  ######  #     #      ##    #####  ###  #####      #####   ####  #    #  ####    #   #    # #    # # #    #   #    ####


postgresql script to create foreign key constraints within OMOP common data model, version 5.3.0

last revised: 15-November-2017

author:  Patrick Ryan, Clair Blacketer


*************************/


/************************
*************************
*************************
*************************

Foreign key constraints

*************************
*************************
*************************
************************/


/************************

Standardized vocabulary

************************/


ALTER TABLE concept DROP CONSTRAINT fpk_concept_domain CASCADE;

ALTER TABLE concept DROP CONSTRAINT fpk_concept_class CASCADE;

ALTER TABLE concept DROP CONSTRAINT fpk_concept_vocabulary CASCADE;

ALTER TABLE vocabulary DROP CONSTRAINT fpk_vocabulary_concept CASCADE;

ALTER TABLE domain DROP CONSTRAINT fpk_domain_concept CASCADE;

ALTER TABLE concept_class DROP CONSTRAINT fpk_concept_class_concept CASCADE;

ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_c_1 CASCADE;

ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_c_2 CASCADE;

ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_id CASCADE;

ALTER TABLE relationship DROP CONSTRAINT fpk_relationship_concept CASCADE;

ALTER TABLE relationship DROP CONSTRAINT fpk_relationship_reverse CASCADE;

ALTER TABLE concept_synonym DROP CONSTRAINT fpk_concept_synonym_concept CASCADE;

ALTER TABLE concept_ancestor DROP CONSTRAINT fpk_concept_ancestor_concept_1 CASCADE;

ALTER TABLE concept_ancestor DROP CONSTRAINT fpk_concept_ancestor_concept_2 CASCADE;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_v_1 CASCADE;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_v_2 CASCADE;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_c_1 CASCADE;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_concept_1 CASCADE;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_concept_2 CASCADE;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_unit_1 CASCADE;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_unit_2 CASCADE;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_unit_3 CASCADE;

ALTER TABLE cohort_definition DROP CONSTRAINT fpk_cohort_definition_concept CASCADE;


/**************************

Standardized meta-data

***************************/





/************************

Standardized clinical data

************************/


---MGURLEY 4/28/2019  The EDW is not always able to populate the person_id field.
--ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_person FOREIGN KEY (person_id)  REFERENCES person (person_id) CASCADE;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_type_concept CASCADE;

---MGURLEY 4/28/2019  The EDW is not always able to populate the provider_id field.
--ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_provider FOREIGN KEY (provider_id)  REFERENCES provider (provider_id) CASCADE;

---MGURLEY 4/28/2019  The EDW is not always able to populate the care_site_id field.
--ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_care_site FOREIGN KEY (care_site_id)  REFERENCES care_site (care_site_id) CASCADE;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_concept_s CASCADE;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_admitting_s CASCADE;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_discharge CASCADE;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_preceding CASCADE;


ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_person CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_type_concept CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_provider CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_care_site CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_concept_s CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_admitting_s CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_discharge CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_preceding CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_parent CASCADE;

ALTER TABLE visit_detail DROP CONSTRAINT fpd_v_detail_visit CASCADE;

---MGURLEY 4/28/2019  The EDW is not always able to populate the person_id field.
--ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_person FOREIGN KEY (person_id)  REFERENCES person (person_id) CASCADE;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_concept CASCADE;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_type_concept CASCADE;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_modifier CASCADE;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_provider CASCADE;

---MGURLEY 4/28/2019  The EDW is not always able to populate the visit_occurrence_id field.
--ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_visit FOREIGN KEY (visit_occurrence_id)  REFERENCES visit_occurrence (visit_occurrence_id) CASCADE;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_concept_s CASCADE;


ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_person CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_concept CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_type_concept CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_route_concept CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_provider CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_visit CASCADE;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_concept_s CASCADE;


ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_person CASCADE;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_concept CASCADE;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_type_concept CASCADE;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_provider CASCADE;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_visit CASCADE;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_concept_s CASCADE;


ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_person CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_concept CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_type_concept CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_provider CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_visit CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_concept_s CASCADE;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_status_concept CASCADE;


ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_person CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_concept CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_type_concept CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_operator CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_value CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_unit CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_provider CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_visit CASCADE;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_concept_s CASCADE;


--5/2/2019 MGURLEY  Temporarily removing until we can get a provider_id from the EDW.
--ALTER TABLE note DROP CONSTRAINT fpk_note_person FOREIGN KEY (person_id)  REFERENCES person (person_id) CASCADE;

ALTER TABLE note DROP CONSTRAINT fpk_note_type_concept CASCADE;

ALTER TABLE note DROP CONSTRAINT fpk_note_class_concept CASCADE;

ALTER TABLE note DROP CONSTRAINT fpk_note_encoding_concept CASCADE;

ALTER TABLE note DROP CONSTRAINT fpk_language_concept CASCADE;

--2/2/2019 MGURLEY  Temporarily removing until we can get a provider_id from the EDW.
-- ALTER TABLE note DROP CONSTRAINT fpk_note_provider FOREIGN KEY (provider_id)  REFERENCES provider (provider_id) CASCADE;

---MGURLEY 4/28/2019  The EDW is not always able to populate the visit_occurrence_id field.
--ALTER TABLE note DROP CONSTRAINT fpk_note_visit FOREIGN KEY (visit_occurrence_id)  REFERENCES visit_occurrence (visit_occurrence_id) CASCADE;

ALTER TABLE note_nlp DROP CONSTRAINT fpk_note_nlp_note CASCADE;

ALTER TABLE note_nlp DROP CONSTRAINT fpk_note_nlp_section_concept CASCADE;

ALTER TABLE note_nlp DROP CONSTRAINT fpk_note_nlp_concept CASCADE;



ALTER TABLE observation DROP CONSTRAINT fpk_observation_person CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_concept CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_type_concept CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_value CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_qualifier CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_unit CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_provider CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_visit CASCADE;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_concept_s CASCADE;


ALTER TABLE fact_relationship DROP CONSTRAINT fpk_fact_domain_1 CASCADE;

ALTER TABLE fact_relationship DROP CONSTRAINT fpk_fact_domain_2 CASCADE;

ALTER TABLE fact_relationship DROP CONSTRAINT fpk_fact_relationship CASCADE;



/************************

Standardized health system data

************************/

ALTER TABLE care_site DROP CONSTRAINT fpk_care_site_location CASCADE;

ALTER TABLE care_site DROP CONSTRAINT fpk_care_site_place CASCADE;


---MGURLEY 4/28/2019  The EDW is not always able to populate the specialty_concept_id field.
--ALTER TABLE provider DROP CONSTRAINT fpk_provider_specialty FOREIGN KEY (specialty_concept_id)  REFERENCES concept (concept_id) CASCADE;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_care_site CASCADE;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_gender CASCADE;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_specialty_s CASCADE;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_gender_s CASCADE;




/************************

Standardized health economics

************************/

ALTER TABLE payer_plan_period DROP CONSTRAINT fpk_payer_plan_period CASCADE;

ALTER TABLE cost DROP CONSTRAINT fpk_visit_cost_currency CASCADE;

ALTER TABLE cost DROP CONSTRAINT fpk_visit_cost_period CASCADE;

ALTER TABLE cost DROP CONSTRAINT fpk_drg_concept CASCADE;

/************************

Standardized derived elements

************************/


ALTER TABLE cohort DROP CONSTRAINT fpk_cohort_definition CASCADE;


ALTER TABLE cohort_attribute DROP CONSTRAINT fpk_ca_cohort_definition CASCADE;

ALTER TABLE cohort_attribute DROP CONSTRAINT fpk_ca_attribute_definition CASCADE;

ALTER TABLE cohort_attribute DROP CONSTRAINT fpk_ca_value CASCADE;


ALTER TABLE drug_era DROP CONSTRAINT fpk_drug_era_person CASCADE;

ALTER TABLE drug_era DROP CONSTRAINT fpk_drug_era_concept CASCADE;


ALTER TABLE dose_era DROP CONSTRAINT fpk_dose_era_person CASCADE;

ALTER TABLE dose_era DROP CONSTRAINT fpk_dose_era_concept CASCADE;

ALTER TABLE dose_era DROP CONSTRAINT fpk_dose_era_unit_concept CASCADE;


ALTER TABLE condition_era DROP CONSTRAINT fpk_condition_era_person CASCADE;

ALTER TABLE condition_era DROP CONSTRAINT fpk_condition_era_concept CASCADE;


/************************
*************************
*************************
*************************

Unique constraints

*************************
*************************
*************************
************************/

ALTER TABLE concept_synonym DROP CONSTRAINT uq_concept_synonym CASCADE;
