# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Blog code blocks", type: :system do
  it "contains long code lines within the page across reference viewports" do
    post = Railspress::Post.find_by!(slug: "hello-world")
    long_line = "puts #{'very_long_identifier_' * 20}"
    post.update!(content: %(<pre>#{long_line}</pre>))

    visit blog_post_path(slug: post.slug)

    expect(page).to have_css(".post-content pre")
    [ 375, 768, 1024 ].each do |width|
      page.current_window.resize_to(width, 800)
      metrics = page.evaluate_script(<<~JAVASCRIPT)
        (() => {
          const block = document.querySelector('.post-content pre')
          const container = document.querySelector('.post-content')

          return {
            documentWidth: document.documentElement.scrollWidth,
            viewportWidth: document.documentElement.clientWidth,
            blockWidth: block.getBoundingClientRect().width,
            containerWidth: container.getBoundingClientRect().width,
            overflowX: getComputedStyle(block).overflowX,
            blockScrollWidth: block.scrollWidth,
            blockClientWidth: block.clientWidth
          }
        })()
      JAVASCRIPT

      expect(metrics.fetch("documentWidth")).to be <= metrics.fetch("viewportWidth"), "at #{width}px"
      expect(metrics.fetch("blockWidth")).to be <= metrics.fetch("containerWidth"), "at #{width}px"
      expect(metrics.fetch("overflowX")).to eq("auto"), "at #{width}px"
      expect(metrics.fetch("blockScrollWidth")).to be > metrics.fetch("blockClientWidth"), "at #{width}px"
    end
  end
end
