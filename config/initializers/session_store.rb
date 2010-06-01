# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_restApp_session',
  :secret      => 'f7f79445a34c03f02970a231b8f559fc7ab1bafbd1bfe0d798cda70275cab77b8a96535a582be973294ace86ad9dc5b295f9f426088548e5ba6efb22b7b2a143'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
