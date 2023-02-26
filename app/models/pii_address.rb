class PiiAddress < ApplicationRecord
  self.table_name = 'pii_address'

  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  belongs_to :location, class_name: 'Location', foreign_key: 'location_id'

  validates_presence_of :location_id, :person_id
end
