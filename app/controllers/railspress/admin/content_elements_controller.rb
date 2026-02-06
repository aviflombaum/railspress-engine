# frozen_string_literal: true

module Railspress
  module Admin
    class ContentElementsController < BaseController
      before_action :set_content_element, only: [:show, :edit, :update, :destroy, :inline]

      def index
        scope = ContentElement.active
        scope = scope.where(content_group_id: params[:content_group_id]) if params[:content_group_id].present?
        @content_elements = scope.includes(:content_group)
                                 .order(created_at: :desc)
        @content_groups = ContentGroup.active.order(:name)
      end

      def show
        @versions = @content_element.versions.limit(10)
      end

      def new
        @content_element = ContentElement.new
        @content_groups = ContentGroup.active.order(:name)
        @content_element.content_group_id = params[:content_group_id] if params[:content_group_id].present?
      end

      def create
        @content_element = ContentElement.new(content_element_params)
        @content_element.author_id = current_author&.id if authors_enabled?

        if @content_element.save
          redirect_to admin_content_element_path(@content_element), notice: "Content element '#{@content_element.name}' created."
        else
          @content_groups = ContentGroup.active.order(:name)
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @content_groups = ContentGroup.active.order(:name)
      end

      def update
        if @content_element.update(content_element_params)
          Railspress::CmsHelper.clear_cache if defined?(Railspress::CmsHelper)

          if request.headers["Turbo-Frame"].present?
            render turbo_stream: turbo_stream.replace(
              "cms_inline_editor_form_#{@content_element.id}",
              partial: "railspress/admin/content_elements/inline_form_frame",
              locals: { content_element: @content_element }
            )
          else
            redirect_to admin_content_element_path(@content_element), notice: "Content element '#{@content_element.name}' updated."
          end
        else
          @content_groups = ContentGroup.active.order(:name)

          if request.headers["Turbo-Frame"].present?
            render turbo_stream: turbo_stream.replace(
              "cms_inline_editor_form_#{@content_element.id}",
              partial: "railspress/admin/content_elements/inline_form_frame",
              locals: { content_element: @content_element }
            ), status: :unprocessable_entity
          else
            render :edit, status: :unprocessable_entity
          end
        end
      end

      def destroy
        @content_element.soft_delete
        redirect_to admin_content_elements_path, notice: "Content element '#{@content_element.name}' deleted."
      end

      def inline
        if request.headers["Turbo-Frame"].present?
          render partial: "railspress/admin/content_elements/inline_form_frame",
                 locals: { content_element: @content_element }
        else
          redirect_to edit_admin_content_element_path(@content_element)
        end
      end

      private

      def set_content_element
        @content_element = ContentElement.active.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_content_elements_path, alert: "Content element not found."
      end

      def content_element_params
        params.require(:content_element).permit(:name, :content_group_id, :content_type, :position, :text_content, :image)
      end
    end
  end
end
