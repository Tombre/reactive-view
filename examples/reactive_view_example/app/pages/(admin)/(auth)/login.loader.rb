# frozen_string_literal: true

module Pages
  module Admin
    module Auth
      class LoginLoader < ReactiveView::Loader
        response_shape do
          param :require_2fa, :boolean
          param :session_timeout, :integer
        end

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
