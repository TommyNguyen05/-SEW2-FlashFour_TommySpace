# This migration creates the users table.
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # The user's email address, used for login and notifications. Must be unique.
      # Tommy: change email to username
      t.string :username, null: false
      # The user's display name, shown publicly.
      t.string :display_name, null: false
      # The user's encrypted password.
      t.string :password_digest, null: false

      t.timestamps
    end
    # Add an index to the email column for faster lookups and to enforce uniqueness.
    add_index :users, :email, unique: true
  end
end
