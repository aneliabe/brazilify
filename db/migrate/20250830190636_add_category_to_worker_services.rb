class AddCategoryToWorkerServices < ActiveRecord::Migration[7.1]
  def change
    add_reference :worker_services, :category, foreign_key: true
  end
end
