require './lib/omop_abstractor/setup/setup'
require './lib/clamp_mapper/parser'
namespace :setup do
  desc "Truncate stable identifiers"
  task(truncate_stable_identifiers: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
  end

  desc "Compare ICDO3"
  task(compare_icdo3: :environment) do |t, args|
    Icdo3Histology.delete_all
    Icdo3HistologySynonym.delete_all
    Icdo3Site.delete_all
    Icdo3SiteSynonym.delete_all
    Icdo3Category.delete_all
    Icdo3Categorization.delete_all

    icdo3_category_primary_cns_histology = Icdo3Category.where(version: 'all', category: 'primary cns histology', categorizable_type: Icdo3Histology.to_s).first_or_create
    icdo3_category_primary_cns_2021_histology = Icdo3Category.where(version: 'all', category: '2021 primary cns histology', categorizable_type: Icdo3Histology.to_s).first_or_create
    icdo3_category_metastatic_histology = Icdo3Category.where(version: 'all', category: 'metastatic histology', categorizable_type: Icdo3Histology.to_s).first_or_create

    icdo3_category_primary_cns_site = Icdo3Category.where(version: 'all', category: 'primary cns site', categorizable_type: Icdo3Site.to_s).first_or_create
    icdo3_category_primary_site = Icdo3Category.where(version: 'all', category: 'primary site', categorizable_type: Icdo3Site.to_s).first_or_create

    #Legacy ICDO3 Histologies
    primary_cns_histologies = CSV.new(File.open('lib/setup/vocabulary/primary_cns_diagnoses.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_histologies.each do |histology|
      name = histology['name'].downcase.gsub(', nos', '').strip
      if histology['icdo3_code'].present?
        icdo3_histology = Icdo3Histology.where(version: 'legacy', minor_version: 'primary_cns_diagnoses.csv', icdo3_code: histology['icdo3_code'], icdo3_name: name, icdo3_description: "#{name} (#{histology['icdo3_code']})").first_or_create
      else
        icdo3_histology = Icdo3Histology.where(version: 'legacy', minor_version: 'primary_cns_diagnoses.csv', icdo3_code: "#{name}".downcase, icdo3_name: name, icdo3_description: "#{name}").first_or_create
      end

      Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology['name'].downcase).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
      end

      histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/primary_cns_diagnosis_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      histology_synonyms = histology_synonyms.select { |histology_synonym| histology_synonym['diagnosis_id'] == histology['id'] }
      histology_synonyms.each do |histology_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(histology_synonym['name'].downcase)
        normalized_values.each do |normalized_value|
          Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
        end
      end
    end

    primary_cns_histologies = CSV.new(File.open('lib/setup/vocabulary/cap_ecc_primary_cns_histologies.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    primary_cns_histologies.each do |histology|
      icdo3_code = histology['icdo3_code']
      icdo3_code.insert(4,'/')
      name = histology['name'].gsub(icdo3_code, '').strip
      name = name.downcase.gsub(', nos', '').strip
      icdo3_histology = Icdo3Histology.where(version: 'legacy', icdo3_code: icdo3_code, icdo3_name: name, icdo3_description: "#{name} (#{icdo3_code})").first
      if icdo3_histology.blank?
        icdo3_histology = Icdo3Histology.where(version: 'legacy', minor_version: 'cap_ecc_primary_cns_histologies.csv', icdo3_code: icdo3_code, icdo3_name: name, icdo3_description: "#{name} (#{icdo3_code})").first_or_create
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
      else
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
      end
      Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
      normalized_values = OmopAbstractor::Setup.normalize(name)
      normalized_values.each do |normalized_value|
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
      end
    end

    ##begin moomin
    primary_cns_2021_histologies = CSV.new(File.open('lib/setup/vocabulary/cap_ecc_primary_cns_histologies_2021.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    primary_cns_2021_histologies.each do |histology|
      icdo3_code = histology['icdo3_code']
      if icdo3_code
        icdo3_code.insert(4,'/')
        name = histology['name'].gsub(icdo3_code, '').strip
        name = name.downcase.gsub(', nos', '').strip
      else
        name = histology['name'].strip
        name = name.downcase.gsub(', nos', '').strip
      end
      if icdo3_code
        icdo3_histology = Icdo3Histology.where(version: '2021', minor_version: 'cap_ecc_primary_cns_histologies_2021.csv', icdo3_code: icdo3_code, icdo3_name: name, icdo3_description: "#{name} (#{icdo3_code})").first
      else
        icdo3_histology = Icdo3Histology.where(version: '2021', minor_version: 'cap_ecc_primary_cns_histologies_2021.csv', icdo3_code: name, icdo3_name: name, icdo3_description: name).first
      end

      if icdo3_histology.blank?
        if icdo3_code
          icdo3_histology = Icdo3Histology.where(version: '2021', minor_version: 'cap_ecc_primary_cns_histologies_2021.csv', icdo3_code: icdo3_code, icdo3_name: name, icdo3_description: "#{name} (#{icdo3_code})").first_or_create
        else
          icdo3_histology = Icdo3Histology.where(version: '2021', minor_version: 'cap_ecc_primary_cns_histologies_2021.csv', icdo3_code: name, icdo3_name: name, icdo3_description: name).first_or_create
        end
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
      else
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
      end
      Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_2021_histology.id, categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
      normalized_values = OmopAbstractor::Setup.normalize(name)
      normalized_values.each do |normalized_value|
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
      end
    end
    ##end moomin

    #metastatic histologies
    metastatic_histologies = CSV.new(File.open('lib/setup/vocabulary/metastatic_diagnoses.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    metastatic_histologies.each do |histology|
      name = histology['name'].downcase.gsub(', nos', '').strip
      if histology['icdo3_code'].present?
        icdo3_histology = Icdo3Histology.where(version: 'legacy', minor_version: 'metastatic_diagnoses.csv', icdo3_code: histology['icdo3_code'], icdo3_name: name, icdo3_description: "#{name} (#{histology['icdo3_code']})").first_or_create
      else
        icdo3_histology = Icdo3Histology.where(version: 'legacy', minor_version: 'metastatic_diagnoses.csv', icdo3_code: name, icdo3_name: name, icdo3_description: name).first_or_create
      end
      Icdo3Categorization.where(icdo3_category_id: icdo3_category_metastatic_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value.downcase).first_or_create
      end

      histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/metastatic_diagnosis_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      histology_synonyms = histology_synonyms.select { |histology_synonym| histology_synonym['diagnosis_id'] == histology['id'] }
      histology_synonyms.each do |histology_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(histology_synonym['name'].downcase)
        normalized_values.each do |normalized_value|
          Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value.downcase).first_or_create
        end
      end
    end

    sites = CSV.new(File.open('lib/setup/vocabulary/icdo3_sites.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = CSV.new(File.open('lib/setup/vocabulary/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites.each do |site|
      name = site.to_hash['name'].downcase.gsub(', nos', '').strip
      icdo3_site = Icdo3Site.where(version: 'legacy', minor_version: 'icdo3_sites.csv', icdo3_code: site.to_hash['icdo3_code'], icdo3_name: name, icdo3_description: "#{name} (#{site.to_hash['icdo3_code']})", category: 'central nervous system').first_or_create
      Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: name).first_or_create

      if primary_cns_sites.include?(icdo3_site.icdo3_code)
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_site.id, categorizable_id: icdo3_site.id, categorizable_type: Icdo3Site.to_s).first_or_create
      else
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_site.id, categorizable_id: icdo3_site.id, categorizable_type: Icdo3Site.to_s).first_or_create
      end

      normalized_values = OmopAbstractor::Setup.normalize(name)
      normalized_values.each do |normalized_value|
        Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: site.to_hash['name'].downcase).first_or_create
      end

      site_synonyms = CSV.new(File.open('lib/setup/vocabulary/icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms.select { |site_synonym| site.to_hash['icdo3_code'] == site_synonym.to_hash['icdo3_code'] }.each do |site_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(site_synonym.to_hash['synonym_name'].downcase)
        normalized_values.each do |normalized_value|
          Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: normalized_value.downcase).first_or_create
        end
      end
    end

    # ICDO3 Sites
    # https://apps.who.int/classifications/apps/icd/ClassificationDownload/DLArea/Download.aspx
    # https://apps.who.int/classifications/apps/icd/ClassificationDownload/DLArea/ICD-O-3_CSV-metadata.zip
    # Source File: Topoenglish.txt
    # Primary Central Nerverous Sytem ICDO3 Site Classification
    # https://training.seer.cancer.gov/brain/tumors/abstract-code-stage/topographic.html
    # Plus some custom adds:
    #   C41.0   bones of skull and face and associated joints
    #   C41.1   mandible
    #   C44.4   skin of scalp and neck
    #   C75.1   pituitary gland
    #   C75.2   craniopharyngeal duct
    #   C75.3   pineal gland

    sites = CSV.new(File.open('lib/setup/vocabulary/ICD-O-3_CSV-metadata/Topoenglish.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    sites = sites.select { |site| site['Lvl'] == '4' }
    primary_cns_sites = CSV.new(File.open('lib/setup/vocabulary/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites.each do |site|
      name = site['Title'].downcase.gsub(', nos', '').strip
      icdo3_site = Icdo3Site.where(version: 'new', minor_version: 'Topoenglish.csv', icdo3_code: site['Kode'], icdo3_name: name, icdo3_description: "#{name} (#{site['Kode']})").first_or_create
      Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: name).first_or_create

      if primary_cns_sites.include?(icdo3_site.icdo3_code)
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_site.id, categorizable_id: icdo3_site.id, categorizable_type: Icdo3Site.to_s).first_or_create
      else
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_site.id, categorizable_id: icdo3_site.id, categorizable_type: Icdo3Site.to_s).first_or_create
      end

      normalized_values = OmopAbstractor::Setup.normalize(name)
      normalized_values.each do |normalized_value|
        Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: name).first_or_create
      end

      site_synonyms = CSV.new(File.open('lib/setup/vocabulary/ICD-O-3_CSV-metadata/Topoenglish.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms = site_synonyms.select { |site_synonym| site_synonym['Lvl'] == 'incl' && site_synonym['Kode'] == icdo3_site.icdo3_code }
      site_synonyms.each do |site_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(site_synonym['Title'].downcase)
        normalized_values.each do |normalized_value|
          Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: normalized_value.downcase).first_or_create
        end
      end

      site_synonyms = CSV.new(File.open('lib/setup/vocabulary/legacy_icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms = site_synonyms.select { |site_synonym| site_synonym['icdo3_code'] == icdo3_site.icdo3_code }
      site_synonyms.each do |site_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(site_synonym['icdo3_synonym_description'].downcase)
        normalized_values.each do |normalized_value|
          Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: normalized_value.downcase).first_or_create
        end
      end

      site_synonyms = CSV.new(File.open('lib/setup/vocabulary/new_custom_icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms = site_synonyms.select { |site_synonym| site_synonym['icdo3_code'] == icdo3_site.icdo3_code }
      site_synonyms.each do |site_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(site_synonym['icdo3_synonym_description'].downcase)
        normalized_values.each do |normalized_value|
          Icdo3SiteSynonym.where(icdo3_site_id: icdo3_site.id, icdo3_synonym_description: normalized_value.downcase).first_or_create
        end
      end
    end

    # The 2016 World Health Organization Classification of Tumors of the Central Nervous System
    # https://pubmed.ncbi.nlm.nih.gov/27157931/
    # https://www.kaggle.com/researchnurse/who-2016-cns-tumor-classifications?select=WHO_+2016_+CNS_Tumor_Classifications.csv
    who_2016_cns_histologies = CSV.new(File.open('lib/setup/vocabulary/the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    who_2016_cns_histologies.each do |histology|
      if histology['icdo3_code'].present?
        name = histology['icdo3_description'].downcase.gsub('nos', '').strip
        icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv', icdo3_code: histology['icdo3_code'], icdo3_name: name, icdo3_description: "#{name} (#{histology['icdo3_code']})", category: histology['category']).first_or_create
        icdo3_category = Icdo3Category.where(version: '2016 WHO Classification of CNS Tumors', category: histology['category'], categorizable_type: Icdo3Histology.to_s).first_or_create
        Icdo3Categorization.where(icdo3_category_id: icdo3_category.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create

        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
        normalized_values = OmopAbstractor::Setup.normalize(name)
        normalized_values.each do |normalized_value|
          Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
        end
      end
    end

    # ICD-O-3.2
    # https://www.naaccr.org/icdo3/#1582820761121-27c484fc-46a7
    # Copy-of-ICD-O-3.2_MFin_17042019_web.csv
    # https://www.pathologyoutlines.com/topic/cnstumorwhoclassification.html
    primary_cns_sites = CSV.new(File.open('lib/setup/vocabulary/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    primary_cns_site_wildcards = ['C41._', 'C44._', 'C70._', 'C71._', 'C72._', 'C75._']
    primary_cns_sites.concat(primary_cns_site_wildcards)

    pituitary_histologies = CSV.new(File.open('lib/setup/vocabulary/WHO Classification of Tumors of Endocrine Organs (Medicine) 4th Edition.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    pituitary_histologies = pituitary_histologies.map { |pituitary_histology| pituitary_histology['ICDO3.2'] }.compact!

    icdo_32_cns_histologies = CSV.new(File.open('lib/setup/vocabulary/ICD-O-3.2.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    icdo_32_cns_histologies.each do |histology|
      if ['Preferred'].include?(histology['Level'])
        name = histology['Term'].downcase.gsub(', nos', '').strip
        icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: histology['ICDO3.2'], icdo3_name: name, icdo3_description: "#{name} (#{histology['ICDO3.2']})", code_reference: histology['Code reference'], obs: histology['obs'], see_also: histology['See also'], includes: histology['Includes'], excludes: histology['Excludes'], other_text: histology['Other text']).first_or_create

        if histology['Code reference'].present?
          sites = histology['Code reference'].gsub('(', '')
          sites = sites.gsub(')', '')
          sites = sites.split(',')
          categorizations = sites & primary_cns_sites
          if categorizations.any?
            Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
          end
        end

        if pituitary_histologies.include?(histology['ICDO3.2'])
          puts 'Got a pituitary!'
          puts histology['ICDO3.2']
          Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
        end

        # already
        # glioma, malignant   9380/3              brainstem glioma
        # chordoma, nos       9370/3              chordoma
        # glioma, malignant   9380/3              glioma
        # glioma, malignant   9380/3              optic nerve glioma
        # pineoblastoma       9362/3              pineal tumor of intermediate differentiation
        #
        # add categorization
        # dysembryoplastic neuroepithelial tumor 9413/0               desmoplastic neuroectodermal tumor
        # nerve sheath tumor, nos                9563/0               nerve sheath tumor
        # retinoblastoma, nos                    9510/3               retinoblastoma
        #
        # add custom
        # colloid cyst
        # epidermoid
        # gliosis
        # gliosis-epilepsy
        # no evidence of tumor
        # primary intraocular lymphoma
        # radiation necrosis

        #categorizing of legacy custom histologies to actual ICD3 codes and found histologies declared not categorizable otherwise.
        # '8000/0'= neoplasm, benign = need
        # '8000/3'=neoplasm, malignant = need
        # '9413/0' = dysembryoplastic neuroepithelial tumor = desmoplastic neuroectodermal tumor = legacy custom map
        # '9563/0' = nerve sheath tumor = nerve sheath tumor = legacy custom map
        # '9510/3' = retinoblastoma = retinoblastoma = legacy custom map
        # '9138/1' = pseudomyogenic (epithelioid sarcoma-like) hemangioendothelioma  = need


        if ['8000/0', '8000/3', '9413/0', '9563/0', '9510/3', '9138/1'].include?(histology['ICDO3.2'])
          Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
        end

        Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
        normalized_values = OmopAbstractor::Setup.normalize(name)
        normalized_values.each do |normalized_value|
          Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
        end

        if ['8000/6', '8000/9', '8010/6', '8070/6', '8140/6', '8490/6', '8898/1', '9310/3', '8246/3'].include?(histology['ICDO3.2'])
          Icdo3Categorization.where(icdo3_category_id: icdo3_category_metastatic_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
        end
      end

      if ['Preferred'].include?(histology['Level'])
        icdo_32_cns_histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/ICD-O-3.2.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
        icdo_32_cns_histology_synonyms = icdo_32_cns_histology_synonyms.select { |icdo_32_cns_histology_synonym| icdo_32_cns_histology_synonym['ICDO3.2'] == histology['ICDO3.2'] && ['Synonym', 'Related'].include?(icdo_32_cns_histology_synonym['Level']) }

        icdo_32_cns_histology_synonyms.each do |icdo_32_cns_histology_synonym|
          name = icdo_32_cns_histology_synonym['Term'].downcase.gsub(', NOS', '').strip
          Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: name).first_or_create
          normalized_values = OmopAbstractor::Setup.normalize(name)
          normalized_values.each do |normalized_value|
            Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: normalized_value).first_or_create
          end
        end
      end
    end

    ['colloid cyst', 'epidermoid', 'gliosis', 'gliosis-epilepsy', 'no evidence of tumor', 'primary intraocular lymphoma', 'radiation necrosis'].each do |histology|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: histology, icdo3_name: histology, icdo3_description: "#{histology}").first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology).first_or_create
      Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
    end

    ['no tumor seen', 'no tumor is seen', 'no viable tumor seen', 'negative for malignancy', 'no evidence of malignancy'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'no evidence of tumor').first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    ['metastatic angiosarcoma', 'metastatic glioblastoma', 'metastatic leiomyosarcoma', 'metastatic melanoma', 'metastatic sarcoma'].each do |histology|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: histology, icdo3_name: histology, icdo3_description: "#{histology}").first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology).first_or_create
      Icdo3Categorization.where(icdo3_category_id: icdo3_category_metastatic_histology.id,  categorizable_id: icdo3_histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
    end

    # 'sarcoma'
    ['metastatic spindle cell sarcoma', 'metastatic myxoid spindle cell sarcoma', 'metastatic sarcoma'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'metastatic sarcoma').first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    ['metastatis leiomyosarcoma', 'metastatic leiomyosarcoma', 'metastatic epithelioid leiomyosarcoma'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'metastatic leiomyosarcoma').first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    ['metastatic angiosarcoma'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'metastatic angiosarcoma').first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    ['metastatic glioblastoma'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'metastatic glioblastoma').first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    # 'melanoma'
    ['metastatic melanoma'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'metastatic melanoma').first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    # CIN 1
    ['cin i', 'cin1', 'cin-1', 'cin-i', 'cervical intraepithelial neoplasia 1', 'cervical intra-epithelial neoplasia 1', 'cervical intraepithelial neoplasia i', 'cervical intra-epithelial neoplasia i', 'lsil', 'low grade squamous intraepithelial lesion', 'low grade squamous intra-epithelial lesion', 'low-grade squamous intraepithelial lesion', 'low-grade squamous intra-epithelial lesion', 'adenocarcinoma in situ 1', 'ais 1', 'ais1', 'ais-1'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'CIN 1', icdo3_name: 'CIN 1', icdo3_description: 'CIN 1').first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    # CIN 2
    ['cin ii', 'cin2', 'cin-2', 'cin-ii', 'cervical intraepithelial neoplasia 2', 'cervical intra-epithelial neoplasia 2', 'cervical intraepithelial neoplasia ii', 'cervical intra-epithelial neoplasia ii', 'hsil 2', 'hsil ii', 'hsil2', 'hgsil 2', 'hgsil ii', 'hgsil2', 'adenocarcinoma in situ 2', 'ais 2', 'ais2', 'ais-2'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'CIN 2', icdo3_name: 'CIN 2', icdo3_description: 'CIN 2').first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    # CIN 3
    ['cin iii', 'cin3', 'cin-3', 'CIN 2-3', 'CIN 2/3', 'cin-iii', 'cervical intraepithelial neoplasia 3', 'cervical intra-epithelial neoplasia 3', 'cervical intraepithelial neoplasia iii', 'cervical intra-epithelial neoplasia iii', 'hsil 3', 'hsil iii', 'hsil3', 'hgsil 3', 'hgsil iii', 'hgsil3', 'adenocarcinoma in situ 3', 'ais 3', 'ais3', 'ais-3'].each do |histology_synonym|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: 'CIN 3', icdo3_name: 'CIN 3', icdo3_description: 'CIN 3').first_or_create
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology_synonym).first_or_create
    end

    legacy_icdo3_metastatic_histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/legacy_icdo3_metastatic_histology_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    legacy_icdo3_metastatic_histology_synonyms.each do |histology|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: histology['icdo3_code']).first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology['icdo3_synonym_description']).first_or_create
    end

    who_2016_cns_histologies = CSV.new(File.open('lib/setup/vocabulary/the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    who_2016_cns_idco3_codes = who_2016_cns_histologies.map { |histology| histology['icdo3_code'] }.uniq

    who_2016_cns_idco3_codes.each do |who_2016_cns_idco3_code|
      icdo3_histologies = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: who_2016_cns_idco3_code).all
      icdo3_histologies.each do |histology|
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
      end
    end

    legacy_icdo3_histology_codes = CSV.new(File.open('lib/setup/vocabulary/legacy_icdo3_histology_codes.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    legacy_icdo3_histology_codes = legacy_icdo3_histology_codes.map { |histology| histology['icdo3_code'] }.uniq

    legacy_icdo3_histology_codes.each do |legacy_icdo3_histology_code|
      icdo3_histologies = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: legacy_icdo3_histology_code).all
      icdo3_histologies.each do |histology|
        Icdo3Categorization.where(icdo3_category_id: icdo3_category_primary_cns_histology.id,  categorizable_id: histology.id, categorizable_type: Icdo3Histology.to_s).first_or_create
      end
    end

    legacy_icdo3_histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/legacy_icdo3_histology_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    legacy_icdo3_histology_synonyms.each do |histology|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: histology['icdo3_code']).first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology['icdo3_code_synonym_description']).first_or_create
    end

    new_icdo3_histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/new_custom_icdo3_histology_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    new_icdo3_histology_synonyms.each do |histology|
      icdo3_histology = Icdo3Histology.where(version: 'new', minor_version: 'ICD-O-3.2.csv', icdo3_code: histology['icdo3_code']).first
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology['icdo3_code_synonym_description']).first_or_create
    end

    new_2001_histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/new_custom_2021_icdo3_histology_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    new_2001_histology_synonyms.each do |histology|
      icdo3_histology = Icdo3Histology.where(version: '2021', minor_version: 'cap_ecc_primary_cns_histologies_2021.csv', icdo3_code: histology['icdo3_code']).first
      if icdo3_histology.blank?
        icdo3_histology = Icdo3Histology.where(version: '2021', minor_version: 'cap_ecc_primary_cns_histologies_2021.csv', icdo3_name: histology['name']).first
      end
      Icdo3HistologySynonym.where(icdo3_histology_id: icdo3_histology.id, icdo3_synonym_description: histology['icdo3_code_synonym_description']).first_or_create
    end
  end

  desc 'Load schemas'
  task(schemas: :environment) do |t, args|
    date_object_type = Abstractor::AbstractorObjectType.where(value: 'date').first
    list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
    boolean_object_type = Abstractor::AbstractorObjectType.where(value: 'boolean').first
    string_object_type = Abstractor::AbstractorObjectType.where(value: 'string').first
    number_object_type = Abstractor::AbstractorObjectType.where(value: 'number').first
    radio_button_list_object_type = Abstractor::AbstractorObjectType.where(value: 'radio button list').first
    dynamic_list_object_type = Abstractor::AbstractorObjectType.where(value: 'dynamic list').first
    text_object_type = Abstractor::AbstractorObjectType.where(value: 'text').first
    name_value_rule = Abstractor::AbstractorRuleType.where(name: 'name/value').first
    value_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
    unknown_rule = Abstractor::AbstractorRuleType.where(name: 'unknown').first
    source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
    source_type_custom_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'custom nlp suggestion').first
    indirect_source_type = Abstractor::AbstractorAbstractionSourceType.where(name: 'indirect').first

    #surgical pathology report abstractions setup begin
    #concept_id 10  = 'Procedure Occurrence'
    #concept_id 5085 = 'Note'
    #concept_id 44818790 = 'Has procedure context (SNOMED)'
    #concept_id 4213297 = 'Surgical pathology procedure'
    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note ON note_stable_identifier.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Final Diagnosis', 'Final Pathologic Diagnosis') AND note_date >='2018-03-01'").first_or_create
    # where_clause: "note.note_title = 'Final Diagnosis'").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    primary_cns_histologies = CSV.new(File.open('lib/setup/data/primary_cns_diagnoses.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    primary_cns_histologies.each do |histology|
      name = histology['name'].downcase.gsub(', nos', '').strip
      if histology['icdo3_code'].present?
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology['icdo3_code']})".downcase, vocabulary_code: histology['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: 'ICD-O-3').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology['name'].downcase).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = CSV.new(File.open('lib/setup/data/primary_cns_diagnosis_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      histology_synonyms = histology_synonyms.select { |histology_synonym| histology_synonym['diagnosis_id'] == histology['id'] }
      histology_synonyms.each do |histology_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology_synonym['name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    sites = CSV.new(File.open('lib/setup/data/icdo3_sites.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = CSV.new(File.open('lib/setup/data/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites = sites.select { |site| primary_cns_sites.include?(site['icdo3_code']) }
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.to_hash['name']} (#{site.to_hash['icdo3_code']})".downcase, vocabulary_code: site.to_hash['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.to_hash['name'].downcase).first_or_create
      site_synonyms = CSV.new(File.open('lib/setup/data/icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms.select { |site_synonym| site.to_hash['icdo3_code'] == site_synonym.to_hash['icdo3_code'] }.each do |site_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site_synonym.to_hash['synonym_name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create
    lateralites = ['bilateral', 'left', 'right']
    lateralites.each do |laterality|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: laterality, vocabulary_code: laterality).first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin WHO Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_who_grade',
      display_name: 'WHO Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'grade').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 1', vocabulary_code: 'Grade 1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade I').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 2', vocabulary_code: 'Grade 2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade II').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 3', vocabulary_code: 'Grade 3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade III').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 4', vocabulary_code: 'Grade 4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade IV').first_or_create


    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End WHO Grade

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'initial', vocabulary_code: 'initial').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'recurrent', vocabulary_code: 'recurrent').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'residual').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'recurrence').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End primary cancer
    #Begin metastatic
    metastatic_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Metastatic Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    metastatic_histologies = CSV.new(File.open('lib/setup/data/metastatic_diagnoses.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    metastatic_histologies.each do |histology|
      name = histology['name'].downcase.gsub(', nos', '').strip
      if histology['icdo3_code'].present?
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology['icdo3_code']})".downcase, vocabulary_code: histology['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: 'ICD-O-3').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology['name'].downcase).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = CSV.new(File.open('lib/setup/data/primary_cns_diagnosis_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      histology_synonyms = histology_synonyms.select { |histology_synonym| histology_synonym['diagnosis_id'] == histology['id'] }
      histology_synonyms.each do |histology_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology_synonym['name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #Begin metastatic cancer site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    sites = CSV.new(File.open('lib/setup/data/icdo3_sites.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = CSV.new(File.open('lib/setup/data/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites = sites.select { |site| primary_cns_sites.include?(site['icdo3_code']) }
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.to_hash['name']} (#{site.to_hash['icdo3_code']})".downcase, vocabulary_code: site.to_hash['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.to_hash['name'].downcase).first_or_create
      site_synonyms = CSV.new(File.open('lib/setup/data/icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms.select { |site_synonym| site.to_hash['icdo3_code'] == site_synonym.to_hash['icdo3_code'] }.each do |site_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site_synonym.to_hash['synonym_name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer site

    #Begin metastatic cancer primary site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_primary_site',
      display_name: 'Primary Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'primary cancer site').first_or_create

    sites = CSV.new(File.open('lib/setup/data/icdo3_sites.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = CSV.new(File.open('lib/setup/data/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites = sites.select { |site| !primary_cns_sites.include?(site['icdo3_code']) }
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.to_hash['name']} (#{site.to_hash['icdo3_code']})".downcase, vocabulary_code: site.to_hash['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.to_hash['name'].downcase).first_or_create
      site_synonyms = CSV.new(File.open('lib/setup/data/icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms.select { |site_synonym| site.to_hash['icdo3_code'] == site_synonym.to_hash['icdo3_code'] }.each do |site_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site_synonym.to_hash['synonym_name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer primary site

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create
    lateralites = ['bilateral', 'left', 'right']
    lateralites.each do |laterality|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: laterality, vocabulary_code: laterality).first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'initial', vocabulary_code: 'initial').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'recurrent', vocabulary_code: 'recurrent').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'residual').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'recurrence').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End metastatic

    #Begin IDH1 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh1_status',
      display_name: 'IDH1 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh1').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh-1')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh 1')

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create

    #End IDH1 status

    #Begin IDH2 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh2_status',
      display_name: 'IDH2 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh2').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh-2')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh 2')

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End IDH2 status

    #Begin 1p status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_1p_status',
      display_name: '1P Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '1P').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'OneP')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '1-P')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '1P19Q')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '1P-19Q')

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'deleted', vocabulary_code: 'deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'del.').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'non-deleted', vocabulary_code: 'non-deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'nondeleted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not deleted').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End 1p status

    #Begin 19q status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_19q_status',
      display_name: '19q Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '19Q').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'NineteenQ')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '19-Q')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '1P19Q')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '1P-19Q')

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'deleted', vocabulary_code: 'deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'del.').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'non-deleted', vocabulary_code: 'non-deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'nondeleted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not deleted').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End 19q status

    #Begin 10q/PTEN status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_10q_PTEN_status',
      display_name: '10q/PTEN Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '10q/PTEN').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '10qPTEN')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '10q-PTEN')

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'deleted', vocabulary_code: 'deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'del.').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'non-deleted', vocabulary_code: 'non-deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'nondeleted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not deleted').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End 10q/PTEN status

    #Begin MGMT promoter methylation status Status status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_mgmt_status',
      display_name: 'MGMT promoter methylation status Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'MGMT').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End MGMT promoter methylation status Status

    #Begin ki67
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_ki67',
      display_name: 'ki67',
      abstractor_object_type: number_object_type,
      preferred_name: 'ki67').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'ki-67')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'mib-1')
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'mib1')

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End ki67

    #Begin p53
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_p53',
      display_name: 'p53',
      abstractor_object_type: number_object_type,
      preferred_name: 'p53').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.create(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'p-53')

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create

    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End p53

    # #Begin text_area
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_text_schema',
    #   display_name: 'Text Schema',
    #   abstractor_object_type: text_object_type,
    #   preferred_name: 'Text Schema').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # #End text_area

    #surgical pathology report abstractions setup end

    #outside surgical pathology report abstractions setup begin
    #surgical pathology report abstractions setup begin
    #concept_id 10  = 'Procedure Occurrence'
    #concept_id 5085 = 'Note'
    #concept_id 44818790 = 'Has procedure context (SNOMED)'
    #concept_id 4244107 = 'Surgical pathology consultation and report on referred slides prepared elsewhere'
    abstractor_namespace_outside_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note ON note_stable_identifier.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    # where_clause: "note.note_title = 'Final Diagnosis'").first_or_create
    where_clause: "note.note_title IN('Final Diagnosis', 'Final Pathologic Diagnosis') AND note_date >='2018-03-01'").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    #End primary cancer
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin surgery date
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_surgery_date',
      display_name: 'Surgery Date',
      abstractor_object_type: date_object_type,
      preferred_name: 'Surgery Date').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End surgery date

    #Begin WHO Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_who_grade',
      display_name: 'WHO Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'grade').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End WHO Grade

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End primary cancer
    #Begin metastatic
    metastatic_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Metastatic Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #Begin metastatic cancer site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer site

    #Begin metastatic cancer primary site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_primary_site',
      display_name: 'Primary Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'primary cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer primary site

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End metastatic

    #Begin IDH1 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh1_status',
      display_name: 'IDH1 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh1').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create

    #End IDH1 status

    #Begin IDH2 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh2_status',
      display_name: 'IDH2 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh2').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End IDH2 status

    #Begin 1p status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_1p_status',
      display_name: '1P Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '1P').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End 1p status

    #Begin 19q status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_19q_status',
      display_name: '19q Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '19Q').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End 19q status

    #Begin 10q/PTEN status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_10q_PTEN_status',
      display_name: '10q/PTEN Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '10q/PTEN').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End 10q/PTEN status

    #Begin MGMT promoter methylation status Status status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_mgmt_status',
      display_name: 'MGMT promoter methylation status Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'MGMT').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End MGMT promoter methylation status Status

    #Begin ki67
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_ki67',
      display_name: 'ki67',
      abstractor_object_type: number_object_type,
      preferred_name: 'ki67').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End ki67

    #Begin p53
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_p53',
      display_name: 'p53',
      abstractor_object_type: number_object_type,
      preferred_name: 'p53').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
    #End p53

    #outside surgical pathology report abstractions setup end

    #molecular genetics report abstractions setup begin
    abstractor_namespace_molecular_pathology = Abstractor::AbstractorNamespace.where(name: 'Molecular Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note ON note_stable_identifier.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4019097",
     where_clause: "note.note_title = 'Interpretation'").first_or_create

     abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
       predicate: 'has_mgmt_status',
       display_name: 'MGMT promoter methylation status Status',
       abstractor_object_type: radio_button_list_object_type,
       preferred_name: 'MGMT').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_molecular_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'health_heritage_casefinder_nlp_service').first_or_create
  end

  desc "Load dummy data"
  task(dummy_data: :environment) do |t, args|
    #Person 1
    location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
    person = Person.where(person_id: 1, gender_concept_id: Concept.genders.first, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: Concept.races.first, ethnicity_concept_id: Concept.ethnicities.first, person_source_value: '123', location: location).first_or_create
    location = Location.where(location_id: 2, address_1: '123 Main St', address_2: '3F', city: 'Chicago', state: 'IL', zip: '60657', county: 'Cook', location_source_value: nil).first_or_create
    person.adresses.where(location: location).first_or_create
    person.emails.where(email: 'person1@ohdsi.org').first_or_create
    person.mrns.where(health_system: 'NMHC',  mrn: '111').first_or_create
    if person.name
      person.name.destroy!
    end
    person.build_name(first_name: 'Harold', middle_name: nil , last_name: 'Baines' , suffix: 'Mr' , prefix: nil)
    person.save!
    person.phone_numbers.where(phone_number: '8471111111').first_or_create
    gender_concept = Concept.genders.where(concept_name: 'MALE').first

    provider = Provider.where(provider_id: 1, provider_name: 'Craig Horbinski', npi: '1730345026', dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept.concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil).first_or_create
    procedure_concept = Concept.procedure_concepts.where(concept_code: '39228008').first #Surgical Pathology
    procedure_type_concept = Concept.procedure_types.where(concept_name: 'Secondary Procedure').first
    procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: 1, person_id: person.person_id, procedure_concept_id: procedure_concept.concept_id, procedure_date: Date.parse('1/1/2018'), procedure_datetime: Date.parse('1/1/2018'), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: provider.provider_id, visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil).first_or_create
    note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
    note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first

    inside = true
    if inside
      #surgical pathology report begin
      note_text = File.read("#{Rails.root}/lib/setup/data/pathology_cases/1.txt")
      note = Note.where(note_id: 1, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Final Diagnosis', note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      note = Note.where(note_id: 2, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Gross Description', note_text: 'Gross description of the front parietal lobe.', encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      note = Note.where(note_id: 3, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Comment', note_text: 'Comment on the surgical pathology procedure.', encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      specimen_code_concept = Concept.specimen_concepts.where(concept_name: 'Brain neoplasm tissue sample').first
      specimen_type_concept = Concept.specimen_types.first
      domain_concept_specimen = Concept.domain_concepts.where(concept_name: 'Specimen').first
      relationship_has_specimen = Relationship.where(relationship_id: 'Has specimen').first
      relationship_specimen_of = Relationship.where(relationship_id: 'Specimen of').first
      specimen = Specimen.where(specimen_id: 1, person_id: person.person_id, specimen_concept_id: specimen_code_concept.concept_id, specimen_type_concept_id: specimen_type_concept.concept_id, specimen_date: Date.parse('1/1/2018'), specimen_datetime: Date.parse('1/1/2018')).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_specimen.concept_id, fact_id_2: specimen.specimen_id, relationship_concept_id: relationship_has_specimen.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_specimen.concept_id, fact_id_1: specimen.specimen_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      procedure_concept = Concept.procedure_concepts.where(concept_code: '61512', vocabulary_id: 'CPT4').first #PR EXCIS SUPRATENT MENINGIOMA
      procedure_type_concept = Concept.procedure_types.where(concept_name: 'Primary Procedure').first
      gender_concept = Concept.genders.where(concept_name: 'MALE').first
      provider = Provider.where(provider_id: 2, provider_name: 'James Chandler', npi: '1881656411', dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept.concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil).first_or_create
      surgery_procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: 2, person_id: person.person_id, procedure_concept_id: procedure_concept.concept_id, procedure_date: Date.parse('1/1/2018'), procedure_datetime: Date.parse('1/1/2018'), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: provider.provider_id, visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil).first_or_create
      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: surgery_procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: surgery_procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      #surgical pathology report end
    end

    synoptic = false
    if synoptic
      #synoptic begin
      note_text = File.read("#{Rails.root}/lib/setup/data/pathology_cases/2.txt")
      note = Note.where(note_id: 4, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Synoptic Reports', note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      note = Note.where(note_id: 5, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Gross Description', note_text: 'Gross description of the front parietal lobe.', encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      note = Note.where(note_id: 6, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Comment', note_text: 'Comment on the surgical pathology procedure.', encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      specimen_code_concept = Concept.specimen_concepts.where(concept_name: 'Brain neoplasm tissue sample').first
      specimen_type_concept = Concept.specimen_types.first
      domain_concept_specimen = Concept.domain_concepts.where(concept_name: 'Specimen').first
      relationship_has_specimen = Relationship.where(relationship_id: 'Has specimen').first
      relationship_specimen_of = Relationship.where(relationship_id: 'Specimen of').first
      specimen = Specimen.where(specimen_id: 2, person_id: person.person_id, specimen_concept_id: specimen_code_concept.concept_id, specimen_type_concept_id: specimen_type_concept.concept_id, specimen_date: Date.parse('1/1/2018'), specimen_datetime: Date.parse('1/1/2018')).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_specimen.concept_id, fact_id_2: specimen.specimen_id, relationship_concept_id: relationship_has_specimen.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_specimen.concept_id, fact_id_1: specimen.specimen_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      procedure_concept = Concept.procedure_concepts.where(concept_code: '61512', vocabulary_id: 'CPT4').first #PR EXCIS SUPRATENT MENINGIOMA
      procedure_type_concept = Concept.procedure_types.where(concept_name: 'Primary Procedure').first
      gender_concept = Concept.genders.where(concept_name: 'MALE').first
      provider = Provider.where(provider_id: 2, provider_name: 'James Chandler', npi: '1881656411', dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept.concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil).first_or_create
      surgery_procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: 2, person_id: person.person_id, procedure_concept_id: procedure_concept.concept_id, procedure_date: Date.parse('1/1/2018'), procedure_datetime: Date.parse('1/1/2018'), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: provider.provider_id, visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil).first_or_create
      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: surgery_procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: surgery_procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create

      #surgical pathology report end
    end

    outside = true
    if outside
      # #outside surgical pathology report begin
      gender_concept = Concept.genders.where(concept_name: 'MALE').first
      provider = Provider.where(provider_id: 1, provider_name: 'Craig Horbinski', npi: '1730345026', dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept.concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil).first_or_create
      procedure_concept = Concept.where(concept_code: '59000001').first #"Surgical pathology consultation and report on referred slides prepared elsewhere"
      procedure_type_concept = Concept.procedure_types.where(concept_name: 'Secondary Procedure').first

      procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: 3, person_id: person.person_id, procedure_concept_id: procedure_concept.concept_id, procedure_date: Date.parse('1/1/2018'), procedure_datetime: Date.parse('1/1/2018'), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: provider.provider_id, visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil).first_or_create
      note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
      note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first
      note_text = File.read("#{Rails.root}/lib/setup/data/pathology_cases/2.txt")
      note = Note.where(note_id: 4, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Final Diagnosis', note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create

      note = Note.where(note_id: 5, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Gross Description', note_text: 'Gross description of the front parietal lobe.', encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end

      domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
      domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
      relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
      relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
      FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create


      note = Note.where(note_id: 6, person_id: person.person_id, note_date: Date.parse('1/1/2019'), note_datetime: Date.parse('1/1/2018'), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Comment', note_text: 'Comment on the surgical pathology procedure.', encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: nil, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end
      #outside surgical pathology report end
    end
  end

  desc "Update provider specialties"
  task(update_provider_specialities: :environment) do |t, args|
    neurosurgeons = ['1922261742', '1710018551', '1881656411', '1336107937', '1831307339', '1366487969', '1235220955', '1467616193', '1124041603', '1326103151', '1902148158', '1306174008', '1053336776', '1982846788', '1023261138', '1316203995', '1861768566', '1730217563', '1265478119']
    neuropathologists = ['1639145311', '1982639001', '1972949154', '1730345026', '1053514513', '1619139631', '1295979003']

    neurosurgeons.each do |neurosurgeon|
      provider = Provider.where(npi: neurosurgeon).first
      provider.specialty_concept_id = 38004459 #Neurosurgery https://athena.ohdsi.org/search-terms/terms/38004459
      provider.save!
    end

    neuropathologists.each do |neuropathologist|
      provider = Provider.where(npi: neuropathologist).first
      provider.specialty_concept_id = 45756790 #Neuropathology https://athena.ohdsi.org/search-terms/terms/45756790
      provider.save!
    end
  end

  desc "Truncate stable identifiers"
  task(truncate_stable_identifiers: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
  end

  desc 'Truncate schemas'
  task(truncate_schemas: :environment) do  |t, args|
    Abstractor::AbstractorAbstraction.delete_all
    Abstractor::AbstractorSuggestion.delete_all
    Abstractor::AbstractorSuggestionSource.delete_all
    Abstractor::AbstractorNamespaceEvent.delete_all
    Abstractor::AbstractorNamespace.delete_all
    Abstractor::AbstractorSubjectGroup.delete_all
    Abstractor::AbstractorAbstractionSchema.delete_all
    Abstractor::AbstractorObjectValue.delete_all
    Abstractor::AbstractorAbstractionSchemaObjectValue.delete_all
    Abstractor::AbstractorObjectValueVariant.delete_all
    Abstractor::AbstractorSubject.delete_all
    Abstractor::AbstractorAbstractionSource.delete_all
    Abstractor::AbstractorSubjectGroupMember.delete_all
    Abstractor::AbstractorSection.delete_all
    Abstractor::AbstractorSectionNameVariant.delete_all
    Abstractor::AbstractorAbstractionSource.delete_all
    Abstractor::AbstractorNamespaceSection.delete_all
    Abstractor::AbstractorAbstractionObjectValue.delete_all
  end

  desc "Fix WHO 2016 Classification of Tumors of the Central Nervous System"
  task(fix_who_2016_classification_of_tumors_cns: :environment) do  |t, args|
    fixes = CSV.new(File.open('lib/setup/vocabulary/the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system_fixes.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    fixes.each do |fix|
      case fix['Comment_XL']
      when 'Updated - Code'
        puts fix['icdo3_code']
        icdo3_histology = Icdo3Histology.where(icdo3_name: fix['icdo3_description'], version: 'new', minor_version: 'the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv').first
        icdo3_histology.icdo3_code = fix['icdo3_code']
        icdo3_histology.save!
      when 'Added - whole row'
        puts fix['icdo3_code']
        icdo3_histology = Icdo3Histology.where(icdo3_code: fix['icdo3_code'], icdo3_name: fix['icdo3_description'], icdo3_description: fix['icdo3_description'], version: 'new', minor_version: 'the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv', category: fix['category']).first_or_create
        icdo3_category = Icdo3Category.where(version: '2016 WHO Classification of CNS Tumors', category: fix['category'] ).first
        icdo3_histology.icdo3_categorizations.build(icdo3_category: icdo3_category)
        icdo3_histology.save!
      when 'Updated - name and code'
        puts fix['icdo3_code']
        icdo3_histology = Icdo3Histology.where(icdo3_name: fix['icdo3_description_old'], version: 'new', minor_version: 'the_2016_world_health_organization_classification_of_tumors_of_the_central_nervous_system.csv').first
        icdo3_histology.icdo3_code = fix['icdo3_code']
        icdo3_histology.icdo3_name = fix['icdo3_description']
        icdo3_histology.icdo3_description = fix['icdo3_description']
        icdo3_histology.save!
      when 'Updated - category'
        puts fix['category_old']
        icdo3_category = Icdo3Category.where(version: '2016 WHO Classification of CNS Tumors', category: fix['category_old']).first
        if icdo3_category
          icdo3_category.category = fix['category']
          icdo3_category.save!
        end
      end
    end
  end

  desc "Prostate SPORE data"
  task(prostate_spore_data: :environment) do |t, args|
    files = ['lib/setup/data/prostate_spore/Pathology Cases with Surgeries 1.xlsx', 'lib/setup/data/prostate_spore/Pathology Cases with Surgeries 2.xlsx', 'lib/setup/data/prostate_spore/Pathology Cases with Surgeries 3.xlsx', 'lib/setup/data/prostate_spore/Pathology Cases with Surgeries 4.xlsx', 'lib/setup/data/prostate_spore/Pathology Cases with Surgeries 5.xlsx', 'lib/setup/data/prostate_spore/Pathology Cases with Surgeries 6.xlsx']
    load_data(files)
  end

  desc "Prostate SPORE clinic vist data"
  task(prostate_spore_clinic_visit_data: :environment) do |t, args|
    files = ['lib/setup/data/prostate_spore/Northwestern Prostate SPORE ECOG Performance Status Notes.xlsx']
    load_clinic_vist_data(files)
  end

  desc "OHDSI NLP Proposal data"
  task(ohdsi_nlp_proposal_data: :environment) do |t, args|
    directory_path = 'lib/setup/data/ohdsi_nlp_proposal/'
    files = Dir.glob(File.join(directory_path, '*.xml'))
    files = files.sort_by { |file| File.stat(file).mtime }
    load_data_xml(files)
  end

  # bundle exec rake setup:aml_data["?"]
  desc "AML data"
  task :aml_data, [:west_mrn] => :environment do |t, args|
    puts 'you need to care'
    puts args[:west_mrn]
    directory_path = 'lib/setup/data/aml/diagnositic_pathology'
    files = Dir.glob(File.join(directory_path, '*.xml'))
    files = files.sort_by { |file| File.stat(file).mtime }

    load_data_xml(files, west_mrn: args[:west_mrn])
  end

  desc "Prostate data"
  task(prostate_data: :environment) do |t, args|
    directory_path = 'lib/setup/data/prostate/'
    files = Dir.glob(File.join(directory_path, '*.xml'))
    files = files.sort_by { |file| File.stat(file).mtime }
    load_data_xml(files)
  end

# RAILS_ENV=staging bundle exec rake setup:breast_data
  desc "Breast data"
  task(breast_data: :environment) do |t, args|
    directory_path = 'lib/setup/data/breast/'
    files = Dir.glob(File.join(directory_path, '*.xml'))
    files = files.sort_by { |file| File.stat(file).mtime }
    load_data_xml(files)
  end

  # RAILS_ENV=staging bundle exec rake setup:aml_data["?"]
  desc "Cervical data"
  task :cervical_data, [:west_mrn] => :environment do |t, args|
    puts 'you need to care'
    puts args[:west_mrn]
    directory_path = 'lib/setup/data/cervical/'
    files = Dir.glob(File.join(directory_path, '*.xml'))
    files = files.sort_by { |file| File.stat(file).mtime }

    load_data_xml(files, west_mrn: args[:west_mrn])
  end
end

def load_data_xml(files, options= {})
  options = { west_mrn: nil }.merge(options)
  @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
  @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first
  files.each do |file|
    pathology_case_handler = Omop::PathologyCaseHandler.new
    File.open(file) do |file|
      parser = Nokogiri::XML::SAX::Parser.new(pathology_case_handler)
      parser.parse(file)
    end

    location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
    gender_concept_id = Concept.genders.first.concept_id
    race_concept_id = Concept.races.first.concept_id
    ethnicity_concept_id =   Concept.ethnicities.first.concept_id

    pathology_cases = []
    if !options[:west_mrn].present?
      puts 'wrong way'
      pathology_cases =  pathology_case_handler.pathology_cases
    else
      puts 'in clover'
      pathology_cases = pathology_case_handler.pathology_cases.select { |pathology_case| pathology_case.west_mrn ==  options[:west_mrn] }
    end

    pathology_cases.each_with_index do |pathology_case, i|
      puts 'row'
      puts i
      puts 'west mrn'
      west_mrn = pathology_case.west_mrn
      puts west_mrn

      #Person 1
      person = Person.where(gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location).first
      if person.blank?
        person_id = Person.maximum(:person_id)
        if person_id.nil?
          person_id = 1
        else
          person_id+=1
        end
        person = Person.new(person_id: person_id, gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location)
        person.save!
        person.mrns.where(health_system: 'NMHC',  mrn: west_mrn).first_or_create
      end

      provider = Provider.where(provider_source_value: pathology_case.responsible_pathologist_full_name).first
      if provider.blank?
        provider_id = Provider.maximum(:provider_id)
        if provider_id.nil?
          provider_id = 1
        else
          provider_id+=1
        end
        provider = Provider.new(provider_id: provider_id, provider_name: pathology_case.responsible_pathologist_full_name, npi: pathology_case.responsible_pathologist_npi, dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_case.responsible_pathologist_full_name, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
        provider.save!
      end

      accession_nbr_formatted = pathology_case.accession_nbr_formatted
      puts 'accession_nbr_formatted'
      puts accession_nbr_formatted
      accessioned_datetime = pathology_case.accessioned_datetime
      accessioned_datetime = accessioned_datetime.to_date.to_s
      procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted).first
      if procedure_occurrence_stable_identifier.blank?
        puts 'not here yet'
        snomed_code = pathology_case.snomed_code
        puts 'snomed_code'
        puts snomed_code
        procedure_concept = Concept.where(concept_code: snomed_code, vocabulary_id: Concept::VOCABULARY_ID_SNOMED).first
        if procedure_concept
          procedure_concept_id = procedure_concept.concept_id
        else
          procedure_concept_id = 0
        end

        procedure_type_concept = Concept.procedure_types.where(concept_name: 'Secondary Procedure').first
        procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
        if procedure_occurrence_id.nil?
          procedure_occurrence_id = 1
        else
          procedure_occurrence_id+=1
        end

        procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil)
        procedure_occurrence.save!
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted)
        procedure_occurrence_stable_identifier.save!
      else
        procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurrence_stable_identifier.procedure_occurrence_id).first
      end

      stable_identifier_path = pathology_case.stable_identifier_path
      stable_identifier_value = pathology_case.stable_identifier_value
      stable_identifier_value_1 = pathology_case.stable_identifier_value_1
      stable_identifier_value_2 = pathology_case.stable_identifier_value_2

      note_stable_identifier = NoteStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)

      if note_stable_identifier.blank?
        note_title = pathology_case.section_description
        puts 'hello booch'
        puts pathology_case.section_description
        puts note_title
        note_text = pathology_case.note_text
        note_id = Note.maximum(:note_id)
        if note_id.nil?
          note_id = 1
        else
          note_id+=1
        end

        puts 'taking a look'
        puts pathology_case.source_system
        puts note_title
        if pathology_case.source_system == 'clarity_west' && note_title == 'Microscopic Description'
          puts 'in the clover'
          file_path = "spacy_parser/input.txt"
          File.open(file_path, "w") do |file|
            file.write(note_text)
          end

          result = system("python spacy_parser/sentences.py spacy_parser/input.txt spacy_parser/output.txt")
          if result
            puts "Python script executed successfully."

            # Specify the file path
            file_path = "spacy_parser/output.txt"

            # Read the contents of the file into a string
            file_contents = File.read('spacy_parser/output.txt')

            # Now, 'file_contents' contains the content of the file as a string
            puts "File contents:"
            note_text = file_contents
          else
            puts "Python script execution failed."
          end
        end

        note = Note.new(note_id: note_id, person_id: person.person_id, note_date: Date.parse(accessioned_datetime), note_datetime: Date.parse(accessioned_datetime), note_type_concept_id: @note_type_concept.concept_id, note_class_concept_id: @note_class_concept.concept_id, note_title: note_title, note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, note_source_value: nil)
        note.save!
        note_stable_identifier_full = NoteStableIdentifierFull.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)
        note_stable_identifier_full.save!

        note_stable_identifier = NoteStableIdentifier.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value, stable_identifier_value_1: stable_identifier_value_1, stable_identifier_value_2: stable_identifier_value_2)
        note_stable_identifier.save!

        domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
        domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
        relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
        relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
        FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
      end

      surgical_case_number = pathology_case.surgical_case_number

      surgery = false
      if surgical_case_number.present?
        puts 'here 1'
        stable_identifier_path = 'surgical case number'
        stable_identifier_value_1 = surgical_case_number
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: surgical_case_number).first
        surgery = true
      end

      if surgery && procedure_occurrence_stable_identifier.blank?
        cpt = pathology_case.cpt_code
        surgery_name = pathology_case.surgery_name

        if surgery_name
          surgery_name = surgery_name.truncate(50)
        end

        if cpt
          procedure_concept = Concept.standard.valid.where(vocabulary_id: Concept::CONCEPT_CLASS_CPT4, concept_code: cpt).first
          if procedure_concept.present?
            procedure_concept_id = procedure_concept.concept_id
          else
            procedure_concept_id = 0
          end
        else
          procedure_concept_id = 0
        end

        procedure_type_concept = Concept.procedure_types.where(concept_name: 'Primary Procedure').first
        procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
        if procedure_occurrence_id.nil?
          procedure_occurrence_id = 1
        else
          procedure_occurrence_id+=1
        end

        provider = Provider.where(provider_source_value: pathology_case.primary_surgeon_full_name).first
        if provider.blank?
          provider_id = Provider.maximum(:provider_id)
          if provider_id.nil?
            provider_id = 1
          else
            provider_id+=1
          end
          provider = Provider.new(provider_id: provider_id, provider_name: pathology_case.primary_surgeon_full_name, npi: pathology_case.primary_surgeon_npi, dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_case.primary_surgeon_full_name, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
          provider.save!
        end

        surgery_procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: surgery_name, procedure_source_concept_id: nil, modifier_source_value: nil)
        surgery_procedure_occurrence.save!
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: stable_identifier_path, stable_identifier_value_1: stable_identifier_value_1)
        procedure_occurrence_stable_identifier.save!

        domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
        domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
        relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
        relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: surgery_procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: surgery_procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      end
    end
  end
