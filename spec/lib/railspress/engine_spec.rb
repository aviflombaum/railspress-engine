# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe Railspress::Engine do
  describe "CMS helper load hook" do
    it "does not depend on app helper autoload timing" do
      script = <<~RUBY
        require "rails/all"
        require "railspress"

        Railspress.reset_configuration!

        initializer = Railspress::Engine.initializers.find { |item| item.name == "railspress.cms_helper" }
        initializer.bind(Railspress::Engine.instance).run(nil)

        ActiveSupport.run_load_hooks(:action_view, Class.new)
      RUBY

      stdout, stderr, status = Open3.capture3("bundle", "exec", "ruby", "-Ilib", "-e", script)
      expect(status).to be_success, "#{stdout}\n#{stderr}"
    end
  end
end
