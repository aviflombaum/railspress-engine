require "railspress/version"
require "railspress/engine"
require "lexxy"

module Railspress
  class Configuration
    attr_accessor :author_class_name,
                  :current_author_method,
                  :author_scope,
                  :author_display_method

    attr_reader :authors_enabled, :header_images_enabled

    def initialize
      @authors_enabled = false
      @header_images_enabled = false
      @author_class_name = "User"
      @current_author_method = :current_user
      @author_scope = nil
      @author_display_method = :name
    end

    # Declarative setter: config.enable_authors
    def enable_authors
      @authors_enabled = true
    end

    # Declarative setter: config.enable_header_images
    def enable_header_images
      @header_images_enabled = true
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
  end
end
