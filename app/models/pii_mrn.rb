class PiiMrn < ApplicationRecord
  self.table_name = 'pii_mrn'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'

  validates_presence_of :person_id, :health_system, :mrn
end
