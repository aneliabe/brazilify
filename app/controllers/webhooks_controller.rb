# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET'] # your secret from Stripe dashboard

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      return head :bad_request
    rescue Stripe::SignatureVerificationError => e
      return head :bad_request
    end

    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      handle_checkout_session(session)
    when 'customer.subscription.deleted'
      subscription = event.data.object
      handle_subscription_cancellation(subscription)
    end

    head :ok
  end

  private

  def handle_checkout_session(session)
    user = User.find_by(stripe_customer_id: session.customer)
    return unless user

    Subscription.create(
      user: user,
      stripe_subscription_id: session.subscription,
      stripe_customer_id: session.customer,
      status: 'active',
    )
  end

  def handle_subscription_cancellation(subscription)
    record = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless record

    record.update(status: 'canceled', canceled_at: Time.current)
  end
end
