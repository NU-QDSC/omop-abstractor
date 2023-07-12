require 'fileutils'
module Omop
  module Setup
    def self.compile_omop_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_ddl.sql"`
    end

    def self.compile_omop_primary_keys
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_primary_keys.sql"`
    end

    def self.load_omop_vocabulary_tables
      file_name = "#{Rails.root}/db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql.template"
      file_name_dest = file_name.gsub('.template','')
      FileUtils.cp(file_name, file_name_dest)
      text = File.read(file_name_dest)
      text = text.gsub(/RAILS_ROOT/, "#{Rails.root}")
      File.open(file_name_dest, "w") {|file| file.puts text }

      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}//db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql"`
    end

    def self.compile_omop_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_indices.sql"`
    end

    def self.compile_omop_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_constraints.sql"`
    end

    def self.drop_omop_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_drop_indices.sql"`
    end

    def self.drop_omop_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/DROP OMOP CDM postgresql constraints.sql"`
    end

    def self.drop_all_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/DROP all tables ddl.sql"`
    end

    def self.truncate_omop_clinical_data_tables
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
    end

    def self.truncate_omop_vocabulary_tables
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
  end
end