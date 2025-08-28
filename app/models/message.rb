class Message < ApplicationRecord
  belongs_to :user
  belongs_to :appointment
  validates :content, presence: true

  after_create_commit :broadcast_message

  private

  def broadcast_message
    broadcast_append_to(
      "appointment_#{appointment.id}_messages",
      partial: "messages/message",
      locals: { message: self, user: user },
      target: "messages" # matches the id="messages" container
    )
  end
end