end

def load_data_new(files)
  @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
  @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first

  files.each do |file|
    pathology_procedures = Roo::Spreadsheet.open(file)
    pathology_procedure_map = {
       'west mrn' => 0,
       'source system' => 1,
       'source system_id' => 2,
       'stable identifier path' => 3,
       'stable identifier value' => 4,
       'stable identifier value 1' => 5,
       'stable identifier value 2' => 6,
       'pathology stable identifier path' => 7,
       'pathology stable identifier value_1' => 8,
       'accession nbr formatted' => 9,
       'accessioned datetime'   => 10,
       'case collect datetime'   => 11,
       'surgery stable identifier path' => 12,
       'surgery stable identifier value 1' => 13,
       'surgical case number' => 14,
       'surgery start date' => 15,
       'primary surgeon full name' => 16,
       'primary surgeon specialty 1 description' => 17,
       'primary surgeon npi' => 18,
       'surgery name' => 19,
       'code type' => 20,
       'cpt code' => 21,
       'cpt name' => 22,
       'group name' => 23,
       'group desc' => 24,
       'snomed code' => 25,
       'snomed name' => 26,
       'group id' => 27,
       'responsible pathologist full name' => 28,
       'responsible pathologist npi' => 29,
       'section description' => 30,
       'note text' => 31
    }

    location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
    gender_concept_id = Concept.genders.first.concept_id
    race_concept_id = Concept.races.first.concept_id
    ethnicity_concept_id =   Concept.ethnicities.first.concept_id

    for i in 2..pathology_procedures.sheet(0).last_row do
      puts 'row'
      puts i
      puts 'west mrn'
      west_mrn = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
      puts west_mrn

      #Person 1
      person = Person.where(gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location).first
      if person.blank?
        person_id = Person.maximum(:person_id)
        if person_id.nil?
          person_id = 1
        else
          person_id+=1
        end
        person = Person.new(person_id: person_id, gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location)
        person.save!
        person.mrns.where(health_system: 'NMHC',  mrn: west_mrn).first_or_create
      end

      provider = Provider.where(provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]).first
      if provider.blank?
        provider_id = Provider.maximum(:provider_id)
        if provider_id.nil?
          provider_id = 1
        else
          provider_id+=1
        end
        provider = Provider.new(provider_id: provider_id, provider_name: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], npi: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
        provider.save!
      end

      accession_nbr_formatted = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
      puts 'accession_nbr_formatted'
      puts accession_nbr_formatted
      accessioned_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
      accessioned_datetime = accessioned_datetime.to_date.to_s
      procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted).first
      if procedure_occurrence_stable_identifier.blank?
        puts 'not here yet'
        snomed_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
        puts 'snomed_code'
        puts snomed_code
        procedure_concept = Concept.where(concept_code: snomed_code, vocabulary_id: Concept::VOCABULARY_ID_SNOMED).first
        if procedure_concept
          procedure_concept_id = procedure_concept.concept_id
        else
          procedure_concept_id = 0
        end

        procedure_type_concept = Concept.procedure_types.where(concept_name: 'Secondary Procedure').first
        procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
        if procedure_occurrence_id.nil?
          procedure_occurrence_id = 1
        else
          procedure_occurrence_id+=1
        end

        procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil)
        procedure_occurrence.save!
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted)
        procedure_occurrence_stable_identifier.save!
      else
        procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurrence_stable_identifier.procedure_occurrence_id).first
      end

      stable_identifier_path = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
      stable_identifier_value = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value']]
      stable_identifier_value_1 = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value 1']]
      stable_identifier_value_2 = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value 2']]

      note_stable_identifier = NoteStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)

      if note_stable_identifier.blank?
        note_title = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
        puts 'hello booch'
        puts pathology_procedure_map['section description']
        puts note_title
        note_text = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['note text']]
        note_id = Note.maximum(:note_id)
        if note_id.nil?
          note_id = 1
        else
          note_id+=1
        end

        note = Note.new(note_id: note_id, person_id: person.person_id, note_date: Date.parse(accessioned_datetime), note_datetime: Date.parse(accessioned_datetime), note_type_concept_id: @note_type_concept.concept_id, note_class_concept_id: @note_class_concept.concept_id, note_title: note_title, note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, note_source_value: nil)
        note.save!
        note_stable_identifier_full = NoteStableIdentifierFull.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)
        note_stable_identifier_full.save!

        note_stable_identifier = NoteStableIdentifier.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value, stable_identifier_value_1: stable_identifier_value_1, stable_identifier_value_2: stable_identifier_value_2)
        note_stable_identifier.save!

        domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
        domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
        relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
        relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
        FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
      end

      surgical_case_number = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]

      surgery = false
      if surgical_case_number.present?
        puts 'here 1'
        stable_identifier_path = 'surgical case number'
        stable_identifier_value_1 = surgical_case_number
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: surgical_case_number).first
        surgery = true
      end

      if surgery && procedure_occurrence_stable_identifier.blank?
        cpt = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
        surgery_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]

        if surgery_name
          surgery_name = surgery_name.truncate(50)
        end

        if cpt
          procedure_concept = Concept.standard.valid.where(vocabulary_id: Concept::CONCEPT_CLASS_CPT4, concept_code: cpt).first
          if procedure_concept.present?
            procedure_concept_id = procedure_concept.concept_id
          else
            procedure_concept_id = 0
          end
        else
          procedure_concept_id = 0
        end

        procedure_type_concept = Concept.procedure_types.where(concept_name: 'Primary Procedure').first
        procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
        if procedure_occurrence_id.nil?
          procedure_occurrence_id = 1
        else
          procedure_occurrence_id+=1
        end

        provider = Provider.where(provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]).first
        if provider.blank?
          provider_id = Provider.maximum(:provider_id)
          if provider_id.nil?
            provider_id = 1
          else
            provider_id+=1
          end
          provider = Provider.new(provider_id: provider_id, provider_name: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], npi: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
          provider.save!
        end

        surgery_procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: surgery_name, procedure_source_concept_id: nil, modifier_source_value: nil)
        surgery_procedure_occurrence.save!
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: stable_identifier_path, stable_identifier_value_1: stable_identifier_value_1)
        procedure_occurrence_stable_identifier.save!

        domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
        domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
        relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
        relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: surgery_procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: surgery_procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      end
    end
  end
