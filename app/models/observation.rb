class Observation < ApplicationRecord
  self.table_name = 'observation'
  self.primary_key = 'observation_id'
  belongs_to :observation_concept, class_name: 'Concept', foreign_key: 'observation_concept_id'
  belongs_to :observation_type_concept, class_name: 'Concept', foreign_key: 'observation_type_concept_id'
  belongs_to :value_as_concept, class_name: 'Concept', foreign_key: 'value_as_concept_id'
  belongs_to :qualifier_concept, class_name: 'Concept', foreign_key: 'qualifier_concept_id'
  belongs_to :unit_concept, class_name: 'Concept', foreign_key: 'unit_concept_id'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  DOMAIN_ID = 'Observation'

  validates_presence_of :observation_concept_id, :observation_date, :observation_type_concept_id

  def observation_date
    read_attribute(:observation_date).to_s(:date) if read_attribute(:observation_date).present?
  end

  def value
    if value_as_number.present?
      value_as_number
    elsif value_as_string.present?
      value_as_string
    elsif value_as_concept.present?
      value_as_concept.concept_name
    end
  end
end