# frozen_string_literal: true

ReactiveView::Engine.routes.draw do
  # Internal route for SolidStart to fetch loader data
  # Path: /_reactive_view/loaders/:path/load
  # Example: /_reactive_view/loaders/users/[id]/load?id=123
  get 'loaders/*path/load', to: 'loader_data#show', as: :loader_data

  # Internal route for mutations
  # Path: /_reactive_view/loaders/:path/mutate
  # Example: POST /_reactive_view/loaders/users/[id]/mutate?_mutation=update
  # Supports POST, PUT, PATCH, DELETE methods
  match 'loaders/*path/mutate', to: 'loader_data#mutate',
                                via: %i[post put patch delete], as: :loader_mutate
end
