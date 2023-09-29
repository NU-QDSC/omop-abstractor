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

ActiveRecord::Schema.define(version: 2023_06_09_151518) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "abstractions", id: false, force: :cascade do |t|
    t.string "stable_identifier_path", limit: 255
    t.string "stable_identifier_value", limit: 255
    t.bigint "note_id"
    t.date "note_date"
    t.string "note_title", limit: 255
    t.date "pathology_date"
    t.date "surgery_date"
    t.string "pathologist_name", limit: 255
    t.string "surgeon_name", limit: 255
    t.string "surgeon_speciality", limit: 255
    t.string "has_idh1_status", limit: 255
    t.string "has_idh2_status", limit: 255
    t.string "has_1p_status", limit: 255
    t.string "has_19q_status", limit: 255
    t.string "has_10q_pten_status", limit: 255
    t.string "has_mgmt_status", limit: 255
    t.string "has_ki67", limit: 255
    t.string "has_p53", limit: 255
    t.string "has_surgery_date", limit: 255
    t.string "abstractor_namespace_name", limit: 255
    t.string "has_cancer_histology", limit: 255
    t.string "has_cancer_site", limit: 255
    t.string "has_cancer_site_laterality", limit: 255
    t.string "has_cancer_who_grade", limit: 255
    t.string "has_cancer_recurrence_status", limit: 255
    t.string "has_metastatic_cancer_histology", limit: 255
    t.string "has_metastatic_cancer_site", limit: 255
    t.string "has_metastatic_cancer_primary_site", limit: 255
    t.string "has_metastatic_cancer_site_laterality", limit: 255
    t.string "has_metastatic_cancer_recurrence_status", limit: 255
  end

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

  create_table "articles", force: :cascade do |t|
    t.text "note_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "attribute_definition", primary_key: "attribute_definition_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "attribute_name", limit: 255, null: false
    t.text "attribute_description"
    t.bigint "attribute_type_concept_id", null: false
    t.text "attribute_syntax"
    t.index ["attribute_definition_id"], name: "idx_attribute_definition_id"
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

  create_table "care_site", primary_key: "care_site_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "care_site_name", limit: 255
    t.bigint "place_of_service_concept_id"
    t.bigint "location_id"
    t.string "care_site_source_value", limit: 50
    t.string "place_of_service_source_value", limit: 50
  end

  create_table "case_numbers", force: :cascade do |t|
    t.string "case_number"
    t.string "west_mrn"
    t.string "cohort"
    t.string "site"
  end

  create_table "cdm_source", id: false, force: :cascade do |t|
    t.string "cdm_source_name", limit: 255, null: false
    t.string "cdm_source_abbreviation", limit: 25
    t.string "cdm_holder", limit: 255
    t.text "source_description"
    t.string "source_documentation_reference", limit: 255
    t.string "cdm_etl_reference", limit: 255
    t.date "source_release_date"
    t.date "cdm_release_date"
    t.string "cdm_version", limit: 10
    t.string "vocabulary_version", limit: 20
  end

  create_table "cohort", primary_key: ["cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date"], force: :cascade do |t|
    t.bigint "cohort_definition_id", null: false
    t.bigint "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
    t.index ["cohort_definition_id"], name: "idx_cohort_c_definition_id"
    t.index ["subject_id"], name: "idx_cohort_subject_id"
  end

  create_table "cohort_attribute", primary_key: ["cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date", "attribute_definition_id"], force: :cascade do |t|
    t.bigint "cohort_definition_id", null: false
    t.bigint "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
    t.bigint "attribute_definition_id", null: false
    t.decimal "value_as_number"
    t.bigint "value_as_concept_id"
    t.index ["cohort_definition_id"], name: "idx_ca_definition_id"
    t.index ["subject_id"], name: "idx_ca_subject_id"
  end

  create_table "cohort_definition", primary_key: "cohort_definition_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "cohort_definition_name", limit: 255, null: false
    t.text "cohort_definition_description"
    t.bigint "definition_type_concept_id", null: false
    t.text "cohort_definition_syntax"
    t.bigint "subject_concept_id", null: false
    t.date "cohort_initiation_date"
    t.index ["cohort_definition_id"], name: "idx_cohort_definition_id"
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

  create_table "concept", primary_key: "concept_id", id: :bigint, default: nil, force: :cascade do |t|
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
    t.index ["concept_id"], name: "idx_concept_concept_id", unique: true
    t.index ["domain_id"], name: "idx_concept_domain_id"
    t.index ["vocabulary_id"], name: "idx_concept_vocabluary_id"
  end

  create_table "concept_ancestor", primary_key: ["ancestor_concept_id", "descendant_concept_id"], force: :cascade do |t|
    t.bigint "ancestor_concept_id", null: false
    t.bigint "descendant_concept_id", null: false
    t.bigint "min_levels_of_separation", null: false
    t.bigint "max_levels_of_separation", null: false
    t.index ["ancestor_concept_id"], name: "idx_concept_ancestor_id_1"
    t.index ["descendant_concept_id"], name: "idx_concept_ancestor_id_2"
  end

  create_table "concept_class", primary_key: "concept_class_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "concept_class_name", limit: 255, null: false
    t.bigint "concept_class_concept_id", null: false
    t.index ["concept_class_id"], name: "idx_concept_class_class_id", unique: true
  end

  create_table "concept_relationship", primary_key: ["concept_id_1", "concept_id_2", "relationship_id"], force: :cascade do |t|
    t.bigint "concept_id_1", null: false
    t.bigint "concept_id_2", null: false
    t.string "relationship_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["concept_id_1"], name: "idx_concept_relationship_id_1"
    t.index ["concept_id_2"], name: "idx_concept_relationship_id_2"
    t.index ["relationship_id"], name: "idx_concept_relationship_id_3"
  end

  create_table "concept_synonym", id: false, force: :cascade do |t|
    t.bigint "concept_id", null: false
    t.string "concept_synonym_name", limit: 1000, null: false
    t.bigint "language_concept_id", null: false
    t.index ["concept_id", "concept_synonym_name", "language_concept_id"], name: "uq_concept_synonym", unique: true
    t.index ["concept_id"], name: "idx_concept_synonym_id"
  end

  create_table "condition_era", primary_key: "condition_era_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "condition_concept_id", null: false
    t.date "condition_era_start_date", null: false
    t.date "condition_era_end_date", null: false
    t.bigint "condition_occurrence_count"
    t.index ["condition_concept_id"], name: "idx_condition_era_concept_id"
    t.index ["person_id"], name: "idx_condition_era_person_id"
  end

  create_table "condition_occurrence", primary_key: "condition_occurrence_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "condition_concept_id", null: false
    t.date "condition_start_date", null: false
    t.datetime "condition_start_datetime"
    t.date "condition_end_date"
    t.datetime "condition_end_datetime"
    t.bigint "condition_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.string "condition_source_value", limit: 50
    t.bigint "condition_source_concept_id"
    t.string "condition_status_source_value", limit: 50
    t.bigint "condition_status_concept_id"
    t.index ["condition_concept_id"], name: "idx_condition_concept_id"
    t.index ["person_id"], name: "idx_condition_person_id"
    t.index ["visit_occurrence_id"], name: "idx_condition_visit_id"
  end

  create_table "cost", primary_key: "cost_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "cost_event_id", null: false
    t.string "cost_domain_id", limit: 20, null: false
    t.bigint "cost_type_concept_id", null: false
    t.bigint "currency_concept_id"
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
    t.bigint "payer_plan_period_id"
    t.decimal "amount_allowed"
    t.bigint "revenue_code_concept_id"
    t.string "reveue_code_source_value", limit: 50
    t.bigint "drg_concept_id"
    t.string "drg_source_value", limit: 3
  end

  create_table "death", primary_key: "person_id", id: :bigint, default: nil, force: :cascade do |t|
    t.date "death_date", null: false
    t.datetime "death_datetime"
    t.bigint "death_type_concept_id", null: false
    t.bigint "cause_concept_id"
    t.string "cause_source_value", limit: 50
    t.bigint "cause_source_concept_id"
    t.index ["person_id"], name: "idx_death_person_id"
  end

  create_table "device_exposure", primary_key: "device_exposure_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "device_concept_id", null: false
    t.date "device_exposure_start_date", null: false
    t.datetime "device_exposure_start_datetime"
    t.date "device_exposure_end_date"
    t.datetime "device_exposure_end_datetime"
    t.bigint "device_type_concept_id", null: false
    t.string "unique_device_id", limit: 50
    t.bigint "quantity"
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.bigint "visit_detail_id"
    t.string "device_source_value", limit: 100
    t.bigint "device_source_concept_id"
    t.index ["device_concept_id"], name: "idx_device_concept_id"
    t.index ["person_id"], name: "idx_device_person_id"
    t.index ["visit_occurrence_id"], name: "idx_device_visit_id"
  end

  create_table "domain", primary_key: "domain_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "domain_name", limit: 255, null: false
    t.bigint "domain_concept_id", null: false
    t.index ["domain_id"], name: "idx_domain_domain_id", unique: true
  end

  create_table "dose_era", primary_key: "dose_era_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "drug_concept_id", null: false
    t.bigint "unit_concept_id", null: false
    t.decimal "dose_value", null: false
    t.date "dose_era_start_date", null: false
    t.date "dose_era_end_date", null: false
    t.index ["drug_concept_id"], name: "idx_dose_era_concept_id"
    t.index ["person_id"], name: "idx_dose_era_person_id"
  end

  create_table "drug_era", primary_key: "drug_era_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "drug_concept_id", null: false
    t.date "drug_era_start_date", null: false
    t.date "drug_era_end_date", null: false
    t.bigint "drug_exposure_count"
    t.bigint "gap_days"
    t.index ["drug_concept_id"], name: "idx_drug_era_concept_id"
    t.index ["person_id"], name: "idx_drug_era_person_id"
  end

  create_table "drug_exposure", primary_key: "drug_exposure_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "drug_concept_id", null: false
    t.date "drug_exposure_start_date", null: false
    t.datetime "drug_exposure_start_datetime"
    t.date "drug_exposure_end_date"
    t.datetime "drug_exposure_end_datetime"
    t.date "verbatim_end_date"
    t.bigint "drug_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.bigint "refills"
    t.decimal "quantity"
    t.bigint "days_supply"
    t.text "sig"
    t.bigint "route_concept_id"
    t.string "lot_number", limit: 50
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.bigint "visit_detail_id"
    t.string "drug_source_value", limit: 50
    t.bigint "drug_source_concept_id"
    t.string "route_source_value", limit: 50
    t.string "dose_unit_source_value", limit: 50
    t.index ["drug_concept_id"], name: "idx_drug_concept_id"
    t.index ["person_id"], name: "idx_drug_person_id"
    t.index ["visit_occurrence_id"], name: "idx_drug_visit_id"
  end

  create_table "drug_strength", primary_key: ["drug_concept_id", "ingredient_concept_id"], force: :cascade do |t|
    t.bigint "drug_concept_id", null: false
    t.bigint "ingredient_concept_id", null: false
    t.decimal "amount_value"
    t.bigint "amount_unit_concept_id"
    t.decimal "numerator_value"
    t.bigint "numerator_unit_concept_id"
    t.decimal "denominator_value"
    t.bigint "denominator_unit_concept_id"
    t.bigint "box_size"
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["drug_concept_id"], name: "idx_drug_strength_id_1"
    t.index ["ingredient_concept_id"], name: "idx_drug_strength_id_2"
  end

  create_table "encounter_notes", force: :cascade do |t|
    t.text "note_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fact_relationship", id: false, force: :cascade do |t|
    t.bigint "domain_concept_id_1", null: false
    t.bigint "fact_id_1", null: false
    t.bigint "domain_concept_id_2", null: false
    t.bigint "fact_id_2", null: false
    t.bigint "relationship_concept_id", null: false
    t.index ["domain_concept_id_1", "fact_id_1", "domain_concept_id_2", "fact_id_2"], name: "idx_fact_relationship_custom_1"
    t.index ["domain_concept_id_1"], name: "idx_fact_relationship_id_1"
    t.index ["domain_concept_id_2"], name: "idx_fact_relationship_id_2"
    t.index ["relationship_concept_id"], name: "idx_fact_relationship_id_3"
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

  create_table "imaging_exams", force: :cascade do |t|
    t.text "note_text", null: false
    t.integer "patient_id", null: false
    t.date "report_date", null: false
    t.string "accession_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "location", primary_key: "location_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "address_1", limit: 50
    t.string "address_2", limit: 50
    t.string "city", limit: 50
    t.string "state", limit: 2
    t.string "zip", limit: 9
    t.string "county", limit: 20
    t.string "location_source_value", limit: 50
  end

  create_table "login_audits", force: :cascade do |t|
    t.string "username", null: false
    t.string "login_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "measurement", primary_key: "measurement_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "measurement_concept_id", null: false
    t.date "measurement_date", null: false
    t.string "measurement_time", limit: 10
    t.datetime "measurement_datetime"
    t.bigint "measurement_type_concept_id", null: false
    t.bigint "operator_concept_id"
    t.decimal "value_as_number"
    t.bigint "value_as_concept_id"
    t.bigint "unit_concept_id"
    t.decimal "range_low"
    t.decimal "range_high"
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.bigint "visit_detail_id"
    t.string "measurement_source_value", limit: 50
    t.bigint "measurement_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "value_source_value", limit: 50
    t.index ["measurement_concept_id"], name: "idx_measurement_concept_id"
    t.index ["person_id"], name: "idx_measurement_person_id"
    t.index ["visit_occurrence_id"], name: "idx_measurement_visit_id"
  end

  create_table "metadata", id: false, force: :cascade do |t|
    t.bigint "metadata_concept_id", null: false
    t.bigint "metadata_type_concept_id", null: false
    t.string "name", limit: 250, null: false
    t.text "value_as_string"
    t.bigint "value_as_concept_id"
    t.date "metadata_date"
    t.datetime "metadata_datetime"
  end

  create_table "moomins", force: :cascade do |t|
    t.text "note_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "note", primary_key: "note_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.date "note_date", null: false
    t.datetime "note_datetime"
    t.bigint "note_type_concept_id", null: false
    t.bigint "note_class_concept_id", null: false
    t.string "note_title", limit: 250
    t.text "note_text"
    t.bigint "encoding_concept_id", null: false
    t.bigint "language_concept_id", null: false
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.bigint "visit_detail_id"
    t.string "note_source_value", limit: 50
    t.index ["note_date"], name: "index_note_on_note_date"
    t.index ["note_type_concept_id"], name: "idx_note_concept_id"
    t.index ["person_id"], name: "idx_note_person_id"
    t.index ["visit_occurrence_id"], name: "idx_note_visit_id"
  end

  create_table "note_nlp", primary_key: "note_nlp_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "note_id", null: false
    t.bigint "section_concept_id"
    t.string "snippet", limit: 250
    t.string "offset", limit: 250
    t.string "lexical_variant", limit: 250, null: false
    t.bigint "note_nlp_concept_id"
    t.bigint "note_nlp_source_concept_id"
    t.string "nlp_system", limit: 250
    t.date "nlp_date", null: false
    t.datetime "nlp_datetime"
    t.string "term_exists", limit: 1
    t.string "term_temporal", limit: 50
    t.string "term_modifiers", limit: 2000
    t.index ["note_id"], name: "idx_note_nlp_note_id"
    t.index ["note_nlp_concept_id"], name: "idx_note_nlp_concept_id"
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
    t.index ["note_id"], name: "idx_note_stable_identifier_full_1"
    t.index ["stable_identifer_hash_id"], name: "index_note_stable_identifier_stable_identifer_hash_id"
    t.index ["stable_identifier_path", "stable_identifier_value"], name: "idx_note_stable_identifier_2"
    t.index ["stable_identifier_path", "stable_identifier_value"], name: "idx_note_stable_identifier_full_2"
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

  create_table "observation", primary_key: "observation_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "observation_concept_id", null: false
    t.date "observation_date", null: false
    t.datetime "observation_datetime"
    t.bigint "observation_type_concept_id", null: false
    t.decimal "value_as_number"
    t.string "value_as_string", limit: 60
    t.bigint "value_as_concept_id"
    t.bigint "qualifier_concept_id"
    t.bigint "unit_concept_id"
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.bigint "visit_detail_id"
    t.string "observation_source_value", limit: 50
    t.bigint "observation_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "qualifier_source_value", limit: 50
    t.index ["observation_concept_id"], name: "idx_observation_concept_id"
    t.index ["person_id"], name: "idx_observation_person_id"
    t.index ["visit_occurrence_id"], name: "idx_observation_visit_id"
  end

  create_table "observation_period", primary_key: "observation_period_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.date "observation_period_start_date", null: false
    t.date "observation_period_end_date", null: false
    t.bigint "period_type_concept_id", null: false
    t.index ["person_id"], name: "idx_observation_period_id"
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

  create_table "pathology_cases", force: :cascade do |t|
    t.text "note_text", null: false
    t.integer "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payer_plan_period", primary_key: "payer_plan_period_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.date "payer_plan_period_start_date", null: false
    t.date "payer_plan_period_end_date", null: false
    t.bigint "payer_concept_id"
    t.string "payer_source_value", limit: 50
    t.bigint "payer_source_concept_id"
    t.bigint "plan_concept_id"
    t.string "plan_source_value", limit: 50
    t.bigint "plan_source_concept_id"
    t.bigint "sponsor_concept_id"
    t.string "sponsor_source_value", limit: 50
    t.bigint "sponsor_source_concept_id"
    t.string "family_source_value", limit: 50
    t.bigint "stop_reason_concept_id"
    t.bigint "stop_reason_source_value"
    t.bigint "stop_reason_source_concept_id"
    t.index ["person_id"], name: "idx_period_person_id"
  end

  create_table "person", primary_key: "person_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "gender_concept_id", null: false
    t.bigint "year_of_birth", null: false
    t.bigint "month_of_birth"
    t.bigint "day_of_birth"
    t.datetime "birth_datetime"
    t.bigint "race_concept_id", null: false
    t.bigint "ethnicity_concept_id", null: false
    t.bigint "location_id"
    t.bigint "provider_id"
    t.bigint "care_site_id"
    t.string "person_source_value", limit: 50
    t.string "gender_source_value", limit: 50
    t.bigint "gender_source_concept_id"
    t.string "race_source_value", limit: 50
    t.bigint "race_source_concept_id"
    t.string "ethnicity_source_value", limit: 50
    t.bigint "ethnicity_source_concept_id"
    t.index ["person_id"], name: "idx_person_id", unique: true
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
    t.string "has_cancer_site_laterality"
    t.string "has_cancer_who_grade"
    t.string "has_metastatic_cancer_primary_site"
    t.string "has_cancer_recurrence_status"
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

  create_table "procedure_occurrence", primary_key: "procedure_occurrence_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "procedure_concept_id", null: false
    t.date "procedure_date", null: false
    t.datetime "procedure_datetime"
    t.bigint "procedure_type_concept_id", null: false
    t.bigint "modifier_concept_id"
    t.bigint "quantity"
    t.bigint "provider_id"
    t.bigint "visit_occurrence_id"
    t.bigint "visit_detail_id"
    t.string "procedure_source_value", limit: 50
    t.bigint "procedure_source_concept_id"
    t.string "modifier_source_value", limit: 50
    t.index ["person_id"], name: "idx_procedure_person_id"
    t.index ["procedure_concept_id"], name: "idx_procedure_concept_id"
    t.index ["provider_id"], name: "index_procedure_occurrence_on_provider_id"
    t.index ["visit_occurrence_id"], name: "idx_procedure_visit_id"
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
    t.index ["procedure_occurrence_id"], name: "idx_procedure_occurrence_stable_identifier_1"
    t.index ["stable_identifier_path", "stable_identifier_value_1"], name: "idx_procedure_occurrence_stable_identifier_2"
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

  create_table "provider", primary_key: "provider_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "provider_name", limit: 255
    t.string "npi", limit: 20
    t.string "dea", limit: 20
    t.bigint "specialty_concept_id"
    t.bigint "care_site_id"
    t.bigint "year_of_birth"
    t.bigint "gender_concept_id"
    t.string "provider_source_value", limit: 50
    t.string "specialty_source_value", limit: 50
    t.bigint "specialty_source_concept_id"
    t.string "gender_source_value", limit: 50
    t.bigint "gender_source_concept_id"
    t.index ["provider_name"], name: "index_provider_on_provider_name"
  end

  create_table "radiation_therapy_prescriptions", force: :cascade do |t|
    t.string "site_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "relationship", primary_key: "relationship_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "relationship_name", limit: 255, null: false
    t.string "is_hierarchical", limit: 1, null: false
    t.string "defines_ancestry", limit: 1, null: false
    t.string "reverse_relationship_id", limit: 20, null: false
    t.bigint "relationship_concept_id", null: false
    t.index ["relationship_id"], name: "idx_relationship_rel_id", unique: true
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

  create_table "source_to_concept_map", primary_key: ["source_vocabulary_id", "target_concept_id", "source_code", "valid_end_date"], force: :cascade do |t|
    t.string "source_code", limit: 50, null: false
    t.bigint "source_concept_id", null: false
    t.string "source_vocabulary_id", limit: 20, null: false
    t.string "source_code_description", limit: 255
    t.bigint "target_concept_id", null: false
    t.string "target_vocabulary_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["source_code"], name: "idx_source_to_concept_map_code"
    t.index ["source_vocabulary_id"], name: "idx_source_to_concept_map_id_1"
    t.index ["target_concept_id"], name: "idx_source_to_concept_map_id_3"
    t.index ["target_vocabulary_id"], name: "idx_source_to_concept_map_id_2"
  end

  create_table "specimen", primary_key: "specimen_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "specimen_concept_id", null: false
    t.bigint "specimen_type_concept_id", null: false
    t.date "specimen_date", null: false
    t.datetime "specimen_datetime"
    t.decimal "quantity"
    t.bigint "unit_concept_id"
    t.bigint "anatomic_site_concept_id"
    t.bigint "disease_status_concept_id"
    t.string "specimen_source_id", limit: 50
    t.string "specimen_source_value", limit: 50
    t.string "unit_source_value", limit: 50
    t.string "anatomic_site_source_value", limit: 50
    t.string "disease_status_source_value", limit: 50
    t.index ["person_id"], name: "idx_specimen_person_id"
    t.index ["specimen_concept_id"], name: "idx_specimen_concept_id"
  end

  create_table "sql_audits", force: :cascade do |t|
    t.string "username", null: false
    t.string "auditable_type"
    t.text "auditable_ids"
    t.text "sql", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "surgeries", force: :cascade do |t|
    t.integer "surg_case_id", null: false
    t.string "surg_case_nbr", null: false
    t.integer "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "surgical_procedure_reports", force: :cascade do |t|
    t.text "note_text", null: false
    t.integer "patient_id", null: false
    t.date "report_date", null: false
    t.string "reference_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "surgical_procedures", force: :cascade do |t|
    t.integer "surg_case_id", null: false
    t.string "description", null: false
    t.string "modifier", null: false
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

  create_table "visit_detail", primary_key: "visit_detail_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "visit_detail_concept_id", null: false
    t.date "visit_start_date", null: false
    t.datetime "visit_start_datetime"
    t.date "visit_end_date", null: false
    t.datetime "visit_end_datetime"
    t.bigint "visit_type_concept_id", null: false
    t.bigint "provider_id"
    t.bigint "care_site_id"
    t.bigint "admitting_source_concept_id"
    t.bigint "discharge_to_concept_id"
    t.bigint "preceding_visit_detail_id"
    t.string "visit_source_value", limit: 50
    t.bigint "visit_source_concept_id"
    t.string "admitting_source_value", limit: 50
    t.string "discharge_to_source_value", limit: 50
    t.bigint "visit_detail_parent_id"
    t.bigint "visit_occurrence_id", null: false
    t.index ["person_id"], name: "idx_visit_detail_person_id"
    t.index ["visit_detail_concept_id"], name: "idx_visit_detail_concept_id"
  end

  create_table "visit_occurrence", primary_key: "visit_occurrence_id", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "visit_concept_id", null: false
    t.date "visit_start_date", null: false
    t.datetime "visit_start_datetime"
    t.date "visit_end_date", null: false
    t.datetime "visit_end_datetime"
    t.bigint "visit_type_concept_id", null: false
    t.bigint "provider_id"
    t.bigint "care_site_id"
    t.string "visit_source_value", limit: 50
    t.bigint "visit_source_concept_id"
    t.bigint "admitting_source_concept_id"
    t.string "admitting_source_value", limit: 50
    t.bigint "discharge_to_concept_id"
    t.string "discharge_to_source_value", limit: 50
    t.bigint "preceding_visit_occurrence_id"
    t.index ["person_id"], name: "idx_visit_person_id"
    t.index ["visit_concept_id"], name: "idx_visit_concept_id"
  end

  create_table "vocabulary", primary_key: "vocabulary_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "vocabulary_name", limit: 255, null: false
    t.string "vocabulary_reference", limit: 255
    t.string "vocabulary_version", limit: 255
    t.bigint "vocabulary_concept_id", null: false
    t.index ["vocabulary_id"], name: "idx_vocabulary_vocabulary_id", unique: true
  end

  add_foreign_key "care_site", "concept", column: "place_of_service_concept_id", primary_key: "concept_id", name: "fpk_care_site_place"
  add_foreign_key "care_site", "location", primary_key: "location_id", name: "fpk_care_site_location"
  add_foreign_key "cohort", "cohort_definition", primary_key: "cohort_definition_id", name: "fpk_cohort_definition"
  add_foreign_key "cohort_attribute", "attribute_definition", primary_key: "attribute_definition_id", name: "fpk_ca_attribute_definition"
  add_foreign_key "cohort_attribute", "cohort_definition", primary_key: "cohort_definition_id", name: "fpk_ca_cohort_definition"
  add_foreign_key "cohort_attribute", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_ca_value"
  add_foreign_key "cohort_definition", "concept", column: "definition_type_concept_id", primary_key: "concept_id", name: "fpk_cohort_definition_concept"
  add_foreign_key "concept", "concept_class", primary_key: "concept_class_id", name: "fpk_concept_class"
  add_foreign_key "concept", "domain", primary_key: "domain_id", name: "fpk_concept_domain"
  add_foreign_key "concept", "vocabulary", primary_key: "vocabulary_id", name: "fpk_concept_vocabulary"
  add_foreign_key "concept_ancestor", "concept", column: "ancestor_concept_id", primary_key: "concept_id", name: "fpk_concept_ancestor_concept_1"
  add_foreign_key "concept_ancestor", "concept", column: "descendant_concept_id", primary_key: "concept_id", name: "fpk_concept_ancestor_concept_2"
  add_foreign_key "concept_class", "concept", column: "concept_class_concept_id", primary_key: "concept_id", name: "fpk_concept_class_concept"
  add_foreign_key "concept_relationship", "concept", column: "concept_id_1", primary_key: "concept_id", name: "fpk_concept_relationship_c_1"
  add_foreign_key "concept_relationship", "concept", column: "concept_id_2", primary_key: "concept_id", name: "fpk_concept_relationship_c_2"
  add_foreign_key "concept_relationship", "relationship", primary_key: "relationship_id", name: "fpk_concept_relationship_id"
  add_foreign_key "concept_synonym", "concept", primary_key: "concept_id", name: "fpk_concept_synonym_concept"
  add_foreign_key "condition_era", "concept", column: "condition_concept_id", primary_key: "concept_id", name: "fpk_condition_era_concept"
  add_foreign_key "condition_era", "person", primary_key: "person_id", name: "fpk_condition_era_person"
  add_foreign_key "condition_occurrence", "concept", column: "condition_concept_id", primary_key: "concept_id", name: "fpk_condition_concept"
  add_foreign_key "condition_occurrence", "concept", column: "condition_source_concept_id", primary_key: "concept_id", name: "fpk_condition_concept_s"
  add_foreign_key "condition_occurrence", "concept", column: "condition_status_concept_id", primary_key: "concept_id", name: "fpk_condition_status_concept"
  add_foreign_key "condition_occurrence", "concept", column: "condition_type_concept_id", primary_key: "concept_id", name: "fpk_condition_type_concept"
  add_foreign_key "condition_occurrence", "person", primary_key: "person_id", name: "fpk_condition_person"
  add_foreign_key "condition_occurrence", "provider", primary_key: "provider_id", name: "fpk_condition_provider"
  add_foreign_key "condition_occurrence", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_condition_visit"
  add_foreign_key "cost", "concept", column: "currency_concept_id", primary_key: "concept_id", name: "fpk_visit_cost_currency"
  add_foreign_key "cost", "concept", column: "drg_concept_id", primary_key: "concept_id", name: "fpk_drg_concept"
  add_foreign_key "cost", "payer_plan_period", primary_key: "payer_plan_period_id", name: "fpk_visit_cost_period"
  add_foreign_key "death", "concept", column: "cause_concept_id", primary_key: "concept_id", name: "fpk_death_cause_concept"
  add_foreign_key "death", "concept", column: "cause_source_concept_id", primary_key: "concept_id", name: "fpk_death_cause_concept_s"
  add_foreign_key "death", "concept", column: "death_type_concept_id", primary_key: "concept_id", name: "fpk_death_type_concept"
  add_foreign_key "death", "person", primary_key: "person_id", name: "fpk_death_person"
  add_foreign_key "device_exposure", "concept", column: "device_concept_id", primary_key: "concept_id", name: "fpk_device_concept"
  add_foreign_key "device_exposure", "concept", column: "device_source_concept_id", primary_key: "concept_id", name: "fpk_device_concept_s"
  add_foreign_key "device_exposure", "concept", column: "device_type_concept_id", primary_key: "concept_id", name: "fpk_device_type_concept"
  add_foreign_key "device_exposure", "person", primary_key: "person_id", name: "fpk_device_person"
  add_foreign_key "device_exposure", "provider", primary_key: "provider_id", name: "fpk_device_provider"
  add_foreign_key "device_exposure", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_device_visit"
  add_foreign_key "domain", "concept", column: "domain_concept_id", primary_key: "concept_id", name: "fpk_domain_concept"
  add_foreign_key "dose_era", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_dose_era_concept"
  add_foreign_key "dose_era", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_dose_era_unit_concept"
  add_foreign_key "dose_era", "person", primary_key: "person_id", name: "fpk_dose_era_person"
  add_foreign_key "drug_era", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_era_concept"
  add_foreign_key "drug_era", "person", primary_key: "person_id", name: "fpk_drug_era_person"
  add_foreign_key "drug_exposure", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_concept"
  add_foreign_key "drug_exposure", "concept", column: "drug_source_concept_id", primary_key: "concept_id", name: "fpk_drug_concept_s"
  add_foreign_key "drug_exposure", "concept", column: "drug_type_concept_id", primary_key: "concept_id", name: "fpk_drug_type_concept"
  add_foreign_key "drug_exposure", "concept", column: "route_concept_id", primary_key: "concept_id", name: "fpk_drug_route_concept"
  add_foreign_key "drug_exposure", "person", primary_key: "person_id", name: "fpk_drug_person"
  add_foreign_key "drug_exposure", "provider", primary_key: "provider_id", name: "fpk_drug_provider"
  add_foreign_key "drug_exposure", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_drug_visit"
  add_foreign_key "drug_strength", "concept", column: "amount_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_unit_1"
  add_foreign_key "drug_strength", "concept", column: "denominator_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_unit_3"
  add_foreign_key "drug_strength", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_concept_1"
  add_foreign_key "drug_strength", "concept", column: "ingredient_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_concept_2"
  add_foreign_key "drug_strength", "concept", column: "numerator_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_unit_2"
  add_foreign_key "fact_relationship", "concept", column: "domain_concept_id_1", primary_key: "concept_id", name: "fpk_fact_domain_1"
  add_foreign_key "fact_relationship", "concept", column: "domain_concept_id_2", primary_key: "concept_id", name: "fpk_fact_domain_2"
  add_foreign_key "fact_relationship", "concept", column: "relationship_concept_id", primary_key: "concept_id", name: "fpk_fact_relationship"
  add_foreign_key "measurement", "concept", column: "measurement_concept_id", primary_key: "concept_id", name: "fpk_measurement_concept"
  add_foreign_key "measurement", "concept", column: "measurement_source_concept_id", primary_key: "concept_id", name: "fpk_measurement_concept_s"
  add_foreign_key "measurement", "concept", column: "measurement_type_concept_id", primary_key: "concept_id", name: "fpk_measurement_type_concept"
  add_foreign_key "measurement", "concept", column: "operator_concept_id", primary_key: "concept_id", name: "fpk_measurement_operator"
  add_foreign_key "measurement", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_measurement_unit"
  add_foreign_key "measurement", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_measurement_value"
  add_foreign_key "measurement", "person", primary_key: "person_id", name: "fpk_measurement_person"
  add_foreign_key "measurement", "provider", primary_key: "provider_id", name: "fpk_measurement_provider"
  add_foreign_key "measurement", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_measurement_visit"
  add_foreign_key "note", "concept", column: "encoding_concept_id", primary_key: "concept_id", name: "fpk_note_encoding_concept"
  add_foreign_key "note", "concept", column: "language_concept_id", primary_key: "concept_id", name: "fpk_language_concept"
  add_foreign_key "note", "concept", column: "note_class_concept_id", primary_key: "concept_id", name: "fpk_note_class_concept"
  add_foreign_key "note", "concept", column: "note_type_concept_id", primary_key: "concept_id", name: "fpk_note_type_concept"
  add_foreign_key "note_nlp", "concept", column: "note_nlp_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_concept"
  add_foreign_key "note_nlp", "concept", column: "section_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_section_concept"
  add_foreign_key "note_nlp", "note", primary_key: "note_id", name: "fpk_note_nlp_note"
  add_foreign_key "observation", "concept", column: "observation_concept_id", primary_key: "concept_id", name: "fpk_observation_concept"
  add_foreign_key "observation", "concept", column: "observation_source_concept_id", primary_key: "concept_id", name: "fpk_observation_concept_s"
  add_foreign_key "observation", "concept", column: "observation_type_concept_id", primary_key: "concept_id", name: "fpk_observation_type_concept"
  add_foreign_key "observation", "concept", column: "qualifier_concept_id", primary_key: "concept_id", name: "fpk_observation_qualifier"
  add_foreign_key "observation", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_observation_unit"
  add_foreign_key "observation", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_observation_value"
  add_foreign_key "observation", "person", primary_key: "person_id", name: "fpk_observation_person"
  add_foreign_key "observation", "provider", primary_key: "provider_id", name: "fpk_observation_provider"
  add_foreign_key "observation", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_observation_visit"
  add_foreign_key "observation_period", "concept", column: "period_type_concept_id", primary_key: "concept_id", name: "fpk_observation_period_concept"
  add_foreign_key "observation_period", "person", primary_key: "person_id", name: "fpk_observation_period_person"
  add_foreign_key "payer_plan_period", "person", primary_key: "person_id", name: "fpk_payer_plan_period"
  add_foreign_key "person", "care_site", primary_key: "care_site_id", name: "fpk_person_care_site"
  add_foreign_key "person", "concept", column: "ethnicity_concept_id", primary_key: "concept_id", name: "fpk_person_ethnicity_concept"
  add_foreign_key "person", "concept", column: "ethnicity_source_concept_id", primary_key: "concept_id", name: "fpk_person_ethnicity_concept_s"
  add_foreign_key "person", "concept", column: "gender_concept_id", primary_key: "concept_id", name: "fpk_person_gender_concept"
  add_foreign_key "person", "concept", column: "gender_source_concept_id", primary_key: "concept_id", name: "fpk_person_gender_concept_s"
  add_foreign_key "person", "concept", column: "race_concept_id", primary_key: "concept_id", name: "fpk_person_race_concept"
  add_foreign_key "person", "concept", column: "race_source_concept_id", primary_key: "concept_id", name: "fpk_person_race_concept_s"
  add_foreign_key "person", "location", primary_key: "location_id", name: "fpk_person_location"
  add_foreign_key "person", "provider", primary_key: "provider_id", name: "fpk_person_provider"
  add_foreign_key "procedure_occurrence", "concept", column: "modifier_concept_id", primary_key: "concept_id", name: "fpk_procedure_modifier"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_type_concept_id", primary_key: "concept_id", name: "fpk_procedure_type_concept"
  add_foreign_key "provider", "care_site", primary_key: "care_site_id", name: "fpk_provider_care_site"
  add_foreign_key "provider", "concept", column: "gender_concept_id", primary_key: "concept_id", name: "fpk_provider_gender"
  add_foreign_key "provider", "concept", column: "gender_source_concept_id", primary_key: "concept_id", name: "fpk_provider_gender_s"
  add_foreign_key "provider", "concept", column: "specialty_source_concept_id", primary_key: "concept_id", name: "fpk_provider_specialty_s"
  add_foreign_key "relationship", "concept", column: "relationship_concept_id", primary_key: "concept_id", name: "fpk_relationship_concept"
  add_foreign_key "relationship", "relationship", column: "reverse_relationship_id", primary_key: "relationship_id", name: "fpk_relationship_reverse"
  add_foreign_key "source_to_concept_map", "concept", column: "target_concept_id", primary_key: "concept_id", name: "fpk_source_to_concept_map_c_1"
  add_foreign_key "source_to_concept_map", "vocabulary", column: "source_vocabulary_id", primary_key: "vocabulary_id", name: "fpk_source_to_concept_map_v_1"
  add_foreign_key "source_to_concept_map", "vocabulary", column: "target_vocabulary_id", primary_key: "vocabulary_id", name: "fpk_source_to_concept_map_v_2"
  add_foreign_key "specimen", "concept", column: "anatomic_site_concept_id", primary_key: "concept_id", name: "fpk_specimen_site_concept"
  add_foreign_key "specimen", "concept", column: "disease_status_concept_id", primary_key: "concept_id", name: "fpk_specimen_status_concept"
  add_foreign_key "specimen", "concept", column: "specimen_concept_id", primary_key: "concept_id", name: "fpk_specimen_concept"
  add_foreign_key "specimen", "concept", column: "specimen_type_concept_id", primary_key: "concept_id", name: "fpk_specimen_type_concept"
  add_foreign_key "specimen", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_specimen_unit_concept"
  add_foreign_key "specimen", "person", primary_key: "person_id", name: "fpk_specimen_person"
  add_foreign_key "visit_detail", "care_site", primary_key: "care_site_id", name: "fpk_v_detail_care_site"
  add_foreign_key "visit_detail", "concept", column: "admitting_source_concept_id", primary_key: "concept_id", name: "fpk_v_detail_admitting_s"
  add_foreign_key "visit_detail", "concept", column: "discharge_to_concept_id", primary_key: "concept_id", name: "fpk_v_detail_discharge"
  add_foreign_key "visit_detail", "concept", column: "visit_source_concept_id", primary_key: "concept_id", name: "fpk_v_detail_concept_s"
  add_foreign_key "visit_detail", "concept", column: "visit_type_concept_id", primary_key: "concept_id", name: "fpk_v_detail_type_concept"
  add_foreign_key "visit_detail", "person", primary_key: "person_id", name: "fpk_v_detail_person"
  add_foreign_key "visit_detail", "provider", primary_key: "provider_id", name: "fpk_v_detail_provider"
  add_foreign_key "visit_detail", "visit_detail", column: "preceding_visit_detail_id", primary_key: "visit_detail_id", name: "fpk_v_detail_preceding"
  add_foreign_key "visit_detail", "visit_detail", column: "visit_detail_parent_id", primary_key: "visit_detail_id", name: "fpk_v_detail_parent"
  add_foreign_key "visit_detail", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpd_v_detail_visit"
  add_foreign_key "visit_occurrence", "concept", column: "admitting_source_concept_id", primary_key: "concept_id", name: "fpk_visit_admitting_s"
  add_foreign_key "visit_occurrence", "concept", column: "discharge_to_concept_id", primary_key: "concept_id", name: "fpk_visit_discharge"
  add_foreign_key "visit_occurrence", "concept", column: "visit_source_concept_id", primary_key: "concept_id", name: "fpk_visit_concept_s"
  add_foreign_key "visit_occurrence", "concept", column: "visit_type_concept_id", primary_key: "concept_id", name: "fpk_visit_type_concept"
  add_foreign_key "visit_occurrence", "visit_occurrence", column: "preceding_visit_occurrence_id", primary_key: "visit_occurrence_id", name: "fpk_visit_preceding"
  add_foreign_key "vocabulary", "concept", column: "vocabulary_concept_id", primary_key: "concept_id", name: "fpk_vocabulary_concept"
end
