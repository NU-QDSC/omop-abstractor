class SqlAudit < ApplicationRecord
  def self.find_and_audit(username, active_record_relation)
    sql_audit = SqlAudit.save_sql_audit(username, active_record_relation)
    results = active_record_relation.all

    auditable_ids = []
    results.each do |result|
      if result.respond_to?(:id)
        auditable_ids << result.send(:id)
      end
    end

    if auditable_ids.any?
      SqlAudit.save_auditable_ids(sql_audit, active_record_relation, auditable_ids)
    end
    results
  end

  private
    def self.save_sql_audit(username, active_record_relation)
      sql_audit = SqlAudit.create!(username: username, sql: active_record_relation.to_sql, auditable_type: active_record_relation.klass.to_s)
    end

    def self.save_auditable_ids(sql_audit, active_record_relation, auditable_ids)
      sql_audit.auditable_ids = { id: auditable_ids }.to_json
      sql_audit.save!
    end
end