end

def load_data(files)
  @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
  @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first
  files.each do |file|
    pathology_procedures = Roo::Spreadsheet.open(file)
    pathology_procedure_map = {
       'west mrn' => 0,
       'source system' => 1,
       'stable identifier path' => 2,
       'stable identifier value' => 3,
       'stable identifier value 1' => 4,
       'stable identifier value 2' => 5,
       'case collect datetime'   => 6,
       'accessioned datetime'   => 7,
       'accession nbr formatted' => 8,
       'group name' => 9,
       'group desc' => 10,
       'group id' => 11,
       'snomed code' => 12,
       'snomed name' => 13,
       'responsible pathologist full name' => 14,
       'responsible pathologist npi' => 15,
       'section description' => 16,
       'note text' => 17,
       'surgical case number' => 18,
       'surgery name' => 19,
       'surgery start date' => 20,
       'code type' => 21,
       'cpt code' => 22,
       'cpt name' => 23,
       'primary surgeon full name' => 24,
       'primary surgeon npi' => 25
    }

    location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
    gender_concept_id = Concept.genders.first.concept_id
    race_concept_id = Concept.races.first.concept_id
    ethnicity_concept_id =   Concept.ethnicities.first.concept_id

    for i in 2..pathology_procedures.sheet(0).last_row do
      batch_pathology_case_surgery = BatchPathologyCaseSurgery.new
      batch_pathology_case_surgery.west_mrn = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
      batch_pathology_case_surgery.source_system = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['source system']]
      batch_pathology_case_surgery.stable_identifier_path = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
      batch_pathology_case_surgery.stable_identiifer_value = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value']]
      batch_pathology_case_surgery.case_collect_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['case collect datetime']]
      batch_pathology_case_surgery.accessioned_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
      batch_pathology_case_surgery.accession_nbr_formatted = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
      batch_pathology_case_surgery.group_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group name']]
      batch_pathology_case_surgery.group_desc = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group desc']]
      batch_pathology_case_surgery.group_id = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group id']]
      batch_pathology_case_surgery.snomed_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
      batch_pathology_case_surgery.snomed_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed name']]
      batch_pathology_case_surgery.responsible_pathologist_full_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]
      batch_pathology_case_surgery.responsible_pathologist_npi = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']]
      batch_pathology_case_surgery.section_description = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
      # batch_pathology_report_section.note_text
      batch_pathology_case_surgery.surgical_case_number = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]
      batch_pathology_case_surgery.surgery_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]
      batch_pathology_case_surgery.surgery_start_date = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery start date']]
      batch_pathology_case_surgery.code_type = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['code type']]
      batch_pathology_case_surgery.cpt_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
      batch_pathology_case_surgery.cpt_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt name']]
      batch_pathology_case_surgery.primary_surgeon_full_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]
      batch_pathology_case_surgery.primary_surgeon_npi = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']]

      batch_pathology_case_surgery.save!

      puts 'row'
      puts i
      puts 'west mrn'
      west_mrn = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
      puts west_mrn

      #Person 1
      person = Person.where(gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location).first
      if person.blank?
        person_id = Person.maximum(:person_id)
        if person_id.nil?
          person_id = 1
        else
          person_id+=1
        end
        person = Person.new(person_id: person_id, gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location)
        person.save!
        person.mrns.where(health_system: 'NMHC',  mrn: west_mrn).first_or_create
      end

      provider = Provider.where(provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]).first
      if provider.blank?
        provider_id = Provider.maximum(:provider_id)
        if provider_id.nil?
          provider_id = 1
        else
          provider_id+=1
        end
        provider = Provider.new(provider_id: provider_id, provider_name: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], npi: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
        provider.save!
      end

      accession_nbr_formatted = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
      puts 'accession_nbr_formatted'
      puts accession_nbr_formatted
      accessioned_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
      accessioned_datetime = accessioned_datetime.to_date.to_s
      procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted).first
      if procedure_occurrence_stable_identifier.blank?
        puts 'not here yet'
        snomed_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
        puts 'snomed_code'
        puts snomed_code
        procedure_concept = Concept.where(concept_code: snomed_code, vocabulary_id: Concept::VOCABULARY_ID_SNOMED).first
        if procedure_concept
          procedure_concept_id = procedure_concept.concept_id
        else
          procedure_concept_id = 0
        end

        procedure_type_concept = Concept.procedure_types.where(concept_name: 'Secondary Procedure').first
        procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
        if procedure_occurrence_id.nil?
          procedure_occurrence_id = 1
        else
          procedure_occurrence_id+=1
        end

        procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil)
        procedure_occurrence.save!
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted)
        procedure_occurrence_stable_identifier.save!
      else
        procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurrence_stable_identifier.procedure_occurrence_id).first
      end

      stable_identifier_path = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
      stable_identifier_value = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value']]
      stable_identifier_value_1 = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value 1']]
      stable_identifier_value_2 = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier value 2']]

      note_stable_identifier = NoteStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)

      if note_stable_identifier.blank?
        note_title = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
        puts 'hello booch'
        puts pathology_procedure_map['section description']
        puts note_title
        note_text = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['note text']]
        note_id = Note.maximum(:note_id)
        if note_id.nil?
          note_id = 1
        else
          note_id+=1
        end

        note = Note.new(note_id: note_id, person_id: person.person_id, note_date: Date.parse(accessioned_datetime), note_datetime: Date.parse(accessioned_datetime), note_type_concept_id: @note_type_concept.concept_id, note_class_concept_id: @note_class_concept.concept_id, note_title: note_title, note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, note_source_value: nil)
        note.save!
        note_stable_identifier_full = NoteStableIdentifierFull.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)
        note_stable_identifier_full.save!

        note_stable_identifier = NoteStableIdentifier.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value, stable_identifier_value_1: stable_identifier_value_1, stable_identifier_value_2: stable_identifier_value_2)
        note_stable_identifier.save!

        domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
        domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
        relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
        relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
        FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
      end

      surgical_case_number = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]

      surgery = false
      if surgical_case_number.present?
        puts 'here 1'
        stable_identifier_path = 'surgical case number'
        stable_identifier_value_1 = surgical_case_number
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: surgical_case_number).first
        surgery = true
      end

      if surgery && procedure_occurrence_stable_identifier.blank?
        cpt = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
        surgery_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]

        if surgery_name
          surgery_name = surgery_name.truncate(50)
        end

        if cpt
          procedure_concept = Concept.standard.valid.where(vocabulary_id: Concept::CONCEPT_CLASS_CPT4, concept_code: cpt).first
          if procedure_concept.present?
            procedure_concept_id = procedure_concept.concept_id
          else
            procedure_concept_id = 0
          end
        else
          procedure_concept_id = 0
        end

        procedure_type_concept = Concept.procedure_types.where(concept_name: 'Primary Procedure').first
        procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
        if procedure_occurrence_id.nil?
          procedure_occurrence_id = 1
        else
          procedure_occurrence_id+=1
        end

        provider = Provider.where(provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]).first
        if provider.blank?
          provider_id = Provider.maximum(:provider_id)
          if provider_id.nil?
            provider_id = 1
          else
            provider_id+=1
          end
          provider = Provider.new(provider_id: provider_id, provider_name: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], npi: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
          provider.save!
        end

        surgery_procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: surgery_name, procedure_source_concept_id: nil, modifier_source_value: nil)
        surgery_procedure_occurrence.save!
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: stable_identifier_path, stable_identifier_value_1: stable_identifier_value_1)
        procedure_occurrence_stable_identifier.save!

        domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
        domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
        relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
        relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: surgery_procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
        FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: surgery_procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
      end
    end
  end
