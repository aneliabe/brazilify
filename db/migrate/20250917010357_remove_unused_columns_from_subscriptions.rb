class RemoveUnusedColumnsFromSubscriptions < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscriptions, :plan_name, :string
    remove_column :subscriptions, :current_period_start, :datetime
    remove_column :subscriptions, :current_period_end, :datetime
    remove_column :subscriptions, :canceled_at, :datetime
  end
end
