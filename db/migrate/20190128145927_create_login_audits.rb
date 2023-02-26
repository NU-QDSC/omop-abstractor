class CreateLoginAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :login_audits do |t|
      t.string     :username,     null: false
      t.string     :login_type,     null: false
      t.timestamps
    end
  end
end