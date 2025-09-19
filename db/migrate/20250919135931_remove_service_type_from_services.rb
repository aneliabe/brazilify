class RemoveServiceTypeFromServices < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:services, :service_type)
      remove_column :services, :service_type, :string
    end
  end
end
