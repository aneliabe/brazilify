class SupportController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
  end

  def create
    @name = params[:name].to_s.strip
    @email = params[:email].to_s.strip
    @subject = params[:subject].to_s.strip
    @message = params[:message].to_s.strip

    if valid_support_params?
      begin
        SupportMailer.new_message(@name, @email, @subject, @message).deliver_now
        redirect_to new_support_path, notice: "Mensagem enviada com sucesso! Entraremos em contato em breve."
      rescue => e
        Rails.logger.error "Support email failed: #{e.message}"
        flash.now[:alert] = "Erro ao enviar mensagem. Tente novamente ou entre em contato diretamente."
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Por favor, preencha todos os campos obrigatórios."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def valid_support_params?
    @name.present? && @email.present? && @subject.present? && @message.present? &&
    @email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
end
