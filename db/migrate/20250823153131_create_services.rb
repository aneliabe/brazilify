class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.string :name
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :services, [:category_id, :name], unique: true
  end
end
