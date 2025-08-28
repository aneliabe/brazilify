class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :status
      t.references :user, null: false, foreign_key: true
      t.references :worker_profile, null: false, foreign_key: true

      t.timestamps
    end
  end
end
