FactoryBot.define do

  factory :client do
    name 'abc'
    contact_person_name 'abc'
    contact_person_email '1234@ab.com'
    whitelisted_ip '0.0.0.0'
    client_api_key '123456'
    activation_status true
    status true
  end

  factory :product do
    name '1234'
    code '1234'
  end

  factory :client_api do
    id 1
    path 'api/test'
    activation_status true
    status true
    product
  end

  factory :client_api_client do
  end

  factory :insurer do
    company_name 'abcd'
    contact_person_name 'abcd'
    contact_person_email 'abcd@1234.com'
    company_code '11111'
    status true
    activation_status true
  end

  factory :insurer_client do
  end

  factory :insurer_product do
  end

  factory :insurer_product_api do
    api_method "GET"
    api_url "https://jsonplaceholder.typicode.com/posts/1"
    payload "{\"data\":\"11\"}"
    cache_policy 'Database'
    api_flavour 'Type 1'
    payload_type 'JSON'
    payload_validation '[]'
    activation_status true
    status true
    client_api
  end

  factory :response_cache do
    payload_sha256 Digest::SHA256.base64digest("{\"data\":\"11\"}")
    response 'MTIzNDU2Nzg5MA=='
  end

end