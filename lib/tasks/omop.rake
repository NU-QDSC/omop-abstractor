# bundle exec rake db:migrate
# bundle exec rake omop:load_omop_vocabulary_tables
# bundle exec rake omop:compile_omop_vocabulary_indexes
# data
# bundle exec rake omop:compile_omop_primary_keys
# bundle exec rake omop:compile_omop_constraints
# bundle exec rake omop:compile_omop_indexes
# schemas
# abstract

# other
# bundle exec rake omop:compile_omop_tables
# bundle exec rake omop:drop_omop_indexes
# bundle exec rake omop:truncate_omop_vocabulary_tables

require 'omop/setup'
namespace :omop do
  desc "Compile OMOP tables"
  task(compile_omop_tables: :environment) do |t, args|
    Omop::Setup.compile_omop_tables
  end

  desc "Compile OMOP primary keys"
  task(compile_omop_primary_keys: :environment) do |t, args|
    Omop::Setup.compile_omop_primary_keys
  end

  desc "Compile OMOP constraints"
  task(compile_omop_constraints: :environment) do |t, args|
    Omop::Setup.compile_omop_constraints
  end

  desc "Load OMOP vocabulary tables"
  task(load_omop_vocabulary_tables: :environment) do |t, args|
    Omop::Setup.load_omop_vocabulary_tables
  end

  desc "Truncate OMOP vocabulary tables"
  task(truncate_omop_vocabulary_tables: :environment) do |t, args|
    Omop::Setup.truncate_omop_vocabulary_tables
  end

  desc "Compile OMOP Vocabulary indexes"
  task(compile_omop_vocabulary_indexes: :environment) do |t, args|
    Omop::Setup.compile_omop_vocabulary_indexes
  end

  desc "Compile OMOP indexes"
  task(compile_omop_indexes: :environment) do |t, args|
    Omop::Setup.compile_omop_indexes
  end

  desc "Drop OMOP indexes"
  task(drop_omop_indexes: :environment) do |t, args|
    Omop::Setup.drop_omop_indexes
  end

  desc "Truncate clinical data tables"
  task(truncate_omop_clinical_data_tables: :environment) do  |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE care_site CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cdm_source CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort_definition CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_occurrence CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cost CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE death CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE device_exposure CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE dose_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_exposure CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE episode CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE episode_event CASCADE;')
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
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE specimen CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE visit_detail CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE visit_occurrence CASCADE;')

    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_address CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_email CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_mrn CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_name CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE pii_phone_number CASCADE;')

    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE procedure_occurrence_stable_identifier CASCADE;')
  end
end