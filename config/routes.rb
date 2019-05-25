Rails.application.routes.draw do
  namespace :manage do
    #root
    root 'static_pages#home'

    #users
    get '/signup', to: 'users#new'
    post '/signup', to: 'users#create'
    resources :users

    #types
    get 'types/new'

    #sessions
    get '/login', to: 'sessions#new'
    post '/login', to: 'sessions#create'
    delete '/logout', to: 'sessions#destroy'
  end

  namespace :admin do
    resources :types
    resources :users

    root to: "types#index"
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
