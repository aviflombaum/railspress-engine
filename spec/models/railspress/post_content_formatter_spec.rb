# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::PostContentFormatter, type: :model do
  describe "#to_html" do
    it "preserves HTML content" do
      formatter = described_class.new(content: "<h2>Heading</h2><p>Body</p>", format: :html)

      expect(formatter.to_html).to eq("<h2>Heading</h2><p>Body</p>")
    end

    it "renders Markdown as HTML" do
      formatter = described_class.new(content: "## Heading\n\n**Body**", format: :markdown)

      expect(formatter.to_html).to include("<h2>Heading</h2>", "<strong>Body</strong>")
    end

    it "escapes and preserves plain text without interpreting Markdown" do
      formatter = described_class.new(content: "# Literal <title>\nsecond line", format: :plain)

      expect(formatter.to_html).to eq("<p># Literal &lt;title&gt;<br>second line</p>")
    end

    it "detects an obvious Markdown document when auto is requested" do
      formatter = described_class.new(content: "## Heading\n\nBody", format: :auto)

      expect(formatter.to_html).to include("<h2>Heading</h2>")
    end

    it "rejects unsupported formats" do
      formatter = described_class.new(content: "Body", format: :rst)

      expect(formatter).not_to be_supported
      expect { formatter.to_html }.to raise_error(ArgumentError, "Unsupported content format: rst")
    end
  end
end
