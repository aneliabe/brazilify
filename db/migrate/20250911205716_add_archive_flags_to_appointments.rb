class AddArchiveFlagsToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :client_archived_at, :datetime
    add_column :appointments, :worker_archived_at, :datetime

    add_index :appointments, [:user_id, :client_archived_at]
    add_index :appointments, [:worker_profile_id, :worker_archived_at]
  end
end
