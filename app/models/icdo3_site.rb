class Icdo3Site < ApplicationRecord
  has_many :icdo3_site_synonyms
  has_many :icdo3_categorizations, as: :categorizable

  SITES_BREAST = ['C50.0', 'C50.1', 'C50.2', 'C50.3', 'C50.4', 'C50.5', 'C50.6', 'C50.8', 'C50.9']
  SITES_COLON = ['C18.0','C18.2', 'C18.3', 'C18.4', 'C18.5','C18.6', 'C18.7', 'C18.9', 'C19.9', 'C20.9']
  SITES_LUNG = ['C34.0', 'C34.1', 'C34.2', 'C34.3', 'C34.8', 'C34.9']
  SITES_PANCREAS = ['C25.0', 'C25.1', 'C25.2', 'C25.3', 'C25.4', 'C25.7', 'C25.8', 'C25.9']
  SITES_PROSTATE = ['C61.9']

  SITES_ENDOMETRIAL = ['C54.0', 'C54.1', 'C54.2', 'C54.3', 'C54.9', 'C55.9']
  #done
  #'C54.2' custom
  #'C54.3' custom
  #'C54.9' custom
  #'C55.9' custom

  SITES_UTERINE_CERVIX = ['C53.0', 'C53.1', 'C53.9']
  #done
  #'C53.0' custom
  #'C53.1' custom
  #'C57.4' custom
  #'C57.4' custom remove

  SITES_OVARIAN = ['C53.9', 'C56.9', 'C57.0']
  #done
  #'C57.0' custom
  #'C48.1' custom remove

  SITES_VAGINA = ['C52.9']
  #done

  SITES_VULVA = ['C51.0', 'C51.1', 'C51.2', 'C51.9', 'C76.3']
   #done

  SITES_LYMPH_NODE = ['C77.9']

  scope :current, -> do
    where('icdo3_sites.version = ? AND icdo3_sites.minor_version = ?', 'new', 'Topoenglish.csv')
  end

  scope :by_primary_cns, -> do
    current.joins(icdo3_categorizations: :icdo3_category).where('icdo3_categories.category = ?', 'primary cns site')
  end

  scope :by_primary_metastatic_cns, -> do
    current.joins(icdo3_categorizations: :icdo3_category).where.not('icdo3_categories.category = ?', 'primary cns site')
  end

  scope :by_primary_breast, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_BREAST + Icdo3Site::SITES_LYMPH_NODE)
  end

  scope :by_primary_metastatic_breast, -> do
    current.where.not('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_LYMPH_NODE)
  end

  scope :by_primary_colon, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_COLON)
  end

  scope :by_primary_metastatic_colon, -> do
    current.where.not('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_COLON)
  end

  scope :by_primary_lung, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_LUNG)
  end

  scope :by_primary_metastatic_lung, -> do
    current.where.not('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_LUNG)
  end

  scope :by_primary_pancreas, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_PANCREAS)
  end

  scope :by_primary_metastatic_pancreas, -> do
    current.where.not('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_PANCREAS)
  end

  scope :by_primary_prostate, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_PROSTATE)
  end

  scope :by_primary_metastatic_prostate, -> do
    current.where.not('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_PROSTATE)
  end

  scope :by_primary_gyne, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', [Icdo3Site::SITES_ENDOMETRIAL, Icdo3Site::SITES_UTERINE_CERVIX, Icdo3Site::SITES_OVARIAN, Icdo3Site::SITES_VAGINA, Icdo3Site::SITES_VULVA].flatten.uniq!)
  end

  scope :by_primary_cervical, -> do
    current.where('icdo3_sites.icdo3_code IN(?)', Icdo3Site::SITES_UTERINE_CERVIX)
  end

  scope :by_icdo3_code_with_synonyms, ->(icdo3_code) do
    current.joins(:icdo3_site_synonyms).where('icdo3_sites.icdo3_code = ?',icdo3_code).select('icdo3_site_synonyms.icdo3_synonym_description')
  end
end