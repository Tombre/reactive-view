# frozen_string_literal: true

module Pages
  module Admin
    module Auth
      class LoginLoader < ReactiveView::Loader
        include RodauthLoaderAuthentication

        before_action :redirect_authenticated_user!, only: :call

        shape :load do
          param :supports_passkeys, :boolean
        end

        response_shape :load, :load

        shape :begin_sign_in do
          param :email
        end

        params_shape :begin_sign_in, :begin_sign_in

        shape :begin_sign_in_result do
          param :success, :boolean
          param :email
          param :public_key, :any
          param :challenge
          param :challenge_hmac
        end

        response_shape :begin_sign_in, :begin_sign_in_result

        shape :finish_sign_in do
          param :email
          param :credential_json, :any
          param :challenge
          param :challenge_hmac
        end

        params_shape :finish_sign_in, :finish_sign_in

        shape :finish_sign_in_result do
          param :success, :boolean
        end

        response_shape :finish_sign_in, :finish_sign_in_result
        def load
          {
            supports_passkeys: true
          }
        end

        def begin_sign_in
          result = shapes.begin_sign_in.call!(params)
          email = result.data[:email].to_s.strip.downcase

          begin
            options = RodauthApp.rodauth.webauthn_login_params(rodauth_internal_options(login: email))
          rescue Rodauth::InternalRequestError
            return render_error(base: ['No passkey found for that email'])
          end

          render_success(
            email: email,
            public_key: options.fetch(:webauthn_auth),
            challenge: options.fetch(:webauthn_auth_challenge),
            challenge_hmac: options.fetch(:webauthn_auth_challenge_hmac)
          )
        end

        def finish_sign_in
          result = shapes.finish_sign_in.call!(params)
          data = result.data

          begin
            account_id = RodauthApp.rodauth.webauthn_login(
              rodauth_internal_options(
                login: data[:email].to_s.strip.downcase,
                webauthn_auth: data[:credential_json],
                webauthn_auth_challenge: data[:challenge],
                webauthn_auth_challenge_hmac: data[:challenge_hmac]
              )
            )
          rescue Rodauth::InternalRequestError => e
            return render_error(base: [rodauth_error_message(e)])
          end

          return render_error(base: ['Passkey sign-in failed']) if account_id.blank?

          session[:account_id] = account_id

          mutation_redirect('/dashboard')
        end
      end
    end
  end
end
