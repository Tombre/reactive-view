# frozen_string_literal: true

module RodauthLoaderAuthentication
  class AuthenticationRequired < StandardError
    attr_reader :redirect_path

    def initialize(message = 'Authentication required', redirect_path: '/login')
      @redirect_path = redirect_path
      super(message)
    end
  end

  private

  def rodauth_internal_env
    {
      'rack.url_scheme' => request.protocol.delete_suffix('://'),
      'HTTP_HOST' => request.host_with_port,
      'SERVER_NAME' => request.host,
      'SERVER_PORT' => request.port.to_s
    }
  end

  def rodauth_internal_options(options = {})
    options.merge(session: session, env: rodauth_internal_env)
  end

  def current_user
    return @current_user if defined?(@current_user)

    account_id = session[:account_id] || session['account_id']
    @current_user = account_id ? User.find_by(id: account_id) : nil
  end

  def authenticated_user?
    return false unless current_user
    return true if Rails.env.test? && (session[:e2e_authenticated] || session['e2e_authenticated'])

    AccountWebauthnKey.where(account_id: current_user.id).exists?
  end

  def require_authenticated_user!
    return if authenticated_user?

    raise AuthenticationRequired.new if loader_data_request?

    redirect_to '/login'
  end

  def redirect_authenticated_user!
    return unless authenticated_user?

    redirect_to '/dashboard'
  end

  def rodauth_error_message(error)
    field_errors = error.field_errors.values.flatten.join(' ')
    [error.flash, error.reason, field_errors.presence].compact.join(' ').strip
  end

  def loader_data_request?
    request.path.to_s.start_with?('/_reactive_view/loaders/')
  end
end
