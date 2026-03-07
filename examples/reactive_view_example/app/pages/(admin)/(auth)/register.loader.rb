# frozen_string_literal: true

module Pages
  module Admin
    module Auth
      class RegisterLoader < ReactiveView::Loader
        include RodauthLoaderAuthentication

        before_action :redirect_authenticated_user!, only: :call

        shape :load do
          param :supports_passkeys, :boolean
        end

        response_shape :load, :load

        shape :begin_register do
          param :name
          param :email
        end

        params_shape :begin_register, :begin_register

        shape :begin_register_result do
          param :success, :boolean
          param :email
          param :public_key, :any
          param :challenge
          param :challenge_hmac
        end

        response_shape :begin_register, :begin_register_result

        shape :finish_register do
          param :credential_json, :any
          param :challenge
          param :challenge_hmac
        end

        params_shape :finish_register, :finish_register

        shape :finish_register_result do
          param :success, :boolean
        end

        response_shape :finish_register, :finish_register_result

        def load
          {
            supports_passkeys: true
          }
        end

        def begin_register
          result = shapes.begin_register.call!(params)
          name = result.data[:name].to_s.strip
          email = result.data[:email].to_s.strip.downcase
          account_id = nil

          begin
            RodauthApp.rodauth.create_account(
              rodauth_internal_options(
                login: email,
                params: { 'name' => name }
              )
            )
            account_id = RodauthApp.rodauth.account_id_for_login(login: email)
          rescue Rodauth::InternalRequestError => e
            existing_user = User.find_by(email: email)
            passkey_exists = existing_user && AccountWebauthnKey.where(account_id: existing_user.id).exists?

            can_resume_registration = existing_user && !passkey_exists &&
                                      (current_user.nil? || current_user.id == existing_user.id)

            return render_error(base: [rodauth_error_message(e)]) unless can_resume_registration

            account_id = existing_user.id
          end

          begin
            options = RodauthApp.rodauth.webauthn_setup_params(rodauth_internal_options(account_id: account_id))
          rescue Rodauth::InternalRequestError => e
            return render_error(base: [rodauth_error_message(e)])
          end

          session[:pending_webauthn_account_id] = account_id

          render_success(
            email: email,
            public_key: options.fetch(:webauthn_setup),
            challenge: options.fetch(:webauthn_setup_challenge),
            challenge_hmac: options.fetch(:webauthn_setup_challenge_hmac)
          )
        end

        def finish_register
          result = shapes.finish_register.call!(params)
          data = result.data
          account_id = session[:pending_webauthn_account_id] || session['pending_webauthn_account_id']

          return render_error(base: ['Registration session expired. Please try again.']) if account_id.blank?

          begin
            RodauthApp.rodauth.webauthn_setup(
              rodauth_internal_options(
                account_id: account_id,
                webauthn_setup: data[:credential_json],
                webauthn_setup_challenge: data[:challenge],
                webauthn_setup_challenge_hmac: data[:challenge_hmac]
              )
            )
          rescue Rodauth::InternalRequestError => e
            return render_error(base: [rodauth_error_message(e)])
          end

          session.delete(:pending_webauthn_account_id)
          session.delete('pending_webauthn_account_id')
          session[:account_id] = account_id

          mutation_redirect('/dashboard')
        end
      end
    end
  end
end
