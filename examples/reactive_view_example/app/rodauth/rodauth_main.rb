require 'sequel/core'

class RodauthMain < Rodauth::Rails::Auth
  configure do
    enable :create_account, :login, :logout, :webauthn, :webauthn_login, :internal_request

    db Sequel.sqlite(extensions: :activerecord_connection, keep_reference: false)
    convert_token_id_to_integer? { User.columns_hash['id'].type == :integer }

    accounts_table :users
    prefix '/_rodauth'
    rails_controller { RodauthController }
    login_param 'email'
    login_label 'Email'

    hmac_secret { Rails.application.secret_key_base }

    create_account_set_password? false
    require_login_confirmation? false

    webauthn_user_verification 'required'
    webauthn_rp_name 'ReactiveView Example'

    before_create_account do
      name = param('name').strip
      throw_error_status(422, 'name', 'must be present') if name.empty?

      now = Time.current
      account[:name] = name
      account[:created_at] = now
      account[:updated_at] = now
    end

    logout_redirect '/'
  end
end
