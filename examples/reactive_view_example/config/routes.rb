Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # ReactiveView routes are automatically drawn from app/pages/
  # The engine mounts at /_reactive_view for internal loader data routes
  #
  # Page routes created:
  #   GET /              -> app/pages/index.tsx
  #   GET /about         -> app/pages/about.tsx
  #   GET /counter       -> app/pages/counter.tsx
  #   GET /users         -> app/pages/users/index.tsx
  #   GET /users/:id     -> app/pages/users/[id].tsx

  if Rails.env.test?
    get '/__e2e__/auth/sign_in', to: 'e2e_auth#sign_in'
    get '/__e2e__/auth/sign_out', to: 'e2e_auth#sign_out'
  end
end
