# frozen_string_literal: true

module Pages
  module Admin
    module Dashboard
      class IndexLoader < Pages::Admin::BaseDashboardLoader
        shape :load do
          param :authenticated, :boolean
        end

        response_shape :load, :load

        def dashboard_load
          { authenticated: true }
        end
      end
    end
  end
end
