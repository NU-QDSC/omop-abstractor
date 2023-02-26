class PiiName < ApplicationRecord
  self.table_name = 'pii_name'
  self.primary_key = 'person_id'

  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'

  validates_presence_of :person_id, :first_name, :last_name

  def full_name
    [first_name.titleize, middle_name.try(:titleize), last_name.titleize].reject { |n| n.nil? or n.blank?  }.join(' ')
  end
end