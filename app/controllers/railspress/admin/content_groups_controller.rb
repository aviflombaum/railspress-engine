# frozen_string_literal: true

module Railspress
  module Admin
    class ContentGroupsController < BaseController
      before_action :set_content_group, only: [:show, :edit, :update, :destroy]

      def index
        @content_groups = ContentGroup.active
                                      .includes(:content_elements)
                                      .order(created_at: :desc)
      end

      def show
        @content_elements = @content_group.content_elements
                                          .active
                                          .ordered
      end

      def new
        @content_group = ContentGroup.new
      end

      def create
        @content_group = ContentGroup.new(content_group_params)
        @content_group.author_id = current_author&.id if authors_enabled?

        if @content_group.save
          redirect_to admin_content_group_path(@content_group), notice: "Content group '#{@content_group.name}' created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @content_group.update(content_group_params)
          redirect_to admin_content_group_path(@content_group), notice: "Content group '#{@content_group.name}' updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @content_group.soft_delete
        redirect_to admin_content_groups_path, notice: "Content group '#{@content_group.name}' deleted."
      end

      private

      def set_content_group
        @content_group = ContentGroup.active.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_content_groups_path, alert: "Content group not found."
      end

      def content_group_params
        params.require(:content_group).permit(:name, :description)
      end
    end
  end
end
