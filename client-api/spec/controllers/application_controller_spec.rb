require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  it 'returns 404 for unsupported path' do
    get :render_no_route
    expect(response).to have_http_status(404)
  end
end
