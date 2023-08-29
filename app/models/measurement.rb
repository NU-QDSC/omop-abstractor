class Measurement < ApplicationRecord
  self.table_name = 'measurement'
  self.primary_key = 'measurement_id'
  belongs_to :measurement_concept, class_name: 'Concept', foreign_key: 'measurement_concept_id'
  belongs_to :measurement_type_concept, class_name: 'Concept', foreign_key: 'measurement_type_concept_id'
  belongs_to :value_as_concept, class_name: 'Concept', foreign_key: 'value_as_concept_id'
  belongs_to :unit_concept, class_name: 'Concept', foreign_key: 'unit_concept_id'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  DOMAIN_ID = 'Measurement'

  validates_presence_of :measurement_concept_id
  # , :measurement_date, :measurement_type_concept_id

  def value
    if value_as_number.present?
      value_as_number
    elsif value_as_concept.present?
      value_as_concept.concept_name
    end
  end
end