end

def load_clinic_vist_data(files)
  files.each do |file|
    clinic_visit_notes = Roo::Spreadsheet.open(file)
    clinic_visit_note_map = {
       'west mrn' => 0,
       'encounter type' => 1,
       'contact date' => 2,
       'department name' => 3,
       'speciality' => 4,
       'provider full name' => 5,
       'provider npi' => 6,
       'note text'  => 7
    }

    location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
    gender_concept_id = Concept.genders.first.concept_id
    race_concept_id = Concept.races.first.concept_id
    ethnicity_concept_id =   Concept.ethnicities.first.concept_id

    for i in 2..clinic_visit_notes.sheet(0).last_row do
      puts 'row'
      puts i
      puts 'west mrn'
      west_mrn = clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['west mrn']]
      puts west_mrn

      #Person 1
      person = Person.where(gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location).first
      if person.blank?
        person_id = Person.maximum(:person_id)
        if person_id.nil?
          person_id = 1
        else
          person_id+=1
        end
        person = Person.new(person_id: person_id, gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location)
        person.save!
        person.mrns.where(health_system: 'NMHC',  mrn: west_mrn).first_or_create
      end

      provider = Provider.where(provider_source_value: clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['provider full name']]).first
      if provider.blank?
        provider_id = Provider.maximum(:provider_id)
        if provider_id.nil?
          provider_id = 1
        else
          provider_id+=1
        end
        provider = Provider.new(provider_id: provider_id, provider_name: clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['provider full name']], npi: clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['provider npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['provider full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
        provider.save!
      end

      #progress report begin
      visit_concept = Concept.visit_concepts.where(concept_id: 581477).first        #Office Visit
      visit_type_concept = Concept.visit_types.where(concept_id: 44818518).first    #Visit derived from EHR record
      visit_source_value = "#{clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['speciality']]}:#{clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['department name']]}".truncate(50)
      visit_occurrence = VisitOccurrence.where(visit_occurrence_id: i, person_id: person.person_id, visit_concept_id: visit_concept.concept_id, visit_start_date: Date.parse(clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['contact date']].to_s), visit_end_date: Date.parse(clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['contact date']].to_s), visit_type_concept_id: visit_type_concept.concept_id, visit_source_value: visit_source_value).first_or_create

      note_type_concept = Concept.note_types.where(concept_id: 44814640).first #Outpatient note
      note_class_concept = Concept.valid.where(concept_id: 36205960).first #Progress note | Outpatient

      note_text = clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['note text']]
      note_date = clinic_visit_notes.sheet(0).row(i)[clinic_visit_note_map['contact date']]
      note = Note.where(note_id: i, person_id: person.person_id, note_date: note_date, note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Progress Report', note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: visit_occurrence.visit_occurrence_id, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
        NoteStableIdentifier.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end
    end
  end
end

# biorepository prostate ps
  # data
  # bundle exec rake biorepository_prostate:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:prostate_spore_clinic_visit_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate_clinic_vists

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will

# biorepository prostate
  # data
  # bundle exec rake biorepository_prostate:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:prostate_spore_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate_biopsy
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will

#biorepository_prostate_development_biopsy_one
  # bundle exec rake biorepository_prostate:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:dummy_data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate_biopsy
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate

  #abstraction
  # br
  # make start-service
  # bundle exec rake suggestor:do_multiple_will

# export RAILS_ENV=staging

# bundle exec rake mbti:mbti_data
# bundle exec rake suggestor:do_multiple_will

# export RAILS_ENV=staging
# mbti final will
  # data
  # bundle exec rake mbti:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake mbti:mbti_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake mbti:schemas_mbti

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will
  # bundle exec rake suggestor:do_multiple_will_one["?"]
  # OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES' bundle exec rake suggestor:do_multiple_will

# mbti will one
  #data
  # bundle exec rake mbti:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake mbti:schemas_mbti

  #abstraction
  # br
  # make start-service
  # bundle exec rake suggestor:do_multiple_will
  # bundle exec rake suggestor:do_multiple_will_one["?"]

# biorepository prostate
  # data
  # bundle exec rake biorepository_prostate:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake biorepository_prostate:biorepository_prostate_data_3

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate_biopsy

  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will

# bundle exec rake biorepository_breast_new:biorepository_breast_abstractions
# biorepository breast new will
  # data
  # bundle exec rake biorepository_breast_new:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake biorepository_breast_new:biorepository_breast_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES' bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_breast_new:schemas_breast

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will
  # OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES' bundle exec rake suggestor:do_multiple_will

# biorepository breast new will one
  #data
  # bundle exec rake biorepository_breast:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_breast_new:schemas_breast

  #abstraction
  # br
  # make start-service
  # bundle exec rake suggestor:do_multiple_will

# mbti will
  # data
  # bundle exec rake db:migrate
  # bundle exec rake abstractor:setup:system

  #schemas
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake clamp:schemas_clamp

  #abstraction
  # make start-service
  # bundle exec rake suggestor:do_multiple_will

# biorepository breast new one will
  #data
  # bundle exec rake biorepository_breast:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_breast_new:schemas_breast

  #abstraction
  # br
  # make start-service
  # bundle exec rake suggestor:do_multiple_will


# mbti will
  # data
  # bundle exec rake db:migrate
  # bundle exec rake abstractor:setup:system

  #schemas
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake clamp:schemas_clamp

  #abstraction
  # make start-service
  # bundle exec rake suggestor:do_multiple_will

# mbti will one
  #data
  # bundle exec rake biorepository_breast:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake clamp:schemas_clamp

  #abstraction
  # br
  # make start-service
  # bundle exec rake suggestor:do_multiple_will

# biorepository prostate one
  #data
  # bundle exec rake biorepository_prostate:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas

  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate_biopsy

  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will

# biorepository prostate
  # data
  # bundle exec rake biorepository_prostate:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake biorepository_prostate:biorepository_prostate_data_2

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate_biopsy

  # bundle exec rake biorepository_prostate:schemas_omop_abstractor_nlp_biorepository_prostate

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will

# nu chers
  # data
  # bundle exec rake nu_chers:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake nu_chers:nu_chers_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake nu_chers:schemas_omop_abstractor_nlp_nu_chers_final_diagnosis
  # bundle exec rake nu_chers:schemas_omop_abstractor_nlp_nu_chers_synoptic

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will

# nu chers one
  #data
  # bundle exec rake biorepository_breast:truncate_stable_identifiers
  # bundle exec rake data:truncate_omop_clinical_data_tables
  # bundle exec rake setup:data
  # bundle exec rake data:create_note_stable_identifier_entires

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake clamp:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake nu_chers:schemas_omop_abstractor_nlp_nu_chers_final_diagnosis

  #abstraction
  # br
  # bundle exec rake suggestor:do_multiple_will