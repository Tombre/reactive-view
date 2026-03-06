class E2eAuthController < ApplicationController
  before_action :ensure_test_environment!

  def sign_in
    user = find_user
    return render json: { success: false, error: 'User not found' }, status: :not_found unless user

    session[:account_id] = user.id
    session[:e2e_authenticated] = true

    render json: {
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    }
  end

  def sign_out
    session.delete(:account_id)
    session.delete('account_id')
    session.delete(:e2e_authenticated)
    session.delete('e2e_authenticated')
    session.delete(:pending_webauthn_account_id)
    session.delete('pending_webauthn_account_id')

    render json: { success: true }
  end

  private

  def ensure_test_environment!
    head :not_found unless Rails.env.test?
  end

  def find_user
    return User.order(:id).first if params[:email].blank?

    normalized_email = params[:email].to_s.strip.downcase
    User.find_by(email: normalized_email)
  end
end
