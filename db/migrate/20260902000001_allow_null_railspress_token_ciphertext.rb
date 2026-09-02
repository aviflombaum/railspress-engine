# frozen_string_literal: true

class AllowNullRailspressTokenCiphertext < ActiveRecord::Migration[8.1]
  COMPATIBILITY_SENTINEL = "railspress-digest-only-token"

  def up
    change_column_null :railspress_api_keys, :secret_ciphertext, true
    change_column_null :railspress_agent_bootstrap_keys, :secret_ciphertext, true
  end

  def down
    change_column_null :railspress_api_keys, :secret_ciphertext, false, COMPATIBILITY_SENTINEL
    change_column_null :railspress_agent_bootstrap_keys, :secret_ciphertext, false, COMPATIBILITY_SENTINEL
  end
end
