class ProcedureOccurrence < ApplicationRecord
  self.table_name = 'procedure_occurrence'
  self.primary_key = 'procedure_occurrence_id'
  belongs_to :procedure_concept, class_name: 'Concept', foreign_key: 'procedure_concept_id'
  belongs_to :procedure_type_concept, class_name: 'Concept', foreign_key: 'procedure_type_concept_id'
  belongs_to :modifier_concept, class_name: 'Concept', foreign_key: 'modifier_concept_id', optional: true
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  belongs_to :provider, class_name: 'Provider', foreign_key: 'provider_id', optional: true
  DOMAIN_ID = 'Procedure'

  validates_numericality_of :quantity, message: 'is not a number', only_integer: true, greater_than: 0, allow_nil: true
  validates_presence_of :procedure_concept_id, :procedure_date, :procedure_type_concept_id

  def specimens(options={})
    get_specimens(options)
  end

  def procedure_occurences(options={})
    get_procedures(options)
  end

  def notes(options={})
    options.reverse_merge!(except_notes: [])
    n = get_notes(options)
    if options[:except_notes].any?
      n = n - options[:except_notes]
    end
    n
  end

  private
    def get_specimens(options={})
      domain_concept_specimen = Concept.domain_concepts.where(concept_name: 'Specimen').first
      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      relationship_has_specimen = Relationship.where(relationship_id: 'Has specimen').first
      specimen_ids = FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: self.procedure_occurrence_id, domain_concept_id_2: domain_concept_specimen.concept_id, relationship_concept_id: relationship_has_specimen.relationship_concept_id).map(&:fact_id_2)
      specimens = SqlAudit.find_and_audit(options[:username], Specimen.where(specimen_id: specimen_ids))
    end

    def get_procedures(options={})
      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Proc context of').first
      procedure_occurence_ids = FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: self.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).map(&:fact_id_2)
      procedures = SqlAudit.find_and_audit(options[:username], ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurence_ids))
    end

    def get_notes(options)
      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      note_ids = FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: self.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).map(&:fact_id_2)
      notes = SqlAudit.find_and_audit(options[:username], Note.where(note_id: note_ids))
    end
end