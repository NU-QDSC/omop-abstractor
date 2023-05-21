class DrugExposure < ApplicationRecord
  self.table_name = 'drug_exposure'
  self.primary_key = 'drug_exposure_id'
  belongs_to :drug_concept, class_name: 'Concept', foreign_key: 'drug_concept_id'
  belongs_to :drug_type_concept, class_name: 'Concept', foreign_key: 'drug_type_concept_id'
  belongs_to :person, class_name: 'Person', foreign_key: 'person_id'
  belongs_to :route_concept, class_name: 'Concept', foreign_key: 'route_concept_id'
  belongs_to :dose_unit_concept, class_name: 'Concept', foreign_key: 'dose_unit_concept_id'

  DOMAIN_ID = 'Drug'

  validates_presence_of :drug_concept_id, :drug_exposure_start_date, :drug_type_concept_id

  def drug_exposure_start_date
    read_attribute(:drug_exposure_start_date).to_s(:date) if read_attribute(:drug_exposure_start_date).present?
  end

  def drug_exposure_end_date
    read_attribute(:drug_exposure_end_date).to_s(:date) if read_attribute(:drug_exposure_end_date).present?
  end
end
