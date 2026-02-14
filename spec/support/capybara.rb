require "capybara/rspec"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1280, 800 ],
    browser_options: {},
    process_timeout: 10,
    timeout: 10,
    headless: true
  )
end

Capybara.javascript_driver = :cuprite
Capybara.default_driver = :cuprite

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
