# frozen_string_literal: true

module Pages
  module Admin
    class BaseDashboardLoader < ReactiveView::Loader
      include RodauthLoaderAuthentication

      before_action :require_authenticated_user!, only: :call

      def load
        require_authenticated_user!
        dashboard_load
      end

      private

      def dashboard_load
        {}
      end
    end
  end
end
