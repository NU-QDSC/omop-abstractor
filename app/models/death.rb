class Death < ApplicationRecord
  self.table_name = 'death'
  self.primary_key = 'death_id'

  belongs_to :death_type_concept, class_name: 'Concept', foreign_key: 'death_type_concept_id'
  belongs_to :cause_concept, class_name: 'Concept', foreign_key: 'cause_concept_id'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  DOMAIN_ID = 'Death'

  validates_presence_of :death_date, :death_type_concept_id, :cause_concept_id

  def death_date
    read_attribute(:death_date).to_s(:date) if read_attribute(:death_date).present?
  end
end
