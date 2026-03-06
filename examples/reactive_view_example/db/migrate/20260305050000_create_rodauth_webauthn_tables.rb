# frozen_string_literal: true

class CreateRodauthWebauthnTables < ActiveRecord::Migration[8.0]
  def change
    create_table :account_webauthn_user_ids, id: false do |t|
      t.integer :id, primary_key: true
      t.string :webauthn_id, null: false
      t.foreign_key :users, column: :id, on_delete: :cascade
    end

    add_index :account_webauthn_user_ids, :webauthn_id, unique: true

    create_table :account_webauthn_keys, id: false do |t|
      t.integer :account_id, null: false
      t.string :webauthn_id, null: false
      t.string :public_key, null: false
      t.integer :sign_count, null: false
      t.datetime :last_use
      t.foreign_key :users, column: :account_id, on_delete: :cascade
    end

    add_index :account_webauthn_keys, %i[account_id webauthn_id], unique: true
  end
end
