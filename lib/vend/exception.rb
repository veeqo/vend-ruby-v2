module Vend
  class HttpError < StandardError
    attr_accessor :response_headers
    def initialize(headers)
      @response_headers = headers
    end
  end

  class BadRequest < HttpError; end
  class Unauthorized < HttpError; end
  class PaymentRequired < HttpError; end
  class Forbidden < HttpError; end
  class NotFound < HttpError; end
  class MethodNotAllowed < HttpError; end
  class NotAccepted < HttpError; end
  class TimeOut < HttpError; end
  class ResourceConflict < HttpError; end
  class TooManyRequests < HttpError; end
  class InternalServerError < HttpError; end
  class BadGateway < HttpError; end
  class ServiceUnavailable < HttpError; end
  class GatewayTimeout < HttpError; end
  class BandwidthLimitExceeded < HttpError; end

  module HttpErrors
    ERRORS = {
      400 => Vend::BadRequest,
      401 => Vend::Unauthorized,
      402 => Vend::PaymentRequired,
      403 => Vend::Forbidden,
      404 => Vend::NotFound,
      405 => Vend::MethodNotAllowed,
      406 => Vend::NotAccepted,
      408 => Vend::TimeOut,
      409 => Vend::ResourceConflict,
      429 => Vend::TooManyRequests,
      500 => Vend::InternalServerError,
      502 => Vend::BadGateway,
      503 => Vend::ServiceUnavailable,
      504 => Vend::GatewayTimeout,
      509 => Vend::BandwidthLimitExceeded
    }.freeze

    def throw_http_exception!(code, env)
      return if (200..299).include?(code.to_i)

      response_headers = extract_headers_for_error(env)
      error_class = error_class_by(code)

      raise error_class.new(response_headers), env.body
    end

    def error_class_by(code)
      ERRORS.fetch(code, ::Vend::HttpError)
    end

    def extract_headers_for_error(env)
      response_headers = {}

      unless env.body.empty?
        response_headers = begin
          Oj.load(env.body, symbol_keys: true)
        rescue
          {}
        end
      end

      unless env[:response_headers] && env[:response_headers]['X-Retry-After'].nil?
        response_headers[:retry_after] = env[:response_headers]['X-Retry-After'].to_i
      end

      response_headers
    end
  end
end
