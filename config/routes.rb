Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api do
    get('/links/:term/:identifier', to: 'links#show')
    post('/links', to: 'links#create')
  end
end
