require 'csv'
namespace :suggestor do
  desc 'Make suggestions'
  task(do: :environment) do |t, args|
    abstractor_suggestor(multiple: false)
  end

  task(do_multiple_mbti: :environment) do |t, args|
    abstractor_suggestor_mbti(multiple: true)
  end

  task(do_multiple_biorepository: :environment) do |t, args|
    abstractor_suggestor_biorepoisoty(multiple: true)
  end

  task(do_multiple_will: :environment) do |t, args|
    abstractor_suggestor_will(multiple: true)
  end

  # RAILS_ENV=staging bundle exec rake suggestor:do_multiple_will_one["?"]
  task :do_multiple_will_one, [:person_source_value] => [:environment] do |t, args|
    person = Person.where(person_source_value: args[:person_source_value]).first
    if person
      abstractor_suggestor_will_one(multiple: true, person_id: person.person_id)
    end
  end

  task(do_multiple: :environment) do |t, args|
    abstractor_suggestor(multiple: true)
  end
end

def abstractor_suggestor_mbti(options = {})
  options.reverse_merge!({ multiple: false })
  # stable_identifier_values = CSV.new(File.open('lib/setup/data/stable_identifier_values_all.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
  # stable_identifier_values = CSV.new(File.open('lib/setup/data/stable_identifier_values_all_missing_guys_2.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
  stable_identifier_values = CSV.new(File.open('lib/setup/data/stable_identifier_values_all_colon.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

  stable_identifier_values = stable_identifier_values.map { |stable_identifier_value| stable_identifier_value['stable_identifier_value'] }

  # stable_identifier_values = CSV.new(File.open('lib/setup/data/stable_identifier_values_recent.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
  # stable_identifier_values = stable_identifier_values.map { |stable_identifier_value| stable_identifier_value['stable_identifier_value'] }

  # stable_identifier_values_last = CSV.new(File.open('lib/setup/data/stable_identifier_values_all_last.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
  # stable_identifier_values_last = stable_identifier_values_last.map { |stable_identifier_value| stable_identifier_value['stable_identifier_value'] }

  # Abstractor::AbstractorNamespace.all.each do |abstractor_namespace|
  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').all.each do |abstractor_namespace|
  # Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology').all.each do |abstractor_namespace|
  # Abstractor::AbstractorNamespace.where(name: 'Molecular Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name

    # MBTI All
    # abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    # MBTI stable identifiers
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).where(stable_identifier_value: stable_identifier_values).order('note.person_id ASC, note.note_date ASC')

    # MBTI All after '11/15/2020'
    # abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where("note.note_date >= '11/15/2020'").where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    # MBTI All after '2018-03-01'
    # abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where("note.note_date >= '2018-03-01'").where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    # #MBTI single person_id
    # abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).where(stable_identifier_value: stable_identifier_values).where('note.person_id = '?').order('note.person_id ASC, note.note_date ASC').each do |abstractable_event|
    # #Fake Data
    # abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note_date ASC').each do |abstractable_event|

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          note_titles = ['Microscopic Description', 'Addendum']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.include?(other_note.note_title)
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            puts 'begin a new abstraction'
            start = Time.now
            Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            Rails.logger.info('End abstraction')
            finish = Time.now
            diff = finish - start
            puts 'how long did you take?'
            puts diff
            puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      end
      Process.wait(child_pid)
    end
  end
end

def abstractor_suggestor(options = {})
  options.reverse_merge!({ multiple: false })

  Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology').all.each do |abstractor_namespace|
    puts abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).to_sql
    puts 'hello'
    puts abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).count
    abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      child_pid = fork do
        if options[:multiple]
          abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      end
      Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').all.each do |abstractor_namespace|
    puts abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).to_sql
    puts 'hello'
    puts abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).count
    abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      child_pid = fork do
        if options[:multiple]
          abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      end
      Process.wait(child_pid)
    end
  end
end

def abstractor_suggestor_biorepoisoty(options = {})
  options.reverse_merge!({ multiple: false })

  Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3', 'AP ADDENDUM 4', 'AP ADDENDUM 5', 'AP ADDENDUM 6', 'AP ADDENDUM 7', 'ADDENDUM 1', 'ADDENDUM 2', 'ADDENDUM 3', 'ADDENDUM 4', 'ADDENDUM 5', 'ADDENDUM 6', 'ADDENDUM 7']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.include?(other_note.note_title)
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            puts 'begin a new abstraction'
            start = Time.now
            Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            Rails.logger.info('End abstraction')
            finish = Time.now
            diff = finish - start
            puts 'how long did you take?'
            puts diff
            puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      end
      Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.include?(other_note.note_title)
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            puts 'begin a new abstraction'
            start = Time.now
            Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            Rails.logger.info('End abstraction')
            finish = Time.now
            diff = finish - start
            puts 'how long did you take?'
            puts diff
            puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      end
      Process.wait(child_pid)
    end
  end
