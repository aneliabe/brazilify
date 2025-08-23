class CreateWorkerServices < ActiveRecord::Migration[7.1]
  def change
    create_table :worker_services do |t|
      t.references :worker_profile, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true

      t.timestamps
    end

    add_index :worker_services, [:worker_profile_id, :service_id], unique: true
  end
end
