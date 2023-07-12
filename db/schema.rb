# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_07_10_095607) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "abstractor_abstraction_group_members", force: :cascade do |t|
    t.integer "abstractor_abstraction_group_id"
    t.integer "abstractor_abstraction_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abstractor_abstraction_group_id"], name: "index_abstractor_abstraction_group_id"
    t.index ["abstractor_abstraction_id"], name: "index_abstractor_abstraction_id"
  end

  create_table "abstractor_abstraction_groups", force: :cascade do |t|
    t.integer "abstractor_subject_group_id"
    t.string "about_type"
    t.integer "about_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system_generated", default: false
    t.string "subtype"
    t.index ["about_id", "about_type", "deleted_at"], name: "index_about_id_about_type_deleted_at"
  end

  create_table "abstractor_abstraction_object_values", force: :cascade do |t|
    t.integer "abstractor_abstraction_id"
    t.integer "abstractor_object_value_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abstractor_abstraction_id"], name: "index_abstractor_abstraction_object_values_1"
    t.index ["abstractor_object_value_id"], name: "index_abstractor_abstraction_object_values_2"
  end

  create_table "abstractor_abstraction_schema_object_values", force: :cascade do |t|
    t.integer "abstractor_abstraction_schema_id"
    t.integer "abstractor_object_value_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "display_order"
  end

  create_table "abstractor_abstraction_schema_predicate_variants", force: :cascade do |t|
    t.integer "abstractor_abstraction_schema_id"
    t.string "value"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_abstraction_schema_relations", force: :cascade do |t|
    t.integer "subject_id"
    t.integer "object_id"
    t.integer "abstractor_relation_type_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_abstraction_schemas", force: :cascade do |t|
    t.string "predicate"
    t.string "display_name"
    t.integer "abstractor_object_type_id"
    t.string "preferred_name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_abstraction_source_sections", force: :cascade do |t|
    t.integer "abstractor_abstraction_source_id", null: false
    t.integer "abstractor_section_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_abstraction_source_types", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_abstraction_sources", force: :cascade do |t|
    t.integer "abstractor_subject_id"
    t.string "from_method"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "custom_method"
    t.integer "abstractor_abstraction_source_type_id"
    t.integer "abstractor_rule_type_id"
    t.string "section_name"
    t.string "custom_nlp_provider"
    t.boolean "section_required", default: false
  end

  create_table "abstractor_abstractions", force: :cascade do |t|
    t.integer "abstractor_subject_id"
    t.string "value"
    t.string "about_type"
    t.integer "about_id"
    t.boolean "unknown"
    t.boolean "not_applicable"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "workflow_status"
    t.string "workflow_status_whodunnit"
    t.index ["about_id", "about_type", "deleted_at"], name: "index_about_id_about_type_deleted_at_2"
    t.index ["abstractor_subject_id"], name: "index_abstractor_subject_id"
  end

  create_table "abstractor_indirect_sources", force: :cascade do |t|
    t.integer "abstractor_abstraction_id"
    t.integer "abstractor_abstraction_source_id"
    t.string "source_type"
    t.integer "source_id"
    t.string "source_method"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_namespace_events", force: :cascade do |t|
    t.integer "abstractor_namespace_id", null: false
    t.string "eventable_type", null: false
    t.integer "eventable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_namespace_sections", force: :cascade do |t|
    t.integer "abstractor_namespace_id", null: false
    t.integer "abstractor_section_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_namespaces", force: :cascade do |t|
    t.string "name", null: false
    t.string "subject_type", null: false
    t.text "joins_clause", null: false
    t.text "where_clause", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_object_types", force: :cascade do |t|
    t.string "value"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_object_value_variants", force: :cascade do |t|
    t.integer "abstractor_object_value_id"
    t.string "value"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "case_sensitive", default: false
  end

  create_table "abstractor_object_values", force: :cascade do |t|
    t.string "value"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "properties"
    t.string "vocabulary_code"
    t.string "vocabulary"
    t.string "vocabulary_version"
    t.text "comments"
    t.boolean "case_sensitive", default: false
    t.boolean "favor_more_specific"
  end

  create_table "abstractor_relation_types", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_rule_abstractor_subjects", force: :cascade do |t|
    t.integer "abstractor_rule_id", null: false
    t.integer "abstractor_subject_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_rule_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_rules", force: :cascade do |t|
    t.text "rule", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_section_mention_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_section_name_variants", force: :cascade do |t|
    t.integer "abstractor_section_id"
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_section_types", force: :cascade do |t|
    t.string "name"
    t.string "regular_expression"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_sections", force: :cascade do |t|
    t.integer "abstractor_section_type_id"
    t.string "source_type"
    t.string "source_method"
    t.string "name"
    t.string "description"
    t.string "delimiter"
    t.string "custom_regular_expression"
    t.boolean "return_note_on_empty_section"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "abstractor_section_mention_type_id"
  end

  create_table "abstractor_subject_group_members", force: :cascade do |t|
    t.integer "abstractor_subject_id"
    t.integer "abstractor_subject_group_id"
    t.integer "display_order"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abstractor_subject_id"], name: "index_abstractor_subject_id_2"
  end

  create_table "abstractor_subject_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cardinality"
    t.string "subtype"
    t.boolean "enable_workflow_status", default: false
    t.string "workflow_status_submit"
    t.string "workflow_status_pend"
  end

  create_table "abstractor_subject_relations", force: :cascade do |t|
    t.integer "subject_id"
    t.integer "object_id"
    t.integer "abstractor_relation_type_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_subjects", force: :cascade do |t|
    t.integer "abstractor_abstraction_schema_id"
    t.string "subject_type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dynamic_list_method"
    t.string "namespace_type"
    t.integer "namespace_id"
    t.boolean "anchor"
    t.integer "default_abstractor_object_value_id"
    t.index ["namespace_type", "namespace_id"], name: "index_namespace_type_namespace_id"
    t.index ["subject_type"], name: "index_subject_type"
  end

  create_table "abstractor_suggestion_object_value_variants", force: :cascade do |t|
    t.integer "abstractor_suggestion_id"
    t.integer "abstractor_object_value_variant_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_suggestion_object_values", force: :cascade do |t|
    t.integer "abstractor_suggestion_id"
    t.integer "abstractor_object_value_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abstractor_suggestion_sources", force: :cascade do |t|
    t.integer "abstractor_abstraction_source_id"
    t.integer "abstractor_suggestion_id"
    t.text "match_value"
    t.text "sentence_match_value"
    t.integer "source_id"
    t.string "source_method"
    t.string "source_type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "custom_method"
    t.string "custom_explanation"
    t.string "section_name"
    t.index ["abstractor_suggestion_id"], name: "index_abstractor_suggestion_id"
  end

  create_table "abstractor_suggestions", force: :cascade do |t|
    t.integer "abstractor_abstraction_id"
    t.string "suggested_value"
    t.boolean "unknown"
    t.boolean "not_applicable"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "accepted"
    t.boolean "system_rejected", default: false
    t.string "system_rejected_reason"
    t.boolean "system_accepted", default: false
    t.string "system_accepted_reason"
    t.index ["abstractor_abstraction_id"], name: "index_abstractor_abstraction_id_2"
  end

  create_table "api_logs", force: :cascade do |t|
    t.string "system", null: false
    t.text "url"
    t.text "payload"
    t.text "response"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_api_logs_on_created_at"
    t.index ["system"], name: "index_api_logs_on_system"
  end

  create_table "batch_nu_chers_pathology_report_sections", force: :cascade do |t|
    t.string "west_mrn"
    t.string "source_system"
    t.string "stable_identifier_path"
    t.string "stable_identiifer_value"
    t.string "case_collect_datetime"
    t.string "accessioned_datetime"
    t.string "accession_nbr_formatted"
    t.string "group_name"
    t.string "group_desc"
    t.string "group_id"
    t.string "snomed_code"
    t.string "snomed_name"
    t.string "responsible_pathologist_full_name"
    t.string "responsible_pathologist_npi"
    t.string "section_description"
    t.text "note_text"
    t.string "surgical_case_number"
    t.string "surgery_name"
    t.string "surgery_start_date"
    t.string "code_type"
    t.string "cpt_code"
    t.string "cpt_name"
    t.string "primary_surgeon_full_name"
    t.string "primary_surgeon_npi"
    t.string "case_num"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "batch_pathology_case_surgeries", force: :cascade do |t|
    t.string "west_mrn"
    t.string "source_system"
    t.string "stable_identifier_path"
    t.string "stable_identiifer_value"
    t.string "case_collect_datetime"
    t.string "accessioned_datetime"
    t.string "accession_nbr_formatted"
    t.string "group_name"
    t.string "group_desc"
    t.string "group_id"
    t.string "snomed_code"
    t.string "snomed_name"
    t.string "responsible_pathologist_full_name"
    t.string "responsible_pathologist_npi"
    t.string "section_description"
    t.string "surgical_case_number"
    t.string "surgery_name"
    t.string "surgery_start_date"
    t.string "code_type"
    t.string "cpt_code"
    t.string "cpt_name"
    t.string "primary_surgeon_full_name"
    t.string "primary_surgeon_npi"
    t.string "row_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "batch_pathology_report_sections", force: :cascade do |t|
    t.string "west_mrn"
    t.string "source_system"
    t.string "stable_identifier_path"
    t.string "stable_identifier_value"
    t.string "accession_nbr_formatted"
    t.string "accessioned_datetime"
    t.string "present_map_count"
    t.string "surgical_case_key"
    t.string "or_case_id"
    t.string "surg_case_id"
    t.string "cpt"
    t.string "cpt_description"
    t.string "surgery_name"
    t.string "group_name"
    t.string "group_desc"
    t.string "snomed_code"
    t.string "snomed_name"
    t.string "group_id"
    t.string "responsible_pathologist_full_name"
    t.string "responsible_pathologist_npi"
    t.string "primary_surgeon_full_name"
    t.string "primary_surgeon_npi"
    t.string "section_description"
    t.text "note_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "care_site", primary_key: "care_site_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "care_site_name", limit: 255
    t.integer "place_of_service_concept_id"
    t.integer "location_id"
    t.string "care_site_source_value", limit: 50
    t.string "place_of_service_source_value", limit: 50
    t.index ["care_site_id"], name: "idx_care_site_id_1"
  end

  create_table "case_numbers", force: :cascade do |t|
    t.string "case_number"
    t.string "west_mrn"
    t.string "cohort"
    t.string "site"
  end

  create_table "cdm_source", id: false, force: :cascade do |t|
    t.string "cdm_source_name", limit: 255, null: false
    t.string "cdm_source_abbreviation", limit: 25, null: false
    t.string "cdm_holder", limit: 255, null: false
    t.text "source_description"
    t.string "source_documentation_reference", limit: 255
    t.string "cdm_etl_reference", limit: 255
    t.date "source_release_date", null: false
    t.date "cdm_release_date", null: false
    t.string "cdm_version", limit: 10
    t.integer "cdm_version_concept_id", null: false
    t.string "vocabulary_version", limit: 20, null: false
  end

  create_table "cohort", id: false, force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.integer "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
  end

  create_table "cohort_definition", id: false, force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.string "cohort_definition_name", limit: 255, null: false
    t.text "cohort_definition_description"
    t.integer "definition_type_concept_id", null: false
    t.text "cohort_definition_syntax"
    t.integer "subject_concept_id", null: false
    t.date "cohort_initiation_date"
  end

  create_table "compare_breast_cancer_abstractions", force: :cascade do |t|
    t.string "abstractor_namespace_name"
    t.string "person_source_value"
    t.integer "note_id"
    t.string "stable_identifier_path"
    t.string "stable_identifier_value"
    t.integer "subject_id"
    t.string "procedure_occurrence_stable_identifier_path"
    t.string "procedure_occurrence_stable_identifier_value"
    t.date "procedure_date"
    t.string "has_cancer_histology"
    t.text "has_cancer_histology_suggestions"
    t.string "has_cancer_site"
    t.text "has_cancer_site_suggestions"
    t.string "has_cancer_site_laterality"
    t.string "has_cancer_pathologic_sbr_grade"
    t.string "has_cancer_recurrence_status"
    t.string "has_metastatic_cancer_histology"
    t.text "has_metastatic_cancer_histology_suggestions"
    t.string "has_metastatic_cancer_site"
    t.text "has_metastatic_cancer_site_suggestions"
    t.string "has_metastatic_cancer_primary_site"
    t.string "has_metastatic_cancer_site_laterality"
    t.string "has_metastatic_cancer_recurrence_status"
    t.string "procedure_occurrence_stable_identifier_surgery_path"
    t.string "procedure_occurrence_stable_identifier_surgery_value"
    t.date "surgery_procedure_date"
    t.string "surgery_concept_name"
    t.string "surgery_vocabulary_id"
    t.string "surgery_concept_code"
    t.string "surgery_procedure_source_value"
    t.string "has_surgery_date"
    t.date "has_surgery_date_normalized"
    t.string "pathological_tumor_staging_category"
    t.string "pathological_nodes_staging_category"
    t.string "pathological_metastasis_staging_category"
    t.string "has_tumor_size"
    t.string "has_estrogen_receptor_status"
    t.string "has_progesterone_receptor_status"
    t.string "has_her2_status"
  end

  create_table "compare_cancer_abstractions", force: :cascade do |t|
    t.integer "source_id"
    t.integer "note_id"
    t.string "stable_identifier_path"
    t.string "stable_identifier_value"
    t.integer "subject_id"
    t.string "has_idh1_status"
    t.string "has_idh2_status"
    t.string "has_mgmt_status"
    t.string "has_1p_status"
    t.string "has_19q_status"
    t.string "has_10q_PTEN_status"
    t.string "has_ki67"
    t.string "has_p53"
    t.string "has_surgery_date"
    t.string "abstractor_namespace_name"
    t.string "abstractor_subject_group_name"
    t.string "system_type"
    t.string "status"
  end

  create_table "compare_cancer_diagnosis_abstractions", force: :cascade do |t|
    t.integer "source_id"
    t.integer "note_id"
    t.string "stable_identifier_path"
    t.string "stable_identifier_value"
    t.integer "subject_id"
    t.string "has_cancer_histology"
    t.string "has_cancer_histology_suggestions"
    t.string "has_cancer_histology_other"
    t.string "has_cancer_histology_other_suggestions"
    t.string "has_metastatic_cancer_histology"
    t.string "has_metastatic_cancer_histology_suggestions"
    t.string "has_metastatic_cancer_histology_other"
    t.string "has_metastatic_cancer_histology_other_suggestions"
    t.string "has_cancer_site"
    t.string "has_cancer_site_suggestions"
    t.string "has_cancer_site_other"
    t.string "has_cancer_site_other_suggestions"
    t.string "has_cancer_site_laterality"
    t.string "has_cancer_who_grade"
    t.string "has_metastatic_cancer_primary_site"
    t.string "has_cancer_recurrence_status"
    t.string "abstractor_namespace_name"
    t.string "abstractor_subject_group_name"
    t.string "system_type"
    t.string "status"
  end

  create_table "compare_pspore_surgeries", force: :cascade do |t|
    t.string "record_id"
    t.string "pop_id"
    t.string "case_number"
    t.string "nmhc_mrn"
    t.string "diagnosis"
    t.string "diagnosis_abstractor"
    t.string "affiliate"
    t.date "registration_date"
    t.date "consent_date"
    t.string "surgery_date"
    t.string "surgery_date_abstractor"
    t.string "surgery_type"
    t.string "surgery_type_abstractor"
    t.string "pathological_staging_t"
    t.string "pathological_staging_t_abstractor"
    t.string "pathological_staging_n"
    t.string "pathological_staging_n_abstractor"
    t.string "pathological_staging_m"
    t.string "pathological_staging_m_abstractor"
    t.string "surgery_prostate_weight"
    t.string "surgery_prostate_weight_abstractor"
    t.string "nervesparing_procedure"
    t.string "extra_capsular_extension"
    t.string "extra_capsular_extension_abstractor"
    t.string "margins"
    t.string "margins_abstractor"
    t.string "seminal_vesicle"
    t.string "seminal_vesicle_abstractor"
    t.string "lymph_nodes"
    t.string "lymph_nodes_abstractor"
    t.string "lymphatic_vascular_invasion"
    t.string "lymphatic_vascular_invasion_abstractor"
    t.string "surgery_perineural"
    t.string "surgery_perineural_abstractor"
    t.string "surgery_gleason_1"
    t.string "surgery_gleason_1_abstractor"
    t.string "surgery_gleason_2"
    t.string "surgery_gleason_2_abstractor"
    t.string "surgery_gleason_tertiary"
    t.string "surgery_precentage_of_prostate_cancer_tissue"
    t.string "surgery_precentage_of_prostate_cancer_tissue_abstractor"
    t.string "accession_number"
  end

  create_table "concept", primary_key: "concept_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "concept_name", limit: 255, null: false
    t.string "domain_id", limit: 20, null: false
    t.string "vocabulary_id", limit: 20, null: false
    t.string "concept_class_id", limit: 20, null: false
    t.string "standard_concept", limit: 1
    t.string "concept_code", limit: 50, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["concept_class_id"], name: "idx_concept_class_id"
    t.index ["concept_code"], name: "idx_concept_code"
    t.index ["concept_id"], name: "idx_concept_concept_id"
    t.index ["domain_id"], name: "idx_concept_domain_id"
    t.index ["vocabulary_id"], name: "idx_concept_vocabluary_id"
  end

  create_table "concept_ancestor", id: false, force: :cascade do |t|
    t.integer "ancestor_concept_id", null: false
    t.integer "descendant_concept_id", null: false
    t.integer "min_levels_of_separation", null: false
    t.integer "max_levels_of_separation", null: false
    t.index ["ancestor_concept_id"], name: "idx_concept_ancestor_id_1"
    t.index ["descendant_concept_id"], name: "idx_concept_ancestor_id_2"
  end

  create_table "concept_class", primary_key: "concept_class_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "concept_class_name", limit: 255, null: false
    t.integer "concept_class_concept_id", null: false
    t.index ["concept_class_id"], name: "idx_concept_class_class_id"
  end

  create_table "concept_relationship", id: false, force: :cascade do |t|
    t.integer "concept_id_1", null: false
    t.integer "concept_id_2", null: false
    t.string "relationship_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["concept_id_1"], name: "idx_concept_relationship_id_1"
    t.index ["concept_id_2"], name: "idx_concept_relationship_id_2"
    t.index ["relationship_id"], name: "idx_concept_relationship_id_3"
  end

  create_table "concept_synonym", id: false, force: :cascade do |t|
    t.integer "concept_id", null: false
    t.string "concept_synonym_name", limit: 1000, null: false
    t.integer "language_concept_id", null: false
    t.index ["concept_id"], name: "idx_concept_synonym_id"
  end

  create_table "condition_era", primary_key: "condition_era_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "condition_concept_id", null: false
    t.date "condition_era_start_date", null: false
    t.date "condition_era_end_date", null: false
    t.integer "condition_occurrence_count"
    t.index ["condition_concept_id"], name: "idx_condition_era_concept_id_1"
    t.index ["person_id"], name: "idx_condition_era_person_id_1"
  end

  create_table "condition_occurrence", primary_key: "condition_occurrence_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "condition_concept_id", null: false
    t.date "condition_start_date", null: false
    t.datetime "condition_start_datetime"
    t.date "condition_end_date"
    t.datetime "condition_end_datetime"
    t.integer "condition_type_concept_id", null: false
    t.integer "condition_status_concept_id"
    t.string "stop_reason", limit: 20
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "condition_source_value", limit: 50
    t.integer "condition_source_concept_id"
    t.string "condition_status_source_value", limit: 50
    t.index ["condition_concept_id"], name: "idx_condition_concept_id_1"
    t.index ["person_id"], name: "idx_condition_person_id_1"
    t.index ["visit_occurrence_id"], name: "idx_condition_visit_id_1"
  end

  create_table "cost", primary_key: "cost_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "cost_event_id", null: false
    t.string "cost_domain_id", limit: 20, null: false
    t.integer "cost_type_concept_id", null: false
    t.integer "currency_concept_id"
    t.decimal "total_charge"
    t.decimal "total_cost"
    t.decimal "total_paid"
    t.decimal "paid_by_payer"
    t.decimal "paid_by_patient"
    t.decimal "paid_patient_copay"
    t.decimal "paid_patient_coinsurance"
    t.decimal "paid_patient_deductible"
    t.decimal "paid_by_primary"
    t.decimal "paid_ingredient_cost"
    t.decimal "paid_dispensing_fee"
    t.integer "payer_plan_period_id"
    t.decimal "amount_allowed"
    t.integer "revenue_code_concept_id"
    t.string "revenue_code_source_value", limit: 50
    t.integer "drg_concept_id"
    t.string "drg_source_value", limit: 3
    t.index ["cost_event_id"], name: "idx_cost_event_id"
  end

  create_table "death", id: false, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "death_date", null: false
    t.datetime "death_datetime"
    t.integer "death_type_concept_id"
    t.integer "cause_concept_id"
    t.string "cause_source_value", limit: 50
    t.integer "cause_source_concept_id"
    t.index ["person_id"], name: "idx_death_person_id_1"
  end

  create_table "device_exposure", primary_key: "device_exposure_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "device_concept_id", null: false
    t.date "device_exposure_start_date", null: false
    t.datetime "device_exposure_start_datetime"
    t.date "device_exposure_end_date"
    t.datetime "device_exposure_end_datetime"
    t.integer "device_type_concept_id", null: false
    t.string "unique_device_id", limit: 255
    t.string "production_id", limit: 255
    t.integer "quantity"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "device_source_value", limit: 50
    t.integer "device_source_concept_id"
    t.integer "unit_concept_id"
    t.string "unit_source_value", limit: 50
    t.integer "unit_source_concept_id"
    t.index ["device_concept_id"], name: "idx_device_concept_id_1"
    t.index ["person_id"], name: "idx_device_person_id_1"
    t.index ["visit_occurrence_id"], name: "idx_device_visit_id_1"
  end

  create_table "domain", primary_key: "domain_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "domain_name", limit: 255, null: false
    t.integer "domain_concept_id", null: false
    t.index ["domain_id"], name: "idx_domain_domain_id"
  end

  create_table "dose_era", primary_key: "dose_era_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.integer "unit_concept_id", null: false
    t.decimal "dose_value", null: false
    t.date "dose_era_start_date", null: false
    t.date "dose_era_end_date", null: false
    t.index ["drug_concept_id"], name: "idx_dose_era_concept_id_1"
    t.index ["person_id"], name: "idx_dose_era_person_id_1"
  end

  create_table "drug_era", primary_key: "drug_era_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.date "drug_era_start_date", null: false
    t.date "drug_era_end_date", null: false
    t.integer "drug_exposure_count"
    t.integer "gap_days"
    t.index ["drug_concept_id"], name: "idx_drug_era_concept_id_1"
    t.index ["person_id"], name: "idx_drug_era_person_id_1"
  end

  create_table "drug_exposure", primary_key: "drug_exposure_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.date "drug_exposure_start_date", null: false
    t.datetime "drug_exposure_start_datetime"
    t.date "drug_exposure_end_date", null: false
    t.datetime "drug_exposure_end_datetime"
    t.date "verbatim_end_date"
    t.integer "drug_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.integer "refills"
    t.decimal "quantity"
    t.integer "days_supply"
    t.text "sig"
    t.integer "route_concept_id"
    t.string "lot_number", limit: 50
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "drug_source_value", limit: 50
    t.integer "drug_source_concept_id"
    t.string "route_source_value", limit: 50
    t.string "dose_unit_source_value", limit: 50
    t.index ["drug_concept_id"], name: "idx_drug_concept_id_1"
    t.index ["person_id"], name: "idx_drug_person_id_1"
    t.index ["visit_occurrence_id"], name: "idx_drug_visit_id_1"
  end

  create_table "drug_strength", id: false, force: :cascade do |t|
    t.integer "drug_concept_id", null: false
    t.integer "ingredient_concept_id", null: false
    t.decimal "amount_value"
    t.integer "amount_unit_concept_id"
    t.decimal "numerator_value"
    t.integer "numerator_unit_concept_id"
    t.decimal "denominator_value"
    t.integer "denominator_unit_concept_id"
    t.integer "box_size"
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["drug_concept_id"], name: "idx_drug_strength_id_1"
    t.index ["ingredient_concept_id"], name: "idx_drug_strength_id_2"
  end

  create_table "episode", primary_key: "episode_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "episode_concept_id", null: false
    t.date "episode_start_date", null: false
    t.datetime "episode_start_datetime"
    t.date "episode_end_date"
    t.datetime "episode_end_datetime"
    t.integer "episode_parent_id"
    t.integer "episode_number"
    t.integer "episode_object_concept_id", null: false
    t.integer "episode_type_concept_id", null: false
    t.string "episode_source_value", limit: 50
    t.integer "episode_source_concept_id"
  end

  create_table "episode_event", id: false, force: :cascade do |t|
    t.integer "episode_id", null: false
    t.integer "event_id", null: false
    t.integer "episode_event_field_concept_id", null: false
  end

  create_table "fact_relationship", id: false, force: :cascade do |t|
    t.integer "domain_concept_id_1", null: false
    t.integer "fact_id_1", null: false
    t.integer "domain_concept_id_2", null: false
    t.integer "fact_id_2", null: false
    t.integer "relationship_concept_id", null: false
    t.index ["domain_concept_id_1"], name: "idx_fact_relationship_id1"
    t.index ["domain_concept_id_2"], name: "idx_fact_relationship_id2"
    t.index ["relationship_concept_id"], name: "idx_fact_relationship_id3"
  end

  create_table "icdo3_categories", force: :cascade do |t|
    t.string "version", null: false
    t.string "category", null: false
    t.string "categorizable_type", null: false
    t.integer "parent_icdo3_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "icdo3_categorizations", force: :cascade do |t|
    t.integer "icdo3_category_id", null: false
    t.integer "categorizable_id", null: false
    t.string "categorizable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "icdo3_histologies", force: :cascade do |t|
    t.string "version", null: false
    t.string "minor_version", null: false
    t.string "icdo3_code", null: false
    t.string "icdo3_name", null: false
    t.string "icdo3_description", null: false
    t.string "level"
    t.string "code_reference"
    t.string "obs"
    t.string "see_also"
    t.string "includes"
    t.string "excludes"
    t.string "other_text"
    t.string "category"
    t.string "subcategory"
    t.integer "grade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "icdo3_histology_synonyms", force: :cascade do |t|
    t.integer "icdo3_histology_id", null: false
    t.string "icdo3_synonym_description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "icdo3_site_synonyms", force: :cascade do |t|
    t.integer "icdo3_site_id", null: false
    t.string "icdo3_synonym_description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "icdo3_sites", force: :cascade do |t|
    t.string "version", null: false
    t.string "minor_version", null: false
    t.string "icdo3_code", null: false
    t.string "icdo3_name", null: false
    t.string "icdo3_description", null: false
    t.string "category"
    t.string "subcategory"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "location", primary_key: "location_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "address_1", limit: 50
    t.string "address_2", limit: 50
    t.string "city", limit: 50
    t.string "state", limit: 2
    t.string "zip", limit: 9
    t.string "county", limit: 20
    t.string "location_source_value", limit: 50
    t.integer "country_concept_id"
    t.string "country_source_value", limit: 80
    t.decimal "latitude"
    t.decimal "longitude"
    t.index ["location_id"], name: "idx_location_id_1"
  end

  create_table "login_audits", force: :cascade do |t|
    t.string "username", null: false
    t.string "login_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "measurement", primary_key: "measurement_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "measurement_concept_id", null: false
    t.date "measurement_date", null: false
    t.datetime "measurement_datetime"
    t.string "measurement_time", limit: 10
    t.integer "measurement_type_concept_id", null: false
    t.integer "operator_concept_id"
    t.decimal "value_as_number"
    t.integer "value_as_concept_id"
    t.integer "unit_concept_id"
    t.decimal "range_low"
    t.decimal "range_high"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "measurement_source_value", limit: 50
    t.integer "measurement_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.integer "unit_source_concept_id"
    t.string "value_source_value", limit: 50
    t.integer "measurement_event_id"
    t.integer "meas_event_field_concept_id"
    t.index ["measurement_concept_id"], name: "idx_measurement_concept_id_1"
    t.index ["person_id"], name: "idx_measurement_person_id_1"
    t.index ["visit_occurrence_id"], name: "idx_measurement_visit_id_1"
  end

  create_table "metadata", primary_key: "metadata_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "metadata_concept_id", null: false
    t.integer "metadata_type_concept_id", null: false
    t.string "name", limit: 250, null: false
    t.string "value_as_string", limit: 250
    t.integer "value_as_concept_id"
    t.decimal "value_as_number"
    t.date "metadata_date"
    t.datetime "metadata_datetime"
    t.index ["metadata_concept_id"], name: "idx_metadata_concept_id_1"
  end

  create_table "nlp_comparison_suggestions", force: :cascade do |t|
    t.integer "nlp_comparison_id", null: false
    t.string "source", null: false
    t.string "suggested_value", null: false
  end

  create_table "nlp_comparisons", force: :cascade do |t|
    t.string "stable_identifier_path", null: false
    t.string "stable_identifier_value", null: false
    t.integer "note_id", null: false
    t.integer "note_stable_identifier_id_old"
    t.integer "note_stable_identifier_id_new"
    t.string "abstractor_subject_group_name"
    t.integer "abstractor_abstraction_group_id_old"
    t.integer "abstractor_abstraction_group_id_new"
    t.integer "abstractor_subject_group_counter"
    t.integer "abstractor_abstraction_id_old", null: false
    t.string "predicate_old", null: false
    t.string "predicate_new"
    t.string "predicate", null: false
    t.string "value_old"
    t.float "value_old_float"
    t.string "value_old_normalized"
    t.string "value_new"
    t.float "value_new_float"
    t.string "value_new_normalized"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value_new_normalized_raw"
  end

  create_table "note", primary_key: "note_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "note_date", null: false
    t.datetime "note_datetime"
    t.integer "note_type_concept_id", null: false
    t.integer "note_class_concept_id", null: false
    t.string "note_title", limit: 250
    t.text "note_text", null: false
    t.integer "encoding_concept_id", null: false
    t.integer "language_concept_id", null: false
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "note_source_value", limit: 50
    t.integer "note_event_id"
    t.integer "note_event_field_concept_id"
    t.index ["note_date"], name: "index_note_on_note_date"
    t.index ["note_type_concept_id"], name: "idx_note_concept_id_1"
    t.index ["person_id"], name: "idx_note_person_id_1"
    t.index ["visit_occurrence_id"], name: "idx_note_visit_id_1"
  end

  create_table "note_nlp", primary_key: "note_nlp_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "note_id", null: false
    t.integer "section_concept_id"
    t.string "snippet", limit: 250
    t.string "offset", limit: 50
    t.string "lexical_variant", limit: 250, null: false
    t.integer "note_nlp_concept_id"
    t.integer "note_nlp_source_concept_id"
    t.string "nlp_system", limit: 250
    t.date "nlp_date", null: false
    t.datetime "nlp_datetime"
    t.string "term_exists", limit: 1
    t.string "term_temporal", limit: 50
    t.string "term_modifiers", limit: 2000
    t.index ["note_id"], name: "idx_note_nlp_note_id_1"
    t.index ["note_nlp_concept_id"], name: "idx_note_nlp_concept_id_1"
  end

  create_table "note_stable_identifier", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.string "stable_identifier_path", null: false
    t.string "stable_identifier_value", null: false
    t.string "stable_identifier_path_2"
    t.string "stable_identifier_value_2"
    t.string "stable_identifer_hash_id"
    t.string "stable_identifier_value_1"
    t.index ["note_id"], name: "idx_note_stable_identifier_1"
    t.index ["stable_identifer_hash_id"], name: "index_note_stable_identifier_stable_identifer_hash_id"
    t.index ["stable_identifier_path", "stable_identifier_value"], name: "idx_note_stable_identifier_2"
  end

  create_table "note_stable_identifier_full", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.string "stable_identifier_path", null: false
    t.string "stable_identifier_value", null: false
    t.string "stable_identifier_path_2"
    t.string "stable_identifier_value_2"
    t.string "stable_identifer_hash_id"
    t.index ["stable_identifer_hash_id"], name: "index_note_stable_identifier_full_stable_identifer_hash_id"
  end

  create_table "observation", primary_key: "observation_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "observation_concept_id", null: false
    t.date "observation_date", null: false
    t.datetime "observation_datetime"
    t.integer "observation_type_concept_id", null: false
    t.decimal "value_as_number"
    t.string "value_as_string", limit: 60
    t.integer "value_as_concept_id"
    t.integer "qualifier_concept_id"
    t.integer "unit_concept_id"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "observation_source_value", limit: 50
    t.integer "observation_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "qualifier_source_value", limit: 50
    t.string "value_source_value", limit: 50
    t.integer "observation_event_id"
    t.integer "obs_event_field_concept_id"
    t.index ["observation_concept_id"], name: "idx_observation_concept_id_1"
    t.index ["person_id"], name: "idx_observation_person_id_1"
    t.index ["visit_occurrence_id"], name: "idx_observation_visit_id_1"
  end

  create_table "observation_period", primary_key: "observation_period_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "observation_period_start_date", null: false
    t.date "observation_period_end_date", null: false
    t.integer "period_type_concept_id", null: false
    t.index ["person_id"], name: "idx_observation_period_id_1"
  end

  create_table "ohdsi_nlp_proposal_pathology_cases", force: :cascade do |t|
    t.string "abstractor_namespace_name"
    t.string "west_mrn"
    t.string "note_stable_identifier_path"
    t.string "note_stable_identifier_value_1"
    t.string "note_stable_identifier_value_2"
    t.bigint "note_id"
    t.string "pathology_stable_identifier_path"
    t.string "pathology_stable_identifier_value_1"
    t.date "pathology_procedure_date"
    t.string "pathology_provider_name"
    t.string "pathology_procedure_source_value"
    t.string "pathology_concept_name"
    t.string "surgery_stable_identifier_path"
    t.string "surgery_stable_identifier_value_1"
    t.date "surgery_procedure_date"
    t.string "surgery_provider_name"
    t.string "surgery_procedure_source_value"
    t.string "surgery_concept_name"
    t.string "diagnosis_type"
    t.string "has_cancer_histology"
    t.text "has_cancer_histology_suggestions"
    t.string "has_cancer_site"
    t.text "has_cancer_site_suggestions"
    t.string "has_cancer_site_laterality"
    t.string "has_cancer_who_grade"
    t.string "has_metastatic_cancer_primary_site"
    t.string "has_cancer_recurrence_status"
    t.string "has_surgery_date"
  end

  create_table "pathology_accession_numbers", force: :cascade do |t|
    t.string "case_number"
    t.string "specimen_identifier"
    t.string "specimen_type"
    t.string "specimen_type_normalized"
    t.string "collection_date_raw"
    t.date "collection_date"
    t.string "receive_date_raw"
    t.date "receive_date"
    t.string "source"
    t.string "accession_number_raw"
    t.string "raw_found"
    t.string "accession_number_normalized"
    t.boolean "accession_number_found"
    t.boolean "accession_number_case_number_found"
    t.boolean "accession_number_case_number_collection_date_found"
    t.boolean "case_number_found"
    t.boolean "case_number_collection_date_found"
    t.string "accession_number_assigned"
  end

  create_table "payer_plan_period", primary_key: "payer_plan_period_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "payer_plan_period_start_date", null: false
    t.date "payer_plan_period_end_date", null: false
    t.integer "payer_concept_id"
    t.string "payer_source_value", limit: 50
    t.integer "payer_source_concept_id"
    t.integer "plan_concept_id"
    t.string "plan_source_value", limit: 50
    t.integer "plan_source_concept_id"
    t.integer "sponsor_concept_id"
    t.string "sponsor_source_value", limit: 50
    t.integer "sponsor_source_concept_id"
    t.string "family_source_value", limit: 50
    t.integer "stop_reason_concept_id"
    t.string "stop_reason_source_value", limit: 50
    t.integer "stop_reason_source_concept_id"
    t.index ["person_id"], name: "idx_period_person_id_1"
  end

  create_table "person", primary_key: "person_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "gender_concept_id", null: false
    t.integer "year_of_birth", null: false
    t.integer "month_of_birth"
    t.integer "day_of_birth"
    t.datetime "birth_datetime"
    t.integer "race_concept_id", null: false
    t.integer "ethnicity_concept_id", null: false
    t.integer "location_id"
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "person_source_value", limit: 50
    t.string "gender_source_value", limit: 50
    t.integer "gender_source_concept_id"
    t.string "race_source_value", limit: 50
    t.integer "race_source_concept_id"
    t.string "ethnicity_source_value", limit: 50
    t.integer "ethnicity_source_concept_id"
    t.index ["gender_concept_id"], name: "idx_gender"
    t.index ["person_id"], name: "idx_person_id"
  end

  create_table "pii_address", id: false, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "location_id"
  end

  create_table "pii_email", id: false, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.string "email", limit: 255
  end

  create_table "pii_mrn", id: false, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.string "health_system", limit: 50
    t.string "mrn", limit: 50
    t.index ["person_id"], name: "index_person_id"
  end

  create_table "pii_name", id: false, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.string "first_name", limit: 200
    t.string "middle_name", limit: 508
    t.string "last_name", limit: 200
    t.string "suffix", limit: 50
    t.string "prefix", limit: 50
  end

  create_table "pii_phone_number", id: false, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.string "phone_number", limit: 50
  end

  create_table "primary_cns_pathology_cases", force: :cascade do |t|
    t.string "abstractor_namespace_name"
    t.string "west_mrn"
    t.string "note_stable_identifier_path"
    t.string "note_stable_identifier_value_1"
    t.string "note_stable_identifier_value_2"
    t.bigint "note_id"
    t.string "pathology_stable_identifier_path"
    t.string "pathology_stable_identifier_value_1"
    t.date "pathology_procedure_date"
    t.string "pathology_provider_name"
    t.string "pathology_procedure_source_value"
    t.string "pathology_concept_name"
    t.string "surgery_stable_identifier_path"
    t.string "surgery_stable_identifier_value_1"
    t.date "surgery_procedure_date"
    t.string "surgery_provider_name"
    t.string "surgery_procedure_source_value"
    t.string "surgery_concept_name"
    t.string "diagnosis_type"
    t.string "has_cancer_histology"
    t.text "has_cancer_histology_suggestions"
    t.string "integrated_mention"
    t.string "has_cancer_integrated_histology"
    t.text "has_cancer_integrated_histology_suggestions"
    t.string "has_cancer_site"
    t.text "has_cancer_site_suggestions"
    t.string "has_idh1_status"
    t.string "has_idh2_status"
    t.string "has_1p_status"
    t.string "has_19q_status"
    t.string "has_10q_pten_status"
    t.string "has_mgmt_status"
    t.string "has_ki67"
    t.string "has_p53"
    t.string "has_surgery_date"
  end

  create_table "procedure_occurrence", primary_key: "procedure_occurrence_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "procedure_concept_id", null: false
    t.date "procedure_date", null: false
    t.datetime "procedure_datetime"
    t.date "procedure_end_date"
    t.datetime "procedure_end_datetime"
    t.integer "procedure_type_concept_id", null: false
    t.integer "modifier_concept_id"
    t.integer "quantity"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "procedure_source_value", limit: 50
    t.integer "procedure_source_concept_id"
    t.string "modifier_source_value", limit: 50
    t.index ["person_id"], name: "idx_procedure_person_id_1"
    t.index ["procedure_concept_id"], name: "idx_procedure_concept_id_1"
    t.index ["provider_id"], name: "index_procedure_occurrence_on_provider_id"
    t.index ["visit_occurrence_id"], name: "idx_procedure_visit_id_1"
  end

  create_table "procedure_occurrence_stable_identifier", force: :cascade do |t|
    t.bigint "procedure_occurrence_id", null: false
    t.string "stable_identifier_path", null: false
    t.string "stable_identifier_value_1", null: false
    t.string "stable_identifier_value_2"
    t.string "stable_identifier_value_3"
    t.string "stable_identifier_value_4"
    t.string "stable_identifier_value_5"
    t.string "stable_identifier_value_6"
  end

  create_table "prostate_surgery_pathology_cases", force: :cascade do |t|
    t.string "abstractor_namespace_name"
    t.string "west_mrn"
    t.string "note_stable_identifier_path"
    t.string "note_stable_identifier_value_1"
    t.string "note_stable_identifier_value_2"
    t.bigint "note_id"
    t.string "pathology_stable_identifier_path"
    t.string "pathology_stable_identifier_value_1"
    t.date "pathology_procedure_date"
    t.string "pathology_provider_name"
    t.string "pathology_procedure_source_value"
    t.string "pathology_concept_name"
    t.string "surgery_stable_identifier_path"
    t.string "surgery_stable_identifier_value_1"
    t.date "surgery_procedure_date"
    t.string "surgery_provider_name"
    t.string "surgery_procedure_source_value"
    t.string "surgery_concept_name"
    t.string "diagnosis_type"
    t.string "has_cancer_histology"
    t.text "has_cancer_histology_suggestions"
    t.string "has_cancer_site"
    t.text "has_cancer_site_suggestions"
    t.string "has_gleason_score_grade"
    t.string "has_perineural_invasion"
    t.string "has_prostate_weight"
    t.string "pathological_tumor_staging_category"
    t.string "pathological_nodes_staging_category"
    t.string "pathological_metastasis_staging_category"
    t.string "has_extraprostatic_extension"
    t.string "has_seminal_vesicle_invasion"
    t.string "has_margin_status"
    t.string "has_number_lymph_nodes_examined"
    t.string "has_number_lymph_nodes_positive_tumor"
    t.string "has_surgery_date"
  end

  create_table "provider", primary_key: "provider_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "provider_name", limit: 255
    t.string "npi", limit: 20
    t.string "dea", limit: 20
    t.integer "specialty_concept_id"
    t.integer "care_site_id"
    t.integer "year_of_birth"
    t.integer "gender_concept_id"
    t.string "provider_source_value", limit: 50
    t.string "specialty_source_value", limit: 50
    t.integer "specialty_source_concept_id"
    t.string "gender_source_value", limit: 50
    t.integer "gender_source_concept_id"
    t.index ["provider_id"], name: "idx_provider_id_1"
    t.index ["provider_name"], name: "index_provider_on_provider_name"
  end

  create_table "relationship", primary_key: "relationship_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "relationship_name", limit: 255, null: false
    t.string "is_hierarchical", limit: 1, null: false
    t.string "defines_ancestry", limit: 1, null: false
    t.string "reverse_relationship_id", limit: 20, null: false
    t.integer "relationship_concept_id", null: false
    t.index ["relationship_id"], name: "idx_relationship_rel_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "site_categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "site_categories_sites", id: false, force: :cascade do |t|
    t.integer "site_id"
    t.integer "site_category_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "icdo3_code", null: false
    t.integer "level", null: false
    t.string "name", null: false
    t.boolean "synonym", null: false
    t.boolean "laterality"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "source_to_concept_map", id: false, force: :cascade do |t|
    t.string "source_code", limit: 50, null: false
    t.integer "source_concept_id", null: false
    t.string "source_vocabulary_id", limit: 20, null: false
    t.string "source_code_description", limit: 255
    t.integer "target_concept_id", null: false
    t.string "target_vocabulary_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["source_code"], name: "idx_source_to_concept_map_c"
    t.index ["source_vocabulary_id"], name: "idx_source_to_concept_map_1"
    t.index ["target_concept_id"], name: "idx_source_to_concept_map_3"
    t.index ["target_vocabulary_id"], name: "idx_source_to_concept_map_2"
  end

  create_table "specimen", primary_key: "specimen_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "specimen_concept_id", null: false
    t.integer "specimen_type_concept_id", null: false
    t.date "specimen_date", null: false
    t.datetime "specimen_datetime"
    t.decimal "quantity"
    t.integer "unit_concept_id"
    t.integer "anatomic_site_concept_id"
    t.integer "disease_status_concept_id"
    t.string "specimen_source_id", limit: 50
    t.string "specimen_source_value", limit: 50
    t.string "unit_source_value", limit: 50
    t.string "anatomic_site_source_value", limit: 50
    t.string "disease_status_source_value", limit: 50
    t.index ["person_id"], name: "idx_specimen_person_id_1"
    t.index ["specimen_concept_id"], name: "idx_specimen_concept_id_1"
  end

  create_table "sql_audits", force: :cascade do |t|
    t.string "username", null: false
    t.string "auditable_type"
    t.text "auditable_ids"
    t.text "sql", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "username", null: false
    t.boolean "system_administrator"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "visit_detail", primary_key: "visit_detail_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "visit_detail_concept_id", null: false
    t.date "visit_detail_start_date", null: false
    t.datetime "visit_detail_start_datetime"
    t.date "visit_detail_end_date", null: false
    t.datetime "visit_detail_end_datetime"
    t.integer "visit_detail_type_concept_id", null: false
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "visit_detail_source_value", limit: 50
    t.integer "visit_detail_source_concept_id"
    t.integer "admitted_from_concept_id"
    t.string "admitted_from_source_value", limit: 50
    t.string "discharged_to_source_value", limit: 50
    t.integer "discharged_to_concept_id"
    t.integer "preceding_visit_detail_id"
    t.integer "parent_visit_detail_id"
    t.integer "visit_occurrence_id", null: false
    t.index ["person_id"], name: "idx_visit_det_person_id_1"
    t.index ["visit_detail_concept_id"], name: "idx_visit_det_concept_id_1"
    t.index ["visit_occurrence_id"], name: "idx_visit_det_occ_id"
  end

  create_table "visit_occurrence", primary_key: "visit_occurrence_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "visit_concept_id", null: false
    t.date "visit_start_date", null: false
    t.datetime "visit_start_datetime"
    t.date "visit_end_date", null: false
    t.datetime "visit_end_datetime"
    t.integer "visit_type_concept_id", null: false
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "visit_source_value", limit: 50
    t.integer "visit_source_concept_id"
    t.integer "admitted_from_concept_id"
    t.string "admitted_from_source_value", limit: 50
    t.integer "discharged_to_concept_id"
    t.string "discharged_to_source_value", limit: 50
    t.integer "preceding_visit_occurrence_id"
    t.index ["person_id"], name: "idx_visit_person_id_1"
    t.index ["visit_concept_id"], name: "idx_visit_concept_id_1"
  end

  create_table "vocabulary", primary_key: "vocabulary_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "vocabulary_name", limit: 255, null: false
    t.string "vocabulary_reference", limit: 255
    t.string "vocabulary_version", limit: 255
    t.integer "vocabulary_concept_id", null: false
    t.index ["vocabulary_id"], name: "idx_vocabulary_vocabulary_id"
  end

  add_foreign_key "care_site", "concept", column: "place_of_service_concept_id", primary_key: "concept_id", name: "fpk_care_site_place_of_service_concept_id"
  add_foreign_key "care_site", "location", primary_key: "location_id", name: "fpk_care_site_location_id"
  add_foreign_key "cdm_source", "concept", column: "cdm_version_concept_id", primary_key: "concept_id", name: "fpk_cdm_source_cdm_version_concept_id"
  add_foreign_key "cohort_definition", "concept", column: "definition_type_concept_id", primary_key: "concept_id", name: "fpk_cohort_definition_definition_type_concept_id"
  add_foreign_key "cohort_definition", "concept", column: "subject_concept_id", primary_key: "concept_id", name: "fpk_cohort_definition_subject_concept_id"
  add_foreign_key "concept", "concept_class", primary_key: "concept_class_id", name: "fpk_concept_concept_class_id"
  add_foreign_key "concept", "domain", primary_key: "domain_id", name: "fpk_concept_domain_id"
  add_foreign_key "concept", "vocabulary", primary_key: "vocabulary_id", name: "fpk_concept_vocabulary_id"
  add_foreign_key "concept_ancestor", "concept", column: "ancestor_concept_id", primary_key: "concept_id", name: "fpk_concept_ancestor_ancestor_concept_id"
  add_foreign_key "concept_ancestor", "concept", column: "descendant_concept_id", primary_key: "concept_id", name: "fpk_concept_ancestor_descendant_concept_id"
  add_foreign_key "concept_class", "concept", column: "concept_class_concept_id", primary_key: "concept_id", name: "fpk_concept_class_concept_class_concept_id"
  add_foreign_key "concept_relationship", "concept", column: "concept_id_1", primary_key: "concept_id", name: "fpk_concept_relationship_concept_id_1"
  add_foreign_key "concept_relationship", "concept", column: "concept_id_2", primary_key: "concept_id", name: "fpk_concept_relationship_concept_id_2"
  add_foreign_key "concept_relationship", "relationship", primary_key: "relationship_id", name: "fpk_concept_relationship_relationship_id"
  add_foreign_key "concept_synonym", "concept", column: "language_concept_id", primary_key: "concept_id", name: "fpk_concept_synonym_language_concept_id"
  add_foreign_key "concept_synonym", "concept", primary_key: "concept_id", name: "fpk_concept_synonym_concept_id"
  add_foreign_key "condition_era", "concept", column: "condition_concept_id", primary_key: "concept_id", name: "fpk_condition_era_condition_concept_id"
  add_foreign_key "condition_era", "person", primary_key: "person_id", name: "fpk_condition_era_person_id"
  add_foreign_key "condition_occurrence", "concept", column: "condition_concept_id", primary_key: "concept_id", name: "fpk_condition_occurrence_condition_concept_id"
  add_foreign_key "condition_occurrence", "concept", column: "condition_source_concept_id", primary_key: "concept_id", name: "fpk_condition_occurrence_condition_source_concept_id"
  add_foreign_key "condition_occurrence", "concept", column: "condition_status_concept_id", primary_key: "concept_id", name: "fpk_condition_occurrence_condition_status_concept_id"
  add_foreign_key "condition_occurrence", "concept", column: "condition_type_concept_id", primary_key: "concept_id", name: "fpk_condition_occurrence_condition_type_concept_id"
  add_foreign_key "condition_occurrence", "person", primary_key: "person_id", name: "fpk_condition_occurrence_person_id"
  add_foreign_key "condition_occurrence", "provider", primary_key: "provider_id", name: "fpk_condition_occurrence_provider_id"
  add_foreign_key "condition_occurrence", "visit_detail", primary_key: "visit_detail_id", name: "fpk_condition_occurrence_visit_detail_id"
  add_foreign_key "condition_occurrence", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_condition_occurrence_visit_occurrence_id"
  add_foreign_key "cost", "concept", column: "cost_type_concept_id", primary_key: "concept_id", name: "fpk_cost_cost_type_concept_id"
  add_foreign_key "cost", "concept", column: "currency_concept_id", primary_key: "concept_id", name: "fpk_cost_currency_concept_id"
  add_foreign_key "cost", "concept", column: "drg_concept_id", primary_key: "concept_id", name: "fpk_cost_drg_concept_id"
  add_foreign_key "cost", "concept", column: "revenue_code_concept_id", primary_key: "concept_id", name: "fpk_cost_revenue_code_concept_id"
  add_foreign_key "cost", "domain", column: "cost_domain_id", primary_key: "domain_id", name: "fpk_cost_cost_domain_id"
  add_foreign_key "death", "concept", column: "cause_concept_id", primary_key: "concept_id", name: "fpk_death_cause_concept_id"
  add_foreign_key "death", "concept", column: "cause_source_concept_id", primary_key: "concept_id", name: "fpk_death_cause_source_concept_id"
  add_foreign_key "death", "concept", column: "death_type_concept_id", primary_key: "concept_id", name: "fpk_death_death_type_concept_id"
  add_foreign_key "death", "person", primary_key: "person_id", name: "fpk_death_person_id"
  add_foreign_key "device_exposure", "concept", column: "device_concept_id", primary_key: "concept_id", name: "fpk_device_exposure_device_concept_id"
  add_foreign_key "device_exposure", "concept", column: "device_source_concept_id", primary_key: "concept_id", name: "fpk_device_exposure_device_source_concept_id"
  add_foreign_key "device_exposure", "concept", column: "device_type_concept_id", primary_key: "concept_id", name: "fpk_device_exposure_device_type_concept_id"
  add_foreign_key "device_exposure", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_device_exposure_unit_concept_id"
  add_foreign_key "device_exposure", "concept", column: "unit_source_concept_id", primary_key: "concept_id", name: "fpk_device_exposure_unit_source_concept_id"
  add_foreign_key "device_exposure", "person", primary_key: "person_id", name: "fpk_device_exposure_person_id"
  add_foreign_key "device_exposure", "provider", primary_key: "provider_id", name: "fpk_device_exposure_provider_id"
  add_foreign_key "device_exposure", "visit_detail", primary_key: "visit_detail_id", name: "fpk_device_exposure_visit_detail_id"
  add_foreign_key "device_exposure", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_device_exposure_visit_occurrence_id"
  add_foreign_key "domain", "concept", column: "domain_concept_id", primary_key: "concept_id", name: "fpk_domain_domain_concept_id"
  add_foreign_key "dose_era", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_dose_era_drug_concept_id"
  add_foreign_key "dose_era", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_dose_era_unit_concept_id"
  add_foreign_key "dose_era", "person", primary_key: "person_id", name: "fpk_dose_era_person_id"
  add_foreign_key "drug_era", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_era_drug_concept_id"
  add_foreign_key "drug_era", "person", primary_key: "person_id", name: "fpk_drug_era_person_id"
  add_foreign_key "drug_exposure", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_exposure_drug_concept_id"
  add_foreign_key "drug_exposure", "concept", column: "drug_source_concept_id", primary_key: "concept_id", name: "fpk_drug_exposure_drug_source_concept_id"
  add_foreign_key "drug_exposure", "concept", column: "drug_type_concept_id", primary_key: "concept_id", name: "fpk_drug_exposure_drug_type_concept_id"
  add_foreign_key "drug_exposure", "concept", column: "route_concept_id", primary_key: "concept_id", name: "fpk_drug_exposure_route_concept_id"
  add_foreign_key "drug_exposure", "person", primary_key: "person_id", name: "fpk_drug_exposure_person_id"
  add_foreign_key "drug_exposure", "provider", primary_key: "provider_id", name: "fpk_drug_exposure_provider_id"
  add_foreign_key "drug_exposure", "visit_detail", primary_key: "visit_detail_id", name: "fpk_drug_exposure_visit_detail_id"
  add_foreign_key "drug_exposure", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_drug_exposure_visit_occurrence_id"
  add_foreign_key "drug_strength", "concept", column: "amount_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_amount_unit_concept_id"
  add_foreign_key "drug_strength", "concept", column: "denominator_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_denominator_unit_concept_id"
  add_foreign_key "drug_strength", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_drug_concept_id"
  add_foreign_key "drug_strength", "concept", column: "ingredient_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_ingredient_concept_id"
  add_foreign_key "drug_strength", "concept", column: "numerator_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_numerator_unit_concept_id"
  add_foreign_key "episode", "concept", column: "episode_concept_id", primary_key: "concept_id", name: "fpk_episode_episode_concept_id"
  add_foreign_key "episode", "concept", column: "episode_object_concept_id", primary_key: "concept_id", name: "fpk_episode_episode_object_concept_id"
  add_foreign_key "episode", "concept", column: "episode_source_concept_id", primary_key: "concept_id", name: "fpk_episode_episode_source_concept_id"
  add_foreign_key "episode", "concept", column: "episode_type_concept_id", primary_key: "concept_id", name: "fpk_episode_episode_type_concept_id"
  add_foreign_key "episode", "person", primary_key: "person_id", name: "fpk_episode_person_id"
  add_foreign_key "episode_event", "concept", column: "episode_event_field_concept_id", primary_key: "concept_id", name: "fpk_episode_event_episode_event_field_concept_id"
  add_foreign_key "episode_event", "episode", primary_key: "episode_id", name: "fpk_episode_event_episode_id"
  add_foreign_key "fact_relationship", "concept", column: "domain_concept_id_1", primary_key: "concept_id", name: "fpk_fact_relationship_domain_concept_id_1"
  add_foreign_key "fact_relationship", "concept", column: "domain_concept_id_2", primary_key: "concept_id", name: "fpk_fact_relationship_domain_concept_id_2"
  add_foreign_key "fact_relationship", "concept", column: "relationship_concept_id", primary_key: "concept_id", name: "fpk_fact_relationship_relationship_concept_id"
  add_foreign_key "location", "concept", column: "country_concept_id", primary_key: "concept_id", name: "fpk_location_country_concept_id"
  add_foreign_key "measurement", "concept", column: "meas_event_field_concept_id", primary_key: "concept_id", name: "fpk_measurement_meas_event_field_concept_id"
  add_foreign_key "measurement", "concept", column: "measurement_concept_id", primary_key: "concept_id", name: "fpk_measurement_measurement_concept_id"
  add_foreign_key "measurement", "concept", column: "measurement_source_concept_id", primary_key: "concept_id", name: "fpk_measurement_measurement_source_concept_id"
  add_foreign_key "measurement", "concept", column: "measurement_type_concept_id", primary_key: "concept_id", name: "fpk_measurement_measurement_type_concept_id"
  add_foreign_key "measurement", "concept", column: "operator_concept_id", primary_key: "concept_id", name: "fpk_measurement_operator_concept_id"
  add_foreign_key "measurement", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_measurement_unit_concept_id"
  add_foreign_key "measurement", "concept", column: "unit_source_concept_id", primary_key: "concept_id", name: "fpk_measurement_unit_source_concept_id"
  add_foreign_key "measurement", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_measurement_value_as_concept_id"
  add_foreign_key "measurement", "person", primary_key: "person_id", name: "fpk_measurement_person_id"
  add_foreign_key "measurement", "provider", primary_key: "provider_id", name: "fpk_measurement_provider_id"
  add_foreign_key "measurement", "visit_detail", primary_key: "visit_detail_id", name: "fpk_measurement_visit_detail_id"
  add_foreign_key "measurement", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_measurement_visit_occurrence_id"
  add_foreign_key "metadata", "concept", column: "metadata_concept_id", primary_key: "concept_id", name: "fpk_metadata_metadata_concept_id"
  add_foreign_key "metadata", "concept", column: "metadata_type_concept_id", primary_key: "concept_id", name: "fpk_metadata_metadata_type_concept_id"
  add_foreign_key "metadata", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_metadata_value_as_concept_id"
  add_foreign_key "note", "concept", column: "encoding_concept_id", primary_key: "concept_id", name: "fpk_note_encoding_concept_id"
  add_foreign_key "note", "concept", column: "language_concept_id", primary_key: "concept_id", name: "fpk_note_language_concept_id"
  add_foreign_key "note", "concept", column: "note_class_concept_id", primary_key: "concept_id", name: "fpk_note_note_class_concept_id"
  add_foreign_key "note", "concept", column: "note_event_field_concept_id", primary_key: "concept_id", name: "fpk_note_note_event_field_concept_id"
  add_foreign_key "note", "concept", column: "note_type_concept_id", primary_key: "concept_id", name: "fpk_note_note_type_concept_id"
  add_foreign_key "note", "person", primary_key: "person_id", name: "fpk_note_person_id"
  add_foreign_key "note", "provider", primary_key: "provider_id", name: "fpk_note_provider_id"
  add_foreign_key "note", "visit_detail", primary_key: "visit_detail_id", name: "fpk_note_visit_detail_id"
  add_foreign_key "note", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_note_visit_occurrence_id"
  add_foreign_key "note_nlp", "concept", column: "note_nlp_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_note_nlp_concept_id"
  add_foreign_key "note_nlp", "concept", column: "note_nlp_source_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_note_nlp_source_concept_id"
  add_foreign_key "note_nlp", "concept", column: "section_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_section_concept_id"
  add_foreign_key "observation", "concept", column: "obs_event_field_concept_id", primary_key: "concept_id", name: "fpk_observation_obs_event_field_concept_id"
  add_foreign_key "observation", "concept", column: "observation_concept_id", primary_key: "concept_id", name: "fpk_observation_observation_concept_id"
  add_foreign_key "observation", "concept", column: "observation_source_concept_id", primary_key: "concept_id", name: "fpk_observation_observation_source_concept_id"
  add_foreign_key "observation", "concept", column: "observation_type_concept_id", primary_key: "concept_id", name: "fpk_observation_observation_type_concept_id"
  add_foreign_key "observation", "concept", column: "qualifier_concept_id", primary_key: "concept_id", name: "fpk_observation_qualifier_concept_id"
  add_foreign_key "observation", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_observation_unit_concept_id"
  add_foreign_key "observation", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_observation_value_as_concept_id"
  add_foreign_key "observation", "person", primary_key: "person_id", name: "fpk_observation_person_id"
  add_foreign_key "observation", "provider", primary_key: "provider_id", name: "fpk_observation_provider_id"
  add_foreign_key "observation", "visit_detail", primary_key: "visit_detail_id", name: "fpk_observation_visit_detail_id"
  add_foreign_key "observation", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_observation_visit_occurrence_id"
  add_foreign_key "observation_period", "concept", column: "period_type_concept_id", primary_key: "concept_id", name: "fpk_observation_period_period_type_concept_id"
  add_foreign_key "observation_period", "person", primary_key: "person_id", name: "fpk_observation_period_person_id"
  add_foreign_key "payer_plan_period", "concept", column: "payer_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_payer_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "payer_source_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_payer_source_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "plan_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_plan_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "plan_source_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_plan_source_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "sponsor_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_sponsor_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "sponsor_source_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_sponsor_source_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "stop_reason_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_stop_reason_concept_id"
  add_foreign_key "payer_plan_period", "concept", column: "stop_reason_source_concept_id", primary_key: "concept_id", name: "fpk_payer_plan_period_stop_reason_source_concept_id"
  add_foreign_key "payer_plan_period", "person", primary_key: "person_id", name: "fpk_payer_plan_period_person_id"
  add_foreign_key "person", "care_site", primary_key: "care_site_id", name: "fpk_person_care_site_id"
  add_foreign_key "person", "concept", column: "ethnicity_concept_id", primary_key: "concept_id", name: "fpk_person_ethnicity_concept_id"
  add_foreign_key "person", "concept", column: "ethnicity_source_concept_id", primary_key: "concept_id", name: "fpk_person_ethnicity_source_concept_id"
  add_foreign_key "person", "concept", column: "gender_concept_id", primary_key: "concept_id", name: "fpk_person_gender_concept_id"
  add_foreign_key "person", "concept", column: "gender_source_concept_id", primary_key: "concept_id", name: "fpk_person_gender_source_concept_id"
  add_foreign_key "person", "concept", column: "race_concept_id", primary_key: "concept_id", name: "fpk_person_race_concept_id"
  add_foreign_key "person", "concept", column: "race_source_concept_id", primary_key: "concept_id", name: "fpk_person_race_source_concept_id"
  add_foreign_key "person", "location", primary_key: "location_id", name: "fpk_person_location_id"
  add_foreign_key "person", "provider", primary_key: "provider_id", name: "fpk_person_provider_id"
  add_foreign_key "procedure_occurrence", "concept", column: "modifier_concept_id", primary_key: "concept_id", name: "fpk_procedure_occurrence_modifier_concept_id"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_concept_id", primary_key: "concept_id", name: "fpk_procedure_occurrence_procedure_concept_id"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_source_concept_id", primary_key: "concept_id", name: "fpk_procedure_occurrence_procedure_source_concept_id"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_type_concept_id", primary_key: "concept_id", name: "fpk_procedure_occurrence_procedure_type_concept_id"
  add_foreign_key "procedure_occurrence", "person", primary_key: "person_id", name: "fpk_procedure_occurrence_person_id"
  add_foreign_key "procedure_occurrence", "provider", primary_key: "provider_id", name: "fpk_procedure_occurrence_provider_id"
  add_foreign_key "procedure_occurrence", "visit_detail", primary_key: "visit_detail_id", name: "fpk_procedure_occurrence_visit_detail_id"
  add_foreign_key "procedure_occurrence", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_procedure_occurrence_visit_occurrence_id"
  add_foreign_key "provider", "care_site", primary_key: "care_site_id", name: "fpk_provider_care_site_id"
  add_foreign_key "provider", "concept", column: "gender_concept_id", primary_key: "concept_id", name: "fpk_provider_gender_concept_id"
  add_foreign_key "provider", "concept", column: "gender_source_concept_id", primary_key: "concept_id", name: "fpk_provider_gender_source_concept_id"
  add_foreign_key "provider", "concept", column: "specialty_concept_id", primary_key: "concept_id", name: "fpk_provider_specialty_concept_id"
  add_foreign_key "provider", "concept", column: "specialty_source_concept_id", primary_key: "concept_id", name: "fpk_provider_specialty_source_concept_id"
  add_foreign_key "relationship", "concept", column: "relationship_concept_id", primary_key: "concept_id", name: "fpk_relationship_relationship_concept_id"
  add_foreign_key "source_to_concept_map", "concept", column: "source_concept_id", primary_key: "concept_id", name: "fpk_source_to_concept_map_source_concept_id"
  add_foreign_key "source_to_concept_map", "concept", column: "target_concept_id", primary_key: "concept_id", name: "fpk_source_to_concept_map_target_concept_id"
  add_foreign_key "source_to_concept_map", "vocabulary", column: "target_vocabulary_id", primary_key: "vocabulary_id", name: "fpk_source_to_concept_map_target_vocabulary_id"
  add_foreign_key "specimen", "concept", column: "anatomic_site_concept_id", primary_key: "concept_id", name: "fpk_specimen_anatomic_site_concept_id"
  add_foreign_key "specimen", "concept", column: "disease_status_concept_id", primary_key: "concept_id", name: "fpk_specimen_disease_status_concept_id"
  add_foreign_key "specimen", "concept", column: "specimen_concept_id", primary_key: "concept_id", name: "fpk_specimen_specimen_concept_id"
  add_foreign_key "specimen", "concept", column: "specimen_type_concept_id", primary_key: "concept_id", name: "fpk_specimen_specimen_type_concept_id"
  add_foreign_key "specimen", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_specimen_unit_concept_id"
  add_foreign_key "specimen", "person", primary_key: "person_id", name: "fpk_specimen_person_id"
  add_foreign_key "visit_detail", "care_site", primary_key: "care_site_id", name: "fpk_visit_detail_care_site_id"
  add_foreign_key "visit_detail", "concept", column: "admitted_from_concept_id", primary_key: "concept_id", name: "fpk_visit_detail_admitted_from_concept_id"
  add_foreign_key "visit_detail", "concept", column: "discharged_to_concept_id", primary_key: "concept_id", name: "fpk_visit_detail_discharged_to_concept_id"
  add_foreign_key "visit_detail", "concept", column: "visit_detail_concept_id", primary_key: "concept_id", name: "fpk_visit_detail_visit_detail_concept_id"
  add_foreign_key "visit_detail", "concept", column: "visit_detail_source_concept_id", primary_key: "concept_id", name: "fpk_visit_detail_visit_detail_source_concept_id"
  add_foreign_key "visit_detail", "concept", column: "visit_detail_type_concept_id", primary_key: "concept_id", name: "fpk_visit_detail_visit_detail_type_concept_id"
  add_foreign_key "visit_detail", "person", primary_key: "person_id", name: "fpk_visit_detail_person_id"
  add_foreign_key "visit_detail", "provider", primary_key: "provider_id", name: "fpk_visit_detail_provider_id"
  add_foreign_key "visit_detail", "visit_detail", column: "parent_visit_detail_id", primary_key: "visit_detail_id", name: "fpk_visit_detail_parent_visit_detail_id"
  add_foreign_key "visit_detail", "visit_detail", column: "preceding_visit_detail_id", primary_key: "visit_detail_id", name: "fpk_visit_detail_preceding_visit_detail_id"
  add_foreign_key "visit_detail", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_visit_detail_visit_occurrence_id"
  add_foreign_key "visit_occurrence", "care_site", primary_key: "care_site_id", name: "fpk_visit_occurrence_care_site_id"
  add_foreign_key "visit_occurrence", "concept", column: "admitted_from_concept_id", primary_key: "concept_id", name: "fpk_visit_occurrence_admitted_from_concept_id"
  add_foreign_key "visit_occurrence", "concept", column: "discharged_to_concept_id", primary_key: "concept_id", name: "fpk_visit_occurrence_discharged_to_concept_id"
  add_foreign_key "visit_occurrence", "concept", column: "visit_concept_id", primary_key: "concept_id", name: "fpk_visit_occurrence_visit_concept_id"
  add_foreign_key "visit_occurrence", "concept", column: "visit_source_concept_id", primary_key: "concept_id", name: "fpk_visit_occurrence_visit_source_concept_id"
  add_foreign_key "visit_occurrence", "concept", column: "visit_type_concept_id", primary_key: "concept_id", name: "fpk_visit_occurrence_visit_type_concept_id"
  add_foreign_key "visit_occurrence", "person", primary_key: "person_id", name: "fpk_visit_occurrence_person_id"
  add_foreign_key "visit_occurrence", "provider", primary_key: "provider_id", name: "fpk_visit_occurrence_provider_id"
  add_foreign_key "visit_occurrence", "visit_occurrence", column: "preceding_visit_occurrence_id", primary_key: "visit_occurrence_id", name: "fpk_visit_occurrence_preceding_visit_occurrence_id"
  add_foreign_key "vocabulary", "concept", column: "vocabulary_concept_id", primary_key: "concept_id", name: "fpk_vocabulary_vocabulary_concept_id"
end
