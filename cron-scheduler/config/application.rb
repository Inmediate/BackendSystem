require_relative 'boot'

require 'rails/all'
# require "#{Rails.root.to_s}/lib/task/cron.rake"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CronJob
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.generators.system_tests = nil
    config.active_job.queue_adapter = :delayed_job
    config.time_zone = 'Singapore'
    config.assets.enabled = false


    # delayed job table
    config.after_initialize do
      Delayed::Backend::ActiveRecord::Job.table_name = 'cron_delayed_jobs'
    end
  end
end
