# copy down
# scp -r  deploy@vfsmmbtiapps01.fsm.northwestern.edu:/mnt/mbti/datastore/NUDB13C03/20220925/*.csv /Users/mjg994/Documents/omop-abstractor/db/migrate/CommonDataModel-5.3.0/PostgreSQL/ClinicalImport
# scp -r  deploy@vfsmmbtiapps01.fsm.northwestern.edu:/mnt/mbti/datastore/NUDB13C03/note.json /Users/mjg994/Documents/omop-abstractor/db/migrate/CommonDataModel-5.3.0/PostgreSQL/ClinicalImport

# initial setup
# bundle exec rake db:migrate
# bundle exec rake data:load_omop_vocabulary_tables
# bundle exec rake data:compile_omop_vocabulary_indexes

# load data

# bundle exec rake data:compile_omop_indexes
# bundle exec rake data:compile_omop_constraints

require 'fileutils'
require 'csv'
require 'yajl'
namespace :data do
  desc "Compile OMOP tables"
  task(compile_omop_tables: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/OMOP CDM postgresql ddl.sql"`
  end

  desc "Load OMOP vocabulary tables"
  task(load_omop_vocabulary_tables: :environment) do  |t, args|
    file_name = "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql.template"
    file_name_dest = file_name.gsub('.template','')
    FileUtils.cp(file_name, file_name_dest)
    text = File.read(file_name_dest)
    text = text.gsub(/RAILS_ROOT/, "#{Rails.root}")
    File.open(file_name_dest, "w") {|file| file.puts text }

    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql"`
  end

  desc "Compile OMOP constraints"
  task(compile_omop_constraints: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/OMOP CDM postgresql constraints.sql"`
  end

  desc "Compile OMOP vocabulary indexes"
  task(compile_omop_vocabulary_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/OMOP CDM postgresql indexes standardized vocabulary.sql"`
  end

  desc "Drop OMOP indexes"
  task(drop_omop_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/Drop OMOP CDM postgresql indexes.sql"`
  end

  desc "Drop OMOP vocabulary indexes"
  task(drop_omop_vocabulary_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/Drop OMOP CDM postgresql indexes standardized vocabulary.sql"`
  end

  desc "Truncate clinical data tables"
  task(truncate_omop_clinical_data_tables: :environment) do  |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE attribute_definition CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE care_site CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cdm_source CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort_attribute CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort_definition CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_occurrence CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cost CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE death CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE device_exposure CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE dose_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_exposure CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE fact_relationship CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE location CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE measurement CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_nlp CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE observation CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE observation_period CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE payer_plan_period CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE person CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE procedure_occurrence CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE provider CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE source_to_concept_map CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE specimen CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE visit_occurrence CASCADE;')

    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_address CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_email CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_mrn CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_name CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_phone_number CASCADE;')

    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE procedure_occurrence_stable_identifier CASCADE;')
  end

  desc "Load OMOP clinical tables"
  task(load_omop_clinical_tables: :environment) do  |t, args|
    file_name = "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/ClinicalImport/OMOP CDM clinical load - PostgreSQL.sql.template"
    file_name_dest = file_name.gsub('.template','')
    FileUtils.cp(file_name, file_name_dest)
    text = File.read(file_name_dest)

    if Rails.env.development?
      clinical_data = "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/ClinicalImport/"
    else
      clinical_data = Rails.application.credentials.clinical_data[Rails.env.to_sym][:path]
    end

    file = "#{clinical_data}provider.csv"
    provider = File.read(file)
    provider.encode!('UTF-8', invalid: :replace, undef: :replace)
    File.write("#{clinical_data}provider.csv", provider)

    text = text.gsub(/CLINICAL_DATA/, "#{clinical_data}")
    File.open(file_name_dest, "w") {|file| file.puts text }

    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/ClinicalImport/OMOP CDM clinical load - PostgreSQL.sql"`

    puts 'hello note'
    note_file = "#{clinical_data}/note.json"
    parse_and_load_note_file_new(note_file)
  end

  desc "Compile OMOP indexes"
  task(compile_omop_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/OMOP CDM postgresql indexes.sql"`
  end

  desc "Truncate vocabulary tables"
  task(truncate_omop_vocabulary_tables: :environment) do  |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_ancestor CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_class CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_relationship CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_synonym CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE domain CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_strength CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE relationship CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE vocabulary CASCADE;')
  end

  desc "Create entries in note_stable_identifier."
  task(create_note_stable_identifier_entires: :environment) do  |t, args|
    NoteStableIdentifierFull.where('NOT EXISTS (SELECT 1 FROM note_stable_identifier WHERE note_stable_identifier_full.stable_identifier_path = note_stable_identifier.stable_identifier_path AND note_stable_identifier_full.stable_identifier_value = note_stable_identifier.stable_identifier_value)').each do |note_stable_identifier_full|
      NoteStableIdentifier.create!(note_id: note_stable_identifier_full.note_id, stable_identifier_path: note_stable_identifier_full.stable_identifier_path, stable_identifier_value: note_stable_identifier_full.stable_identifier_value)
    end
  end

  desc "Drop OMOP constraints"
  task(drop_omop_constraints: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/DROP OMOP CDM postgresql constraints.sql"`
  end
end

def create_note(note)
    n = Yajl::Parser.parse(note)
    puts 'note_id'
    puts n['note_id']

    # puts 'person_id'
    # puts n['person_id']
    #
    # puts 'note_date'
    # puts n['note_date']
    #
    # puts 'note_datetime'
    # puts n['note_datetime']
    #
    # puts 'note_type_concept_id'
    # puts n['note_type_concept_id']
    #
    # puts 'note_class_concept_id'
    # puts n['note_class_concept_id']
    #
    # puts 'note_title'
    # puts n['p'][0]['note_title']
    #
    # puts 'note_text'
    # puts n['p'][0]['n'][0]['note_text']
    #
    # puts 'encoding_concept_id'
    # puts n['encoding_concept_id']
    #
    # puts 'language_concept_id'
    # puts n['language_concept_id']
    #
    # puts 'provider_id'
    # puts n['provider_id']
    #
    # puts 'visit_occurrence_id'
    # puts n['visit_occurrence_id']
    #
    # puts 'visit_detail_id'
    # puts n['visit_detail_id']
    #
    # puts 'note_source_value'
    # puts n['note_source_value']

    note_attributes = {}
    note_attributes[:note_id] = n['note_id']
    note_attributes[:person_id] = n['person_id']
    note_attributes[:note_date] = n['note_date']
    note_attributes[:note_datetime] = n['note_datetime']
    note_attributes[:note_type_concept_id] = n['note_type_concept_id']
    note_attributes[:note_class_concept_id] = n['note_class_concept_id']
    note_attributes[:note_title] = n['p'][0]['note_title']
    note_attributes[:note_text] = n['p'][0]['n'][0]['note_text']
    note_attributes[:encoding_concept_id] = n['encoding_concept_id']
    note_attributes[:language_concept_id] = n['language_concept_id']
    note_attributes[:provider_id] = n['provider_id']
    note_attributes[:visit_occurrence_id] = n['visit_occurrence_id']
    note_attributes[:visit_detail_id] = n['visit_detail_id']
    note_attributes[:note_source_value] = n['note_source_value']
    Note.create!(note_attributes)
end

def parse_and_load_note_file(note_file)
  f = File.open(note_file)
  previous_chunk = nil
  chunk = f.read(10240)
  chunk[0] = ''
  chunk[0] = ''
  chunk.delete!("\000")
  chunk.delete!("\u0000")
  chunk.gsub!('\u0000', '')
  chunk.gsub!('ocf_blob', '')
  chunk.gsub!(/\r\n/, '')
  chunk.gsub!("JSON",'')
  chunk.gsub!('[{"note_id"', '"note_id"')

  while chunk
    puts 'hello chunk'
    if previous_chunk.present?
      chunk = "#{previous_chunk}#{chunk}"
    end
    # puts 'begin complete chunk'
    # puts chunk
    # puts 'end complete chunk'

    chunk.delete!("\000")
    chunk.delete!("\u0000")
    chunk.gsub!('\u0000', '')
    chunk.gsub!('ocf_blob', '')
    chunk.gsub!(/\r\n/, '')
    notes = chunk.scan(/\"note_id\".*?}\]}\]/)

    note_attrs = []
    notes.each do |n|
      begin
        n.encode('UTF-8', :invalid => :replace, :undef => :replace)
        # puts 'begin Yajl'
        # puts "{#{n}}"
        # puts 'end Yajl'
        n = Yajl::Parser.parse("{#{n}}")
        note_attributes = {}
        note_attributes[:note_id] = n['note_id']
        note_attributes[:person_id] = n['person_id']
        note_attributes[:note_date] = n['note_date']
        note_attributes[:note_datetime] = n['note_datetime']
        note_attributes[:note_type_concept_id] = n['note_type_concept_id']
        note_attributes[:note_class_concept_id] = n['note_class_concept_id']
        note_attributes[:note_title] = n['p'][0]['note_title']
        note_attributes[:note_text] = clean_note(n['p'][0]['n'][0]['note_text'])
        note_attributes[:encoding_concept_id] = n['encoding_concept_id']
        note_attributes[:language_concept_id] = n['language_concept_id']
        note_attributes[:provider_id] = n['provider_id']
        note_attributes[:visit_occurrence_id] = n['visit_occurrence_id']
        note_attributes[:visit_detail_id] = n['visit_detail_id']
        note_attributes[:note_source_value] = n['note_source_value']
        note_attrs << note_attributes
      rescue Exception => e
        puts 'Kaboom!'
        puts e.message
        puts notes.to_s
        puts 'Kaboom End'
      end
    end

    Note.bulk_insert do |worker|
      note_attrs.each do |attrs|
        worker.add(attrs)
      end
    end

    leftovers= chunk.split(/\"note_id\".*?}\]}\]/)

    leftovers.reject!{ |leftover| leftover == "" || leftover == "},{" }

    previous_chunk = leftovers.join('')
    chunk = f.read(102400)
  end
end

def clean_note(note)
  note.delete!("\000")
  note.delete!("\u0000")
  note.gsub!('\u0000', '')
  note.gsub!('ocf_blob', '')
  note.gsub!(/\r\n/, '')
  note
end

#vocabulary refresh
# bundle exec rake db:migrate
# bundle exec rake data:truncate_omop_clinical_data_tables
# bundle exec rake data:drop_omop_indexes
# bundle exec rake data:drop_omop_vocabulary_indexes
# bundle exec rake data:truncate_omop_vocabulary_tables
# bundle exec rake data:drop_omop_constraints
# bundle exec rake data:load_omop_vocabulary_tables
# bundle exec rake data:compile_omop_vocabulary_indexes
# bundle exec rake data:compile_omop_constraints
# bundle exec rake data:load_omop_clinical_tables
# bundle exec rake data:compile_omop_indexes
# bundle exec rake data:create_note_stable_identifier_entires

# initial setup
# bundle exec rake data:compile_omop_tables
# bundle exec rake setup:truncate_schemas
# bundle exec rake abstractor:setup:system
# bundle exec rake setup:schemas