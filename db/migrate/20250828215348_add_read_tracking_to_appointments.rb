class AddReadTrackingToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :client_last_read_at, :datetime
    add_column :appointments, :worker_last_read_at, :datetime
  end
end
