module Railspress
  module ApplicationHelper
    # Formats reading time for display
    # @param post [Railspress::Post] the post to format reading time for
    # @param format [Symbol] :short for "5 min" or :long for "5 minute read"
    # @return [String] formatted reading time
    def reading_time(post, format: :short)
      minutes = post.reading_time_display
      case format
      when :long
        "#{minutes} minute read"
      else
        "#{minutes} min"
      end
    end

    # Returns the featured image URL for a post, useful for og:image meta tags
    # @param post [Railspress::Post] the post
    # @param variant [Hash] image variant options (default: resize_to_limit: [1200, 630])
    # @return [String, nil] the image URL or nil if no image attached
    def featured_image_url(post, variant: { resize_to_limit: [ 1200, 630 ] })
      return nil unless post.header_image.attached?

      main_app.url_for(post.header_image.variant(variant))
    end
  end
end
