class Icdo3Histology < ApplicationRecord
  has_many :icdo3_histology_synonyms
  has_many :icdo3_categorizations, as: :categorizable

  HISTOLOGIES_BREAST = ['8500/2', '8540/3',  '8504/2', '8509/2', '8500/3', '8520/3', '8522/3',  '8480/3',  '8211/3',  '8201/3',  '8507/3', '8575/3',  '8200/3', '8401/3', '8315/3', '8246/3', '8490/3', '8502/3', '8509/3', '8240/3', '8504/3', '8503/3']
  HISTOLOGIES_COLON = ['8240/3', '8249/3', '8010/3', '8013/3', '8020/3', '8033/3', '8041/3', '8140/3', '8154/3', '8213/3', '8262/3', '8265/3', '8480/3', '8490/3', '8510/3', '8560/3']
  HISTOLOGIES_LUNG = ['8253/2', '8257/3', '8250/3', '8551/3', '8260/3', '8265/3', '8230/3', '8140/3', '8253/3', '8254/3', '8333/3','8144/3', '8070/2', '8071/3', '8072/3', '8083/3', '8041/3', '8045/3', '8046/3', '8013/3', '8240/3', '8249/3', '8012/3', '8560/3', '8022/3', '8032/3', '8031/3', '8980/3', '8972/3', '8082/3', '8023/3', '8430/3', '8200/3', '8562/3', '8010/3', '8250/2', '8256/3', '8044/3', '8982/3', '8070/3', '8310/3']
  HISTOLOGIES_METASTASIS = ['8000/6', '8000/9', '8010/6', '8070/6', '8140/6', '8490/6']
  # HISTOLOGIES_PANCREAS = ['8500/3', '8480/3', '8490/3', '8560/3', '8453/3', '8470/3', '8013/3', '8041/3', '8020/3', '8035/3', '8550/3', '8551/3', '8552/3', '8154/3', '8452/1', '8576/3', '8510/3', '8240/3', '8249/3', '8014/3', '8971/3', '8452/3', '8503/3']

  HISTOLOGIES_PANCREAS = ['8010/3', '8140/2', '8140/3','8500/3', '8480/3', '8490/3', '8560/3', '8453/3', '8470/3', '8013/3', '8041/3', '8020/3', '8035/3', '8550/3', '8551/3', '8552/3', '8154/3', '8452/1', '8576/3', '8510/3', '8240/3', '8249/3', '8014/3', '8971/3', '8452/3', '8503/3']
  HISTOLOGIES_PROSTATE = ['8140/3','8500/3', '8041/3', '8500/2', '8013/3', '8120/3', '8010/3']

  HISTOLOGIES_ENDOMETRIAL = ['8010/3','8013/3','8020/3','8041/3','8070/3','8263/3','8310/3','8323/3','8380/3','8382/3','8441/2','8441/3','8480/3','8570/3','8950/3','9110/3','9111/3']
  #done
  HISTOLOGIES_UTERINE_CERVIX = ['CIN 1', 'CIN 2', 'CIN 3', '8010/3', '8013/3', '8020/3', '8041/3', '8070/3', '8085/3', '8086/3', '8098/3', '8140/3', '8240/3', '8249/3', '8310/3', '8380/3', '8430/3', '8482/3', '8483/3', '8484/3', '8560/3', '8980/3', '9110/3']
  #done
  HISTOLOGIES_OVARIAN = ['8010/3', '8020/3', '8041/3', '8044/3', '8070/3', '8120/3', '8310/3', '8313/1', '8323/1', '8323/3', '8380/1', '8380/3', '8441/2', '8441/3', '8460/2', '8460/3', '8461/3', '8472/1', '8474/1', '8474/3', '8480/3', '8590/1', '8620/3', '8622/1', '8631/1', '8670/0', '8806/3', '8810/3', '8815/1', '8890/3', '8930/3', '8931/3', '8933/3', '8936/3', '8950/3', '9000/1', '9000/3', '9060/3', '9070/3', '9071/3', '9073/1', '9080/3', '9084/3', '9085/3', '9090/3', '9100/3', '9111/3']
  #done

  HISTOLOGIES_VAGINA = [  '8010/3', '8013/3', '8020/3', '8041/3', '8045/3', '8051/3', '8052/3', '8070/3', '8071/3', '8072/3', '8083/3', '8085/3', '8086/3', '8098/3', '8140/3', '8144/3', '8240/3', '8310/3', '8380/3', '8480/3', '8482/3', '8483/3', '8560/3', '8933/3', '8940/0', '8980/3', '9064/3', '9110/3']
  #done

  HISTOLOGIES_VULVA =['8010/3', '8013/3', '8020/3', '8041/3', '8045/3', '8051/3', '8052/3', '8070/3', '8071/3', '8072/3', '8083/3', '8085/3', '8086/3', '8090/3', '8098/3', '8120/3', '8140/3', '8144/3', '8200/3', '8240/3', '8249/3', '8400/3', '8401/3', '8409/3', '8413/3', '8500/3', '8542/3', '8560/3', '8562/3', '8982/3', '9020/1', '9020/3']
  #done

  HISTOLOGIES_AML =[  '9861/3', '9865/3', '9866/3', '9869/3', '9871/3', '9877/3', '9878/3', '9879/3', '9895/3', '9896/3', '9897/3', '9920/3']

  HISTOLOGIES_ESOPHOGEAL =['8140/3' ,'8200/3' ,'8430/3' ,'8244/3' ,'8070/3' ,'8083/3' ,'8560/3' ,'8074/3' ,'8051/3' ,'8013/3' ,'8041/3' ,'8240/3' ,'8249/3' ,'8010/3','8574/3' ,'8020/3','8082/3','9052/3' ,'9051/3','9053/3']
  #done

  scope :current, -> do
    where('icdo3_histologies.version = ? AND icdo3_histologies.minor_version = ?', 'new', 'ICD-O-3.2.csv')
  end

  scope :by_primary, -> do
    current.where.not('icdo3_histologies.icdo3_code IN (?)', Icdo3Histology::HISTOLOGIES_METASTASIS)
  end

  scope :by_primary_cns, -> do
    current.joins(icdo3_categorizations: :icdo3_category).where("icdo3_categories.category = ?", 'primary cns histology')
  end

  scope :by_primary_cns_2021, -> do
    joins(icdo3_categorizations: :icdo3_category).where('icdo3_categories.category = ?', '2021 primary cns histology')
  end

  scope :by_primary_cns_2016_glioma, -> do
    where('icdo3_histologies.version = ? AND icdo3_histologies.minor_version = ? AND icdo3_histologies.category IN(?)', 'new', 'the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv', [ 'diffuse astrocytic and oligodendroglial tumors', 'other astrocytic tumors','ependymal tumors', 'other gliomas'])
  end

  scope :by_cns_metastasis, -> do
    current.joins(icdo3_categorizations: :icdo3_category).where('icdo3_categories.category = ?', 'metastatic histology')
  end

  scope :by_primary_breast, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_BREAST)
  end

  scope :by_primary_colon, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_COLON)
  end

  scope :by_primary_lung, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_LUNG)
  end

  scope :by_primary_pancreas, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_PANCREAS)
  end

  scope :by_primary_prostate, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_PROSTATE)
  end

  scope :by_primary_gyne, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', [Icdo3Histology::HISTOLOGIES_ENDOMETRIAL, Icdo3Histology::HISTOLOGIES_UTERINE_CERVIX, Icdo3Histology::HISTOLOGIES_OVARIAN, Icdo3Histology::HISTOLOGIES_VAGINA, Icdo3Histology::HISTOLOGIES_VULVA].flatten.uniq!)
  end

  scope :by_primary_cervical, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_UTERINE_CERVIX)
  end

  scope :by_primary_esophogeal, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_ESOPHOGEAL)
  end

  scope :by_metastasis, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_METASTASIS)
  end

  scope :by_primary_aml, -> do
    current.where('icdo3_histologies.icdo3_code IN(?)', Icdo3Histology::HISTOLOGIES_AML)
  end

  scope :by_icdo3_code_with_synonyms, ->(icdo3_code) do
    current.joins(:icdo3_histology_synonyms).where('icdo3_histologies.icdo3_code = ?',icdo3_code).select('icdo3_histology_synonyms.icdo3_synonym_description')
  end

  scope :by_icdo3_code_with_synonyms, ->(icdo3_code) do
    current.joins(:icdo3_histology_synonyms).where('icdo3_histologies.icdo3_code = ?', icdo3_code).select('icdo3_histology_synonyms.icdo3_synonym_description')
  end

  scope :by_icdo3_code_with_synonyms_2021, ->(icdo3_code) do
    joins(:icdo3_histology_synonyms).where("icdo3_histologies.icdo3_code = ? AND icdo3_histologies.version = '2021' AND icdo3_histologies.minor_version = 'cap_ecc_primary_cns_histologies_2021.csv'", icdo3_code).select('icdo3_histology_synonyms.icdo3_synonym_description')
  end
end