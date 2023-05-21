class PiiPhoneNumber < ApplicationRecord
  self.table_name = 'pii_phone_number'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'

  validates_presence_of :person_id, :phone_number
end
