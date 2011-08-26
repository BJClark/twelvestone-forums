Twelvestone::Application.routes.draw do
  devise_for :users
  resources :forums
  resources :conversations, :member => { :unsubscribe => :put }
  resources :posts, :member => { :quote => :get, :undelete => :put }

  
  root :to => "forums#index"
end
