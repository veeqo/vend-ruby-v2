# frozen_string_literal: true

require 'securerandom'

RSpec.describe 'Raising on 422 Unprocessable Entity' do
  let(:store) { 'teststore' }
  let(:product_id) { SecureRandom.uuid }
  let(:path) { "https://#{store}.vendhq.com/api/2.1/products/#{product_id}" }
  let(:response_body) { { error: 'Outlet ID is required' }.to_json }

  let(:connection) do
    Vend::Connection.build(Vend::Config.new(domain_prefix: store, access_token: SecureRandom.hex))
  end

  subject { Vend::V21::Product.update(product_id, details: { inventory: [] }, connection: connection) }

  before { stub_request(:put, path).to_return(status: 422, body: response_body, headers: {}) }

  it 'raises Vend::UnprocessableEntity with the response body as message' do
    expect { subject }.to raise_error(Vend::UnprocessableEntity, response_body)
  end

  it 'raises a Vend::HttpError' do
    expect { subject }.to raise_error(Vend::HttpError)
  end
end
