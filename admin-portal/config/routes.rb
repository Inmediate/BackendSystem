Rails.application.routes.draw do

  # Reports
  get 'log/product_api', to: 'log#product_api'
  get 'log/client_api', to: 'log#client_api'
  get 'log/approval', to: 'log#approval'
  get 'log/session_history', to: 'log#session_history'


  # Insurer Product API
  get 'insurer/:insurer_id/api/new', to: 'insurer_product_api#new'
  post 'insurer/:insurer_id/api/create', to: 'insurer_product_api#create'
  get 'insurer/:insurer_id/api/edit/:id', to: 'insurer_product_api#edit'
  get 'insurer/:insurer_id/api/edit_pending/:approval_id', to: 'insurer_product_api#edit_pending'
  post 'insurer/:insurer_id/api/update_pending/:approval_id', to: 'insurer_product_api#update_pending'
  match 'insurer/:insurer_id/api/update/:id', to: 'insurer_product_api#update', via: %i[patch post]
  get 'insurer/:insurer_id/api/delete/:id', to: 'insurer_product_api#delete'
  get 'insurer/:insurer_id/api/approve/:id', to: 'insurer_product_api#approve'
  get 'insurer/:insurer_id/api/approve_create/:approval_id', to: 'insurer_product_api#approve_create'
  get 'insurer/:insurer_id/api/reject/:id', to: 'insurer_product_api#reject'
  get 'insurer/:insurer_id/api/reject_delete/:approval_id', to: 'insurer_product_api#reject_delete'

  # Insurer Mapping
  get 'insurer/:insurer_id/mapping/new', to: 'insurer_mapping#new'
  post 'insurer/:insurer_id/mapping/create', to: 'insurer_mapping#create'
  get 'insurer/:insurer_id/mapping/edit/:id', to: 'insurer_mapping#edit'
  post 'insurer/:insurer_id/mapping/update/:id', to: 'insurer_mapping#update'
  get 'insurer/:insurer_id/mapping/delete/:id', to: 'insurer_mapping#delete'

  # Insurer
  get 'insurer/list', to: 'insurer#list'
  get 'insurer/new', to: 'insurer#new'
  post 'insurer/create', to: 'insurer#create'
  get 'insurer/edit/:id', to: 'insurer#edit'
  get 'insurer/edit_pending/:approval_id', to: 'insurer#edit_pending'
  post 'insurer/update_pending/:approval_id', to: 'insurer#update_pending'
  patch 'insurer/update/:id', to: 'insurer#update'
  get 'insurer/delete/:id', to: 'insurer#delete'
  get 'insurer/approve/:id', to: 'insurer#approve'
  get 'insurer/approve_create/:approval_id', to: 'insurer#approve_create'
  get 'insurer/reject/:id', to: 'insurer#reject'
  get 'insurer/reject_delete/:approval_id', to: 'insurer#reject_delete'

  # Mapping
  get 'mapping/list', to: 'mapping#list'
  get 'mapping/new', to: 'mapping#new'
  post 'mapping/create', to: 'mapping#create'
  get 'mapping/edit/:id', to: 'mapping#edit'
  get 'mapping/edit_pending/:approval_id', to: 'mapping#edit_pending'
  post 'mapping/update_pending/:approval_id', to: 'mapping#update_pending'
  patch 'mapping/update/:id', to: 'mapping#update'
  get 'mapping/delete/:id', to: 'mapping#delete'
  get 'mapping/approve/:id', to: 'mapping#approve'
  get 'mapping/approve_create/:approval_id', to: 'mapping#approve_create'
  get 'mapping/reject/:id', to: 'mapping#reject'
  get 'mapping/reject_delete/:approval_id', to: 'mapping#reject_delete'

  # Client
  get 'client/list', to: 'client#list'
  get 'client/new', to: 'client#new'
  post 'client/create', to: 'client#create'
  get 'client/edit/:id', to: 'client#edit'
  get 'client/edit_pending/:approval_id', to: 'client#edit_pending'
  post 'client/update_pending/:approval_id', to: 'client#update_pending'
  get 'client/reset_api_key_pending/:approval_id', to: 'client#reset_api_key_pending'
  patch 'client/update/:id', to: 'client#update'
  get 'client/delete/:id', to: 'client#delete'
  get 'client/approve/:id', to: 'client#approve'
  get 'client/approve_create/:approval_id', to: 'client#approve_create'
  get 'client/reject/:id', to: 'client#reject'
  get 'client/reject_delete/:approval_id', to: 'client#reject_delete'
  get 'client/reset_api_key/:id', to: 'client#reset_api_key'

  # Product
  get 'product/list', to: 'product#list'
  get 'product/new', to: 'product#new'
  post 'product/create', to: 'product#create'
  get 'product/edit/:id', to: 'product#edit'
  get 'product/edit_pending/:approval_id', to: 'product#edit_pending'
  get 'product/delete_pending/:approval_id', to: 'product#delete_pending'
  post 'product/update_pending/:approval_id', to: 'product#update_pending'
  patch 'product/update/:id', to: 'product#update'
  get 'product/approve/:id', to: 'product#approve'
  get 'product/reject/:id', to: 'product#reject'
  get 'product/approve_create/:approval_id', to: 'product#approve_create'
  get 'product/reject_delete/:approval_id', to: 'product#reject_delete'
  get 'product/delete/:id', to: 'product#delete'

  # client api
  get 'client/api/list', to: 'client_api#list'
  get 'client/api/new', to: 'client_api#new'
  get 'client/api/edit/:id', to: 'client_api#edit'
  get 'client/api/edit_pending/:approval_id', to: 'client_api#edit_pending'
  get 'client/api/delete_pending/:approval_id', to: 'client_api#delete_pending'
  post 'client/api/update_pending/:approval_id', to: 'client_api#update_pending'
  post 'client/api/create', to: 'client_api#create'
  patch 'client/api/update/:id', to: 'client_api#update'
  get 'client/api/approve/:id', to: 'client_api#approve'
  get 'client/api/reject/:id', to: 'client_api#reject'
  get 'client/api/approve_create/:approval_id', to: 'client_api#approve_create'
  get 'client/api/reject_delete/:approval_id', to: 'client_api#reject_delete'
  get 'client/api/delete/:id', to: 'client_api#delete'

  # dashboard
  root 'dashboard#main'
  get  '/setup', to: 'dashboard#setup'
  post '/setup_submit', to: 'dashboard#setup_submit'
  get '/profile', to: 'dashboard#profile'
  post '/profile_submit', to: 'dashboard#profile_submit'
  get '/setting', to: 'dashboard#setting'
  post '/setting_submit', to: 'dashboard#setting_submit'


  # authentication
  get 'login', to: 'authentication#login'
  get 'logout', to: 'authentication#logout'
  get 'password/forgot', to: 'authentication#forgot_password'
  get 'password/reset/:token', to: 'authentication#reset_password'
  get 'invite/:token', to: 'authentication#invite'
  post 'password/forgot/submit', to: 'authentication#forgot_password_submit'
  post 'password/reset/submit', to: 'authentication#reset_password_submit'
  post 'login/submit', to: 'authentication#login_submit'
  post 'invite_submit', to: 'authentication#invite_submit'

  # user
  get 'user/list', to: 'user#list'
  get 'user/new', to: 'user#new'
  post 'user/create', to: 'user#create'
  get 'user/edit/:id', to: 'user#edit'
  patch 'user/update/:id', to: 'user#update'
  get 'user/delete/:id', to: 'user#delete'
end
