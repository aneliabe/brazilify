class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.setup_stripe_customer

    session = Stripe::Checkout::Session.create(
      customer: current_user.stripe_customer_id,
      payment_method_types: ['card'],
      line_items: [{
        price: 'price_1S6JCRLvltjcLiBvCmyzHC0D',
        quantity: 1
      }],
      mode: 'subscription',
      success_url: worker_user_url(current_user),
      cancel_url: root_url
    )
    redirect_to session.url, allow_other_host: true
    return
  end

  def cancel
    subscription = current_user.subscriptions
    return redirect_to users_worker_path(current_user), alert: "No subscription found" unless subscription

    subscription.update(status: "canceled")
    redirect_to worker_user_url(current_user), notice: "Subscription canceled."
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
end
