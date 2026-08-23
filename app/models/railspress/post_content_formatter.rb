# frozen_string_literal: true

require "erb"
require "redcarpet"

module Railspress
  class PostContentFormatter
    SUPPORTED_FORMATS = %w[html markdown plain auto].freeze
    FORMAT_ALIASES = {
      "htm" => "html",
      "md" => "markdown",
      "text" => "plain",
      "text/html" => "html",
      "text/markdown" => "markdown",
      "text/plain" => "plain"
    }.freeze

    HTML_PATTERN = /<\/?[a-z][^>]*>/i
    MARKDOWN_PATTERN = /(?:\A|\n)\s{0,3}(?:\#{1,6}\s|>|[-+*]\s|\d+\.\s|```)|\[[^\]]+\]\([^)]+\)|\*\*[^*]+\*\*/

    attr_reader :content, :format

    def initialize(content:, format: nil)
      @content = content.to_s
      @format = normalize_format(format)
    end

    def supported?
      SUPPORTED_FORMATS.include?(format)
    end

    def to_html
      case resolved_format
      when "html" then content
      when "markdown" then render_markdown
      when "plain" then render_plain_text
      else raise ArgumentError, "Unsupported content format: #{format}"
      end
    end

    private

    def normalize_format(value)
      normalized = value.presence&.to_s&.strip&.downcase || "html"
      FORMAT_ALIASES.fetch(normalized, normalized)
    end

    def resolved_format
      return format unless format == "auto"
      return "html" if content.match?(HTML_PATTERN)
      return "markdown" if content.match?(MARKDOWN_PATTERN)

      "plain"
    end

    def render_markdown
      renderer = Redcarpet::Render::HTML.new(
        hard_wrap: true,
        filter_html: false,
        safe_links_only: true
      )

      Redcarpet::Markdown.new(
        renderer,
        autolink: true,
        tables: true,
        fenced_code_blocks: true,
        strikethrough: true,
        highlight: true,
        superscript: true,
        no_intra_emphasis: true
      ).render(content)
    end

    def render_plain_text
      return "" if content.blank?

      ERB::Util.html_escape(content)
        .split(/\n{2,}/)
        .map { |paragraph| "<p>#{paragraph.gsub("\n", "<br>")}</p>" }
        .join
    end
  end
end
