# frozen_string_literal: true

require 'securerandom'

RSpec.describe 'Raising on non-2xx HTTP responses' do
  let(:store) { 'teststore' }
  let(:product_id) { SecureRandom.uuid }
  let(:path) { "https://#{store}.vendhq.com/api/2.1/products/#{product_id}" }
  let(:params) { { details: { inventory: [] } } }

  let(:connection) do
    Vend::Connection.build(Vend::Config.new(domain_prefix: store, access_token: SecureRandom.hex))
  end

  subject { Vend::V21::Product.update(product_id, params.merge(connection: connection)) }

  context 'when the response is 422 Unprocessable Entity' do
    before do
      stub_request(:put, path).to_return(
        status: 422,
        body: { error: 'Outlet ID is required' }.to_json,
        headers: {}
      )
    end

    it 'raises Vend::UnprocessableEntity carrying the status and body' do
      expect { subject }.to raise_error(Vend::UnprocessableEntity) do |error|
        expect(error.status).to eq(422)
        expect(error.body).to eq({ error: 'Outlet ID is required' }.to_json)
        expect(error.response_headers).to eq(error: 'Outlet ID is required')
      end
    end

    it 'is a Vend::HttpError' do
      expect { subject }.to raise_error(Vend::HttpError)
    end
  end

  context 'when the response is a non-2xx status without a dedicated class' do
    before do
      stub_request(:put, path).to_return(
        status: 418,
        body: { error: "I'm a teapot" }.to_json,
        headers: {}
      )
    end

    it 'raises the generic Vend::HttpError carrying the status and body' do
      expect { subject }.to raise_error(Vend::HttpError) do |error|
        expect(error.status).to eq(418)
        expect(error.body).to eq({ error: "I'm a teapot" }.to_json)
      end
    end
  end

  context 'when the response is a mapped error status' do
    before do
      stub_request(:put, path).to_return(status: 404, body: '', headers: {})
    end

    it 'raises the dedicated error class carrying the status' do
      expect { subject }.to raise_error(Vend::NotFound) do |error|
        expect(error.status).to eq(404)
      end
    end
  end

  context 'when the response is 2xx' do
    before do
      stub_request(:put, path).to_return(
        status: 200,
        body: { data: {} }.to_json,
        headers: {}
      )
    end

    it 'does not raise' do
      expect { subject }.not_to raise_error
    end
  end
end
