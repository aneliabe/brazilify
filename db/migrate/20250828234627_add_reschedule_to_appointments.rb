class AddRescheduleToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :proposed_starts_at, :datetime
    add_column :appointments, :proposed_by_id, :bigint

    add_index  :appointments, :proposed_by_id
    add_foreign_key :appointments, :users, column: :proposed_by_id
  end
end
