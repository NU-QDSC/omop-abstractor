class Note < ApplicationRecord
  self.table_name = 'note'
  self.primary_key = 'note_id'
  belongs_to :note_type, class_name: 'Concept', foreign_key: 'note_type_concept_id'
  belongs_to :note_class, class_name: 'Concept', foreign_key: 'note_class_concept_id'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id', optional: true
  belongs_to :provider, class_name: 'Provider', foreign_key: 'provider_id', optional: true

  ABSTRACTOR_SITE_STATUS_ACCEPTED_SITE = 'accepted'
  ABSTRACTOR_SITE_STATUS_ACCEPTED_SPECIFIC_SITE = 'accepted specific'
  ABSTRACTOR_SITE_STATUS_ACCEPTED_GENERAL_SITE = 'accepted general'
  ABSTRACTOR_SITE_STATUS_SUGGESTED_SITE = 'suggested'
  ABSTRACTOR_SITE_STATUS_SUGGESTED_SPECIFIC_SITE = 'suggested specific'
  ABSTRACTOR_SITE_STATUS_SUGGESTED_GENERAL_SITE = 'suggested general'
  ABSTRACTOR_SITE_STATUS_NOT_APPLICABLE = 'not applicable'
  ABSTRACTOR_SITE_STATUS_NOT_APPLICABLE_SUGGESTED = 'not applicable suggested'
  ABSTRACTOR_SITE_STATUS_UNKNOWN_SUGGESTED = 'unknown suggested'

  ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_HISTOLOGY = 'accepted'
  ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_SPECIFIC_HISTOLOGY = 'accepted specific'
  ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_GENERAL_HISTOLOGY = 'accepted general'
  ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_HISTOLOGY = 'suggested'
  ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_SPECIFIC_HISTOLOGY = 'suggested specific'
  ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_GENERAL_HISTOLOGY = 'suggested general'
  ABSTRACTOR_HISTOLOGY_STATUS_NOT_APPLICABLE = 'not applicable'
  ABSTRACTOR_HISTOLOGY_STATUS_NOT_APPLICABLE_SUGGESTED = 'not applicable suggested'
  ABSTRACTOR_HISTOLOGY_STATUS_UNKNOWN_SUGGESTED = 'unknown suggested'
  ABSTRACTOR_SITE_STATUSES = [ABSTRACTOR_SITE_STATUS_ACCEPTED_SITE, ABSTRACTOR_SITE_STATUS_ACCEPTED_SPECIFIC_SITE, ABSTRACTOR_SITE_STATUS_ACCEPTED_GENERAL_SITE, ABSTRACTOR_SITE_STATUS_SUGGESTED_SITE, ABSTRACTOR_SITE_STATUS_SUGGESTED_SPECIFIC_SITE, ABSTRACTOR_SITE_STATUS_SUGGESTED_GENERAL_SITE, ABSTRACTOR_SITE_STATUS_NOT_APPLICABLE, ABSTRACTOR_SITE_STATUS_NOT_APPLICABLE_SUGGESTED, ABSTRACTOR_SITE_STATUS_UNKNOWN_SUGGESTED]
  ABSTRACTOR_HISTOLOGY_STATUSES = [ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_HISTOLOGY, ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_SPECIFIC_HISTOLOGY, ABSTRACTOR_HISTOLOGY_STATUS_ACCEPTED_GENERAL_HISTOLOGY, ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_HISTOLOGY, ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_SPECIFIC_HISTOLOGY, ABSTRACTOR_HISTOLOGY_STATUS_SUGGESTED_GENERAL_HISTOLOGY, ABSTRACTOR_HISTOLOGY_STATUS_NOT_APPLICABLE, ABSTRACTOR_HISTOLOGY_STATUS_NOT_APPLICABLE_SUGGESTED, ABSTRACTOR_HISTOLOGY_STATUS_UNKNOWN_SUGGESTED]

  def other_notes(options ={})
    abstractor_abstraction_status = options[:abstractor_abstraction_status] || nil
    namespace_ids = options[:namespace_id].blank? ? Abstractor::AbstractorNamespace.all.map(&:id) : [options[:namespace_id]]
    if namespace_ids.present?
      namespace_type = Abstractor::AbstractorNamespace.to_s
    end
    NoteStableIdentifier.search_across_fields(nil, nil, nil, nil, nil, {}).where('note.person_id = ? AND note.note_id != ?', self.person_id, self.note_id).by_abstractor_abstraction_status(abstractor_abstraction_status, namespace_type: namespace_type, namespace_id: namespace_ids)
  end

  def procedure_occurences(options={})
    options.reverse_merge!({ include_parent_procedures: true })
    get_procedures(options)
  end

  def note_stable_identifier
    if NoteStableIdentifierFull.where(note_id: self.note_id).first
      NoteStableIdentifierFull.where(note_id: self.note_id).first.note_stable_identifier
    end
  end

  private

    def get_procedures(options)
      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      procedure_occurence_ids = FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: self.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).map(&:fact_id_2)
      procedures = SqlAudit.find_and_audit(options[:username], ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurence_ids))
      procedures = procedures.to_a
      if options[:include_parent_procedures]
        procedures_temp = procedures.dup
        procedures_temp.each do |procedure|
          procedures.concat(procedure.procedure_occurences(username: options[:username]))
        end
      end
      procedures.uniq!
      procedures
    end
end