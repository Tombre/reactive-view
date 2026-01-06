# frozen_string_literal: true

ReactiveView::Engine.routes.draw do
  # Internal route for SolidStart to fetch loader data
  # Path: /_reactive_view/loaders/:path/load
  # Example: /_reactive_view/loaders/users/[id]/load?token=xxx
  get 'loaders/*path/load', to: 'loader_data#show', as: :loader_data
end
