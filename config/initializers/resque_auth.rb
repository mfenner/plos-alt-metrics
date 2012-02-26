Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password == APP_CONFIG['resque_password']
end