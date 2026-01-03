# frozen_string_literal: true

module Railspress
  module Admin
    class EntitiesController < BaseController
      before_action :set_entity_config
      before_action :set_record, only: [:show, :edit, :update, :destroy]

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
