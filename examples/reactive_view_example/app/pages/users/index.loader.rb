# frozen_string_literal: true

module Pages
  module Users
    class IndexLoader < ReactiveView::Loader
      # Define the type signature for this loader's response
      # This is used to:
      # 1. Generate TypeScript types for the frontend
      # 2. Validate the response in development/test modes
      loader_sig do
        param :users, ReactiveView::Types::Array[
          ReactiveView::Types::Hash.schema(
            id: ReactiveView::Types::Integer,
            name: ReactiveView::Types::String,
            email: ReactiveView::Types::String
          )
        ]
        param :total, ReactiveView::Types::Integer
      end

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
