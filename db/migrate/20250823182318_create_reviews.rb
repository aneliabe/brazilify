class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :worker_profile, null: false, foreign_key: true
      t.integer :rating
      t.text :comment

      t.timestamps
    end

    add_index :reviews, [:user_id, :worker_profile_id], unique: true
  end
end
