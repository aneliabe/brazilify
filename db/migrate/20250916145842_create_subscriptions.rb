class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.string :status
      t.string :plan_name
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at

      t.timestamps
    end
  end
end
