# frozen_string_literal: true

require 'securerandom'

RSpec.describe Vend::V21::Product do
  it { is_expected.to be_a(Vend::Resource) }

  describe '.update' do
    let(:store) { 'teststore' }
    let(:product_id) { SecureRandom.uuid }
    let(:params) do
      {
        details: {
          inventory: [
            {
              outlet_id: SecureRandom.uuid,
              current_amount: 10
            }
          ]
        }
      }
    end

    let(:connection) do
      Vend::Connection.build(Vend::Config.new(domain_prefix: store, access_token: SecureRandom.hex))
    end

    subject { described_class.update(product_id, params.merge(connection: connection)) }

    before dos
      stub_request(
        :put,
        "https://#{store}.vendhq.com/api/2.1/products/#{product_id}",
      )
      .with(body: params.to_json)
      .to_return(
        body: response.to_json,
        headers: {},
        status: 200
      )
    end

    let(:response) do
      {
        'data' => {
          'product_id' => product_id,
          'common' => {
            'name' => 'Test product',
            'description' => 'Description',
            'track_inventory' => true,
            'brand_id' => '4dc0a66c-201b-c111-4397-b63bdddcf2e4',
            'product_category_id' => '2fa7fc75-451d-be27-b1a5-6de7c1c0d3ff',
            'product_suppliers' => [
              {
                'id' => '8f26486c-5e15-40bb-b375-45bb541c4649',
                'supplier_id' => nil
              }
            ],
            'variant_attributes' => [
              {
                'id' => 1,
                'attribute_id' => '39676602-6198-4574-bc7f-72dfb8b7915c'
              }
            ]
          },
          'details' => {
            'is_active' => true,
            'variant_name' => 'Test product / S / Green',
            'product_codes' => [{'type' => 'CUSTOM','code' => 'MU-HM-S'}],
            'price_excluding_tax' => 25,
            'outlet_taxes' => [],
            'inventory' => [
              {
                'outlet_id' => '10346b77-b098-4d8d-b83a-c0bcc01326cf',
                'current_amount' => 21,
                'reorder_amount' => 0,
                'reorder_point' => 0,
                'initial_average_cost' => nil
              }
            ],
            'product_suppliers' => [
              {
                'supplier_id' => '',
                'price' => 20
              }
            ],
            'variant_attribute_values' => [
              {
                'attribute_id' => '39676602-6198-4574-bc7f-72dfb8b7915c',
                'attribute_value' => 'S'
              }
            ]
          }
        }
      }
    end

    it 'performs a request to the corresponding API path' do
      expect(subject).to eq(Oj.load(response.to_json, symbol_keys: true))

      expect(
        a_request(:put, "https://#{store}.vendhq.com/api/2.1/products/#{product_id}").with(body: params.to_json)
      ).to have_been_made
    end
  end
end
