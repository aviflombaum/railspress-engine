# frozen_string_literal: true

class CreateRailspressAgentBootstrapKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_agent_bootstrap_keys do |t|
      t.string :name, null: false
      t.string :global_uuid, null: false
      t.string :token_prefix, null: false
      t.string :token_digest, null: false
      t.text :secret_ciphertext, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :used_ip
      t.datetime :revoked_at
      t.string :revoke_reason
      t.bigint :exchanged_api_key_id

      t.string :owner_type
      t.bigint :owner_id

      t.string :created_by_type
      t.bigint :created_by_id
      t.string :revoked_by_type
      t.bigint :revoked_by_id

      t.timestamps
    end

    add_index :railspress_agent_bootstrap_keys, :global_uuid, unique: true
    add_index :railspress_agent_bootstrap_keys, :token_prefix
    add_index :railspress_agent_bootstrap_keys, :token_digest, unique: true
    add_index :railspress_agent_bootstrap_keys, :exchanged_api_key_id
    add_index :railspress_agent_bootstrap_keys, [ :owner_type, :owner_id ], name: "idx_rp_agent_bootstrap_keys_owner"
    add_index :railspress_agent_bootstrap_keys, [ :created_by_type, :created_by_id ], name: "idx_rp_agent_bootstrap_keys_created_by"
    add_index :railspress_agent_bootstrap_keys, [ :revoked_by_type, :revoked_by_id ], name: "idx_rp_agent_bootstrap_keys_revoked_by"
  end
end
