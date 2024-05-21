# Products V2.1
# https://x-series-api.lightspeedhq.com/reference/updateproduct

module Vend
  module V21
    class Product < Resource
      include Vend::ResourceActions.new api_version: '2.1', uri: 'products'
    end
  end
end
