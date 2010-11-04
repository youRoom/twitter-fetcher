ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home', :action => 'index'
  map.resources :groups, :only => [] do |group|
    group.resources :twitter_fetchers
    group.resources :oauth, :only => [], :collection => %w(verify_youroom callback_youroom verify_twitter callback_twitter)
  end
  map.logout "logout", :controller => 'sessions', :action => :destroy

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
