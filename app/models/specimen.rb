class Specimen < ApplicationRecord
  self.table_name = 'specimen'
  self.primary_key = 'specimen_id'
  belongs_to :specimen_concept, class_name: 'Concept', foreign_key: 'specimen_concept_id'
  belongs_to :specimen_type_concept, class_name: 'Concept', foreign_key: 'specimen_type_concept_id'
  DOMAIN_ID = 'Specimen'
end