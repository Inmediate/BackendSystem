class AuthenticationController < ApplicationController
  include ActionController::HttpAuthentication::Token::ControllerMethods
  before_action :authenticate
  before_action :whitelist_ip

  # ERROR
  ERROR_AUTHRORIZATION ={ code: '101', message: 'Authorization header not present.' }.freeze
  ERROR_API_KEY_NOT_SUPPORTED = { code: '102', message: 'API key from authorization header is not match with list of active client.' }.freeze
  ERROR_WHITELIST_IP_NOT_SUPPORTED = { code: '103', message: 'IP is not within the whitelisted IP list.' }.freeze
  ERROR_CLIENT_NOT_SUPPORTED = { code: '104', message: 'Client is not allowed to use this Client API.' }.freeze
  ERROR_INSURER_NOT_SUPPORTED = { code: '105', message: 'The requested insurer does not support this end point.' }.freeze
  ERROR_INSURER_NOT_MATCH = { code: '106', message: 'Fail to match with any insurers.' }.freeze
  ERROR_ROUTE_NOT_MATCH = { code: '107', message: 'Fail to match with a route.' }.freeze
  ERROR_VALIDATION = { code: '108', message: 'Validation error in one or more fields.' }.freeze
  ERROR_MANDATORY_MISSING = { code: '109', message: 'Missing one or more mandatory fields.' }.freeze
  ERROR_SERVER_FAIL = { code: '110', message: 'No response from upstream server.' }.freeze

  protected

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_or_request_with_http_token do |token, _options|
      params[:x_token] = token
      @client = Client.where(activation_status: true).where(status: true).find_by_client_api_key(token.to_s)
    end
  end

  def whitelist_ip
    unless current_client.whitelisted_ip.blank?
      unless current_client.whitelisted_ip.split.include?(request.remote_ip)
        # render json: ERROR_WHITELIST_IP_NOT_SUPPORTED.to_json, status: :forbidden
        render_error(ERROR_WHITELIST_IP_NOT_SUPPORTED, "forbidden")
        return
      end
    end
  end

  def current_client
    @client
  end

  def render_error(message_eror, code_error)
    if request.headers['Accept'] == 'application/xml'
      render xml: message_eror.to_xml({root: 'error'}), status: :"#{code_error}"
    else
      render json: {error: message_eror}.to_json, status: :"#{code_error}"
    end
  end

end
