class CreateAbstractorNamespaces < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_namespaces do |t|
      t.string        :name,            null: false
      t.string        :subject_type,    null: false
      t.text          :joins_clause,    null: false
      t.text          :where_clause,    null: false
      t.timestamps
    end
  end
end
