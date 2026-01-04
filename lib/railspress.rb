require "railspress/version"
require "railspress/engine"
require "railspress/entity"
require "lexxy"

module Railspress
  class Configuration
    attr_accessor :author_class_name,
                  :current_author_method,
                  :current_author_proc,
                  :author_scope,
                  :author_display_method,
                  :words_per_minute,
                  :blog_path

    attr_reader :authors_enabled, :header_images_enabled

    def initialize
      @authors_enabled = false
      @header_images_enabled = false
      @author_class_name = "User"
      @current_author_method = :current_user
      @current_author_proc = nil
      @author_scope = nil
      @author_display_method = :name
      @words_per_minute = 200
      @blog_path = "/blog"
    end

    # Declarative setter: config.enable_authors
    def enable_authors
      @authors_enabled = true
    end

    # Declarative setter: config.enable_header_images
    def enable_header_images
      @header_images_enabled = true
    end

    # Register a host model as a CMS-managed entity
    #
    # Accepts class, string, or symbol. String/symbol registration is preferred
    # for Rails reloader compatibility in development.
    #
    # Registration is deferred until first access - this allows registration
    # in initializers before models are loaded by Zeitwerk.
    #
    # @param identifier [Class, String, Symbol] The model to register
    # @param options [Hash] Optional configuration
    # @option options [String] :label Custom sidebar/header label
    #
    # @example String registration (preferred)
    #   config.register_entity "Project"
    #   config.register_entity "Portfolio", label: "Work Samples"
    #
    # @example Symbol registration
    #   config.register_entity :project
    #   config.register_entity :admin_portfolio, label: "Work Samples"
    #
    # @example Class registration (works but may have stale refs after reload)
    #   config.register_entity Project
    #
    def register_entity(identifier, options = {})
      # Normalize to class name string
      class_name = case identifier
                   when String then identifier
                   when Symbol then identifier.to_s.camelize
                   when Class  then identifier.name
                   else
                     raise ArgumentError, "Expected String, Symbol, or Class, got #{identifier.class}"
                   end

      # Compute route_key from class name (e.g., "Project" -> "projects")
      route_key = class_name.underscore.pluralize

      # Store just the class name and options - resolved fresh on each access
      entity_registrations[route_key] = { class_name: class_name, options: options }
    end

    # Entity registrations: route_key => { class_name:, options: }
    # We store class names (strings), not config objects, so Rails reloading works
    def entity_registrations
      @entity_registrations ||= {}
    end

    # Get all registered entities - resolves fresh on each call
    def registered_entities
      result = {}
      entity_registrations.each do |route_key, registration|
        config = resolve_entity(registration[:class_name], registration[:options])
        result[route_key] = config if config
      end
      result
    end

    # Find entity config by route key - resolves fresh on each call
    def entity_for(route_key)
      registration = entity_registrations[route_key.to_s]
      return nil unless registration

      resolve_entity(registration[:class_name], registration[:options])
    end

    # Check if an entity is registered
    def entity_registered?(route_key)
      entity_registrations.key?(route_key.to_s)
    end

    private

    def resolve_entity(class_name, options)
      klass = class_name.constantize
      unless klass.included_modules.include?(Railspress::Entity)
        raise ArgumentError, "#{class_name} must include Railspress::Entity"
      end

      config = klass.railspress_config
      config.label = options[:label] if options[:label]
      config
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    # Convenience accessors
    def authors_enabled?
      configuration.authors_enabled
    end

    def header_images_enabled?
      configuration.header_images_enabled
    end

    def author_class
      configuration.author_class_name.constantize
    end

    def available_authors
      scope = configuration.author_scope
      klass = author_class

      case scope
      when Symbol then klass.public_send(scope)
      when Proc   then scope.call(klass)
      else             klass.all
      end
    end

    def author_display_method
      configuration.author_display_method
    end

    def current_author_method
      configuration.current_author_method
    end

    def current_author_proc
      configuration.current_author_proc
    end

    def words_per_minute
      configuration.words_per_minute
    end

    def blog_path
      configuration.blog_path
    end

    # Entity registry convenience accessors
    def registered_entities
      configuration.registered_entities
    end

    def entity_for(route_key)
      configuration.entity_for(route_key)
    end

    def entity_registered?(route_key)
      configuration.entity_registered?(route_key)
    end
  end
end
