class ApplicationController < ActionController::Base
  private

  def spec_authenticate_admin!
    head :forbidden unless request.headers["X-Railspress-Admin"] == "allowed"
  end

  def spec_current_admin
    User.find_by(id: request.headers["X-Railspress-Actor-ID"])
  end
end
