require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AdminPortal
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # delayed job table
    config.active_job.queue_adapter = :delayed_job
    config.after_initialize do
      Delayed::Backend::ActiveRecord::Job.table_name = 'admin_portal_delayed_jobs'
    end

    config.generators.system_tests = nil
    config.time_zone = 'Singapore'

    config.cache_store = :redis_store, {
        host: "127.0.0.1",
        port: 6379,
        namespace: "IMSG_cache"
    }
  end
end
