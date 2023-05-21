class Person < ApplicationRecord
  self.table_name = 'person'
  self.primary_key = 'person_id'
  belongs_to :gender, class_name: 'Concept', foreign_key: 'gender_concept_id'
  belongs_to :race, class_name: 'Concept', foreign_key: 'race_concept_id'
  belongs_to :ethnicity, class_name: 'Concept', foreign_key: 'ethnicity_concept_id'
  belongs_to :location, class_name: 'Location', foreign_key: 'location_id', optional: true

  has_many :adresses, class_name: 'PiiAddress', foreign_key: 'person_id'
  has_one :name, class_name: 'PiiName', foreign_key: 'person_id'
  has_many :emails, class_name: 'PiiEmail', foreign_key: 'person_id'
  has_many :phone_numbers, class_name: 'PiiPhoneNumber', foreign_key: 'person_id'
  has_many :mrns, class_name: 'PiiMrn', foreign_key: 'person_id'

  def birth_date
    Date.new(year_of_birth, month_of_birth, day_of_birth)
  end

  def full_name
    if name
      name.full_name
    end
  end
end
