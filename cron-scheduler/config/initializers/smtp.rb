ActionMailer::Base.smtp_settings = {
    :address              => '',
    :port                 => 587,
    :domain               => 'amazonaws.com',
    :user_name            => '',
    :password             => '',
    :authentication       => 'plain',
    :enable_starttls_auto => true
}
