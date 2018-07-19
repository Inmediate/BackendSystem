require 'rails_helper'

RSpec.describe ApiController, type: :controller do

  let(:token) { ActionController::HttpAuthentication::Token.encode_credentials('123456') }
  let(:ip_address) { '0.0.0.0' }
  let(:request_payload) { "{\"data\":\"1234\",\"data_array\":[{\"data_child\":\"1234\"}]}" }
  let(:ca_payload) { "[{\"key_name\":\"data\",\"mandatory\":\"true\",\"validation\":\"\",\"parent_array\":\"\",\"description\":\"\"},{\"key_name\":\"data_array\",\"validation\":\"\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"key_name\":\"data_child\",\"validation\":\"\",\"parent_array\":\"data_array\",\"description\":\"\"},{\"key_name\":\"insurer_company_code\",\"validation\":\"\",\"parent_array\":\"\",\"description\":\"\"}]" }
  let(:ca_payload_mandotary) { "[{\"key_name\":\"data\",\"mandatory\":\"true\",\"validation\":\"\",\"parent_array\":\"\",\"description\":\"\"}]" }
  let(:ca_payload_validation) { "[{\"key_name\":\"data\",\"validation\":\"/^[a-z]{2}$/i\",\"enable_validation\":\"true\",\"parent_array\":\"\",\"description\":\"\"}]" }
  let(:ca_payload_array_mandatory) { "[{\"key_name\":\"data_array\",\"mandatory\":\"true\",\"validation\":\"\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"key_name\":\"data_child\",\"mandatory\":\"true\",\"validation\":\"\",\"parent_array\":\"data_array\",\"description\":\"\"}]" }
  let(:ca_payload_array_validation) { "[{\"key_name\":\"data_array\",\"mandatory\":\"true\",\"validation\":\"\",\"enable_validation\":\"true\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"key_name\":\"data_child\",\"mandatory\":\"true\",\"validation\":\"/^[a-z]{2}$/i\",\"enable_validation\":\"true\",\"parent_array\":\"data_array\",\"description\":\"\"}]" }
  let(:ca_payload_specific_insurer) { "[{\"key_name\":\"insurer_company_code\",\"validation\":\"\",\"parent_array\":\"\",\"description\":\"\"}]"}

  let(:ipa_body) { "{\"data\":\"_im_data\",\"_im_data_array\":[{\"child\":\"_im_data_child\"}]}" }
  let(:ipa_pv) {"[{\"name\":\"data\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_array\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_child\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"false\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"data_array\",\"description\":\"\"}]"}
  let(:ipa_pv_mandotary) { "[{\"name\":\"data\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"\",\"description\":\"\"}]" }
  let(:ipa_pv_validation) { "[{\"name\":\"data\",\"ref_name\":\"\",\"validation\":\"/^[a-z]{2}$/i\",\"mapping\":\"\",\"mandatory\":\"false\",\"enable_validation\":\"true\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"\",\"description\":\"\"}]" }
  let(:ipa_pv_array_mandotary) { "[{\"name\":\"data_array\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_child\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"data_array\",\"description\":\"\"}]"  }
  let(:ipa_pv_array_validation) { "[{\"name\":\"data_array\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_child\",\"ref_name\":\"\",\"validation\":\"/^[a-z]{2}$/i\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"true\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"data_array\",\"description\":\"\"}]"  }


  let :setup_request do
    @request.env['HTTP_AUTHORIZATION'] = token
    @request.remote_ip = ip_address
  end

  # controller do
  #   def index
  #     render json: {}, status: :ok
  #   end
  # end

  describe 'Authentication' do

    it 'returns 401 if authorization header missing' do
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 if client/api_key not exists' do
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:unauthorized)
    end

    it 'return 403 if client ip address is not in the whitelist' do
      setup_request
      create(:client, whitelisted_ip: '1.1.1.1')
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:forbidden)
    end

  end

  describe 'Route Matching' do

    # it 'return 404 if route is blank' do
    #   setup_request
    #   create(:client)
    #   get :index, :params => {:route => ''}
    #   expect(response).to have_http_status(:not_found)
    # end

    it 'return 404 if route not found' do
      setup_request
      create(:client)
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:not_found)
    end

    it 'return 403 if client is not supported for the client API (log created)' do
      setup_request
      client = create(:client)
      api = create(:client_api, method: 'GET')
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:forbidden)
      expect(Delayed::Job.count).to eq 1
    end

  end

  describe 'Payload validation' do

    it 'return 422 if missing mandatory variable at Body/Parameters (log created)' do
      setup_request
      client = create(:client)
      api = create(:client_api, method: 'GET', payloads: ca_payload_mandotary)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :data2=> '1234'}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 400 if validation does not meet (log created)' do
      setup_request
      client = create(:client)
      api = create(:client_api, method: 'GET', payloads: ca_payload_validation, validation: true)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :data => '1234'}
      expect(response).to have_http_status(:bad_request)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 422 if missing mandatory array variable at Body/Parameters (log created)' do
      setup_request
      client = create(:client)
      api = create(:client_api, method: 'GET', payloads: ca_payload_array_mandatory)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :data2=> '1234'}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 422 if missing mandatory child variable (of array) at Body/Parameters (log created)' do
      setup_request
      client = create(:client)
      api = create(:client_api, method: 'GET', payloads: ca_payload_array_mandatory)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :data_array => [{ :data_child2 => '1234' }]}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 400 if validation child variable (of array) does not meet (log created)' do
      setup_request
      client = create(:client)
      api = create(:client_api, method: 'GET', payloads: ca_payload_array_validation)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :data_array => [{ :data_child => '1234' }]}
      expect(response).to have_http_status(:bad_request)
      expect(Delayed::Job.count).to eq 1
    end

  end

  describe 'Insurer matching' do

    it 'return 404 if cannot find specific insurer (log created)' do
      setup_request
      insurer = create(:insurer, company_code: '00000')
      client = create(:client)
      api = create(:client_api, method: 'GET', validation: false)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
      expect(response).to have_http_status(:not_found)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 403 if client request for specific insurer that not supported by client (log created)' do
      setup_request
      insurer = create(:insurer)
      client = create(:client)
      api = create(:client_api, method: 'GET', validation: false)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
      expect(response).to have_http_status(:forbidden)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 404 if cannot find any insurer that supported by client (log created)' do
      setup_request
      insurer = create(:insurer)
      client = create(:client)
      api = create(:client_api, method: 'GET', validation: false)
      create(:client_api_client, client_api_id: api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:not_found)
      expect(Delayed::Job.count).to eq 1
    end
  end

  describe 'Insurer Product API matching' do

    it 'return 404 if specific insurer do not support any insurer product api that mapped to client api (log created)' do
      setup_request
      product = create(:product)
      insurer = create(:insurer)
      create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
      client = create(:client)
      create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
      client_api = create(:client_api, method: 'GET', validation: false, product: product)
      create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
      expect(response).to have_http_status(:not_found)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 404 if none of the insurers not support any insurer product api that mapped to client api (log created)' do
      setup_request
      product = create(:product)
      insurer = create(:insurer, company_code: '123')
      insurer2 = create(:insurer, company_code: '456')
      create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
      create(:insurer_product, insurer_id: insurer2.id, product_id: product.id)
      client = create(:client)
      create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
      create(:insurer_client, insurer_id: insurer2.id, client_id:client.id, product_id: product.id)
      client_api = create(:client_api, method: 'GET', validation: false, product: product)
      create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
      get :index, :params => {:route => 'api/test'}
      expect(response).to have_http_status(:not_found)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 404 if insurer product api is deactivated (log created)' do
      setup_request
      product = create(:product)
      insurer = create(:insurer)
      create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
      client = create(:client)
      create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
      client_api = create(:client_api, method: 'GET', validation: false, product: product)
      create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
      create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, activation_status: false)
      get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
      expect(response).to have_http_status(:not_found)
      expect(Delayed::Job.count).to eq 1
    end

    it 'return 404 if insurer product api is deleted (log created)' do
      setup_request
      product = create(:product)
      insurer = create(:insurer)
      create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
      client = create(:client)
      create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
      client_api = create(:client_api, method: 'GET', validation: false, product: product)
      create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
      create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, status: false)
      get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
      expect(response).to have_http_status(:not_found)
      expect(Delayed::Job.count).to eq 1
    end

  end

  describe 'Insurer Connector' do

    let(:headers) { "[{\"head\":\"Accept\",\"value\":\"application/json\"},{\"head\":\"Content-Type\",\"value\":\"application/json\"}]" }


    describe 'Payload Validation' do

      it 'should received response code 422 for missing mandatory variable' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: true, payload_validation: ipa_pv_mandotary, payload: ipa_body)
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "response_code":422,
                "reason":"MISSING_INPUTS"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
      end

      it 'should received response code 400 for validation failed' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: true, payload_validation: ipa_pv_validation, payload: ipa_body)
        get :index, :params => {:route => 'api/test', :data => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "response_code":400,
                "reason":"VALIDATION_FAILED"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
      end

      it 'should received response code 422 for missing mandatory variable (array)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: true, payload_validation: ipa_pv_array_mandotary, payload: ipa_body)
        get :index, :params => {:route => 'api/test', :data_array => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "response_code":422,
                "reason":"MISSING_INPUTS"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
      end

      it 'should received response code 400 for validation failed (array)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: true, payload_validation: ipa_pv_array_validation, payload: ipa_body)
        get :index, :params => {:route => 'api/test', :data_array => [{ :data_child => '1234' }]}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "response_code":400,
                "reason":"VALIDATION_FAILED"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
      end

    end

    describe 'Replace Payload Variable' do

      let(:ipa_body) { "{\"data\":\"_im_data\"}" }
      let(:ipa_body_encrypted) { "{\"p_one\":\"_im_p_one\"}" }
      let(:ipa_body_array ) { "{\"_im_data_array\":[{\"child\":\"_im_data_child\"}]}" }

      let(:standard) { "[{\"name\":\"data\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"\",\"description\":\"\"}]" }
      let(:standard_array) { "[{\"name\":\"data_array\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_child\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"data_array\",\"description\":\"\"}]" }
      let(:encrypted) { "[{\"name\":\"p_one\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"true\",\"is_array\":\"false\",\"parent_array\":\"\",\"description\":\"\"}]" }
      let(:encrypted_array) { "[{\"name\":\"data_array\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_child\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"true\",\"is_array\":\"false\",\"parent_array\":\"data_array\",\"description\":\"\"}]" }
      let(:mapped) { "[{\"name\":\"data\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"1\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"false\",\"parent_array\":\"\",\"description\":\"\"}]" }
      let(:mapped_array) { "[{\"name\":\"data_array\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"false\",\"is_array\":\"true\",\"parent_array\":\"\",\"description\":\"\"},{\"name\":\"data_child\",\"ref_name\":\"\",\"validation\":\"\",\"mapping\":\"1\",\"mandatory\":\"true\",\"enable_validation\":\"false\",\"encrypted\":\"true\",\"is_array\":\"false\",\"parent_array\":\"data_array\",\"description\":\"\"}]" }

      let(:public_key) { "-----BEGIN PUBLIC KEY-----\r\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuu7z3ozAenQrz+87CJiv\r\ns1aCM5ZM9kh7NPVIxPUPgvTHPIKQz6nIhGTpd7M+tvdA2RU90WE+CW0lzNsl8qK0\r\ngpNMvZTX/kNwanqk1P2nyeTNF8rkermJJHsYIevgmvpNaVBgnVuuqXC0aZiIq8zt\r\ncOoR6+vMWBwyN2aq7vT3Pu3KG16eBZrqvEZsFgv68zxmgjaAmxO6I5dBvwpKJy8E\r\n9kNaCHNQ4JG7/+YcC60TynzaWvR4Cv3q7eS34zR/K5lHhPUlwFJoOFL7jCcCENSa\r\nzy5XCX1ozNPTIbKQVsnDC2JQ1QKigYinTrKjoGijXaX6uwB0S1wNt0sFT0ecNSWi\r\n3wIDAQAB\r\n-----END PUBLIC KEY-----\r\n" }
      let(:insurer_map) { "[{\"id\":\"1\",\"master\":[\"Male\",\"Female\"],\"value\":[\"M\",\"F\"]}]" }

      it 'for standard variable' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        insurer_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_method: 'POST', api_url: "http://0.0.0.0:3002/insurer_one/api/two", payload_validation: standard, payload: ipa_body, headers: headers)
        get :index, :params => {:route => 'api/test', :data => '1111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body": Base64.strict_encode64("{\"data\":\"1111\"}")
            }
        ]
        expect(response.body).to eql(expect_body.to_json)

      end

      it 'for encrypted variable ' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        insurer_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_method: 'POST', api_url: "http://0.0.0.0:3002/insurer_one/api/three", payload_validation: encrypted, payload: ipa_body_encrypted, RSA_encrypt_public_key: public_key, headers: headers)
        get :index, :params => {:route => 'api/test', :p_one => 'hello world'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body":''
            }
        ]
        expect(response.body).to eql(expect_body.to_json)

      end

      it 'for mapped variable' do
        setup_request
        product = create(:product)
        insurer = create(:insurer, mapping: insurer_map)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        insurer_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_method: 'POST', api_url: "http://0.0.0.0:3002/insurer_one/api/two", payload_validation: mapped, payload: ipa_body, headers: headers)
        get :index, :params => {:route => 'api/test', :data => 'Male'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body": Base64.strict_encode64("{\"data\":\"M\"}")
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
      end

      it 'for standard variable (array)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        insurer_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_method: 'POST', api_url: "http://0.0.0.0:3002/insurer_one/api/two", payload_validation: standard_array, payload: ipa_body_array, headers: headers)
        get :index, :params => {:route => 'api/test', :data_array => [{ :data_child => '1234' }]}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body": Base64.strict_encode64("{\"data_array\":[{\"child\":\"1234\"}]}")
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
      end

      # it 'for encrypted variable (array)' do
      #
      #   setup_request
      #   product = create(:product)
      #   insurer = create(:insurer)
      #   create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
      #   client = create(:client)
      #   create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
      #   client_api = create(:client_api, method: 'GET', validation: false, product: product)
      #   create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
      #   insurer_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_method: 'POST', api_url: "http://0.0.0.0:3002/insurer_one/api/two", payload_validation: encrypted_array, payload: ipa_body_array, RSA_encrypt_public_key: public_key, headers: headers)
      #   get :index, :params => {:route => 'api/test', :data_array => [{ :data_child => '1234' }]}
      #   key = OpenSSL::PKey::RSA.new(public_key)
      #   expect(response).to have_http_status(:ok)
      #   expect_body = [
      #       {
      #           "company_code":"11111",
      #           "payload_type":"JSON",
      #           "response_code":200,
      #           "response_body": Base64.strict_encode64("{\"data_array\":[{\"child\":\"#{Base64.encode64(key.public_encrypt('1234')).gsub("\n", '')}\"}]}")
      #       }
      #   ]
      #   puts response.body
      #   expect(response.body).to eql(expect_body.to_json)
      #
      # end
      #
      # it 'for mapped variable (array)' do
      # end

    end

    describe 'Request API' do

      it 'should received response code 500 for request timeout/error during request (log created)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_url: "123" )
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":503,
                "reason":"TIMEOUT"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
        expect(Delayed::Job.count).to eq 2

      end

      it 'should received error response code for REMOTE_SERVER_ERROR (log created)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_method: "POST", api_url: "http://0.0.0.0:3002/insurer_one/api/four" )
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":500,
                "response_body":"",
                "reason":"REMOTE_SERVER_ERROR"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
        expect(Delayed::Job.count).to eq 2

      end

      it 'should saved response body to Cache Table (log created)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_url: "http://0.0.0.0:3002/insurer_one/api/one", cache_policy: 'Database', cache_timeout: 1)
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect(Delayed::Job.count).to eq 3

      end

      it 'get response body from Cache Table (log created)' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        insurer_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_url: "http://0.0.0.0:3002/insurer_one/api/one", cache_policy: 'Database', cache_timeout: 1)
        create(:response_cache, insurer_product_api_id: insurer_api.id, url:'http://0.0.0.0:3002/insurer_one/api/one', expired_at: Time.current + 1.hour)
        get :index, :params => {:route => 'api/test', :data => '11'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body": Base64.strict_encode64('1234567890')
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
        expect(Delayed::Job.count).to eq 2
      end

      it 'flavor Type 1' do
        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_url: "http://0.0.0.0:3002/insurer_one/api/one", cache_policy: 'Live', headers: headers )
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body":"#{Base64.encode64({"data":"value"}.to_json).gsub("\n", '')}"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
        expect(Delayed::Job.count).to eq 2
      end

      it 'flavor Type 2' do

        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_url: "http://0.0.0.0:3002/insurer_two/api_one", cache_policy: 'Live', api_flavour: 'Type 2' , auth_scheme_name: "Basic _im_token", credential: "dGVzdGVyOnBhc3N3b3Jk", headers: headers )
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body":"#{Base64.encode64({"data":"value"}.to_json).gsub("\n", '')}"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
        expect(Delayed::Job.count).to eq 2

      end

      it 'flavor Type 3' do

        setup_request
        product = create(:product)
        insurer = create(:insurer)
        create(:insurer_product, insurer_id: insurer.id, product_id: product.id)
        client = create(:client)
        create(:insurer_client, insurer_id: insurer.id, client_id:client.id, product_id: product.id)
        client_api = create(:client_api, method: 'GET', validation: false, product: product)
        create(:client_api_client, client_api_id: client_api.id, client_id: client.id)
        authentication_api = create(:insurer_product_api, insurer_id: insurer.id, client_api: nil, validation: false, payload: '', cache_policy: 'Live', api_method: 'POST', api_url: "http://0.0.0.0:3002/insurer_3/auth_json", is_authentication: true, auth_token_key_name: 'token//value', headers: headers)
        create(:insurer_product_api, insurer_id: insurer.id, client_api: client_api, validation: false, api_url: "http://0.0.0.0:3002/insurer_3/api_one", cache_policy: 'Live', api_flavour: 'Type 3' , auth_scheme_name: "Token token=_im_token", headers: headers, auth_api: authentication_api.id )
        get :index, :params => {:route => 'api/test', :insurer_company_code => '11111'}
        expect(response).to have_http_status(:ok)
        expect_body = [
            {
                "company_code":"11111",
                "payload_type":"JSON",
                "response_code":200,
                "response_body":"#{Base64.encode64({"data":"value"}.to_json).gsub("\n", '')}"
            }
        ]
        expect(response.body).to eql(expect_body.to_json)
        expect(Delayed::Job.count).to eq 3

      end


    end

  end


end
