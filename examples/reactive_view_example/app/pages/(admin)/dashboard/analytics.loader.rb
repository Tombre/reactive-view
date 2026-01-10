# frozen_string_literal: true

module Pages
  module Admin
    module Dashboard
      class AnalyticsLoader < ReactiveView::Loader
        shape :load do
          param :chart_data, ReactiveView::Types::Array[
            ReactiveView::Types::Hash.schema(
              label: ReactiveView::Types::String,
              value: ReactiveView::Types::Integer
            )
          ]
          param :top_pages, ReactiveView::Types::Array[
            ReactiveView::Types::Hash.schema(
              path: ReactiveView::Types::String,
              views: ReactiveView::Types::Integer
            )
          ]
          param :traffic_sources, ReactiveView::Types::Array[
            ReactiveView::Types::Hash.schema(
              source: ReactiveView::Types::String,
              percentage: ReactiveView::Types::Integer
            )
          ]
          param :total_views, ReactiveView::Types::Integer
          param :period, ReactiveView::Types::String
        end

        def load
          period = params[:period] || 'week'

          # Simulate fetching analytics data from database
          # In a real app, this would query your analytics service or database
          {
            chart_data: generate_chart_data(period),
            top_pages: [
              { path: '/dashboard', views: 1234 },
              { path: '/users', views: 892 },
              { path: '/about', views: 456 }
            ],
            traffic_sources: [
              { source: 'Direct', percentage: 45 },
              { source: 'Search', percentage: 32 },
              { source: 'Social', percentage: 23 }
            ],
            total_views: 2582,
            period: period
          }
        end

        private

        def generate_chart_data(period)
          case period
          when 'week'
            [
              { label: 'Mon', value: 45 },
              { label: 'Tue', value: 62 },
              { label: 'Wed', value: 54 },
              { label: 'Thu', value: 71 },
              { label: 'Fri', value: 58 },
              { label: 'Sat', value: 39 },
              { label: 'Sun', value: 48 }
            ]
          when 'month'
            [
              { label: 'Week 1', value: 310 },
              { label: 'Week 2', value: 287 },
              { label: 'Week 3', value: 342 },
              { label: 'Week 4', value: 298 }
            ]
          when 'year'
            [
              { label: 'Jan', value: 1240 },
              { label: 'Feb', value: 1180 },
              { label: 'Mar', value: 1350 },
              { label: 'Apr', value: 1290 },
              { label: 'May', value: 1420 },
              { label: 'Jun', value: 1380 },
              { label: 'Jul', value: 1510 },
              { label: 'Aug', value: 1460 },
              { label: 'Sep', value: 1390 },
              { label: 'Oct', value: 1440 },
              { label: 'Nov', value: 1370 },
              { label: 'Dec', value: 1500 }
            ]
          else
            []
          end
        end
      end
    end
  end
end
