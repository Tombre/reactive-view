# frozen_string_literal: true

module Pages
  module Admin
    module Auth
      class LoginLoader < ReactiveView::Loader
        shape :load do
          param :require_2fa, ReactiveView::Types::Bool
          param :session_timeout, ReactiveView::Types::Integer
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
