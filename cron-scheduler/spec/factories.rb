FactoryBot.define do

  factory :approval do
    table "table_test"
  end

  factory :role do
    id 2
  end

  factory :user do
    name "1234"
    email "1234@abcd.com"
    role_id 2
    status true
    activation_status true
    accept_invitation true
  end

  factory :insurer do
    company_name "1234"
    activation_status true
    status true
    company_code SecureRandom.random_number(100000)
    contact_person_name "abcd"
    contact_person_email "abcd@1234.com"
  end

  factory :insurer_product_api do
    api_method "GET"
    api_url "https://jsonplaceholder.typicode.com/posts/1"
    activation_status true
    status true
    payload "{\"data\":\"11\"}"
    cache_policy 'Database'
    api_flavour 'Type 1'
    payload_validation '[]'
  end

  factory :response_cache do
    payload_sha256 Digest::SHA256.base64digest("{\"data\":\"11\"}")
    url "https://jsonplaceholder.typicode.com/posts/1"
  end


end