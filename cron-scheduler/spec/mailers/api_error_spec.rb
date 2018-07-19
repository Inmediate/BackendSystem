require "rails_helper"

RSpec.describe ApiErrorMailer, type: :mailer do

  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe 'Send Email' do

    it 'if Insurer Product APi is missing' do
      ApiErrorMailer.email(nil, '', '', '', '').deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it 'if response code is missing' do
      insurer = create(:insurer)
      api = create(:insurer_product_api, insurer: insurer)
      ApiErrorMailer.email(api, '', nil, '', '').deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it 'should send an email' do
      insurer = create(:insurer, contact_person_email:'faridul.ahmad@tinkerbox.com.sg' )
      api = create(:insurer_product_api, insurer: insurer)
      ApiErrorMailer.email(api, '', 200, '', '').deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'should send to the receiver email address' do
      insurer = create(:insurer, contact_person_email:'faridul.ahmad@tinkerbox.com.sg' )
      api = create(:insurer_product_api, insurer: insurer)
      ApiErrorMailer.email(api, '', 200, '', '').deliver_now
      expect(ActionMailer::Base.deliveries.first.to.first).to eq('faridul.ahmad@tinkerbox.com.sg')
    end

    it 'should set the subject to the correct subject' do
      insurer = create(:insurer, contact_person_email:'faridul.ahmad@tinkerbox.com.sg' )
      api = create(:insurer_product_api, insurer: insurer)
      ApiErrorMailer.email(api, '', 200, '', '').deliver_now
      expect(ActionMailer::Base.deliveries.first.subject).to eq('Cron Scheduler: Request Insurer API Failed')
    end

  end

end
