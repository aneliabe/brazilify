class AddServiceTypeToWorkerServices < ActiveRecord::Migration[7.1]
  def change
    add_column :worker_services, :service_type, :string
  end
end
