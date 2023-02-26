class CreateSqlAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :sql_audits do |t|
      t.string    :username, null: false
      t.string    :auditable_type, null: true
      t.text      :auditable_ids, null: true
      t.text      :sql, null: false
      t.timestamps
    end
  end
end