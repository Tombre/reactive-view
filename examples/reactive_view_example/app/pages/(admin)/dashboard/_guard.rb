# frozen_string_literal: true

module Pages
  module Admin
    module Dashboard
      class Guard < ReactiveView::RouteGuard
        include RodauthLoaderAuthentication

        guard :require_authenticated_user!
      end
    end
  end
end
