# frozen_string_literal: true

module Pages
  class NavigationStateLoader < ReactiveView::Loader
    include RodauthLoaderAuthentication

    shape :load do
      param :authenticated, :boolean
      param :name, ReactiveView::Types::Optional[ReactiveView::Types::String]
      param :email, ReactiveView::Types::Optional[ReactiveView::Types::String]
    end

    response_shape :load, :load

    shape :logout do
    end

    params_shape :logout, :logout

    shape :logout_result do
      param :success, :boolean
    end

    response_shape :logout, :logout_result

    def load
      return { authenticated: false, name: nil, email: nil } unless authenticated_user?

      {
        authenticated: true,
        name: current_user.name,
        email: current_user.email
      }
    end

    def logout
      session.delete(:account_id)
      session.delete('account_id')
      session.delete(:e2e_authenticated)
      session.delete('e2e_authenticated')
      session.delete(:pending_webauthn_account_id)
      session.delete('pending_webauthn_account_id')

      mutation_redirect('/login')
    end
  end
end
