class AddCategoryToWorkerProfiles < ActiveRecord::Migration[7.1]
  def change
    add_reference :worker_profiles, :category, foreign_key: true
  end
end
