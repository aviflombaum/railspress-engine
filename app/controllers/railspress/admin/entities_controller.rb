# frozen_string_literal: true

module Railspress
  module Admin
    class EntitiesController < BaseController
      before_action :set_entity_config
      before_action :set_record, only: [:show, :edit, :update, :destroy, :image_editor]

      def index
        @records = entity_class.order(created_at: :desc)
      end

      def show
      end

      def new
        @record = entity_class.new
      end

      def create
        @record = entity_class.new(entity_params)

        if @record.save
          redirect_to entity_index_path, notice: "#{entity_config.singular_label} created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        purge_removed_attachments
        if @record.update(entity_params)
          redirect_to entity_index_path, notice: "#{entity_config.singular_label} updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @record.destroy
        redirect_to entity_index_path, notice: "#{entity_config.singular_label} deleted."
      end

      # GET /admin/entities/:entity_type/:id/image_editor/:attachment
      # Returns the expanded image editor in a Turbo Frame
      # Pass ?compact=true to get the compact view (for Cancel)
      def image_editor
        @attachment_name = params[:attachment].to_sym

        if params[:compact] == "true"
          render partial: "railspress/admin/shared/image_section_compact",
                 locals: {
                   record: @record,
                   attachment_name: @attachment_name,
                   label: entity_config.singular_label
                 }
        else
          # Ensure focal point is persisted before editing
          focal_point = @record.send("#{@attachment_name}_focal_point")
          focal_point.save! if focal_point.new_record?

          render partial: "railspress/admin/shared/image_section_editor",
                 locals: {
                   record: @record,
                   attachment_name: @attachment_name,
                   contexts: Railspress.image_contexts
                 }
        end
      end

      private

      def set_entity_config
        @entity_config = Railspress.entity_for(params[:entity_type])
        raise ActionController::RoutingError, "Entity not found: #{params[:entity_type]}" unless @entity_config
      end

      def entity_config
        @entity_config
      end
      helper_method :entity_config

      def entity_class
        entity_config.model_class
      end
      helper_method :entity_class

      def set_record
        @record = entity_class.find(params[:id])
      end

      def entity_params
        permitted = []
        entity_config.fields.each do |name, field|
          case field[:type]
          when :attachments
            permitted << { name => [] }
          when :list, :lines
            # Permit virtual attribute for HTML form input
            permitted << "#{name}_list"
            # Also permit direct array for API/agent access
            permitted << { name => [] }
          else
            permitted << name
          end
        end
        params.require(entity_config.param_key).permit(*permitted)
      end

      def purge_removed_attachments
        entity_config.fields.each do |name, field|
          next unless [:attachment, :attachments].include?(field[:type])

          remove_key = "remove_#{name}"
          remove_ids = params.dig(entity_config.param_key, remove_key)
          next if remove_ids.blank?

          if field[:type] == :attachments
            @record.public_send(name).where(id: remove_ids).each(&:purge)
          else
            @record.public_send(name).purge if remove_ids == "1"
          end
        end
      end

      # Route helpers for views
      def entity_index_path
        railspress.admin_entity_index_path(entity_type: entity_config.route_key)
      end
      helper_method :entity_index_path

      def entity_show_path(record)
        railspress.admin_entity_path(entity_type: entity_config.route_key, id: record.id)
      end
      helper_method :entity_show_path

      def entity_new_path
        railspress.admin_new_entity_path(entity_type: entity_config.route_key)
      end
      helper_method :entity_new_path

      def entity_edit_path(record)
        railspress.admin_edit_entity_path(entity_type: entity_config.route_key, id: record.id)
      end
      helper_method :entity_edit_path
    end
  end
end
