require './lib/omop_abstractor_nlp_mapper/document'
class NoteStableIdentifier < ApplicationRecord
  include Abstractor::Abstractable
  self.table_name = 'note_stable_identifier'

  scope :search_across_fields, ->(search_token, providers, secondary_providers, provider_specialties, secondary_provider_specialties, options={}) do
    if search_token
      search_token.downcase!
    end
    options = { sort_column: 'note_date', sort_direction: 'asc' }.merge(options)

    s = joins('JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
               JOIN note ON note_stable_identifier_full.note_id = note.note_id
               JOIN concept AS note_type ON note.note_type_concept_id = note_type.concept_id
               JOIN person ON note.person_id = person.person_id
               LEFT JOIN pii_name ON person.person_id = pii_name.person_id
               ')
    s = s.select('note_stable_identifier.id, note.*, note_type.concept_name AS note_type, pii_name.first_name, pii_name.last_name, note_stable_identifier.stable_identifier_path, note_stable_identifier.stable_identifier_value')
    if search_token
      s = s.where(["lower(note.note_title) like ? OR lower(note.note_text) like ? OR lower(note_type.concept_name) like ? OR lower(pii_name.first_name) like ? OR lower(pii_name.last_name) like ? OR EXISTS (SELECT 1 FROM pii_mrn WHERE person.person_id = pii_mrn.person_id AND pii_mrn.mrn like ?)", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%","%#{search_token}%", "%#{search_token}%","%#{search_token}%"])
    end

    if providers.present?
      provider_ids = Provider.where("provider_name IN(?)",  providers).pluck(:provider_id)

      s = s.where("EXISTS (SELECT 1
                     FROM fact_relationship JOIN procedure_occurrence ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790 AND fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id
                               JOIN provider ON procedure_occurrence.provider_id = provider.provider_id
                     WHERE provider.provider_id in (?))", provider_ids)
    end

    if secondary_providers.present?
      provider_ids = Provider.where("provider_name IN(?)",  secondary_providers).pluck(:provider_id)
      s = s.where("EXISTS (SELECT 1
                     FROM fact_relationship JOIN procedure_occurrence ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790 AND fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id
                               JOIN fact_relationship AS fr2 ON fr2.domain_concept_id_1 = 10 AND fr2.fact_id_1 = procedure_occurrence.procedure_occurrence_id AND fr2.relationship_concept_id = 44818888
                               JOIN procedure_occurrence pr2 ON fr2.domain_concept_id_2 = 10 AND fr2.fact_id_2 = pr2.procedure_occurrence_id
                               JOIN provider ON pr2.provider_id = provider.provider_id
                     WHERE provider.provider_id in (?))", provider_ids)
    end

    if provider_specialties.present?
      s = s.where("EXISTS (SELECT 1
                     FROM fact_relationship JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
                               JOIN provider ON procedure_occurrence.provider_id = provider.provider_id
                     WHERE provider.specialty_concept_id in (?))", provider_specialties)
    end

    if secondary_provider_specialties.present?
      s = s.where("EXISTS (SELECT 1
                     FROM fact_relationship JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
                               JOIN fact_relationship AS fr2 ON fr2.domain_concept_id_1 = 10 AND fr2.fact_id_1 = procedure_occurrence.procedure_occurrence_id AND fr2.relationship_concept_id = 44818888
                               JOIN procedure_occurrence pr2 ON fr2.domain_concept_id_2 = 10 AND fr2.fact_id_2 = pr2.procedure_occurrence_id AND procedure_occurrence.procedure_occurrence_id != pr2.procedure_occurrence_id
                               JOIN provider ON pr2.provider_id = provider.provider_id
                     WHERE provider.specialty_concept_id in (?))", secondary_provider_specialties)
    end

    sort = options[:sort_column] + ' ' + options[:sort_direction] + ', note.note_id ASC'
    s = s.nil? ? order(sort) : s.order(sort)

    s
  end

  scope :having_not_applicable_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil }.merge(options)

    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first

      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id = ?
                      WHERE aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) = TRUE)
            )", options[:namespace_type], options[:namespace_id],  abstractor_abstraction_schema_id_has_cancer_site)
    end
  end

  scope :having_unknown_suggested_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)
    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id = ?
                                                      JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id
                      WHERE sug.deleted_at IS NULL
                      AND aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND sug.unknown = true
                      AND sug.accepted IS NULL
                      )
            )", options[:namespace_type], options[:namespace_id],  abstractor_abstraction_schema_id_has_cancer_site)
    end
  end

  scope :having_accepted_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if options[:abstractor_site].any?
        abstractor_object_values_has_cancer_site = options[:abstractor_site]
      else
        abstractor_object_values_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
      end

      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id = ?
                                                      JOIN abstractor_abstraction_object_values aaov ON aa.id = aaov.abstractor_abstraction_id
                                                      JOIN abstractor_object_values aov ON aaov.abstractor_object_value_id = aov.id
                      WHERE aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) != TRUE
                      AND aa.value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id],  abstractor_abstraction_schema_id_has_cancer_site, abstractor_object_values_has_cancer_site, options[:favor_more_specific])
    end
  end

  scope :not_having_accepted_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if options[:abstractor_site].any?
        abstractor_object_values_has_cancer_site = options[:abstractor_site]
      else
        abstractor_object_values_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
      end

      where("(NOT EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id = ?
                                                      JOIN abstractor_abstraction_object_values aaov ON aa.id = aaov.abstractor_abstraction_id
                                                      JOIN abstractor_object_values aov ON aaov.abstractor_object_value_id = aov.id
                      WHERE aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) != TRUE
                      AND aa.value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id],  abstractor_abstraction_schema_id_has_cancer_site, abstractor_object_values_has_cancer_site, options[:favor_more_specific])
    end
  end

  scope :having_suggested_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)
    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if options[:abstractor_site].any?
        abstractor_object_values_has_cancer_site = options[:abstractor_site]
      else
        abstractor_object_values_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
      end

      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id = ?
                                                      JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id
                                                      JOIN abstractor_suggestion_object_values asov ON sug.id = asov.abstractor_suggestion_id
                                                      JOIN abstractor_object_values aov ON asov.abstractor_object_value_id = aov.id
                      WHERE sug.deleted_at IS NULL
                      AND aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) != TRUE
                      AND COALESCE(aa.value, '') = ''
                      AND sug.suggested_value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id],  abstractor_abstraction_schema_id_has_cancer_site, abstractor_object_values_has_cancer_site, options[:favor_more_specific])
    end
  end

  scope :having_not_applicable_suggested_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)
    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if options[:abstractor_site].any?
        abstractor_object_values_has_cancer_site = options[:abstractor_site]
      else
        abstractor_object_values_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
      end

      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id = ?
                                                      JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id
                                                      JOIN abstractor_suggestion_object_values asov ON sug.id = asov.abstractor_suggestion_id
                                                      JOIN abstractor_object_values aov ON asov.abstractor_object_value_id = aov.id
                      WHERE sug.deleted_at IS NULL
                      AND aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) = TRUE
                      AND COALESCE(aa.value, '') = ''
                      AND sug.suggested_value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id],  abstractor_abstraction_schema_id_has_cancer_site, abstractor_object_values_has_cancer_site, options[:favor_more_specific])
    end
  end

  scope :having_site, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    case options[:abstractor_site_status]
    when Note::ABSTRACTOR_SITE_STATUS_ACCEPTED_SITE
      having_accepted_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_ACCEPTED_SPECIFIC_SITE
      options[:favor_more_specific] = [false]
      having_accepted_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_ACCEPTED_GENERAL_SITE
      options[:favor_more_specific] = [true]
      having_accepted_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_SUGGESTED_SITE
      having_suggested_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_SUGGESTED_SPECIFIC_SITE
      options[:favor_more_specific] = [false]
      having_suggested_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_SUGGESTED_GENERAL_SITE
      options[:favor_more_specific] = [true]
      having_suggested_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_NOT_APPLICABLE
      having_not_applicable_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_NOT_APPLICABLE_SUGGESTED
      having_not_applicable_suggested_site(options).not_having_accepted_site(options)
    when Note::ABSTRACTOR_SITE_STATUS_UNKNOWN_SUGGESTED
      having_unknown_suggested_site(options)
    end
  end

  scope :having_not_applicable_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first

      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN(?)
                      WHERE aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) = TRUE)
            )", options[:namespace_type], options[:namespace_id], [abstractor_abstraction_schema_id_has_cancer_histology, abstractor_abstraction_schema_id_has_metastatic_cancer_histology])
    end
  end

  scope :having_accepted_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if !options[:abstractor_histology].blank?
        abstractor_object_values_has_cancer_histology = options[:abstractor_histology]
      else
        abstractor_object_values_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
        abstractor_object_values_has_cancer_histology.concat(Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value))
      end

      where("(EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN(?)
                                                      JOIN abstractor_abstraction_object_values aaov ON aa.id = aaov.abstractor_abstraction_id
                                                      JOIN abstractor_object_values aov ON aaov.abstractor_object_value_id = aov.id
                      WHERE aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) != TRUE
                      AND aa.value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id], [abstractor_abstraction_schema_id_has_cancer_histology, abstractor_abstraction_schema_id_has_metastatic_cancer_histology], abstractor_object_values_has_cancer_histology, options[:favor_more_specific])
    end
  end

  scope :no_having_accepted_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if !options[:abstractor_histology].blank?
        abstractor_object_values_has_cancer_histology = options[:abstractor_histology]
      else
        abstractor_object_values_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
        abstractor_object_values_has_cancer_histology.concat(Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value))
      end

      where("(NOT EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN(?)
                                                      JOIN abstractor_abstraction_object_values aaov ON aa.id = aaov.abstractor_abstraction_id
                                                      JOIN abstractor_object_values aov ON aaov.abstractor_object_value_id = aov.id
                      WHERE aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) != TRUE
                      AND aa.value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id], [abstractor_abstraction_schema_id_has_cancer_histology, abstractor_abstraction_schema_id_has_metastatic_cancer_histology], abstractor_object_values_has_cancer_histology, options[:favor_more_specific])
    end
  end

  scope :having_unknown_suggested_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)
    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      where("(
              EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN(?)
                                                      JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id
                      WHERE sug.deleted_at IS NULL
                      AND aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND sug.unknown = true
                      AND sug.accepted IS NULL
                      )
            )", options[:namespace_type], options[:namespace_id], [abstractor_abstraction_schema_id_has_cancer_histology, abstractor_abstraction_schema_id_has_metastatic_cancer_histology])
    end
  end

  scope :having_suggested_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)
    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if !options[:abstractor_histology].blank?
        abstractor_object_values_has_cancer_histology = options[:abstractor_histology]
      else
        abstractor_object_values_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
        abstractor_object_values_has_cancer_histology.concat(Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value))
      end

      where("(
              EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN(?)
                                                      JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id
                                                      JOIN abstractor_suggestion_object_values asov ON sug.id = asov.abstractor_suggestion_id
                                                      JOIN abstractor_object_values aov ON asov.abstractor_object_value_id = aov.id
                      WHERE sug.deleted_at IS NULL
                      AND aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) != TRUE
                      AND COALESCE(aa.value, '') = ''
                      AND sug.suggested_value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id], [abstractor_abstraction_schema_id_has_cancer_histology, abstractor_abstraction_schema_id_has_metastatic_cancer_histology], abstractor_object_values_has_cancer_histology, options[:favor_more_specific])
    end
  end

  scope :having_not_applicable_suggested_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)
    if options[:namespace_type] || options[:namespace_id]
      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      if !options[:abstractor_histology].blank?
        abstractor_object_values_has_cancer_histology = options[:abstractor_histology]
      else
        abstractor_object_values_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value)
        abstractor_object_values_has_cancer_histology.concat(Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", options[:namespace_type], options[:namespace_id]).select('DISTINCT abstractor_object_values.value').map(&:value))
      end

      where("(
              EXISTS (
                      SELECT 1
                      FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN(?)
                                                      JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id
                                                      JOIN abstractor_suggestion_object_values asov ON sug.id = asov.abstractor_suggestion_id
                                                      JOIN abstractor_object_values aov ON asov.abstractor_object_value_id = aov.id
                      WHERE sug.deleted_at IS NULL
                      AND aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND #{self.table_name}.id = aa.about_id
                      AND COALESCE(aa.not_applicable, FALSE) = TRUE
                      AND COALESCE(aa.value, '') = ''
                      AND sug.suggested_value IN(?)
                      AND COALESCE(aov.favor_more_specific, FALSE) IN(?))
            )", options[:namespace_type], options[:namespace_id], [abstractor_abstraction_schema_id_has_cancer_histology, abstractor_abstraction_schema_id_has_metastatic_cancer_histology], abstractor_object_values_has_cancer_histology, options[:favor_more_specific])
    end
  end

  scope :having_histology, ->(options={}) do
    options = { namespace_type: nil, namespace_id: nil, favor_more_specific: [true, false] }.merge(options)

    case options[:abstractor_histology_status]
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_HISTOLOGY
      having_accepted_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_SPECIFIC_HISTOLOGY
      options[:favor_more_specific] = [false]
      having_accepted_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_GENERAL_HISTOLOGY
      options[:favor_more_specific] = [true]
      having_accepted_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_HISTOLOGY
      having_suggested_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_SPECIFIC_HISTOLOGY
      options[:favor_more_specific] = [false]
      having_suggested_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_GENERAL_HISTOLOGY
      options[:favor_more_specific] = [true]
      having_suggested_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_NOT_APPLICABLE
      having_not_applicable_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_NOT_APPLICABLE_SUGGESTED
      having_not_applicable_suggested_histology(options).not_having_accepted_histology(options)
    when Note::ABSTRACTOR_HISTOLOGY_STATUS_UNKNOWN_SUGGESTED
      having_unknown_suggested_histology(options)
    end
  end

  scope :by_note_date, ->(date_from, date_to) do
    if (!date_from.blank? && !date_to.blank?)
      date_range = [date_from, date_to]
    else
      date_range = []
    end

    unless (date_range.first.blank? || date_range.last.blank?)
      where("note_date BETWEEN ? AND ?", Date.parse(date_range.first), (Date.parse(date_range.last) +1).to_s)
    end
  end

  scope :with_note, -> do
    joins('JOIN note_stable_identifier_full ON note_stable_identifier_full.stable_identifier_path = note_stable_identifier.stable_identifier_path AND note_stable_identifier_full.stable_identifier_value = note_stable_identifier.stable_identifier_value JOIN note ON note_stable_identifier_full.note_id = note.note_id')
  end

  def note_text
    if note.present?
      note.note_text
    end
  end

  def note
    Note.joins('JOIN note_stable_identifier_full ON note.note_id = note_stable_identifier_full.note_id').where('note_stable_identifier_full.stable_identifier_path = ? AND note_stable_identifier_full.stable_identifier_value = ?', self.stable_identifier_path, self.stable_identifier_value).first
  end

  def process_abstractor_suggestions(document)
    puts 'Begin NOTE.note_id'
    puts self.note.note_id
    puts 'End NOTE.note_id'
    omop_abstractor_nlp_document = OmopAbstractorNlpMapper::Document.new(document, self.note_text)

    puts 'how many sections at the beginning?'
    puts omop_abstractor_nlp_document.sections.length

    sections_grouped = omop_abstractor_nlp_document.sections.group_by do |section|
     section.name
    end

    bad_guy_sections = []
    sections_grouped.each do |section_name, sections|
     if section_name == 'SPECIMEN'
       previous_section_trigger = sections.first.trigger
       sections.each_with_index do |section, i|
         puts 'section token'
         puts section.to_s
         puts 'trigger'
         puts section.trigger

         if section.trigger.blank?
           bad_guy_sections << section
         elsif i > 0 && section.trigger.downcase <= previous_section_trigger.downcase
           # puts 'bingo'
           bad_guy_sections << section
         else
           # puts 'bango'
           previous_section_trigger = section.trigger
         end
       end
     end
    end

    #Remove all 'specimen' sections after the first 'comment' section.
    bad_guy_sections.each do |bad_guy_section|
     omop_abstractor_nlp_document.sections.reject! { |section| section == bad_guy_section }
    end

    sections_grouped = omop_abstractor_nlp_document.sections.group_by do |section|
      section.name
    end

    if !sections_grouped['SPECIMEN'].nil? && !sections_grouped['COMMENT'].nil?
     bad_guy_sections = []
     sections_grouped['SPECIMEN'].each do |specimen_section|
       if sections_grouped['COMMENT'][0].section_begin < specimen_section.section_begin
         bad_guy_sections << specimen_section
       end
     end
    end

    bad_guy_sections.each do |bad_guy_section|
     omop_abstractor_nlp_document.sections.reject! { |section| section == bad_guy_section  }
    end

    sections_grouped = omop_abstractor_nlp_document.sections.group_by do |section|
     section.name
    end

    #Derive a synthetic 'specimen' section for those pathology reports that have no specimen callout but do have a section 'before' a comment section.
    if sections_grouped['SPECIMEN'].nil? && !sections_grouped['COMMENT'].nil?
      # puts "we are adding!"
      omop_abstractor_nlp_document.add_named_entity(0, sections_grouped['COMMENT'][0].section_begin-2, 'SPECIMEN', nil, nil, 'present', true, 0, 0)
    end

    #Derive a synthetic 'specimen' section for those pathology reports that have no specimen callout and no comment section.
    if sections_grouped['SPECIMEN'].nil? && sections_grouped['COMMENT'].nil?
      # puts "we are adding!"
      omop_abstractor_nlp_document.add_named_entity(0, omop_abstractor_nlp_document.text.length, 'SPECIMEN', nil, nil, 'present', true, 0, 0)
    end

    ActiveRecord::Base.transaction do
      # Partition suggestions by section within an abstractor subject group based on the anchor schema.
      # Do not repeat anchor suggestions across multiple sections.
      section_abstractor_abstraction_group_map = {}
      if omop_abstractor_nlp_document.sections.any?
       self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
         # puts 'hello'
         # puts abstractor_abstraction_group.abstractor_subject_group.name

         if abstractor_abstraction_group.anchor?
           # puts 'we have an anchor'
           anchor_predicate = abstractor_abstraction_group.anchor.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
           anchor_sections = []
           abstractor_abstraction_group.anchor.abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.each do |abstractor_abstraction_source|
             abstractor_abstraction_source.abstractor_abstraction_source_sections.each do |abstractor_abstraction_source_section|
               anchor_sections << abstractor_abstraction_source_section.abstractor_section.name
             end
           end
           anchor_sections.uniq!
           anchor_named_entities = omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == anchor_predicate && !named_entity.negated? && named_entity.sentence.section && anchor_sections.include?(named_entity.sentence.section.name) }
           anchor_named_entity_sections = anchor_named_entities.group_by{ |anchor_named_entity|  anchor_named_entity.sentence.section.section_range }.keys.sort_by(&:min)

           first_anchor_named_entity_section = anchor_named_entity_sections.shift
           if section_abstractor_abstraction_group_map[first_anchor_named_entity_section]
             section_abstractor_abstraction_group_map[first_anchor_named_entity_section] << abstractor_abstraction_group
           else
             # puts 'in the digs'
             section_abstractor_abstraction_group_map[first_anchor_named_entity_section] = [abstractor_abstraction_group]
           end

           anchor_named_entities = omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == anchor_predicate && named_entity.sentence.section && named_entity.sentence.section.section_range == first_anchor_named_entity_section }

           abstractor_namespace = Abstractor::AbstractorNamespace.find(omop_abstractor_nlp_document.namespace_id)
           biopsy = false
           if ['Surgical Pathology Biopsy', 'Outside Surgical Pathology Biopsy'].include?(abstractor_namespace.name)
             biopsy = true
           end

           prior_anchor_named_entities = []
           prior_anchor_named_entities << anchor_named_entities.map(&:semantic_tag_value).sort
           for anchor_named_entity_section in anchor_named_entity_sections
             anchor_named_entities = omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == anchor_predicate && named_entity.sentence.section && named_entity.sentence.section.section_range == anchor_named_entity_section }
             if prior_anchor_named_entities.none?(anchor_named_entities.map(&:semantic_tag_value).sort) || biopsy
               abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.create_abstractor_abstraction_group(abstractor_abstraction_group.abstractor_subject_group_id, self.class.to_s, self.id, omop_abstractor_nlp_document.namespace_type, omop_abstractor_nlp_document.namespace_id)

               if section_abstractor_abstraction_group_map[anchor_named_entity_section]
                 section_abstractor_abstraction_group_map[anchor_named_entity_section] << abstractor_abstraction_group
               else
                 section_abstractor_abstraction_group_map[anchor_named_entity_section] = [abstractor_abstraction_group]
               end

               abstractor_abstraction_group.abstractor_abstraction_group_members.each do |abstractor_abstraction_group_member|
                 abstractor_abstraction_source = abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first
                 abstractor_abstraction = abstractor_abstraction_group_member.abstractor_abstraction
                 abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                 abstractor_abstraction_group_member.abstractor_abstraction,
                 abstractor_abstraction_source,
                 nil, #suggestion_source[:match_value],
                 nil, #suggestion_source[:sentence_match_value]
                 self.id,
                 self.class.to_s,
                 'note_text',
                 nil,                                  #suggestion_source[:section_name]
                 nil,                                  #suggestion[:value]
                 false,                                #suggestion[:unknown].to_s.to_boolean
                 true,                                 #suggestion[:not_applicable].to_s.to_boolean
                 nil,
                 nil,
                 false                                 #suggestion[:negated].to_s.to_boolean
                 )

                 #save so this suggestion gets saved first
                 #abstractor_abstraction.save!
                 abstractor_suggestion.save!
               end
               prior_anchor_named_entities << anchor_named_entities.map(&:semantic_tag_value).sort
             end
           end
         end
       end
      end

      # puts 'Need to be better'
      puts section_abstractor_abstraction_group_map
      # puts 'Going to be better'

      self.abstractor_abstractions_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).order('created_at ASC').each do |abstractor_abstraction|
       # puts abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
       abstractor_abstraction_source = abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first
       abstractor_abstraction_schema = abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema

       abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
       abstractor_abstraction,
       abstractor_abstraction_source,
       nil, #suggestion_source[:match_value],
       nil, #suggestion_source[:sentence_match_value]
       self.id,
       self.class.to_s,
       'note_text',
       nil,                                  #suggestion_source[:section_name]
       nil,                                  #suggestion[:value]
       false,                                #suggestion[:unknown].to_s.to_boolean
       true,                                 #suggestion[:not_applicable].to_s.to_boolean
       nil,
       nil,
       false                                 #suggestion[:negated].to_s.to_boolean
       )
       #save so this suggestion gets saved first
       # abstractor_abstraction.save!
       abstractor_suggestion.save!

       # ABSTRACTOR_RULE_TYPE_UNKNOWN = 'unknown'
       case abstractor_abstraction_source.abstractor_rule_type.name
       when Abstractor::Enum::ABSTRACTOR_RULE_TYPE_VALUE
         # puts 'what the hell?'
         # puts omop_abstractor_nlp_document.named_entities.size
         # omop_abstractor_nlp_document.named_entities. each do |named_entity|
         #   puts named_entity
         # end
         #
         named_entities = omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate }

         if abstractor_abstraction.abstractor_subject.abstractor_subject_group.name == 'Metastatic Cancer'
           if abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_site' && named_entities.empty?
             named_entities.concat(omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_value_type == 'value' && named_entity.semantic_tag_attribute == 'has_metastatic_cancer_primary_site' })
           end
         end

         puts 'here is the predicate'
         puts abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
         puts 'how much you got?'
         puts named_entities.size
         suggested = false
         if named_entities.any?
           named_entities.each do |named_entity|
             abstractor_abstraction.reload
             puts 'here is the note'
             puts omop_abstractor_nlp_document.text

             puts 'named_entity_begin'
             puts named_entity.named_entity_begin
             puts 'named_entity_end'
             puts named_entity.named_entity_end

             puts 'sentence_begin'
             puts named_entity.sentence.sentence_begin
             puts 'sentence_end'
             puts named_entity.sentence.sentence_end

             puts 'match_value'
             puts omop_abstractor_nlp_document.text[named_entity.named_entity_begin..named_entity.named_entity_end]
             puts 'sentence_match_value'
             puts omop_abstractor_nlp_document.text[named_entity.sentence.sentence_begin..named_entity.sentence.sentence_end]

             puts 'here is the sentence'
             puts named_entity.sentence

             puts 'here is the section'
             puts named_entity.sentence.section

             puts 'named_entity.document.sections.size'
             puts named_entity.document.sections.size

             puts 'named_entity.document.section_named_entities.size'
             puts named_entity.document.section_named_entities.size

             named_entity.document.section_named_entities.each do |named_entity|
               puts 'named_entity.named_entity_begin'
               puts named_entity.named_entity_begin
               puts 'named_entity.named_entity_end'
               puts named_entity.named_entity_end
               puts 'named_entity.semantic_tag_attribute'
               puts named_entity.semantic_tag_attribute
             end

             named_entity.document.sections.each do |section|
               puts 'section.section_begin'
               puts section.section_begin
               puts 'section.section_end'
               puts section.section_end
             end

             puts 'how many sections?'
             puts named_entity.document.sections.length

             puts 'how many sections on the doucment?'
             puts omop_abstractor_nlp_document.sections.length

             puts 'do we have a section?'
             puts named_entity.sentence.section.present?

             section_name = nil
             aa = abstractor_abstraction
             if named_entity.sentence.section.present?
               puts 'step 1'
               puts named_entity.sentence.section.section_range
               puts 'more'
               puts section_abstractor_abstraction_group_map
               if section_abstractor_abstraction_group_map[named_entity.sentence.section.section_range].present?
                 puts 'step 2'
                 section_abstractor_abstraction_group_map[named_entity.sentence.section.section_range].each do |abstractor_abstraction_group|
                   abstractor_abstraction_group.abstractor_abstraction_group_members.each do |abstractor_abstraction_group_member|
                     if abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == named_entity.semantic_tag_attribute
                       puts 'hello ninny!'
                       puts named_entity.semantic_tag_attribute
                       aa = abstractor_abstraction_group_member.abstractor_abstraction
                       section_name = named_entity.sentence.section.name

                       suggested_value = named_entity.semantic_tag_value.gsub(' , ', ',')
                       suggested_value = suggested_value.gsub(' - ', '-')

                       abstractor_suggestion = aa.abstractor_subject.suggest(
                       aa,
                       abstractor_abstraction_source,
                       omop_abstractor_nlp_document.text[named_entity.named_entity_begin..named_entity.named_entity_end], #suggestion_source[:match_value],
                       omop_abstractor_nlp_document.text[named_entity.sentence.sentence_begin..named_entity.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                       self.id,
                       self.class.to_s,
                       'note_text',
                       section_name, #suggestion_source[:section_name]
                       suggested_value,    #suggestion[:value]
                       false,                              #suggestion[:unknown].to_s.to_boolean
                       false,                              #suggestion[:not_applicable].to_s.to_boolean
                       nil,
                       nil,
                       named_entity.negated?               #suggestion[:negated].to_s.to_boolean
                       )
                       #save so this suggestion gets saved first
                       #aa.save!
                       abstractor_suggestion.save!
                     end
                   end
                 end
               else
                 puts 'step 3'
                 puts 'hello binny'
                 suggested_value = named_entity.semantic_tag_value.gsub(' , ', ',')
                 suggested_value = suggested_value.gsub(' - ', '-')
                 section_name = named_entity.sentence.section.name
                 section_name = nil
                 abstractor_suggestion = aa.abstractor_subject.suggest(
                 aa,
                 abstractor_abstraction_source,
                 omop_abstractor_nlp_document.text[named_entity.named_entity_begin..named_entity.named_entity_end], #suggestion_source[:match_value],
                 omop_abstractor_nlp_document.text[named_entity.sentence.sentence_begin..named_entity.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                 self.id,
                 self.class.to_s,
                 'note_text',
                 nil, #suggestion_source[:section_name]
                 suggested_value,    #suggestion[:value]
                 false,                              #suggestion[:unknown].to_s.to_boolean
                 false,                              #suggestion[:not_applicable].to_s.to_boolean
                 nil,
                 nil,
                 named_entity.negated?               #suggestion[:negated].to_s.to_boolean
                 )
                 #save so this suggestion gets saved first
                 # aa.save!
                 abstractor_suggestion.save!
               end
             else
               # puts 'we got to be a good person'
               suggested_value = named_entity.semantic_tag_value.gsub(' , ', ',')
               suggested_value = suggested_value.gsub(' - ', '-')

               abstractor_suggestion = aa.abstractor_subject.suggest(
               aa,
               abstractor_abstraction_source,
               omop_abstractor_nlp_document.text[named_entity.named_entity_begin..named_entity.named_entity_end], #suggestion_source[:match_value],
               omop_abstractor_nlp_document.text[named_entity.sentence.sentence_begin..named_entity.sentence.sentence_end], #suggestion_source[:sentence_match_value]
               self.id,
               self.class.to_s,
               'note_text',
               section_name, #suggestion_source[:section_name]
               suggested_value,    #suggestion[:value]
               false,                              #suggestion[:unknown].to_s.to_boolean
               false,                              #suggestion[:not_applicable].to_s.to_boolean
               nil,
               nil,
               named_entity.negated?               #suggestion[:negated].to_s.to_boolean
               )
               #save so this suggestion gets saved first
               #aa.save!
               abstractor_suggestion.save!
             end
             if !named_entity.negated?
               suggested = true
             end
           end
         end
         if !suggested
           # abstractor_abstraction.set_unknown!
           abstractor_abstraction.set_not_applicable!
         end
       when Abstractor::Enum::ABSTRACTOR_RULE_TYPE_NAME_VALUE
         named_entities = omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate }
         # ABSTRACTOR_OBJECT_TYPE_LIST                 = 'list'
         # ABSTRACTOR_OBJECT_TYPE_RADIO_BUTTON_LIST    = 'radio button list'

         # ABSTRACTOR_OBJECT_TYPE_NUMBER               = 'number'
         # ABSTRACTOR_OBJECT_TYPE_NUMBER_LIST          = 'number list'

         # ABSTRACTOR_OBJECT_TYPE_BOOLEAN              = 'boolean'
         # ABSTRACTOR_OBJECT_TYPE_STRING               = 'string'
         # ABSTRACTOR_OBJECT_TYPE_DATE                 = 'date'
         # ABSTRACTOR_OBJECT_TYPE_DYNAMIC_LIST         = 'dynamic list'
         # ABSTRACTOR_OBJECT_TYPE_TEXT                 = 'text'

         case abstractor_abstraction_schema.abstractor_object_type.value
         when Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_LIST, Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_RADIO_BUTTON_LIST
           named_entities = omop_abstractor_nlp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate }
           puts 'here is the predicate for a name/value'
           puts abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
           puts 'how much you got?'
           puts named_entities.size
           suggested = false
           suggestions = []
           #begin new
           named_entities_names = named_entities.select { |named_entity|  named_entity.semantic_tag_value_type == 'name' }
           named_entities_values = omop_abstractor_nlp_document.named_entities.select { |named_entity| (named_entity.semantic_tag_attribute == abstractor_abstraction_schema.predicate  && named_entity.semantic_tag_value_type == 'value') || named_entity.semantic_tag_value == '0' }
           if named_entities_names.any?
             puts 'hello'
             section_name = nil
             named_entities_names.each do |named_entity_name|
               abstractor_abstraction.reload
               if named_entity_name.sentence.section.present?
                 if abstractor_abstraction.group_member?
                   if section_abstractor_abstraction_group_map[named_entity_name.sentence.section.section_range].present?
                     # puts 'step 2'
                     section_abstractor_abstraction_group_map[named_entity_name.sentence.section.section_range].each do |abstractor_abstraction_group|
                       abstractor_abstraction_group.abstractor_abstraction_group_members.each do |abstractor_abstraction_group_member|
                         if abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == named_entity_name.semantic_tag_attribute
                           values = named_entities_values.select { |named_entity_value| named_entity_name.sentence == named_entity_value.sentence && section_abstractor_abstraction_group_map[named_entity_value.sentence.section.section_range].present? }
                           aa = abstractor_abstraction_group_member.abstractor_abstraction
                           if values.any?
                             values.each do |value|
                               section_name = named_entity_name.sentence.section.name
                               suggested_value = named_entity_name.semantic_tag_value.gsub(' , ', ',')
                               suggested_value = suggested_value.gsub(' - ', '-')

                               abstractor_suggestion = aa.abstractor_subject.suggest(
                                 aa,
                                 abstractor_abstraction_source,
                                 omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                                     omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                                 self.id,
                                 self.class.to_s,
                                 'note_text',
                                 section_name, #suggestion_source[:section_name]
                                 value.semantic_tag_value,                 #suggestion[:value]
                                 false,                                     #suggestion[:unknown].to_s.to_boolean
                                 false,                                     #suggestion[:not_applicable].to_s.to_boolean
                                 nil,
                                 nil,
                                 false   #suggestion[:negated].to_s.to_boolean
                               )
                               #save so this suggestion gets saved first
                               #abstractor_abstraction.save!
                               abstractor_suggestion.save!
                               suggestions << abstractor_suggestion
                               suggested = true
                               if canonical_format?(omop_abstractor_nlp_document.text[named_entity_name.named_entity_begin..named_entity_name.named_entity_end], omop_abstractor_nlp_document.text[value.named_entity_begin..value.named_entity_end], omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end])
                                 abstractor_suggestion.accepted = true
                                 abstractor_suggestion.save!
                               end
                             end
                           else
                             if !named_entity_name.negated?
                               suggested = true
                               abstractor_suggestion = aa.abstractor_subject.suggest(
                                 aa,
                                 abstractor_abstraction_source,
                                 omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                                 omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                                 self.id,
                                 self.class.to_s,
                                 'note_text',
                                 nil, #suggestion_source[:section_name]
                                 nil,                 #suggestion[:value]
                                 true,                                     #suggestion[:unknown].to_s.to_boolean
                                 false,                                     #suggestion[:not_applicable].to_s.to_boolean
                                 nil,
                                 nil,
                                 false   #suggestion[:negated].to_s.to_boolean
                               )
                               #save so this suggestion gets saved first
                               #abstractor_abstraction.save!
                               abstractor_suggestion.save!
                             end
                           end
                         end
                       end
                     end
                   end
                 else
                   aa = abstractor_abstraction
                   values = named_entities_values.select { |named_entity_value| named_entity_name.sentence == named_entity_value.sentence }
                   if values.any?
                     values.each do |value|
                       section_name = named_entity_name.sentence.section.name
                       suggested_value = named_entity_name.semantic_tag_value.gsub(' , ', ',')
                       suggested_value = suggested_value.gsub(' - ', '-')

                       abstractor_suggestion = aa.abstractor_subject.suggest(
                         aa,
                         abstractor_abstraction_source,
                         omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                             omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                         self.id,
                         self.class.to_s,
                         'note_text',
                         section_name, #suggestion_source[:section_name]
                         value.semantic_tag_value,                 #suggestion[:value]
                         false,                                     #suggestion[:unknown].to_s.to_boolean
                         false,                                     #suggestion[:not_applicable].to_s.to_boolean
                         nil,
                         nil,
                         false   #suggestion[:negated].to_s.to_boolean
                       )
                       #save so this suggestion gets saved first
                       #abstractor_abstraction.save!
                       abstractor_suggestion.save!
                       suggestions << abstractor_suggestion
                       suggested = true
                       if canonical_format?(omop_abstractor_nlp_document.text[named_entity_name.named_entity_begin..named_entity_name.named_entity_end], omop_abstractor_nlp_document.text[value.named_entity_begin..value.named_entity_end], omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end])
                         abstractor_suggestion.accepted = true
                         abstractor_suggestion.save!
                       end
                     end
                   else
                     if !named_entity_name.negated?
                       suggested = true
                       abstractor_suggestion = aa.abstractor_subject.suggest(
                         aa,
                         abstractor_abstraction_source,
                         omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                         omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                         self.id,
                         self.class.to_s,
                         'note_text',
                         nil, #suggestion_source[:section_name]
                         nil,                 #suggestion[:value]
                         true,                                     #suggestion[:unknown].to_s.to_boolean
                         false,                                     #suggestion[:not_applicable].to_s.to_boolean
                         nil,
                         nil,
                         false   #suggestion[:negated].to_s.to_boolean
                       )
                       #save so this suggestion gets saved first
                       #abstractor_abstraction.save!
                       abstractor_suggestion.save!
                     end
                   end
                 end
               else
                 values = named_entities_values.select { |named_entities_value| named_entity_name.sentence == named_entities_value.sentence }
                 puts 'How many values you got?'
                 puts values.size
                 puts 'What do you say?'
                 if values.any?
                   values.each do |value|
                     if named_entity_name.sentence.section
                       section_name = named_entity_name.sentence.section.name
                     else
                       section_name = nil
                     end

                     abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                       abstractor_abstraction,
                       abstractor_abstraction_source,
                       omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                           omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                       self.id,
                       self.class.to_s,
                       'note_text',
                       section_name, #suggestion_source[:section_name]
                       value.semantic_tag_value,                 #suggestion[:value]
                       false,                                     #suggestion[:unknown].to_s.to_boolean
                       false,                                     #suggestion[:not_applicable].to_s.to_boolean
                       nil,
                       nil,
                       false   #suggestion[:negated].to_s.to_boolean
                     )
                     #save so this suggestion gets saved first
                     #abstractor_abstraction.save!
                     abstractor_suggestion.save!
                     suggestions << abstractor_suggestion
                     suggested = true
                     if canonical_format?(omop_abstractor_nlp_document.text[named_entity_name.named_entity_begin..named_entity_name.named_entity_end], omop_abstractor_nlp_document.text[value.named_entity_begin..value.named_entity_end], omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end])
                       abstractor_suggestion.accepted = true
                       abstractor_suggestion.save!
                     end
                   end
                 else
                   if !named_entity_name.negated?
                     suggested = true
                     abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                       abstractor_abstraction,
                       abstractor_abstraction_source,
                       omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                       omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                       self.id,
                       self.class.to_s,
                       'note_text',
                       nil, #suggestion_source[:section_name]
                       nil,                 #suggestion[:value]
                       true,                                     #suggestion[:unknown].to_s.to_boolean
                       false,                                     #suggestion[:not_applicable].to_s.to_boolean
                       nil,
                       nil,
                       false   #suggestion[:negated].to_s.to_boolean
                     )
                     #save so this suggestion gets saved first
                     #abstractor_abstraction.save!
                     abstractor_suggestion.save!
                   end
                 end
               end
             end
           end
           if !suggested
             # abstractor_abstraction.set_unknown!
             abstractor_abstraction.set_not_applicable!
           else
             suggestions.uniq!
             if suggestions.size == 1
               abstractor_suggestion = suggestions.first
               abstractor_suggestion.accepted = true
               abstractor_suggestion.save!
             end
           end
         when Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_NUMBER, Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_NUMBER_LIST
           named_entities_names = named_entities.select { |named_entity|  named_entity.semantic_tag_value_type == 'name' }
           named_entities_values = omop_abstractor_nlp_document.named_entities.select { |named_entity| (named_entity.semantic_tag_attribute == abstractor_abstraction_schema.predicate  && named_entity.semantic_tag_value_type == 'value') }
           # puts 'here is the predicate for a name/value number'
           # puts abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
           # puts 'how much you got?'
           # puts named_entities.size
           suggested = false
           suggestions = []
           if named_entities_names.any?
             named_entities_names.each do |named_entity_name|
               values = named_entities_values.select { |named_entities_value| named_entity_name.sentence == named_entities_value.sentence }
               values.reject! { |value| named_entity_name.overlap?(value) }
               move = true
               if named_entity_name.sentence.section
                 section_name = named_entity_name.sentence.section.name
               else
                 section_name = nil
               end

               if values.size == 2 #&& values.last.semantic_tag_value.scan('%').present?
                 value_last = values.last.semantic_tag_value.gsub('%', '')
                 sentence = omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end]
                 regexp = Regexp.new("#{values.first.semantic_tag_value}\s?\-\s?#{value_last}\%")
                 match = sentence.match(regexp)
                 if match
                   values.first.semantic_tag_value = (Percentage.new((((values.first.semantic_tag_value.to_f + values.last.semantic_tag_value.to_f)/2)) / 100)).value.to_s
                   abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                   omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   section_name,          #suggestion_source[:section_name]
                   values.first.semantic_tag_value,                         #suggestion[:value]
                   false,                                            #suggestion[:unknown].to_s.to_boolean
                   false,                                            #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   (named_entity_name.negated? || values.first.negated?)    #suggestion[:negated].to_s.to_boolean
                   )
                   #save so this suggestion gets saved first
                   # abstractor_abstraction.save!
                   abstractor_suggestion.save!
                   if !named_entity_name.negated? && !values.first.negated?
                     suggestions << abstractor_suggestion
                     suggested = true
                     # if canonical_format?(omop_abstractor_nlp_document.text[named_entity_name.named_entity_begin..named_entity_name.named_entity_end], omop_abstractor_nlp_document.text[value.named_entity_begin..value.named_entity_end], omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end])
                     #   abstractor_suggestion.accepted = true
                     #   abstractor_suggestion.save!
                     # end
                   end
                   move = false
                 end
               end

               if move && values.any? && values.size <= 4
                 values.each do |value|
                   abstractor_abstraction.reload
                   if value.semantic_tag_value.scan('%').present?
                     value.semantic_tag_value = (Percentage.new(value.semantic_tag_value).to_f / 100).to_s
                   end

                   if value.semantic_tag_value.downcase == 'zero'
                     value.semantic_tag_value = '0'
                   end

                   if !named_entity_name.overlap?(value)
                     abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                     abstractor_abstraction,
                     abstractor_abstraction_source,
                     omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                     omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                     self.id,
                     self.class.to_s,
                     'note_text',
                     section_name,          #suggestion_source[:section_name]
                     value.semantic_tag_value,                         #suggestion[:value]
                     false,                                            #suggestion[:unknown].to_s.to_boolean
                     false,                                            #suggestion[:not_applicable].to_s.to_boolean
                     nil,
                     nil,
                     (named_entity_name.negated? || value.negated?)    #suggestion[:negated].to_s.to_boolean
                     )
                     #save so this suggestion gets saved first
                     # abstractor_abstraction.save!
                     abstractor_suggestion.save!
                     if !named_entity_name.negated? && !value.negated?
                       suggestions << abstractor_suggestion
                       suggested = true
                       # if canonical_format?(omop_abstractor_nlp_document.text[named_entity_name.named_entity_begin..named_entity_name.named_entity_end], omop_abstractor_nlp_document.text[value.named_entity_begin..value.named_entity_end], omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end])
                       #   abstractor_suggestion.accepted = true
                       #   abstractor_suggestion.save!
                       # end
                     end
                   end
                 end
               end

               if values.empty?
                 if !named_entity_name.negated?
                   abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                   omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   nil,          #suggestion_source[:section_name]
                   nil,                         #suggestion[:value]
                   true,                                            #suggestion[:unknown].to_s.to_boolean
                   false,                                            #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   named_entity_name.negated?    #suggestion[:negated].to_s.to_boolean
                   )
                   #save so this suggestion gets saved first
                   # abstractor_abstraction.save!
                   abstractor_suggestion.save!
                 end
               end
             end
           end
           if !suggested
             # puts 'number not suggested!'
             abstractor_abstraction.set_not_applicable!
           else
             # puts 'number is suggested!'
             suggestions.uniq!
             # puts 'here is the size'
             # puts suggestions.size
             if suggestions.size == 1
               # puts 'auto accepting!'
               abstractor_suggestion = suggestions.first
               abstractor_suggestion.accepted = true
               abstractor_suggestion.save!
             end
           end
         when Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_DATE
           named_entities_names = named_entities.select { |named_entity|  named_entity.semantic_tag_value_type == 'name' }
           named_entities_values = omop_abstractor_nlp_document.named_entities.select { |named_entity| (named_entity.semantic_tag_attribute == abstractor_abstraction_schema.predicate  && named_entity.semantic_tag_value_type == 'value') }
           suggested = false
           suggestions = []
           if named_entities_names.any?
             named_entities_names.each do |named_entity_name|
               values = named_entities_values.select { |named_entities_value| named_entity_name.sentence == named_entities_value.sentence }
               values.reject! { |value| named_entity_name.overlap?(value) }
               move = true
               if named_entity_name.sentence.section
                 section_name = named_entity_name.sentence.section.name
               else
                 section_name = nil
               end

               if move && values.any? && values.size <= 4
                 values.each do |value|
                   abstractor_abstraction.reload
                   if !named_entity_name.overlap?(value)
                     abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                     abstractor_abstraction,
                     abstractor_abstraction_source,
                     omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                     omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                     self.id,
                     self.class.to_s,
                     'note_text',
                     section_name,          #suggestion_source[:section_name]
                     value.semantic_tag_value,                         #suggestion[:value]
                     false,                                            #suggestion[:unknown].to_s.to_boolean
                     false,                                            #suggestion[:not_applicable].to_s.to_boolean
                     nil,
                     nil,
                     (named_entity_name.negated? || value.negated?)    #suggestion[:negated].to_s.to_boolean
                     )
                     #save so this suggestion gets saved first
                     #abstractor_abstraction.save!
                     abstractor_suggestion.save!
                     if !named_entity_name.negated? && !value.negated?
                       suggestions << abstractor_suggestion
                       suggested = true
                       # if canonical_format?(omop_abstractor_nlp_document.text[named_entity_name.named_entity_begin..named_entity_name.named_entity_end], omop_abstractor_nlp_document.text[value.named_entity_begin..value.named_entity_end], omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end])
                       #   abstractor_suggestion.accepted = true
                       #   abstractor_suggestion.save!
                       # end
                     end
                   end
                 end
               end

               if values.empty?
                 if !named_entity_name.negated?
                   abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:match_value],
                   omop_abstractor_nlp_document.text[named_entity_name.sentence.sentence_begin..named_entity_name.sentence.sentence_end], #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   nil,          #suggestion_source[:section_name]
                   nil,                         #suggestion[:value]
                   true,                                            #suggestion[:unknown].to_s.to_boolean
                   false,                                            #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   named_entity_name.negated?    #suggestion[:negated].to_s.to_boolean
                   )
                   #save so this suggestion gets saved first
                   #abstractor_abstraction.save!
                   abstractor_suggestion.save!
                 end
               end
             end
           end
           if !suggested
             # puts 'number not suggested!'
             abstractor_abstraction.set_not_applicable!
           else
             # puts 'date is suggested!'
             suggestions.uniq!
             # puts 'here is the size'
             # puts suggestions.size
             if suggestions.size == 1
               # puts 'auto accepting!'
               abstractor_suggestion = suggestions.first
               abstractor_suggestion.accepted = true
               abstractor_suggestion.save!
             end
           end
         end
       end
      end

      # Post-processing across all schemas within an abstraction group:
      # If no suggestions are present otherwise, reset suggestions for anchor schemas that are rejected for not being found within an expected section.
      # puts 'hello before'
      # puts abstractor_note['source_id']
      # puts 'here is note_stable_identifier.id'
      # puts self.id
      # puts abstractor_note['namespace_type']
      # puts abstractor_note['namespace_id']
      # puts self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).size

      loosey_goosey = false
      if loosey_goosey
        abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
        self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
         # puts 'hello'
         # puts abstractor_abstraction_group.abstractor_subject_group.name
         other_abstractor_abstraction_groups = abstractor_abstraction_groups - [abstractor_abstraction_group]
         if !abstractor_abstraction_group.anchor.abstractor_abstraction.suggested?
           abstractor_abstraction_group.anchor.abstractor_abstraction.abstractor_suggestions.not_deleted.each do |abstractor_suggestion|
             if abstractor_suggestion.system_rejected && abstractor_suggestion.system_rejected_reason == Abstractor::Enum::ABSTRACTOR_SUGGESTION_SYSTEM_REJECTED_REASON_NO_SECTION_MATCH
               abstractor_suggestion.system_rejected = false
               abstractor_suggestion.system_rejected_reason = nil
               abstractor_suggestion.accepted = nil
               abstractor_suggestion.save!
             end
           end
         end
        end
      end

      # Post-processing across all schemas within an abstraction group:
      # If the anchor is not 'only less specific suggested' or is 'only less specific suggested' and no other group have a suggested anchor.
      # The prior behavior is not generic.
      # If the anchor is not suggested in a group, set the member to 'Not applicable'.
      # If the anchor is suggested in a group and the member is 'only less specific suggested', set the member to the only suggestion.
      # If the anchor is suggested in a group and the member is not suggested and not 'only less specific suggested' but has a 'detault suggested value', set the member to the 'detault suggested value'
      # If the anchor is suggested in a group and the member is not suggested and not 'only less specific suggested' and has no 'detault suggested value', set the member to 'Not applicable'.
      # puts 'hello before'
      # puts abstractor_note['source_id']
      # puts 'here is note_stable_identifier.id'
      # puts self.id
      # puts abstractor_note['namespace_type']
      # puts abstractor_note['namespace_id']
      # puts self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).size
      abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
      self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
       # puts 'hello'
       # puts abstractor_abstraction_group.abstractor_subject_group.name
       other_abstractor_abstraction_groups = abstractor_abstraction_groups - [abstractor_abstraction_group]
       if !abstractor_abstraction_group.anchor.abstractor_abstraction.only_less_specific_suggested? || (abstractor_abstraction_group.anchor.abstractor_abstraction.only_less_specific_suggested? && other_abstractor_abstraction_groups.detect { |other_abstractor_abstraction_group| other_abstractor_abstraction_group.anchor.abstractor_abstraction.suggested? })
         abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.each do |abstractor_abstraction_group_member|
           # puts abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate

           # member suggested
           if abstractor_abstraction_group_member.abstractor_abstraction.suggested?
             # #anchor suggested
             # if abstractor_abstraction_group.anchor.abstractor_abstraction.suggested?
             #   if abstractor_abstraction_group_member.abstractor_abstraction.only_less_specific_suggested?
             #     abstractor_abstraction_group_member.abstractor_abstraction.set_only_suggestion!
             #   end
             # #anchor not suggested
             # else
             #anchor not suggested
             if !abstractor_abstraction_group.anchor.abstractor_abstraction.suggested?
               abstractor_abstraction_group_member.abstractor_abstraction.set_not_applicable!
             end
           #member not suggested
           else
             #anchor suggested
             if abstractor_abstraction_group.anchor.abstractor_abstraction.suggested?
               if abstractor_abstraction_group_member.abstractor_abstraction.only_less_specific_suggested?
                 abstractor_abstraction_group_member.abstractor_abstraction.set_only_suggestion!
               elsif abstractor_abstraction_group_member.abstractor_abstraction.detault_suggested_value?
                 abstractor_abstraction_group_member.abstractor_abstraction.set_detault_suggested_value!(self.id, self.class.to_s, 'note_text')
               else
                 abstractor_abstraction_group_member.abstractor_abstraction.set_not_applicable!
               end
             #anchor not suggested
             # Don't think the following is needed.
             else
               abstractor_abstraction_group_member.abstractor_abstraction.set_not_applicable!
             end
           end
         end
       end
      end

      # Post-processing across all schemas within an abstraction group.
      # If the anchor is 'only less specific suggested' and no other groups have a suggested anchor.
      # The prior behavior is not generic.
      # Set the anchor to the only suggestion.
      # If the member is not suggested and 'only less specific suggested', set the member to the only suggestion.
      # If the member is not suggested and not 'only less specific suggested' but has a 'detault suggested value', set the member to the 'detault suggested value'
      # If the member is not suggested and not 'only less specific suggested' and has no 'detault suggested value', set  the member to 'Not applicable'.
      # puts 'hello before'
      # puts abstractor_note['source_id']
      # note_stable_identifier = NoteStableIdentifier.find(abstractor_note['source_id'])
      # puts 'here is note_stable_identifier.id'
      # puts self.id
      # puts omop_abstractor_nlp_document.namespace_type
      # puts omop_abstractor_nlp_document.namespace_id
      # puts self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).size
      abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
      self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
       other_abstractor_abstraction_groups = abstractor_abstraction_groups - [abstractor_abstraction_group]
       # puts 'hello'
       # puts abstractor_abstraction_group.abstractor_subject_group.name
       if abstractor_abstraction_group.anchor.abstractor_abstraction.only_less_specific_suggested? && !other_abstractor_abstraction_groups.detect { |other_abstractor_abstraction_group| other_abstractor_abstraction_group.anchor.abstractor_abstraction.suggested? }
         abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.each do |abstractor_abstraction_group_member|
           # puts abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
           if abstractor_abstraction_group_member.anchor?
             abstractor_abstraction_group_member.abstractor_abstraction.set_only_suggestion!
           else
             if abstractor_abstraction_group_member.abstractor_abstraction.suggested?
               # Don't think the following is needed.
               if abstractor_abstraction_group_member.abstractor_abstraction.only_less_specific_suggested?
                 abstractor_abstraction_group_member.abstractor_abstraction.set_only_suggestion!
               end
             else
               # puts 'not suggested'
               if abstractor_abstraction_group_member.abstractor_abstraction.only_less_specific_suggested?
                 abstractor_abstraction_group_member.abstractor_abstraction.set_only_suggestion!
               elsif abstractor_abstraction_group_member.abstractor_abstraction.detault_suggested_value?
                 abstractor_abstraction_group_member.abstractor_abstraction.set_detault_suggested_value!(self.id, self.class.to_s, 'note_text')
               else
                 abstractor_abstraction_group_member.abstractor_abstraction.set_not_applicable!
               end
             end
           end
         end
       end
      end

      # Post-processing across all schemas within an abstraction group.
      # Suggest 'unknown' to non-anchor schemas if the anchor schema has an accepted/suggested value and the non-anchor schmea is marked as not-applicable.
      abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
      self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
       # puts 'hello'
       # puts abstractor_abstraction_group.abstractor_subject_group.name
       if abstractor_abstraction_group.anchor?
         # if !abstractor_abstraction_group.anchor.abstractor_abstraction.value.blank? || (abstractor_abstraction_group.anchor.abstractor_abstraction.value.blank?  && !abstractor_abstraction_group.anchor.abstractor_abstraction.not_applicable)
         if !abstractor_abstraction_group.anchor.abstractor_abstraction.not_applicable
           abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.each do |abstractor_abstraction_group_member|
             # puts abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate
             if !abstractor_abstraction_group_member.anchor?
               abstractor_abstraction = abstractor_abstraction_group_member.abstractor_abstraction
               if abstractor_abstraction_group_member.abstractor_abstraction.not_applicable
                 abstractor_abstraction.set_only_suggestion!
                 abstractor_abstraction.reload
                 if abstractor_abstraction.not_applicable
                   abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first.id)
                   abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.id)

                   abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   nil, #suggestion_source[:match_value],
                   nil, #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   nil,                                  #suggestion_source[:section_name]
                   nil,                                  #suggestion[:value]
                   true,                                #suggestion[:unknown].to_s.to_boolean
                   false,                                 #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   false                                 #suggestion[:negated].to_s.to_boolean
                   )
                   #save so this suggestion gets saved first
                   # abstractor_abstraction.save!
                   abstractor_abstraction.clear!
                   # abstractor_suggestion.update_siblings_status
                   # abstractor_abstraction_group_member.abstractor_abstraction.set_unknown!
                 end
               end
             end
           end
         end
       end
      end

      primary_cns = false
      if primary_cns
        # Post-processing across all schemas within an abstraction group.
        # Create a non-generic post processing step unique to cancer groups to set laterallity based on site.
        abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
        self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
          # puts 'hello'
          # puts abstractor_abstraction_group.abstractor_subject_group.name
          if abstractor_abstraction_group.anchor?
            if !abstractor_abstraction_group.anchor.abstractor_abstraction.not_applicable
              abstractor_abstraction_group_member_has_cancer_site = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_site'}
              abstractor_abstraction_group_member_has_cancer_site_laterality = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_site_laterality'}

              lateral_sites = []
              lateral_sites << 'cerebral meninges (c70.0)'
              lateral_sites << 'cerebrum (c71.0)'
              lateral_sites << 'frontal lobe (c71.1)'
              lateral_sites << 'temporal lobe (c71.2)'
              lateral_sites << 'parietal lobe (c71.3)'
              lateral_sites << 'occipital lobe (c71.4)'
              lateral_sites << 'olfactory nerve (c72.2)'
              lateral_sites << 'optic nerve (c72.3)'
              lateral_sites << 'acoustic nerve (c72.4)'
              lateral_sites << 'cranial nerve (c72.5)'

              # C70.0
              # C71.0
              # C71.1
              # C71.2
              # C71.3
              # C71.4
              # C72.2
              # C72.3
              # C72.4
              # C72.5
              if !abstractor_abstraction_group_member_has_cancer_site_laterality.abstractor_abstraction.value.present? && abstractor_abstraction_group_member_has_cancer_site.abstractor_abstraction.value.present? && !lateral_sites.include?(abstractor_abstraction_group_member_has_cancer_site.abstractor_abstraction.value)
                abstractor_abstraction_group_member_has_cancer_site_laterality.abstractor_abstraction.set_not_applicable!
              end
            end
          end
        end


        # Post-processing across all schemas within an abstraction group.
        # Create a non-generic post processing step set WHO Grade based on histology if it is not set.
        # https://link.springer.com/article/10.1007/s00401-016-1545-1
        histology_who_grade_mappings = CSV.new(File.open('lib/setup/vocabulary/2016_who_classification_of_tumors_grade.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
        abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
        self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
          # puts 'hello inside the WHO grade rule 1'
          # puts abstractor_abstraction_group.abstractor_subject_group.name
          if abstractor_abstraction_group.anchor?
            # puts 'hello inside the WHO grade rule 2'
            if !abstractor_abstraction_group.anchor.abstractor_abstraction.not_applicable
              abstractor_abstraction_group_member_has_cancer_histology = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_histology'}
              abstractor_abstraction_group_member_has_cancer_who_grade = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_who_grade'}
              # puts 'hello inside the WHO grade rule 3'
              # puts 'here is the value'
              if abstractor_abstraction_group_member_has_cancer_histology && abstractor_abstraction_group_member_has_cancer_histology.abstractor_abstraction.accepted?
                puts 'looking for the booch'
                puts abstractor_abstraction_group_member_has_cancer_histology.abstractor_abstraction.id
                histology_who_grade_mapping = histology_who_grade_mappings.detect { |histology_who_grade_mapping|  histology_who_grade_mapping['icdo3_code'] ==  abstractor_abstraction_group_member_has_cancer_histology.abstractor_abstraction.abstractor_object_value.vocabulary_code && histology_who_grade_mapping['grade_2'].blank?  && histology_who_grade_mapping['grade_3'].blank? }
                # puts 'hello inside the WHO grade rule 4'
                if !abstractor_abstraction_group_member_has_cancer_who_grade.abstractor_abstraction.value.present? && !histology_who_grade_mapping
                  # puts 'hello inside the WHO grade rule 5'
                  abstractor_abstraction_group_member_has_cancer_who_grade.abstractor_abstraction.set_not_applicable!
                end

                if !abstractor_abstraction_group_member_has_cancer_who_grade.abstractor_abstraction.value.present? && histology_who_grade_mapping
                  # puts 'skip me'
                  abstractor_abstraction = abstractor_abstraction_group_member_has_cancer_who_grade.abstractor_abstraction
                  abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first.id)
                  abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.id)

                  abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   nil, #suggestion_source[:match_value],
                   nil, #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   nil,                                    #suggestion_source[:section_name]
                   histology_who_grade_mapping['grade_1'], #suggestion[:value]
                   false,                                  #suggestion[:unknown].to_s.to_boolean
                   false,                                  #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   false                                   #suggestion[:negated].to_s.to_boolean
                  )
                  abstractor_suggestion.accepted = true
                  abstractor_suggestion.save!
                end
              end
            end
          end
        end
      end

      # Post-processing across all schemas within an abstraction group.
      # Look to prior path reports to improve recurrent suggestions.
      recurrent = false
      if recurrent
       abstractor_abstraction_groups = self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id)
       self.abstractor_abstraction_groups_by_namespace(namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id).each do |abstractor_abstraction_group|
         # puts 'hello'
         # puts abstractor_abstraction_group.abstractor_subject_group.name
         if abstractor_abstraction_group.anchor?
           if !abstractor_abstraction_group.anchor.abstractor_abstraction.not_applicable
             abstractor_abstraction_group_member_has_cancer_recurrence_status = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_recurrence_status'}

             if abstractor_abstraction_group.abstractor_subject_group.name == 'Metastatic Cancer'
               abstractor_abstraction_group_member_has_metastatic_cancer_histology = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_metastatic_cancer_histology' }
               if abstractor_abstraction_group_member_has_metastatic_cancer_histology && abstractor_abstraction_group_member_has_metastatic_cancer_histology.abstractor_abstraction.value.present?
                 prior_note_stable_identifiers = []
                 options = { namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id }
                 prior_note_stable_identifiers = NoteStableIdentifier.with_note.where('note_stable_identifier.id != ?', self.id).where('note.person_id  = ? AND note.note_date < ?', self.note.person_id, self.note.note_date).pivot_grouped_abstractions(abstractor_abstraction_group.abstractor_subject_group.name, options).where('has_metastatic_cancer_histology = ?', abstractor_abstraction_group_member_has_metastatic_cancer_histology.abstractor_abstraction.value).all
                 if prior_note_stable_identifiers.length > 0
                   abstractor_abstraction = abstractor_abstraction_group_member_has_cancer_recurrence_status.abstractor_abstraction
                   abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first.id)
                   abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.id)

                   abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   nil, #suggestion_source[:match_value],
                   nil, #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   nil,                                    #suggestion_source[:section_name]
                   'recurrent',                            #suggestion[:value]
                   false,                                  #suggestion[:unknown].to_s.to_boolean
                   false,                                  #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   false                                   #suggestion[:negated].to_s.to_boolean
                   )
                   abstractor_suggestion.accepted = true
                   abstractor_suggestion.save!
                 end
               end
             end

             if abstractor_abstraction_group.abstractor_subject_group.name == 'Primary Cancer'
               # puts 'made it here 1'
               abstractor_abstraction_group_member_has_cancer_histology = abstractor_abstraction_group.abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_cancer_histology' }
               if abstractor_abstraction_group_member_has_cancer_histology && abstractor_abstraction_group_member_has_cancer_histology.abstractor_abstraction.value.present?
                 # puts 'made it here 2'
                 prior_note_stable_identifiers = []
                 options = { namespace_type: omop_abstractor_nlp_document.namespace_type, namespace_id: omop_abstractor_nlp_document.namespace_id }
                 # puts 'what the hell'
                 # puts NoteStableIdentifier.with_note.where('note_stable_identifier.id != ?', note_stable_identifier.id).where('note.person_id  = ? AND note.note_date < ?', note_stable_identifier.note.person_id, note_stable_identifier.note.note_date).pivot_grouped_abstractions(abstractor_abstraction_group.abstractor_subject_group.name, options).where('has_cancer_histology = ?', abstractor_abstraction_group_member_has_cancer_histology.abstractor_abstraction.value).to_sql

                 prior_note_stable_identifiers = NoteStableIdentifier.with_note.where('note_stable_identifier.id != ?', self.id).where('note.person_id  = ? AND note.note_date < ?', self.note.person_id, self.note.note_date).pivot_grouped_abstractions(abstractor_abstraction_group.abstractor_subject_group.name, options).where('has_cancer_histology = ?', abstractor_abstraction_group_member_has_cancer_histology.abstractor_abstraction.value).all
                 # puts 'made it here 3'
                 # puts 'how much you got?'
                 # puts prior_note_stable_identifiers.size
                 if prior_note_stable_identifiers.any?
                   abstractor_abstraction = abstractor_abstraction_group_member_has_cancer_recurrence_status.abstractor_abstraction
                   abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first.id)
                   abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.find(abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.id)

                   abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(
                   abstractor_abstraction,
                   abstractor_abstraction_source,
                   nil, #suggestion_source[:match_value],
                   nil, #suggestion_source[:sentence_match_value]
                   self.id,
                   self.class.to_s,
                   'note_text',
                   nil,                                    #suggestion_source[:section_name]
                   'recurrent',                            #suggestion[:value]
                   false,                                  #suggestion[:unknown].to_s.to_boolean
                   false,                                  #suggestion[:not_applicable].to_s.to_boolean
                   nil,
                   nil,
                   false                                   #suggestion[:negated].to_s.to_boolean
                   )
                   abstractor_suggestion.accepted = true
                   abstractor_suggestion.save!
                 end
               end
             end
           end
         end
       end
      end
    end
  end

  def canonical_format?(name, value, sentence)
    canonical_format = false
    begin
      regular_expression = Regexp.new('^\b' + name + '\s*\:\s*' + value.strip + '\s*%')
      canonical_format = sentence.scan(regular_expression).present?

      if !canonical_format
        regular_expression = Regexp.new('^\b' + name + '\s*' + value.strip + '\s*$')
        canonical_format = sentence.scan(regular_expression).present?
      end
    rescue Exception => e
    end

    canonical_format
  end
end