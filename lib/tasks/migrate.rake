require 'csv'
namespace :migrate do
  desc "Backfill unresolved"
  task(backfill_unresolved: :environment) do  |t, args|
    missed_histologies = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_histology/misses_latest_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_histologies.each do |missed_histology|
      if missed_histology['target'] == 'wrong auto-accepted'
        puts missed_histology['note_id_new']
        note = Note.where(note_id: missed_histology['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_cancer_histology'
        puts abstractor_abstraction_schema_id_has_cancer_histology
        puts 'end abstractor_abstraction_schema_id_has_cancer_histology'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_histology]
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_histology['value_new_migrate'] == 'not applicable'
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            else
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_histology['value_new_migrate'], false, false, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            end
          end
        end
      end
    end

    punted_histologies = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_histology/has_cancer_histology_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_histologies.each do |punted_histology|
      puts punted_histology['note_id_new']
      note = Note.where(note_id: punted_histology['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_cancer_histology'
      puts abstractor_abstraction_schema_id_has_cancer_histology
      puts 'end abstractor_abstraction_schema_id_has_cancer_histology'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_histology]
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_histology['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_histology['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_histologies = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_metastatic_cancer_histology/misses_metastatic_latest_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_histologies.each do |missed_histology|
      if missed_histology['target'] == 'wrong auto-accepted'
        puts missed_histology['note_id_new']
        note = Note.where(note_id: missed_histology['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_meastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_meastatic_cancer_histology'
        puts abstractor_abstraction_schema_id_has_meastatic_cancer_histology
        puts 'end abstractor_abstraction_schema_id_has_meastatic_cancer_histology'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_meastatic_cancer_histology]
        # abstractor_abstractions = note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options)
        # puts 'how much you got?'
        # puts abstractor_abstractions.size
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_histology['value_new_migrate'] == 'not applicable'
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            else
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_histology['value_new_migrate'], false, false, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            end
          end
        end
      end
    end

    punted_histologies = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_metastatic_cancer_histology/has_metastatic_cancer_histology_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_histologies.each do |punted_histology|
      puts punted_histology['note_id_new']
      note = Note.where(note_id: punted_histology['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_meastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_meastatic_cancer_histology'
      puts abstractor_abstraction_schema_id_has_meastatic_cancer_histology
      puts 'end abstractor_abstraction_schema_id_has_meastatic_cancer_histology'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_meastatic_cancer_histology]
      # abstractor_abstractions = note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options)
      # puts 'how much you got?'
      # puts abstractor_abstractions.size

      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_histology['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_histology['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_sites = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_site/misses_has_cancer_site_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_sites.each do |missed_site|
      if missed_site['target'] == 'wrong auto-accepted'
        puts missed_site['note_id_new']
        note = Note.where(note_id: missed_site['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_cancer_site'
        puts abstractor_abstraction_schema_id_has_cancer_site
        puts 'end abstractor_abstraction_schema_id_has_cancer_site'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_site]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_site['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_site['value_new_migrate'] == 'not applicable'
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            else
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_site['value_new_migrate'], false, false, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            end
          end
        end
      end
    end

    punted_sites = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_site/has_cancer_site_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_sites.each do |punted_site|
      puts punted_site['note_id_new']
      note = Note.where(note_id: punted_site['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_cancer_site'
      puts abstractor_abstraction_schema_id_has_cancer_site
      puts 'end abstractor_abstraction_schema_id_has_cancer_site'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_site]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_site['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_site['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_site['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_cancer_site_lateralities = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_site_laterality/misses_has_cancer_site_laterality_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_cancer_site_lateralities.each do |missed_cancer_site_laterality|
      if missed_cancer_site_laterality['value_new_normalized'] != missed_cancer_site_laterality['value_new_migrate']
        puts missed_cancer_site_laterality['note_id_new']
        note = Note.where(note_id: missed_cancer_site_laterality['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_cancer_site_laterality = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site_laterality' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_cancer_site_laterality'
        puts abstractor_abstraction_schema_id_has_cancer_site_laterality
        puts 'end abstractor_abstraction_schema_id_has_cancer_site_laterality'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_site_laterality]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_cancer_site_laterality['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_cancer_site_laterality['value_new_migrate'] == 'not applicable'
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            else
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_cancer_site_laterality['value_new_migrate'], false, false, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            end
          end
        end
      end
    end

    punted_cancer_site_lateralities = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_site_laterality/has_cancer_site_laterality_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_cancer_site_lateralities.each do |punted_cancer_site_laterality|
      puts punted_cancer_site_laterality['note_id_new']
      note = Note.where(note_id: punted_cancer_site_laterality['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_cancer_site_laterality = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site_laterality' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_cancer_site_laterality'
      puts abstractor_abstraction_schema_id_has_cancer_site_laterality
      puts 'end abstractor_abstraction_schema_id_has_cancer_site_laterality'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_site_laterality]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_cancer_site_laterality['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_cancer_site_laterality['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_cancer_site_laterality['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_cancer_recurrence_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_recurrence_status/misses_has_cancer_recurrence_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_cancer_recurrence_statuses.each do |missed_cancer_recurrence_status|
      if missed_cancer_recurrence_status['value_new_normalized_raw'] != missed_cancer_recurrence_status['value_new_migrate']
        puts missed_cancer_recurrence_status['note_id_new']
        note = Note.where(note_id: missed_cancer_recurrence_status['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_cancer_recurrence_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_recurrence_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_cancer_recurrence_status'
        puts abstractor_abstraction_schema_id_has_cancer_recurrence_status
        puts 'end abstractor_abstraction_schema_id_has_cancer_recurrence_status'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_recurrence_status]
        #puts 'how much in here?'
        #puts note.note_stable_identifier.abstractor_abstraction_groups.not_deleted.size
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.not_deleted.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_cancer_recurrence_status['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_cancer_recurrence_status['value_new_migrate'] == 'not applicable'
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            else
              #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
              #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
              # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_cancer_recurrence_status['value_new_migrate'], false, false, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            end
          end
        end
      end
    end

    missed_cancer_who_grades = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_who_grade/misses_has_cancer_who_grade_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_cancer_who_grades.each do |missed_cancer_who_grade|
      if missed_cancer_who_grade['value_new_normalized'] != missed_cancer_who_grade['value_new_migrate']
        puts missed_cancer_who_grade['note_id_new']
        note = Note.where(note_id: missed_cancer_who_grade['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_cancer_who_grade = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_who_grade' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_cancer_who_grade'
        puts abstractor_abstraction_schema_id_has_cancer_who_grade
        puts 'end abstractor_abstraction_schema_id_has_cancer_who_grade'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_who_grade]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_cancer_who_grade['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_cancer_who_grade['value_new_migrate'] != 'manual'
              if missed_cancer_who_grade['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_cancer_who_grade['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_cancer_who_grades = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_cancer_who_grade/has_cancer_who_grade_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_cancer_who_grades.each do |punted_cancer_who_grade|
      puts punted_cancer_who_grade['note_id_new']
      note = Note.where(note_id: punted_cancer_who_grade['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_cancer_who_grade = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_who_grade' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_cancer_who_grade'
      puts abstractor_abstraction_schema_id_has_cancer_who_grade
      puts 'end abstractor_abstraction_schema_id_has_cancer_who_grade'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_cancer_who_grade]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_cancer_who_grade['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_cancer_who_grade['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_cancer_who_grade['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_idh1_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_idh1_status/misses_has_idh1_status_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_idh1_statuses.each do |missed_idh1_status|
      if missed_idh1_status['value_new_normalized'] != missed_idh1_status['value_new_migrate']
        puts missed_idh1_status['note_id_new']
        note = Note.where(note_id: missed_idh1_status['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_idh1_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_idh1_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_idh1_status'
        puts abstractor_abstraction_schema_id_has_idh1_status
        puts 'end abstractor_abstraction_schema_id_has_idh1_status'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_idh1_status]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_idh1_status['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_idh1_status['value_new_migrate'] != 'manual'
              if missed_idh1_status['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_idh1_status['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_idh1_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_idh1_status/has_idh1_status_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_idh1_statuses.each do |punted_idh1_status|
      puts punted_idh1_status['note_id_new']
      note = Note.where(note_id: punted_idh1_status['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_idh1_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_idh1_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_idh1_status'
      puts abstractor_abstraction_schema_id_has_idh1_status
      puts 'end abstractor_abstraction_schema_id_has_idh1_status'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_idh1_status]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_idh1_status['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'we made it to the moomin land'
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end
          puts 'what is the new value?'
          puts punted_idh1_status['value_new_migrate']

          if punted_idh1_status['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_idh1_status['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_idh2_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_idh2_status/misses_has_idh2_status_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_idh2_statuses.each do |missed_idh2_status|
      if missed_idh2_status['value_new_normalized'] != missed_idh2_status['value_new_migrate']
        puts missed_idh2_status['note_id_new']
        note = Note.where(note_id: missed_idh2_status['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_idh2_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_idh2_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_idh2_status'
        puts abstractor_abstraction_schema_id_has_idh2_status
        puts 'end abstractor_abstraction_schema_id_has_idh2_status'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_idh2_status]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_idh2_status['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_idh2_status['value_new_migrate'] != 'manual'
              if missed_idh2_status['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_idh2_status['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_idh2_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_idh2_status/has_idh2_status_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_idh2_statuses.each do |punted_idh2_status|
      puts punted_idh2_status['note_id_new']
      note = Note.where(note_id: punted_idh2_status['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_idh2_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_idh2_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_idh2_status'
      puts abstractor_abstraction_schema_id_has_idh2_status
      puts 'end abstractor_abstraction_schema_id_has_idh2_status'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_idh2_status]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_idh2_status['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_idh2_status['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_idh2_status['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_ki67s = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_ki67/misses_has_ki67_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_ki67s.each do |missed_ki67|
      if missed_ki67['value_new_normalized'] != missed_ki67['value_new_migrate']
        puts missed_ki67['note_id_new']
        note = Note.where(note_id: missed_ki67['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_ki67 = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_ki67' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_ki67'
        puts abstractor_abstraction_schema_id_has_ki67
        puts 'end abstractor_abstraction_schema_id_has_ki67'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_ki67]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_ki67['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_ki67['value_new_migrate'] != 'manual'
              if missed_ki67['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_ki67['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_ki67s = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_ki67/has_ki67_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_ki67s.each do |punted_ki67|
      puts punted_ki67['note_id_new']
      note = Note.where(note_id: punted_ki67['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_ki67 = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_ki67' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_ki67'
      puts abstractor_abstraction_schema_id_has_ki67
      puts 'end abstractor_abstraction_schema_id_has_ki67'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_ki67]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_ki67['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_ki67['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_ki67['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_mgmt_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_mgmt_status/misses_has_mgmt_status_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_mgmt_statuses.each do |missed_mgmt_status|
      if missed_mgmt_status['value_new_normalized'] != missed_mgmt_status['value_new_migrate']
        puts missed_mgmt_status['note_id_new']
        note = Note.where(note_id: missed_mgmt_status['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_mgmt_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_mgmt_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_mgmt_status'
        puts abstractor_abstraction_schema_id_has_mgmt_status
        puts 'end abstractor_abstraction_schema_id_has_mgmt_status'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_mgmt_status]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_mgmt_status['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_mgmt_status['value_new_migrate'] != 'manual'
              if missed_mgmt_status['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_mgmt_status['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_mgmt_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_mgmt_status/has_mgmt_status_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_mgmt_statuses.each do |punted_mgmt_status|
      puts punted_mgmt_status['note_id_new']
      note = Note.where(note_id: punted_mgmt_status['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_mgmt_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_mgmt_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_mgmt_status'
      puts abstractor_abstraction_schema_id_has_mgmt_status
      puts 'end abstractor_abstraction_schema_id_has_mgmt_status'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_mgmt_status]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_mgmt_status['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_mgmt_status['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_mgmt_status['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_p53s = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_p53/misses_has_p53_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_p53s.each do |missed_p53|
      if missed_p53['value_new_normalized'] != missed_p53['value_new_migrate']
        puts missed_p53['note_id_new']
        note = Note.where(note_id: missed_p53['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_p53 = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_p53' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_p53'
        puts abstractor_abstraction_schema_id_has_p53
        puts 'end abstractor_abstraction_schema_id_has_p53'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_p53]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_p53['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_p53['value_new_migrate'] != 'manual'
              if missed_p53['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_p53['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_p53s = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_p53/has_p53_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_p53s.each do |punted_p53|
      puts punted_p53['note_id_new']
      note = Note.where(note_id: punted_p53['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_p53 = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_p53' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_p53'
      puts abstractor_abstraction_schema_id_has_p53
      puts 'end abstractor_abstraction_schema_id_has_p53'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_p53]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_p53['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_p53['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_p53['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_metastatic_cancer_primary_sites = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_metastatic_cancer_primary_site/misses_has_metastatic_cancer_primary_site_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_metastatic_cancer_primary_sites.each do |missed_metastatic_cancer_primary_site|
      if missed_metastatic_cancer_primary_site['value_new_normalized'] != missed_metastatic_cancer_primary_site['value_new_migrate']
        puts missed_metastatic_cancer_primary_site['note_id_new']
        note = Note.where(note_id: missed_metastatic_cancer_primary_site['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_primary_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site'
        puts abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site
        puts 'end abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_metastatic_cancer_primary_site['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_metastatic_cancer_primary_site['value_new_migrate'] != 'manual'
              if missed_metastatic_cancer_primary_site['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_metastatic_cancer_primary_site['missed_metastatic_cancer_primary_site'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_cancer_primary_sites = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_metastatic_cancer_primary_site/has_metastatic_cancer_primary_site_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_cancer_primary_sites.each do |punted_cancer_primary_site|
      puts punted_cancer_primary_site['note_id_new']
      note = Note.where(note_id: punted_cancer_primary_site['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_primary_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site'
      puts abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site
      puts 'end abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_metastatic_cancer_primary_site]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_cancer_primary_site['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_cancer_primary_site['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_cancer_primary_site['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end

    missed_1p_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_1p_status/misses_has_1p_status_new_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    missed_1p_statuses.each do |missed_1p_status|
      if missed_1p_status['value_new_normalized'] != missed_1p_status['value_new_migrate']
        puts missed_1p_status['note_id_new']
        note = Note.where(note_id: missed_1p_status['note_id_new']).first
        puts 'note.note_id'
        puts note.note_id
        puts 'note_stable_identifier.id'
        puts note.note_stable_identifier.id

        namespace_type = Abstractor::AbstractorNamespace.to_s
        namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

        abstractor_abstraction_schema_id_has_1p_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_1p_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
        puts 'begin abstractor_abstraction_schema_id_has_1p_status'
        puts abstractor_abstraction_schema_id_has_1p_status
        puts 'end abstractor_abstraction_schema_id_has_1p_status'
        options = {}
        options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_1p_status]
        abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == missed_1p_status['abstractor_subject_group_name'] }
        options[:abstractor_abstraction_group] = abstractor_abstraction_group
        note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
          puts 'abstractor_abstraction.value'
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                abstractor_suggestion.destroy
              end
            end

            if missed_1p_status['value_new_migrate'] != 'manual'
              if missed_1p_status['value_new_migrate'] == 'not applicable'
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              else
                #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, missed_1p_status['value_new_migrate'], false, false, nil, nil)
                abstractor_suggestion.accepted = true
                abstractor_suggestion.save!
              end
            end
          end
        end
      end
    end

    punted_1p_statuses = CSV.new(File.open('lib/setup/data/migrate_unresolved/has_1p_status/has_1p_status_punt_migration.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    punted_1p_statuses.each do |punted_1p_status|
      puts punted_1p_status['note_id_new']
      note = Note.where(note_id: punted_1p_status['note_id_new']).first
      puts 'note.note_id'
      puts note.note_id
      puts 'note_stable_identifier.id'
      puts note.note_stable_identifier.id

      namespace_type = Abstractor::AbstractorNamespace.to_s
      namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first

      abstractor_abstraction_schema_id_has_1p_status = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_1p_status' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
      puts 'begin abstractor_abstraction_schema_id_has_1p_status'
      puts abstractor_abstraction_schema_id_has_1p_status
      puts 'end abstractor_abstraction_schema_id_has_1p_status'
      options = {}
      options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id_has_1p_status]
      abstractor_abstraction_group = note.note_stable_identifier.abstractor_abstraction_groups.detect { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group && abstractor_abstraction_group.abstractor_subject_group.name == punted_1p_status['abstractor_subject_group_name'] }
      options[:abstractor_abstraction_group] = abstractor_abstraction_group
      note.note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).each do |abstractor_abstraction|
        puts 'abstractor_abstraction.value'
        Abstractor::AbstractorAbstraction.transaction do
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
              abstractor_suggestion.destroy
            end
          end

          if punted_1p_status['value_new_migrate'] == 'not applicable'
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, false, true, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          else
            #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
            #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
            # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
            abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, punted_1p_status['value_new_migrate'], false, false, nil, nil)
            abstractor_suggestion.accepted = true
            abstractor_suggestion.save!
          end
        end
      end
    end
  end

  desc "Backfill unresolved V2"
  task(backfill_unresolved_v2: :environment) do  |t, args|
    unresolved_cases = CSV.new(File.open('lib/setup/data/migrate_unresolved/backfill_unresolved_v2_cases.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    unresolved_cases.each do |unresolved_case|
      case unresolved_case['type']
      when 'fixed'
      when 'not applicable', 'abstract', 'punted manual'
        if unresolved_case['has_cancer_histology']
          accept_suggestion(unresolved_case, 'has_cancer_histology')
        end

        if unresolved_case['has_cancer_site']
          accept_suggestion(unresolved_case, 'has_cancer_site')
        end

        if unresolved_case['has_cancer_site_laterality']
          accept_suggestion(unresolved_case, 'has_cancer_site_laterality')
        end

        if unresolved_case['has_cancer_who_grade']
          accept_suggestion(unresolved_case, 'has_cancer_who_grade')
        end

        if unresolved_case['has_cancer_recurrence_status']
          accept_suggestion(unresolved_case, 'has_cancer_recurrence_status')
        end
      end
    end
  end
end

def accept_suggestion(unresolved_case, predicate)
  namespace_type = Abstractor::AbstractorNamespace.to_s
  namespace_id =  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first
  abstractor_abstraction_schema_id = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = '#{predicate}' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", namespace_type, namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
  options = {}
  options[:abstractor_abstraction_schema_ids] = [abstractor_abstraction_schema_id]
  note_stable_identifier = NoteStableIdentifier.where(stable_identifier_value: unresolved_case['stable_identifier_value']).first
  abstractor_abstraction = note_stable_identifier.abstractor_abstractions_by_abstraction_schemas(options).first
  Abstractor::AbstractorAbstraction.transaction do
    puts 'hello'
    abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
      if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
        abstractor_suggestion.destroy
      end
    end

    #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
    #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
    # abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
    abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, unresolved_case[predicate], false, false, nil, nil)
    abstractor_suggestion.accepted = true
    abstractor_suggestion.save!
  end
end