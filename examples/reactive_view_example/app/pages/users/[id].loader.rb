# frozen_string_literal: true

module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      # Define the type shape for this loader's response
      shape :load do
        hash :user do
          param :id, :integer
          param :name
          param :email
          param :created_at
        end
      end

      # Define the shape for update mutation params
      shape :update do
        param :name
        param :email
      end

      # Define the shape for delete mutation (no params needed)
      shape :delete do
      end

      # Assign shapes to actions
      response_shape :load, :load
      params_shape :update, :update
      params_shape :delete, :delete

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
        result = shapes.update.call!(params)

        if user.update(result.data)
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
