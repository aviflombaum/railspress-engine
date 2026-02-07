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

Railspress::ContentElement.find_or_create_by!(name: "hero", content_group: homepage) do |e|
  e.content_type = :text
  e.text_content = "A powerful CMS engine for Rails applications"
  e.position = 1
end

Railspress::ContentElement.find_or_create_by!(name: "about", content_group: homepage) do |e|
  e.content_type = :text
  e.text_content = "RailsPress is a mountable Rails engine providing blog and CMS functionality with content groups, elements, versioning, and a chainable API."
  e.position = 2
end

puts "Done! Created #{Railspress::ContentGroup.count} groups and #{Railspress::ContentElement.count} elements."
