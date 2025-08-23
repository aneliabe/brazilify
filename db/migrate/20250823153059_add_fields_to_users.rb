class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :full_name, :string
    add_column :users, :address, :string
    add_column :users, :birth_date, :date
    add_column :users, :phone, :string
    add_column :users, :country, :string
    add_column :users, :city, :string
    add_column :users, :avatar, :string
    add_column :users, :role, :integer
  end
end
