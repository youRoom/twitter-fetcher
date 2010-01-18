# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_twitter-fetcher_session',
  :secret      => '4cfaecf2fa004b4daa5d83ca5ba0b269d404b6f88f081ea2cb64718d005f0b617e1a6b4d5a82eec8bc1c79545fc713d8dcea30b18e0cbfb1aa3eff789101634f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
