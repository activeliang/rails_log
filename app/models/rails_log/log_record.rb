module RailsLog::LogRecord
  extend ActiveSupport::Concern
  included do
    attribute :controller_name, :string
    attribute :action_name, :string
    attribute :params, :json, default: {}
    attribute :headers, :json, default: {}
    attribute :cookie, :json, default: {}
    attribute :session, :json, default: {}
  
    default_scope -> { order(id: :desc) }
  end
  
  class_methods do
    def record_to_log(controller, exp)
      return if Rails.env.development? && RailsLog.config.disable_debug
  
      request = controller.request
      headers = request.headers
  
      lc = self.new
      lc.path = request.fullpath
      lc.controller_name = controller.class.name
      lc.action_name = controller.action_name
      lc.params = filter_params(request.filtered_parameters)
      lc.headers = request_headers(headers)
      lc.cookie = headers['rack.request.cookie_hash']
      lc.session = Hash.new(headers['rack.session'])
      lc.exception = [exp.class.name, exp.message].join("\r\n")[0..columns_limit['exception']]
      lc.exception_object = exp.class.to_s
      lc.exception_backtrace = exp.backtrace.join("\r\n")[0..columns_limit['exception_backtrace']]
      lc.save
    end

    def request_headers(headers)
      result = headers.select { |k, _| k.start_with?('HTTP_') && k != 'HTTP_COOKIE' }
      result = result.collect { |pair| [pair[0].sub(/^HTTP_/, ''), pair[1]] }
      result.sort.to_h
    end

    def filter_params(params)
      params.deep_transform_values(&:to_s).except('controller', 'action')
    end

    def columns_limit
      @columns_limit ||= self.columns_hash.slice('params', 'headers', 'cookie', 'session', 'exception', 'exception_object', 'exception_backtrace').transform_values { |i| i.limit.nil? ? -1 : i.limit - 1 }
    end
  end
  
end
