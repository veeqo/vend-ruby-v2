module Vend
  class HttpError < StandardError
    attr_accessor :response_headers
    attr_reader :status, :body

    def initialize(response_headers, status: nil, body: nil)
      @response_headers = response_headers
      @status = status
      @body = body
      super()
    end
  end

  class BadRequest < HttpError; end
  class Unauthorized < HttpError; end
  class Forbidden < HttpError; end
  class NotFound < HttpError; end
  class MethodNotAllowed < HttpError; end
  class NotAccepted < HttpError; end
  class TimeOut < HttpError; end
  class ResourceConflict < HttpError; end
  class UnprocessableEntity < HttpError; end
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
      403 => Vend::Forbidden,
      404 => Vend::NotFound,
      405 => Vend::MethodNotAllowed,
      406 => Vend::NotAccepted,
      408 => Vend::TimeOut,
      409 => Vend::ResourceConflict,
      422 => Vend::UnprocessableEntity,
      429 => Vend::TooManyRequests,
      500 => Vend::InternalServerError,
      502 => Vend::BadGateway,
      503 => Vend::ServiceUnavailable,
      504 => Vend::GatewayTimeout,
      509 => Vend::BandwidthLimitExceeded
    }.freeze

    def throw_http_exception!(code, env)
      return if (200..299).cover?(code)

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
      error_class = ERRORS.fetch(code, Vend::HttpError)
      raise error_class.new(response_headers, status: code, body: env.body), env.body
    end
  end
end
