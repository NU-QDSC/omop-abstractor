class ConditionOccurrence < ApplicationRecord
  self.table_name = 'condition_occurrence'
  self.primary_key = 'condition_occurrence_id'
  belongs_to :condition_concept, class_name: 'Concept', foreign_key: 'condition_concept_id'
  belongs_to :condition_type_concept, class_name: 'Concept', foreign_key: 'condition_type_concept_id'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  DOMAIN_ID = 'Condition'

  validates_presence_of :condition_concept_id, :condition_start_date, :condition_type_concept_id

  def condition_start_date
    read_attribute(:condition_start_date).to_s(:date) if read_attribute(:condition_start_date).present?
  end

  def condition_end_date
    read_attribute(:condition_end_date).to_s(:date) if read_attribute(:condition_end_date).present?
  end
end
