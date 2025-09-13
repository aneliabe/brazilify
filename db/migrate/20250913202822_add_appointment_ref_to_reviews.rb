class AddAppointmentRefToReviews < ActiveRecord::Migration[7.1]
  # lightweight models so the migration doesn't depend on app code
  class Review < ApplicationRecord
    self.table_name = "reviews"
  end
  class Appointment < ApplicationRecord
    self.table_name = "appointments"
  end

  def up
    add_reference :reviews, :appointment, foreign_key: true, null: true

    # Optional backfill: try to link existing reviews to the most recent
    # appointment between the same client and worker_profile.
    say_with_time "Backfilling reviews.appointment_id" do
      Review.reset_column_information
      Review.where(appointment_id: nil).find_each do |rev|
        appt = Appointment
                 .where(user_id: rev.user_id, worker_profile_id: rev.worker_profile_id)
                 .order(starts_at: :desc)
                 .first
        rev.update_columns(appointment_id: appt&.id) # direct write, skip validations
      end
    end
  end

  def down
    remove_reference :reviews, :appointment, foreign_key: true
  end
end
