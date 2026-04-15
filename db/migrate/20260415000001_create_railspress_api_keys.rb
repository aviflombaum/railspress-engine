# frozen_string_literal: true

class CreateRailspressApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_api_keys do |t|
      t.string :name, null: false
      t.string :global_uuid, null: false
      t.string :token_prefix, null: false
      t.string :token_digest, null: false
      t.text :secret_ciphertext, null: false
      t.datetime :expires_at
      t.datetime :last_used_at
      t.string :last_used_ip
      t.datetime :revoked_at
      t.string :revoke_reason
      t.integer :rotated_from_id

      t.string :owner_type
      t.bigint :owner_id

      t.string :created_by_type
      t.bigint :created_by_id
      t.string :rotated_by_type
      t.bigint :rotated_by_id
      t.string :revoked_by_type
      t.bigint :revoked_by_id

      t.timestamps
    end

    add_index :railspress_api_keys, :global_uuid, unique: true
    add_index :railspress_api_keys, :token_prefix
    add_index :railspress_api_keys, :token_digest, unique: true
    add_index :railspress_api_keys, :rotated_from_id
    add_index :railspress_api_keys, [ :owner_type, :owner_id ]
    add_index :railspress_api_keys, [ :created_by_type, :created_by_id ]
    add_index :railspress_api_keys, [ :rotated_by_type, :rotated_by_id ]
    add_index :railspress_api_keys, [ :revoked_by_type, :revoked_by_id ]
  end
end
