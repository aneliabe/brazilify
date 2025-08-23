class CreateWorkerProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :worker_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :cpf
      t.text :description
      t.decimal :rating, precision: 3, scale: 2

      t.timestamps
    end
  end
end
