require 'csv'
namespace :gold_standard do
  #bundle exec rake gold_standard:calculate_performance
  desc 'Calculate Performance'
  task(calculate_performance: :environment) do |t, args|
    # 'Primary Cancer'
    puts 'what the hell?'
    # other = 'will'
    other = 'clamp'
    CompareCancerDiagnosisAbstraction.where(abstractor_subject_group_name: 'Primary Cancer').destroy_all
    gold_cancer_diagnosis_abstractions = CSV.new(File.open('lib/setup/data/gold_standard/gold_cancer_diagnosis_abstractions.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    gold_cancer_diagnosis_abstractions.each do |gold_cancer_diagnosis_abstraction|
      puts gold_cancer_diagnosis_abstraction['note_id']
      compare_cancer_diagnosis_abstraction = CompareCancerDiagnosisAbstraction.new
      compare_cancer_diagnosis_abstraction.source_id = gold_cancer_diagnosis_abstraction['id']
      compare_cancer_diagnosis_abstraction.note_id = gold_cancer_diagnosis_abstraction['note_id']
      compare_cancer_diagnosis_abstraction.stable_identifier_path = gold_cancer_diagnosis_abstraction['stable_identifier_path']
      compare_cancer_diagnosis_abstraction.stable_identifier_value = gold_cancer_diagnosis_abstraction['stable_identifier_value']
      compare_cancer_diagnosis_abstraction.subject_id = gold_cancer_diagnosis_abstraction['subject_id']

      compare_cancer_diagnosis_abstraction.has_cancer_histology = gold_cancer_diagnosis_abstraction['has_cancer_histology']
      if gold_cancer_diagnosis_abstraction['has_cancer_histology'] == 'not applicable'
        compare_cancer_diagnosis_abstraction.has_cancer_histology_suggestions = gold_cancer_diagnosis_abstraction['has_cancer_histology_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site = 'not applicable'
        compare_cancer_diagnosis_abstraction.has_cancer_site_suggestions = gold_cancer_diagnosis_abstraction['has_cancer_site_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site_laterality = 'not applicable'
        compare_cancer_diagnosis_abstraction.has_cancer_who_grade = 'not applicable'
        compare_cancer_diagnosis_abstraction.has_cancer_recurrence_status = 'not applicable'
      else
        compare_cancer_diagnosis_abstraction.has_cancer_histology_suggestions = gold_cancer_diagnosis_abstraction['has_cancer_histology_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site = gold_cancer_diagnosis_abstraction['has_cancer_site']
        compare_cancer_diagnosis_abstraction.has_cancer_site_suggestions = gold_cancer_diagnosis_abstraction['has_cancer_site_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site_laterality = gold_cancer_diagnosis_abstraction['has_cancer_site_laterality']
        compare_cancer_diagnosis_abstraction.has_cancer_who_grade = gold_cancer_diagnosis_abstraction['has_cancer_who_grade']
        compare_cancer_diagnosis_abstraction.has_cancer_recurrence_status = gold_cancer_diagnosis_abstraction['has_cancer_recurrence_status']
      end
      compare_cancer_diagnosis_abstraction.abstractor_namespace_name = gold_cancer_diagnosis_abstraction['abstractor_namespace_name']
      compare_cancer_diagnosis_abstraction.system_type = 'gold'
      compare_cancer_diagnosis_abstraction.abstractor_subject_group_name = 'Primary Cancer'
      compare_cancer_diagnosis_abstraction.save!
    end

    other_cancer_diagnosis_abstractions = CSV.new(File.open("lib/setup/data/gold_standard/#{other}_cancer_diagnosis_abstractions.csv"), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    other_cancer_diagnosis_abstractions.each do |other_cancer_diagnosis_abstraction|
      compare_cancer_diagnosis_abstraction = CompareCancerDiagnosisAbstraction.new
      compare_cancer_diagnosis_abstraction.source_id = other_cancer_diagnosis_abstraction['id']
      compare_cancer_diagnosis_abstraction.note_id = other_cancer_diagnosis_abstraction['note_id']
      compare_cancer_diagnosis_abstraction.stable_identifier_path = other_cancer_diagnosis_abstraction['stable_identifier_path']
      compare_cancer_diagnosis_abstraction.stable_identifier_value = other_cancer_diagnosis_abstraction['stable_identifier_value']
      compare_cancer_diagnosis_abstraction.subject_id = other_cancer_diagnosis_abstraction['subject_id']
      compare_cancer_diagnosis_abstraction.has_cancer_histology = other_cancer_diagnosis_abstraction['has_cancer_histology']
      compare_cancer_diagnosis_abstraction.has_cancer_histology_suggestions = other_cancer_diagnosis_abstraction['has_cancer_histology_suggestions']
      compare_cancer_diagnosis_abstraction.has_cancer_site = other_cancer_diagnosis_abstraction['has_cancer_site']
      compare_cancer_diagnosis_abstraction.has_cancer_site_suggestions = other_cancer_diagnosis_abstraction['has_cancer_site_suggestions']
      compare_cancer_diagnosis_abstraction.has_cancer_site_laterality = other_cancer_diagnosis_abstraction['has_cancer_site_laterality']
      compare_cancer_diagnosis_abstraction.has_cancer_who_grade = other_cancer_diagnosis_abstraction['has_cancer_who_grade']
      compare_cancer_diagnosis_abstraction.has_cancer_recurrence_status = other_cancer_diagnosis_abstraction['has_cancer_recurrence_status']
      compare_cancer_diagnosis_abstraction.abstractor_namespace_name = other_cancer_diagnosis_abstraction['abstractor_namespace_name']
      compare_cancer_diagnosis_abstraction.system_type = other
      compare_cancer_diagnosis_abstraction.abstractor_subject_group_name = 'Primary Cancer'
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Primary Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      others = CompareCancerDiagnosisAbstraction.where(system_type: other, note_id: compare_cancer_diagnosis_abstraction.note_id, abstractor_subject_group_name: 'Primary Cancer').all
      has_cancer_histology_other = others.map(&:has_cancer_histology).compact.join('|')
      has_cancer_histology_other_suggestions = others.map(&:has_cancer_histology_suggestions).compact.join('|')

      if has_cancer_histology_other
        compare_cancer_diagnosis_abstraction.has_cancer_histology_other = has_cancer_histology_other
      end

      if has_cancer_histology_other_suggestions
        compare_cancer_diagnosis_abstraction.has_cancer_histology_other_suggestions = has_cancer_histology_other_suggestions
      end

      has_cancer_site_other = others.map(&:has_cancer_site).compact.join('|')
      has_cancer_site_other_suggestions = others.map(&:has_cancer_site_suggestions).compact.join('|')

      if has_cancer_site_other
        compare_cancer_diagnosis_abstraction.has_cancer_site_other = has_cancer_site_other
      end

      if has_cancer_site_other_suggestions
        compare_cancer_diagnosis_abstraction.has_cancer_site_other_suggestions = has_cancer_site_other_suggestions
      end
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Primary Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      matches = CompareCancerDiagnosisAbstraction.where(system_type: other , note_id: compare_cancer_diagnosis_abstraction.note_id, has_cancer_histology: compare_cancer_diagnosis_abstraction.has_cancer_histology, has_cancer_site: compare_cancer_diagnosis_abstraction.has_cancer_site, abstractor_subject_group_name: 'Primary Cancer').count
      if matches == 0
        compare_cancer_diagnosis_abstraction.status = 'not matched'
        others = CompareCancerDiagnosisAbstraction.where(system_type: other, note_id: compare_cancer_diagnosis_abstraction.note_id, abstractor_subject_group_name: 'Primary Cancer').all
        has_cancer_histology_other = others.map(&:has_cancer_histology).compact.join('|')
        has_cancer_histology_other_suggestions = others.map(&:has_cancer_histology_suggestions).compact.join('|')

        if has_cancer_histology_other
          compare_cancer_diagnosis_abstraction.has_cancer_histology_other = has_cancer_histology_other
        end

        if has_cancer_histology_other_suggestions
          compare_cancer_diagnosis_abstraction.has_cancer_histology_other_suggestions = has_cancer_histology_other_suggestions
        end

        has_cancer_site_other = others.map(&:has_cancer_site).compact.join('|')
        has_cancer_site_other_suggestions = others.map(&:has_cancer_site_suggestions).compact.join('|')

        if has_cancer_site_other
          compare_cancer_diagnosis_abstraction.has_cancer_site_other = has_cancer_site_other
        end

        if has_cancer_site_other_suggestions
          compare_cancer_diagnosis_abstraction.has_cancer_site_other_suggestions = has_cancer_site_other_suggestions
        end
      else
        compare_cancer_diagnosis_abstraction.status = 'matched'
      end
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Primary Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      if compare_cancer_diagnosis_abstraction.has_cancer_histology_other.blank?
        compare_cancer_diagnosis_abstraction.has_cancer_histology_other = nil
      end

      if compare_cancer_diagnosis_abstraction.has_cancer_site_other.blank?
        compare_cancer_diagnosis_abstraction.has_cancer_site_other = nil
      end
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Primary Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, malignant (8000/3)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'not applicable'
        compare_cancer_diagnosis_abstraction.status = 'skipped'
      end

      if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, benign (8000/0)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'not applicable'
        compare_cancer_diagnosis_abstraction.status = 'skipped'
      end

      if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, malignant (8000/3)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'no evidence of tumor'
        compare_cancer_diagnosis_abstraction.status = 'skipped'
      end

      if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, benign (8000/0)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'no evidence of tumor'
        compare_cancer_diagnosis_abstraction.status = 'skipped'
      end

      compare_cancer_diagnosis_abstraction.save!
    end

    # 'Metastatic Cancer'
    puts 'what the hell?'
    other = 'will'
    CompareCancerDiagnosisAbstraction.where(abstractor_subject_group_name: 'Metastatic Cancer').destroy_all
    gold_metastatic_cancer_diagnosis_abstractions = CSV.new(File.open('lib/setup/data/gold_standard/gold_metastatic_cancer_diagnosis_abstractions.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    gold_metastatic_cancer_diagnosis_abstractions.each do |gold_metastatic_cancer_diagnosis_abstraction|
      puts gold_metastatic_cancer_diagnosis_abstraction['note_id']
      compare_cancer_diagnosis_abstraction = CompareCancerDiagnosisAbstraction.new
      compare_cancer_diagnosis_abstraction.source_id = gold_metastatic_cancer_diagnosis_abstraction['id']
      compare_cancer_diagnosis_abstraction.note_id = gold_metastatic_cancer_diagnosis_abstraction['note_id']
      compare_cancer_diagnosis_abstraction.stable_identifier_path = gold_metastatic_cancer_diagnosis_abstraction['stable_identifier_path']
      compare_cancer_diagnosis_abstraction.stable_identifier_value = gold_metastatic_cancer_diagnosis_abstraction['stable_identifier_value']
      compare_cancer_diagnosis_abstraction.subject_id = gold_metastatic_cancer_diagnosis_abstraction['subject_id']

      compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology = gold_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_histology']
      if gold_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_histology'] == 'not applicable'
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_suggestions = gold_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_histology_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site = 'not applicable'
        compare_cancer_diagnosis_abstraction.has_cancer_site_suggestions = gold_metastatic_cancer_diagnosis_abstraction['has_cancer_site_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site_laterality = 'not applicable'
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_primary_site = 'not applicable'
        compare_cancer_diagnosis_abstraction.has_cancer_recurrence_status = 'not applicable'
      else
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_suggestions = gold_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_histology_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site = gold_metastatic_cancer_diagnosis_abstraction['has_cancer_site']
        compare_cancer_diagnosis_abstraction.has_cancer_site_suggestions = gold_metastatic_cancer_diagnosis_abstraction['has_cancer_site_suggestions']
        compare_cancer_diagnosis_abstraction.has_cancer_site_laterality = gold_metastatic_cancer_diagnosis_abstraction['has_cancer_site_laterality']
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_primary_site = gold_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_primary_site']
        compare_cancer_diagnosis_abstraction.has_cancer_recurrence_status = gold_metastatic_cancer_diagnosis_abstraction['has_cancer_recurrence_status']
      end
      compare_cancer_diagnosis_abstraction.abstractor_namespace_name = gold_metastatic_cancer_diagnosis_abstraction['abstractor_namespace_name']
      compare_cancer_diagnosis_abstraction.system_type = 'gold'
      compare_cancer_diagnosis_abstraction.abstractor_subject_group_name = 'Metastatic Cancer'
      compare_cancer_diagnosis_abstraction.save!
    end

    other_metastatic_cancer_diagnosis_abstractions = CSV.new(File.open("lib/setup/data/gold_standard/#{other}_metastatic_cancer_diagnosis_abstractions.csv"), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    other_metastatic_cancer_diagnosis_abstractions.each do |other_metastatic_cancer_diagnosis_abstraction|
      compare_cancer_diagnosis_abstraction = CompareCancerDiagnosisAbstraction.new
      compare_cancer_diagnosis_abstraction.source_id = other_metastatic_cancer_diagnosis_abstraction['id']
      compare_cancer_diagnosis_abstraction.note_id = other_metastatic_cancer_diagnosis_abstraction['note_id']
      compare_cancer_diagnosis_abstraction.stable_identifier_path = other_metastatic_cancer_diagnosis_abstraction['stable_identifier_path']
      compare_cancer_diagnosis_abstraction.stable_identifier_value = other_metastatic_cancer_diagnosis_abstraction['stable_identifier_value']
      compare_cancer_diagnosis_abstraction.subject_id = other_metastatic_cancer_diagnosis_abstraction['subject_id']
      compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology = other_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_histology']
      compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_suggestions = other_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_histology_suggestions']
      compare_cancer_diagnosis_abstraction.has_cancer_site = other_metastatic_cancer_diagnosis_abstraction['has_cancer_site']
      compare_cancer_diagnosis_abstraction.has_cancer_site_suggestions = other_metastatic_cancer_diagnosis_abstraction['has_cancer_site_suggestions']
      compare_cancer_diagnosis_abstraction.has_cancer_site_laterality = other_metastatic_cancer_diagnosis_abstraction['has_cancer_site_laterality']
      compare_cancer_diagnosis_abstraction.has_metastatic_cancer_primary_site = other_metastatic_cancer_diagnosis_abstraction['has_metastatic_cancer_primary_site']
      compare_cancer_diagnosis_abstraction.has_cancer_recurrence_status = other_metastatic_cancer_diagnosis_abstraction['has_cancer_recurrence_status']
      compare_cancer_diagnosis_abstraction.abstractor_namespace_name = other_metastatic_cancer_diagnosis_abstraction['abstractor_namespace_name']
      compare_cancer_diagnosis_abstraction.system_type = other
      compare_cancer_diagnosis_abstraction.abstractor_subject_group_name = 'Metastatic Cancer'
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Metastatic Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      others = CompareCancerDiagnosisAbstraction.where(system_type: other, note_id: compare_cancer_diagnosis_abstraction.note_id, abstractor_subject_group_name: 'Metastatic Cancer').all
      has_metastatic_cancer_histology_other = others.map(&:has_metastatic_cancer_histology).compact.join('|')
      has_metastatic_cancer_histology_other_suggestions = others.map(&:has_metastatic_cancer_histology_suggestions).compact.join('|')

      if has_metastatic_cancer_histology_other
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_other = has_metastatic_cancer_histology_other
      end

      if has_metastatic_cancer_histology_other_suggestions
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_other_suggestions = has_metastatic_cancer_histology_other_suggestions
      end

      has_cancer_site_other = others.map(&:has_cancer_site).compact.join('|')
      has_cancer_site_other_suggestions = others.map(&:has_cancer_site_suggestions).compact.join('|')

      if has_cancer_site_other
        compare_cancer_diagnosis_abstraction.has_cancer_site_other = has_cancer_site_other
      end

      if has_cancer_site_other_suggestions
        compare_cancer_diagnosis_abstraction.has_cancer_site_other_suggestions = has_cancer_site_other_suggestions
      end
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Metastatic Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      matches = CompareCancerDiagnosisAbstraction.where(system_type: other , note_id: compare_cancer_diagnosis_abstraction.note_id, has_metastatic_cancer_histology: compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology, has_cancer_site: compare_cancer_diagnosis_abstraction.has_cancer_site, abstractor_subject_group_name: 'Metastatic Cancer').count
      if matches == 0
        compare_cancer_diagnosis_abstraction.status = 'not matched'
        others = CompareCancerDiagnosisAbstraction.where(system_type: other, note_id: compare_cancer_diagnosis_abstraction.note_id, abstractor_subject_group_name: 'Metastatic Cancer').all
        has_metastatic_cancer_histology_other = others.map(&:has_metastatic_cancer_histology).compact.join('|')
        has_metastatic_cancer_histology_other_suggestions = others.map(&:has_metastatic_cancer_histology_suggestions).compact.join('|')

        if has_metastatic_cancer_histology_other
          compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_other = has_metastatic_cancer_histology_other
        end

        if has_metastatic_cancer_histology_other_suggestions
          compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_other_suggestions = has_metastatic_cancer_histology_other_suggestions
        end

        has_cancer_site_other = others.map(&:has_cancer_site).compact.join('|')
        has_cancer_site_other_suggestions = others.map(&:has_cancer_site_suggestions).compact.join('|')

        if has_cancer_site_other
          compare_cancer_diagnosis_abstraction.has_cancer_site_other = has_cancer_site_other
        end

        if has_cancer_site_other_suggestions
          compare_cancer_diagnosis_abstraction.has_cancer_site_other_suggestions = has_cancer_site_other_suggestions
        end
      else
        compare_cancer_diagnosis_abstraction.status = 'matched'
      end
      compare_cancer_diagnosis_abstraction.save!
    end

    CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Metastatic Cancer').all.each do |compare_cancer_diagnosis_abstraction|
      if compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_other.blank?
        compare_cancer_diagnosis_abstraction.has_metastatic_cancer_histology_other = nil
      end

      if compare_cancer_diagnosis_abstraction.has_cancer_site_other.blank?
        compare_cancer_diagnosis_abstraction.has_cancer_site_other = nil
      end
      compare_cancer_diagnosis_abstraction.save!
    end



    compare_cancer_diagnosis_abstractions = CompareCancerDiagnosisAbstraction.where("system_type = 'gold' AND status != 'skipped' AND abstractor_subject_group_name IN('Primary Cancer', 'Metastatic Cancer'").select('DISTINC')
    compare_cancer_diagnosis_abstractions.each do |compare_cancer_diagnosis_abstraction|

    end



    # CompareCancerDiagnosisAbstraction.where(system_type: 'gold', abstractor_subject_group_name: 'Metastatic Cancer').all.each do |compare_cancer_diagnosis_abstraction|
    #
    #   if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, malignant (8000/3)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'not applicable'
    #     compare_cancer_diagnosis_abstraction.status = 'skipped'
    #   end
    #
    #   if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, benign (8000/0)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'not applicable'
    #     compare_cancer_diagnosis_abstraction.status = 'skipped'
    #   end
    #
    #   if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, malignant (8000/3)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'no evidence of tumor'
    #     compare_cancer_diagnosis_abstraction.status = 'skipped'
    #   end
    #
    #   if compare_cancer_diagnosis_abstraction.has_cancer_histology == 'neoplasm, benign (8000/0)' && compare_cancer_diagnosis_abstraction.has_cancer_histology_other == 'no evidence of tumor'
    #     compare_cancer_diagnosis_abstraction.status = 'skipped'
    #   end
    #
    #   compare_cancer_diagnosis_abstraction.save!
    # end
  end
end