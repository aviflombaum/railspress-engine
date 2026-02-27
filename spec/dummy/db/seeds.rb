# Seed content groups and elements for CMS demo
puts "Seeding CMS content..."

headers = Railspress::ContentGroup.find_or_create_by!(name: "Headers") do |g|
  g.description = "Site header content elements"
end

footers = Railspress::ContentGroup.find_or_create_by!(name: "Footers") do |g|
  g.description = "Site footer content elements"
end

homepage = Railspress::ContentGroup.find_or_create_by!(name: "Homepage") do |g|
  g.description = "Homepage content sections"
end

Railspress::ContentElement.find_or_create_by!(name: "Homepage H1", content_group: headers) do |e|
  e.content_type = :text
  e.text_content = "Welcome to Our Site"
  e.position = 1
end

Railspress::ContentElement.find_or_create_by!(name: "Tagline", content_group: headers) do |e|
  e.content_type = :text
  e.text_content = "Building the future, one line of code at a time"
  e.position = 2
end

Railspress::ContentElement.find_or_create_by!(name: "Footer Text", content_group: footers) do |e|
  e.content_type = :text
  e.text_content = "© #{Time.current.year} RailsPress. All rights reserved."
  e.position = 1
end

Railspress::ContentElement.find_or_create_by!(name: "headline", content_group: homepage) do |e|
  e.content_type = :text
  e.text_content = "Build with RailsPress"
  e.position = 1
end

Railspress::ContentElement.find_or_create_by!(name: "subheadline", content_group: homepage) do |e|
  e.content_type = :text
  e.text_content = "A complete CMS for Rails 8 — blog, entities, and inline-editable blocks in one mountable engine."
  e.position = 2
end

Railspress::ContentElement.find_or_create_by!(name: "cta_text", content_group: homepage) do |e|
  e.content_type = :text
  e.text_content = "View Our Work"
  e.position = 3
end

puts "Done! Created #{Railspress::ContentGroup.count} groups and #{Railspress::ContentElement.count} elements."

# Seed projects for portfolio demo
puts "Seeding projects..."

Project.find_or_create_by!(title: "Portfolio Website") do |p|
  p.client = "Creative Agency"
  p.description = "A modern portfolio website with animations and responsive design. Built with Rails 8 and Hotwire for a seamless, app-like experience."
  p.featured = true
  p.tech_stack = [ "Ruby", "Rails", "PostgreSQL", "Stimulus" ]
  p.highlights = [ "Launched in 3 weeks", "99 Lighthouse score", "Featured in Ruby Weekly" ]
end

Project.find_or_create_by!(title: "E-commerce Platform") do |p|
  p.client = "Retail Corp"
  p.description = "Full-featured online store with Stripe payments, inventory management, and real-time order tracking."
  p.featured = true
  p.tech_stack = [ "Ruby", "Rails", "Stripe", "Redis", "Sidekiq" ]
  p.highlights = [ "Processes 10k orders/day", "99.9% uptime", "Sub-second page loads" ]
end

Project.find_or_create_by!(title: "Mobile App") do |p|
  p.client = "Startup Inc"
  p.description = "Cross-platform mobile application for iOS and Android with real-time messaging and push notifications."
  p.featured = false
  p.tech_stack = [ "React Native", "TypeScript", "GraphQL" ]
  p.highlights = [ "50k downloads in first month", "4.8 star rating" ]
end

puts "Done! Created #{Project.count} projects."

# Seed blog content
puts "Seeding blog posts..."

category = Railspress::Category.find_or_create_by!(name: "Tutorials") do |c|
  c.slug = "tutorials"
end

Railspress::Post.find_or_create_by!(title: "Getting Started with RailsPress") do |p|
  p.slug = "getting-started-with-railspress"
  p.status = :published
  p.published_at = 2.days.ago
  p.category = category
  p.content = "RailsPress makes it easy to add a complete CMS to your Rails application. In this guide, we'll walk through installation, configuration, and creating your first content."
end

Railspress::Post.find_or_create_by!(title: "Mastering Inline Editing") do |p|
  p.slug = "mastering-inline-editing"
  p.status = :published
  p.published_at = 1.day.ago
  p.category = category
  p.content = "Learn how to use RailsPress's inline editing feature to let content editors update text directly on the page with right-click editing powered by Turbo Streams."
end

puts "Done! Created #{Railspress::Post.count} posts."
