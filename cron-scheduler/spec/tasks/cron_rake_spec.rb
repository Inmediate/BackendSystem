require 'rails_helper'
require 'rake'

describe 'Cron Schedular' do
  before :all do
    Rake.application.rake_require 'tasks/cron'
    Rake::Task.define_task(:environment)
  end
  describe 'Alert peding approval' do

    let :run_rake_task_pending_approval do
      Rake::Task['cron:pending_approval'].reenable
      Rake.application.invoke_task 'cron:pending_approval'
    end

    it 'not sending email if no pending approval' do
      expect { run_rake_task_pending_approval }.to change(Delayed::Job, :count).by(0)
    end

    it 'not sending email if no admin exists' do
      create(:approval)
      expect { run_rake_task_pending_approval }.to change(Delayed::Job, :count).by(0)
    end

    it 'not sending email if only content editor exists' do
      create(:approval)
      create(:role, id: 3)
      create(:user, role_id: 3)
      expect { run_rake_task_pending_approval }.to change(Delayed::Job, :count).by(0)
    end

    it 'not sending email if Admin status is deleted' do
      create(:approval)
      create(:role)
      create(:user, status: false)
      expect { run_rake_task_pending_approval }.to change(Delayed::Job, :count).by(0)
    end

    it 'not sending email if Admin status is deactivated' do
      create(:approval)
      create(:role)
      create(:user, activation_status: false)
      expect { run_rake_task_pending_approval }.to change(Delayed::Job, :count).by(0)
    end

    it 'should send email to all admins' do
      create(:approval)
      create(:role)
      create(:user)
      expect { run_rake_task_pending_approval }.to change(Delayed::Job, :count).by(1)
    end


  end

  describe 'Update response cahce' do

    let :run_rake_task_update_cache_response do
      Rake::Task['cron:update_cache_response'].reenable
      Rake.application.invoke_task 'cron:update_cache_response'
    end

    it 'not updating if Insurer is deleted' do
      create(:insurer, status: false)
      run_rake_task_update_cache_response
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(0)
    end

    it 'not updating if Insurer is deactivated' do
      create(:insurer, activation_status: false)
      run_rake_task_update_cache_response
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(0)
    end

    it 'not updating if Insurer Product API is deleted' do
      insurer = create(:insurer)
      create(:insurer_product_api, insurer_id: insurer.id, status: false)
      run_rake_task_update_cache_response
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(0)
    end

    it 'not updating if Insurer Product API is deleted' do
      insurer = create(:insurer)
      create(:insurer_product_api, insurer_id: insurer.id, activation_status: false)
      run_rake_task_update_cache_response
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(0)
    end

    it 'should create new response cache in cache table' do
      insurer = create(:insurer)
      api = create(:insurer_product_api, insurer: insurer)
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(2)

      # expect { run_rake_task_update_cache_response }.to change(ResponseCache, :count).by(1)
    end

    it 'send email alert if request return error' do
      insurer = create(:insurer)
      api = create(:insurer_product_api, insurer: insurer, api_url: 'http://123.abcom')
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(2)
    end

    it 'should update any expired response' do
      insurer = create(:insurer)
      api = create(:insurer_product_api, insurer: insurer)
      create(:response_cache, insurer_product_api_id: api.id, expired_at: 1.minutes.ago)
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(2)
    end

    it 'send email alert if retrurn error when update expired response' do
      insurer = create(:insurer)
      api = create(:insurer_product_api, insurer: insurer, api_url: 'http://123.abcom')
      create(:response_cache, insurer_product_api_id: api.id, expired_at: 1.minutes.ago)
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(2)
    end

    it 'should not update for non-expired response' do
      insurer = create(:insurer)
      api = create(:insurer_product_api, insurer: insurer)
      create(:response_cache, insurer_product_api_id: api.id, expired_at: Time.current + 1.hour)
      expect { run_rake_task_update_cache_response }.to change(Delayed::Job, :count).by(0)
    end


  end

end


