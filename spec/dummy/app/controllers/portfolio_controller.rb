class PortfolioController < ApplicationController
  def index
    @projects = Project.ordered
  end

  def show
    @project = Project.find(params[:id])
  end
end
