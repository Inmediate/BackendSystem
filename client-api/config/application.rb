require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ClientAPIServer
  class Application < Rails::Application

    # Initialize number of threads.
    config.max_threads = 2

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.api_only = true
    config.time_zone = 'Singapore'

    # redis configuration
    config.cache_store = :redis_store, {
        host: "127.0.0.1",
        port: 6379,
        namespace: "IMSG_cache"
    }

    # delayed job table
    config.active_job.queue_adapter = :delayed_job
    config.after_initialize do
      Delayed::Backend::ActiveRecord::Job.table_name = 'client_api_delayed_jobs'
    end
  end
end
