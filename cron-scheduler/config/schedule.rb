env :PATH, ENV['PATH']

# handle alert email for every pending apporval
every 1.day, at: '9:00 am' do
  rake 'cron:pending_approval'
end

# handle create/update response insrurer api to Cache table
every 30.minutes do
  rake 'cron:update_cache_response'
end
