# frozen_string_literal: true

module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      # Validate and coerce params for the load action.
      params_shape do
        param :id, :integer
      end

      # Define the type shape for this loader's response.
      response_shape do
        hash :user do
          param :id, :integer
          param :name
          param :email
          param :created_at
        end
      end

      # Validate and coerce params for update mutation.
      params_shape :update do
        param :id, :integer
        param :name
        param :email
      end

      # Validate and coerce params for delete mutation.
      params_shape :delete do
        param :id, :integer
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
        if user.update(name: params[:name], email: params[:email])
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
