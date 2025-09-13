class AddTimeZoneToAppointments < ActiveRecord::Migration[7.1]
  def change
    # Default to São Paulo for existing rows; you can change later per appointment.
    add_column :appointments, :time_zone, :string, null: false, default: "America/Sao_Paulo"
    add_index  :appointments, :time_zone
  end
end
