Rails.application.routes.draw do
  mount MonsoonOpenstackAuth::Engine => '/auth'

  root to: 'services#index'

  scope "/:domain_id/(:project_id)" do
    scope module: 'authenticated_user' do
      resources :instances
      resources :volumes
      resources :os_images
      resources :users, only: [:new, :create]
      resources :credentials
      resources :projects, only: [:update, :create, :index, :show, :destroy] do
        #get 'credentials'
      end
    end
  end

  scope "/:domain_id" do
    match '/', to: 'services#index', via: :get
  end

  scope "/system" do
    get :health, to: "health#show"
  end

end
