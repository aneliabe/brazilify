class AddArchiveFieldsToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :archived_by_client_at, :datetime
    add_column :appointments, :archived_by_worker_at, :datetime
  end
end
