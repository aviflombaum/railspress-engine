# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe "AllowNullRailspressTokenCiphertext migration" do
  it "migrates, rolls back with a non-secret sentinel, and re-migrates" do
    migration_path = Railspress::Engine.root.join(
      "db/migrate/20260902000001_allow_null_railspress_token_ciphertext.rb"
    )
    script = <<~RUBY
      require "active_record"
      require "sqlite3"

      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
      ActiveRecord::Migration.verbose = false
      connection = ActiveRecord::Base.connection
      connection.create_table(:railspress_api_keys) { |table| table.text :secret_ciphertext, null: false }
      connection.create_table(:railspress_agent_bootstrap_keys) { |table| table.text :secret_ciphertext, null: false }
      load #{migration_path.to_s.inspect}

      migration = AllowNullRailspressTokenCiphertext.new
      migration.migrate(:up)
      connection.execute("INSERT INTO railspress_api_keys (secret_ciphertext) VALUES (NULL)")
      connection.execute("INSERT INTO railspress_agent_bootstrap_keys (secret_ciphertext) VALUES (NULL)")
      migration.migrate(:down)

      sentinel = AllowNullRailspressTokenCiphertext::COMPATIBILITY_SENTINEL
      raise "API sentinel missing" unless connection.select_value("SELECT secret_ciphertext FROM railspress_api_keys") == sentinel
      raise "bootstrap sentinel missing" unless connection.select_value("SELECT secret_ciphertext FROM railspress_agent_bootstrap_keys") == sentinel
      raise "API column remained nullable" if connection.columns(:railspress_api_keys).find { _1.name == "secret_ciphertext" }.null
      raise "bootstrap column remained nullable" if connection.columns(:railspress_agent_bootstrap_keys).find { _1.name == "secret_ciphertext" }.null

      migration.migrate(:up)
      raise "API column was not relaxed" unless connection.columns(:railspress_api_keys).find { _1.name == "secret_ciphertext" }.null
      raise "bootstrap column was not relaxed" unless connection.columns(:railspress_agent_bootstrap_keys).find { _1.name == "secret_ciphertext" }.null
    RUBY

    stdout, stderr, status = Open3.capture3("bundle", "exec", "ruby", "-e", script)

    expect(status).to be_success, "#{stdout}\n#{stderr}"
  end
end
