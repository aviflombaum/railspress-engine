# Example pages controller demonstrating how to use the RailsPress CMS
# in a host application's frontend views.
class PagesController < ApplicationController
  helper Railspress::CmsHelper

  def index
    @groups = Railspress::ContentGroup.active.includes(:content_elements).ordered
  end
end
