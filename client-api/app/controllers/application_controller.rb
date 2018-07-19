class ApplicationController < ActionController::API
  def render_no_route
    head :not_found
  end

  def render_unauthorized
    headers['WWW-Authenticate'] = 'Token realm="Application"'
    head :unauthorized
  end

end
