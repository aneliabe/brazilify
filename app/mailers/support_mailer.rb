class SupportMailer < ApplicationMailer
  default from: 'thebrazilifyteam@gmail.com'

  def new_message(name, email, subject, message)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: 'thebrazilifyteam@gmail.com',
      subject: "Suporte Brazilify: #{@subject}",
      reply_to: @email
    )
  end
end
