require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'
require 'pg'

class BasicAuthForModifyingMethods
  def initialize(app, &block)
    @app = app
    @app_with_basic_auth = Rack::Auth::Basic.new(app, &block)
  end

  def call(env)
    if env['REQUEST_METHOD'] == 'GET'
      @app.call(env)
    else
      @app_with_basic_auth.call(env)
    end
  end
end

app = PactBroker::App.new do | config |
  # change these from their default values if desired
  # config.log_dir = "./log"
  # config.auto_migrate_db = true
  # config.use_hal_browser = true
  config.database_connection = Sequel.connect(ENV['DATABASE_URL'], adapter: "postgres", encoding: 'utf8')
end

app_with_auth = BasicAuthForModifyingMethods.new(app) do |username, password|
  username == ENV['PACT_BROKER_USERNAME'] and password == ENV['PACT_BROKER_PASSWORD']
end

run app_with_auth
