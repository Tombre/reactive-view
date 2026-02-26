# frozen_string_literal: true

module Pages
  module Users
    class IndexLoader < ReactiveView::Loader
      # Define the type shape for this loader's response
      # This is used to:
      # 1. Generate TypeScript types for the frontend
      # 2. Validate the response in development/test modes
      shape :load do
        collection :users do
          param :id, :integer
          param :name
          param :email
        end
        param :total, :integer
      end

      response_shape :load, :load

      # Load the data for this page
      # This is called when SolidStart requests data during SSR
      def load
        {
          users: users.map do |user|
            {
              id: user.id,
              name: user.name,
              email: user.email
            }
          end,
          total: User.count
        }
      end

      private

      def users
        User.order(:name).limit(20)
      end
    end
  end
end
