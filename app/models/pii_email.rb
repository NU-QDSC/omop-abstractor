class PiiEmail < ApplicationRecord
  self.table_name = 'pii_email'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'

  validates_presence_of :person_id, :email
end
