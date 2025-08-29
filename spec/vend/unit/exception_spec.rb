RSpec.describe Vend::HttpErrors do
  let(:dummy_class) { Class.new { extend Vend::HttpErrors } }
  let(:env) { double }
  let(:body) { {} }
  let(:headers) { {} }

  before do
    allow(env).to receive(:body) { body }
    allow(env).to receive(:[]) { headers }
  end

  it '::ERRORS is not nil' do
    expect(Vend::HttpErrors::ERRORS).not_to be_nil
  end

  context 'when received a successful response' do
    it 'does not throw an exception' do
      (200..299).each do |code|
        expect { dummy_class.throw_http_exception!(code, env) }.not_to raise_exception
      end
    end
  end

  context 'when response code is 0' do
    subject { dummy_class.throw_http_exception!(0, env) }

    let(:body) { 'Request timeout' }

    it 'throws the default exception' do
      expect { subject }.to raise_exception(Vend::HttpError, body)
    end
  end

  context 'when response code is not successful' do
    context 'when response code is mapped to a known exception class' do
      let(:unknown_error_codes) { [*100..199] + [*300..599] - Vend::HttpErrors::ERRORS.keys }

      let(:body) { 'Something web wrong' }

      it 'throws the default exception' do
        expect(unknown_error_codes.count).to be_positive

        unknown_error_codes.each do |code|
          expect { dummy_class.throw_http_exception!(code, env) }.to raise_exception(Vend::HttpError, body)
        end
      end
    end

    context 'when received code 402' do
      let(:code) { 402 }
      let(:body) do
        <<~HTML
        <html>
        <head><title>402 Payment Required</title></head>
        <body>
        <center><h1>402 Payment Required</h1></center>
        <hr><center>openresty</center>
        </body>
        </html>
        HTML
      end

      it 'throws a corresponding exception' do
        expect { dummy_class.throw_http_exception!(code, env) }.to raise_exception(Vend::PaymentRequired, body)
      end
    end

    context 'when received code 404' do
      let(:code) { 404 }

      it 'throws a corresponding exception' do
        expect { dummy_class.throw_http_exception!(code, env) }.to raise_exception(Vend::NotFound)
      end
    end

    context 'when received a known code' do
      let(:body) { '{ "error": "something went wrong" }' }

      it 'throws a corresponding exception class' do
        Vend::HttpErrors::ERRORS.keys.each do |code|
          expect { dummy_class.throw_http_exception!(code, env) }.to raise_exception(Vend::HttpErrors::ERRORS[code], body)
        end
      end
    end

    context 'when have a body and response headers' do
      let(:body) { JSON.generate({ time: '1426184190' }) }
      let(:headers) { { 'X-Retry-After' => 1 } }
      let(:code) { 429 }

      it 'should parse out a retry-after header if present' do
        begin
          dummy_class.throw_http_exception!(code, env)
        rescue Vend::TooManyRequests => e
          expect(e.response_headers[:retry_after]).to eq 1
        end
      end
    end

    context 'when we get a string body' do
      let(:body) { 'Unauthorized' }
      let(:code) { 401 }

      it 'handle string in body' do
        begin
          dummy_class.throw_http_exception!(code, env)
        rescue Vend::Unauthorized => e
          expect(e.message).to eq body
        end
      end
    end
  end
end