end

def abstractor_suggestor_will(options = {})
  options.reverse_merge!({ multiple: false })

  Abstractor::AbstractorNamespace.where(name: ['Outside Surgical Pathology', 'Outside Surgical Pathology Biopsy']).all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each_with_index do |abstractable_event, i|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          # puts 'here is the stable_identifier_value'
          # puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            if i == 1
              sleep(60)
            end
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Synoptic Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each_with_index do |abstractable_event, i|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          # puts 'here is the stable_identifier_value'
          # puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|

              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            if i == 1
              sleep(60)
            end
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology Biopsy').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            puts 'begin a new abstraction'
            start = Time.now
            Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Molecular Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each_with_index do |abstractable_event, i|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          # puts 'here is the stable_identifier_value'
          # puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            if i == 1
              sleep(60)
            end
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end
end

def abstractor_suggestor_will_one(options = {})
  options.reverse_merge!({ multiple: false })

  Abstractor::AbstractorNamespace.where(name: ['Outside Surgical Pathology', 'Outside Surgical Pathology Biopsy']).all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).where('note.person_id = ?', options[:person_id]).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each_with_index do |abstractable_event, i|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          # puts 'here is the stable_identifier_value'
          # puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            if i == 1
              sleep(60)
            end
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Synoptic Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).where('note.person_id = ?', options[:person_id]).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).where('note.person_id = ?', options[:person_id]).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each_with_index do |abstractable_event, i|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          # puts 'here is the stable_identifier_value'
          # puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            if i == 1
              sleep(60)
            end
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology Biopsy').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).where('note.person_id = ?', options[:person_id]).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each do |abstractable_event|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          puts 'here is the stable_identifier_value'
          puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            puts 'begin a new abstraction'
            start = Time.now
            Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end

  Abstractor::AbstractorNamespace.where(name: 'Molecular Pathology').all.each do |abstractor_namespace|
    puts 'here is the namespace'
    puts abstractor_namespace.name
    #All
    abstractable_events = abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).order('note.person_id ASC, note.note_date ASC')

    puts 'Begin backlog count'
    puts abstractable_events.size
    puts 'End backlog count'
    abstractable_events.each_with_index do |abstractable_event, i|
      puts 'what we got?'
      puts abstractable_event.id
      # child_pid = fork do
        if options[:multiple]
          # puts 'here is the stable_identifier_value'
          # puts abstractable_event.stable_identifier_value

          # note_titles = ['Microscopic Description', 'Addendum', 'AP ADDENDUM 1', 'AP ADDENDUM 2', 'AP ADDENDUM 3']
          note_titles = ['Microscopic Description', 'Addendum', 'Comment']
          procedure_occurrence_options = {}
          procedure_occurrence_options[:username] = 'mjg994'
          procedure_occurrence_options[:include_parent_procedures] = false
          note = abstractable_event.note
          note_options = {}
          note_options[:username] = 'mjg994'
          note_options[:except_notes] = [note]
          note.procedure_occurences(procedure_occurrence_options).each do |procedure_occurence|
            procedure_occurence.notes(note_options).each do |other_note|
              if note_titles.any? {|note_title| other_note.note_title.include?(note_title) }
                note.note_text = "#{note.note_text}\n----------------------------------\n#{other_note.note_title}\n----------------------------------\n#{other_note.note_text}"
                note.save!
                note.reload
              else
                puts 'not so much'
              end
            end

            abstractable_event.reload

            # puts 'begin a new abstraction'
            # start = Time.now
            # Rails.logger.info('Begin an abstraction')
            abstractable_event.abstract_multiple(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
            if i == 1
              sleep(60)
            end
            # Rails.logger.info('End abstraction')
            # finish = Time.now
            # diff = finish - start
            # puts 'how long did you take?'
            # puts diff
            # puts 'end abstraction'
          end
        else
          abstractable_event.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace.id)
        end
        abstractor_namespace.abstractor_namespace_events.build(eventable: abstractable_event)
        abstractor_namespace.save!
      # end
      # Process.wait(child_pid)
    end
  end
end

# abstractor_namespace = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology').first
# # abstractor_namespace = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology').first
# abstractor_namespace.subject_type.constantize.missing_abstractor_namespace_event(abstractor_namespace.id).joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).count
# abstractor_namespace.subject_type.constantize.joins(abstractor_namespace.joins_clause).where(abstractor_namespace.where_clause).count
