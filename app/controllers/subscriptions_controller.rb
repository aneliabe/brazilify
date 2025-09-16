class SubscriptionsController < ApplicationController

  # def show
  # end

  # def new
  # end

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
      success_url: root_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url
    )
    redirect_to session.url, allow_other_host: true
  end

  def destroy
  end
end
