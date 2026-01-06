# frozen_string_literal: true

module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      # Define the type signature for this loader's response
      loader_sig do
        param :user, ReactiveView::Types::Hash.schema(
          id: ReactiveView::Types::Integer,
          name: ReactiveView::Types::String,
          email: ReactiveView::Types::String,
          created_at: ReactiveView::Types::String
        )
      end

      # Load the data for this page
      def load
        {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            created_at: user.created_at.iso8601
          }
        }
      end

      private

      def user
        @user ||= User.find(params[:id])
      end
    end
  end
end
