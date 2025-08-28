class AddIndexesToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_index :appointments, [:worker_profile_id, :starts_at]
    add_index :appointments, [:user_id, :created_at]
    add_index :appointments, :status
  end
end
