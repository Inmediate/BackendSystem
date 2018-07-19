Rails.application.routes.draw do
  match '/', to: 'application#render_no_route', via: :all
  match '/*route', to: 'api#index', via: :all
end
