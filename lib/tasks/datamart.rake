# export RAILS_ENV=staging
namespace :datamart do
  #bundle exec rake datamart:create_primary_cns_pathology_cases_datamart
  desc "Create Primary CNS Pathology Cases Datamart"
  task(create_primary_cns_pathology_cases_datamart: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE primary_cns_pathology_cases CASCADE;')
    sql_file = "#{Rails.root}/lib/tasks/primary_cns_pathology_cases.sql"
    primary_cns_pathology_cases_sql = File.read(sql_file)
    ActiveRecord::Base.connection.execute(primary_cns_pathology_cases_sql)
  end
end
