ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home', :action => 'index'
  map.resources :groups, :only => [] do |group|
    group.resources :twitter_fetchers
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
