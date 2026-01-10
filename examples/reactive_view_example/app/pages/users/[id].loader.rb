# frozen_string_literal: true

module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      # Define the type shape for this loader's response
      shape :load do
        param :user, ReactiveView::Types::Hash.schema(
          id: ReactiveView::Types::Integer,
          name: ReactiveView::Types::String,
          email: ReactiveView::Types::String,
          created_at: ReactiveView::Types::String
        )
      end

      # Define the shape for update mutation params
      shape :update do
        param :name, ReactiveView::Types::String
        param :email, ReactiveView::Types::String
      end

      # Define the shape for delete mutation (no params needed)
      shape :delete do
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

      # Update the user
      def update
        typed_params = shapes.update(params)

        if user.update(typed_params)
          render_success(
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              created_at: user.created_at.iso8601
            },
            revalidate: ['users/index']
          )
        else
          render_error(user)
        end
      end

      # Delete the user
      def delete
        if user.destroy
          mutation_redirect '/users'
        else
          render_error(user)
        end
      end

      private

      def user
        @user ||= User.find(params[:id])
      end
    end
  end
end
