# frozen_string_literal: true

module Pages
  module Admin
    module Auth
      class LoginLoader < ReactiveView::Loader
        shape :load do
          param :require_2fa, :boolean
          param :session_timeout, :integer
        end

        response_shape :load, :load

        def load
          {
            require_2fa: true,
            session_timeout: 30
          }
        end
      end
    end
  end
end
