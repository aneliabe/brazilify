class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
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
      success_url: worker_user_url(current_user),
      cancel_url: root_url
    )
    redirect_to session.url, allow_other_host: true
    return
  end

  # def success
  # session = Stripe::Checkout::Session.retrieve(params[:session_id])
  # stripe_sub = Stripe::Subscription.retrieve(session.subscription)

  # # Create subscription record
  # Subscription.create!(
  #   user: current_user,
  #   stripe_subscription_id: stripe_sub.id,
  #   stripe_customer_id: session.customer,
  #   status: stripe_sub.status,
  #   plan_name: stripe_sub.items.data.first.price.nickname,
  #   current_period_start: Time.at(stripe_sub.current_period_start),
  #   current_period_end: Time.at(stripe_sub.current_period_end),
  #   price_cents: stripe_sub.items.data.first.price.unit_amount,
  #   price_currency: stripe_sub.items.data.first.price.currency
  # )

  # redirect_to worker_dashboard_user_path(current_user), notice: "Subscription created!"
  # end


  # def destroy
  #   @subscription = current_user.subscription # or Subscription.find(params[:id])

  #   if @subscription
  #     # Optionally cancel it in Stripe first
  #     Stripe::Subscription.update(@subscription.stripe_subscription_id, { cancel_at_period_end: true })

  #     @subscription.destroy
  #     flash[:notice] = "Subscription canceled successfully."
  #   else
  #     flash[:alert] = "Subscription not found."
  #   end

  #   redirect_to root_path
  # end

  def cancel
    subscription = current_user.subscription
    return redirect_to users_worker_path(current_user), alert: "No subscription found" unless subscription

    subscription.update(status: "canceled")
    redirect_to worker_user_url(current_user), notice: "Subscription canceled."
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
end
