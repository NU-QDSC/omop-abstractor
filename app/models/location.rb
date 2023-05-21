class Location < ApplicationRecord
  self.table_name = 'location'
  self.primary_key = 'location_id'
  has_one :person, class_name:  'Person', foreign_key: :location_id
  DOMAIN_ID = 'Location'

  validates_presence_of :address_1, :city, :state, :zip
end