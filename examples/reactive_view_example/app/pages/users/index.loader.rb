# frozen_string_literal: true

module Pages
  module Users
    class IndexLoader < ReactiveView::Loader
      # Inline response shape definition for the load action.
      response_shape do
        collection :users do
          param :id, :integer
          param :name
          param :email
        end
        param :total, :integer
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
