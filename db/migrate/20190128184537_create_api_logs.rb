class CreateApiLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :api_logs do |t|
      t.string :system, null: false
      t.text :url
      t.text :payload
      t.text :response
      t.text :error
      t.timestamps
    end

    add_index :api_logs, [:system]
    add_index :api_logs, [:created_at]
  end
end


